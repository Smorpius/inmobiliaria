import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  MySqlConnection? _connection;
  final Logger _logger = Logger('DatabaseService');

  // Configuración mejorada para conexión y reintentos
  static const int maxRetries = 5; // Aumentado de 3 a 5
  static const int initialRetryDelay = 500; // milisegundos
  static const Duration connectionTimeout = Duration(seconds: 20); // Aumentado
  static const Duration estabilizacionPeriod = Duration(seconds: 5);

  // Control de estado de conexión
  bool _isReconnecting = false;
  DateTime? _lastConnectionAttempt;
  bool _reconectadoRecientemente = false;
  Timer? _reconexionTimer;

  // Circuit breaker - nuevo
  int _consecutiveFailures = 0;
  bool _circuitOpen = false;
  DateTime? _circuitResetTime;
  static const int maxConsecutiveFailures = 5;
  static const Duration circuitResetDuration = Duration(minutes: 2);

  // Aumentar intervalo de heartbeat para reducir sobrecarga
  static const Duration heartbeatInterval = Duration(
    seconds: 120,
  ); // Aumentado a 2 minutos
  Timer? _heartbeatTimer;

  // Getter para verificar si hubo una reconexión reciente
  bool get reconectadoRecientemente => _reconectadoRecientemente;

  factory DatabaseService() => _instance;

  DatabaseService._internal() {
    _startHeartbeat();
  }

  Future<MySqlConnection> get connection async {
    if (_connection == null || await _isConnectionClosed()) {
      return await _getConnection();
    }
    return _connection!;
  }

  Future<bool> _isConnectionClosed() async {
    if (_connection == null) return true;

    try {
      // Prueba más confiable de estado de conexión
      final results = await _connection!
          .query('SELECT 1 as test')
          .timeout(
            const Duration(seconds: 2),
            onTimeout:
                () =>
                    throw TimeoutException(
                      'Prueba de conexión excedió el tiempo límite',
                    ),
          );
      return results.isEmpty || results.first.fields['test'] != 1;
    } catch (e) {
      developer.log('La conexión parece estar cerrada o en mal estado: $e');
      return true;
    }
  }

  Future<MySqlConnection> _getConnection() async {
    // Verificar si el circuit breaker está activo - nuevo
    if (_circuitOpen) {
      if (_circuitResetTime != null &&
          DateTime.now().isAfter(_circuitResetTime!)) {
        // Intentar resetear el circuit breaker
        _circuitOpen = false;
        _consecutiveFailures = 0;
        developer.log('Circuit breaker reseteado, intentando reconexión');
      } else {
        developer.log(
          'Circuit breaker activo, conexión bloqueada temporalmente',
        );
        throw Exception(
          'Conexión a base de datos temporalmente deshabilitada por fallos consecutivos',
        );
      }
    }

    // Evitar reconexiones simultáneas
    if (_isReconnecting) {
      developer.log('Reconexión en progreso, esperando...');
      await Future.delayed(const Duration(milliseconds: 700));
      return connection; // Llamada recursiva tras la espera
    }

    // Control de frecuencia de reconexión
    final now = DateTime.now();
    if (_lastConnectionAttempt != null &&
        now.difference(_lastConnectionAttempt!) < const Duration(seconds: 3)) {
      developer.log(
        'Demasiadas reconexiones en poco tiempo, esperando estabilización...',
      );
      await Future.delayed(const Duration(seconds: 1));
    }

    _isReconnecting = true;
    _lastConnectionAttempt = now;

    try {
      // Cerrar cualquier conexión existente que pudiera estar en mal estado
      if (_connection != null) {
        try {
          await _connection!.close().timeout(
            const Duration(seconds: 2),
            onTimeout:
                () => developer.log(
                  'Tiempo de espera agotado al cerrar conexión anterior',
                ),
          );
        } catch (e) {
          developer.log('Error ignorado al cerrar conexión previa: $e');
        }
        _connection = null;
      }

      // Configuración de conexión corregida (useCompression: false)
      final settings = ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'root',
        password: '123456789',
        db: 'Proyecto_Prueba',
        timeout: connectionTimeout,
        maxPacketSize: 33554432, // 32 MB
        useCompression: false, // CORREGIDO: mysql1 no soporta compresión
        useSSL: false, // Sin SSL para local
      );

      // Implementar reintentos con espera exponencial
      int attempts = 0;
      while (attempts < maxRetries) {
        try {
          final newConnection = await MySqlConnection.connect(settings).timeout(
            connectionTimeout,
            onTimeout:
                () =>
                    throw TimeoutException(
                      'Conexión a MySQL excedió el tiempo límite',
                    ),
          );

          _connection = newConnection;
          developer.log(
            'Conexión a MySQL establecida exitosamente (intento ${attempts + 1})',
          );

          // Reiniciar heartbeat con la nueva conexión
          _restartHeartbeat();

          // Marcar como reconectado recientemente
          _marcarReconexionReciente();

          // Periodo de estabilización más robusto
          for (int i = 0; i < 5; i++) {
            developer.log('Esperando estabilización de conexión...');
            await Future.delayed(Duration(seconds: 2));
          }
          developer.log('Período de estabilización de conexión completado');

          _consecutiveFailures = 0; // Resetear contador de fallos
          _isReconnecting = false;
          return _connection!;
        } catch (e) {
          attempts++;
          final delay = Duration(
            milliseconds: initialRetryDelay * (1 << attempts),
          );
          developer.log(
            'Intento $attempts de conexión falló: $e. Reintentando en ${delay.inMilliseconds}ms',
          );

          if (attempts >= maxRetries) {
            _consecutiveFailures++;

            // Activar circuit breaker si hay demasiados fallos
            if (_consecutiveFailures >= maxConsecutiveFailures) {
              _circuitOpen = true;
              _circuitResetTime = DateTime.now().add(circuitResetDuration);
              developer.log(
                'Circuit breaker activado por $_consecutiveFailures fallos consecutivos',
              );
            }

            _logger.severe(
              'No se pudo establecer conexión después de $maxRetries intentos',
            );
            _isReconnecting = false;
            rethrow;
          }

          await Future.delayed(delay);
        }
      }

      throw Exception('No se pudo establecer conexión tras múltiples intentos');
    } catch (e) {
      _isReconnecting = false;
      _logger.severe('Error en proceso de conexión: $e');
      rethrow;
    }
  }

  // Método para marcar reconexión reciente con timer para resetear
  void _marcarReconexionReciente() {
    _reconectadoRecientemente = true;

    // Cancelar timer existente si hay uno
    _reconexionTimer?.cancel();

    // Programar reset del estado después del período de estabilización
    _reconexionTimer = Timer(estabilizacionPeriod, () {
      _reconectadoRecientemente = false;
      developer.log('Estado de reconexión reciente reseteado');
    });
  }

  // Método mejorado para ejecutar consultas con reintentos automáticos
  Future<Results> executeQuery(String query, [List<Object>? params]) async {
    int attempts = 0;
    late Exception lastError;

    while (attempts < maxRetries) {
      try {
        final conn = await connection; // Usar getter que verifica estado
        return await conn
            .query(query, params)
            .timeout(
              const Duration(seconds: 20),
              onTimeout:
                  () =>
                      throw TimeoutException(
                        'Consulta excedió el tiempo límite',
                      ),
            );
      } catch (e) {
        attempts++;
        lastError = e is Exception ? e : Exception(e.toString());

        final isConnectionError =
            e.toString().toLowerCase().contains('closed') ||
            e.toString().toLowerCase().contains('socket') ||
            e.toString().toLowerCase().contains('connection') ||
            e is TimeoutException;

        if (isConnectionError) {
          _logger.warning(
            'Error de conexión en consulta (intento $attempts): $e',
          );
          _connection = null; // Forzar nueva conexión
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        } else {
          _logger.severe('Error de consulta no relacionado con conexión: $e');
          rethrow; // Para errores no relacionados con conexión, no reintentar
        }

        if (attempts >= maxRetries) {
          _logger.severe('Consulta falló después de $maxRetries intentos');
          throw Exception('Consulta falló tras múltiples intentos: $lastError');
        }
      }
    }

    throw lastError;
  }

  // Heartbeat más robusto con menor frecuencia
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) async {
      if (_connection == null || _isReconnecting) return;

      try {
        developer.log(
          'Enviando heartbeat a la base de datos...',
          level: 800,
        ); // Nivel alto para reducir logs
        await _connection!
            .query('SELECT 1')
            .timeout(
              const Duration(seconds: 5),
              onTimeout:
                  () =>
                      throw TimeoutException('Heartbeat excedió tiempo límite'),
            );
        developer.log('Heartbeat exitoso', level: 800);
      } catch (e) {
        developer.log('Error en heartbeat: $e');

        // Marcar conexión para renovación
        _connection = null;

        // En lugar de reconectar inmediatamente, programamos con delay
        Timer(Duration(seconds: 3), () async {
          try {
            await _getConnection();
            developer.log('Reconexión tras heartbeat fallido exitosa');
          } catch (reconnectError) {
            developer.log(
              'Reconexión tras heartbeat fallido falló: $reconnectError',
            );
          }
        });
      }
    });
  }

  void _restartHeartbeat() {
    _startHeartbeat();
  }

  // Método para esperar estabilización si es necesario
  Future<void> esperarEstabilizacion() async {
    if (_reconectadoRecientemente) {
      developer.log('Esperando estabilización de conexión...');
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // Método mejorado para reiniciar conexión
  Future<void> reiniciarConexion() async {
    developer.log('Reinicio forzado de conexión iniciado');

    _heartbeatTimer?.cancel();
    _consecutiveFailures = 0; // Resetear contador de fallos
    _circuitOpen = false; // Resetear circuit breaker

    if (_connection != null) {
      try {
        await _connection!.close().timeout(
          const Duration(seconds: 3),
          onTimeout: () => developer.log('Tiempo agotado al cerrar conexión'),
        );
      } catch (e) {
        developer.log('Error al cerrar conexión: $e');
      }
      _connection = null;
    }

    try {
      await _getConnection();
      developer.log('Reinicio forzado de conexión completado exitosamente');
    } catch (e) {
      developer.log('Error en reinicio forzado de conexión: $e');
      // No propagar la excepción, simplemente registrarla
    }
  }

  Future<bool> isConnected() async {
    if (_connection == null) return false;

    try {
      final results = await _connection!
          .query('SELECT 1 as test')
          .timeout(
            const Duration(seconds: 3),
            onTimeout:
                () =>
                    throw TimeoutException(
                      'Verificación de conexión excedió tiempo límite',
                    ),
          );
      return results.isNotEmpty && results.first.fields['test'] == 1;
    } catch (e) {
      developer.log('Error al verificar estado de conexión: $e');
      return false;
    }
  }

  // Método mejorado para cerrar conexión
  Future<void> closeConnection() async {
    _heartbeatTimer?.cancel();
    _reconexionTimer?.cancel();

    if (_connection != null) {
      try {
        await _connection!.close().timeout(
          const Duration(seconds: 5),
          onTimeout:
              () => developer.log('Cierre de conexión excedió tiempo límite'),
        );
        developer.log('Conexión cerrada correctamente');
      } catch (e) {
        developer.log('Error al cerrar conexión: $e');
      } finally {
        _connection = null;
      }
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _reconexionTimer?.cancel();
    closeConnection();
  }
}

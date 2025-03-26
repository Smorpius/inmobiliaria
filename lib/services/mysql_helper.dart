import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';

/// Excepción personalizada para errores de base de datos
class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  DatabaseException(this.message, {this.originalError, this.stackTrace});

  @override
  String toString() {
    if (originalError != null) {
      return 'DatabaseException: $message (Causa: $originalError)';
    }
    return 'DatabaseException: $message';
  }
}

/// Servicio mejorado para gestión de conexiones a MySQL con alta tolerancia a fallos
class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  MySqlConnection? _connection;
  final Logger _logger = Logger('DatabaseService');

  // Configuración mejorada para conexión y reintentos
  static const int maxRetries = 2;
  static const int initialRetryDelay = 3000;
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration queryTimeout = Duration(seconds: 15);
  static const Duration estabilizacionPeriod = Duration(seconds: 5);

  // Pool de conexiones para mejorar la gestión de recursos
  final List<MySqlConnection> _connectionPool = [];
  static const int maxPoolSize = 3;

  // Control de estado de conexión
  bool _isReconnecting = false;
  DateTime? _lastConnectionAttempt;
  bool _reconectadoRecientemente = false;
  Timer? _reconexionTimer;

  // Circuit breaker
  int _consecutiveFailures = 0;
  bool _circuitOpen = false;
  DateTime? _circuitResetTime;
  static const int maxConsecutiveFailures = 5;
  static const Duration circuitResetDuration = Duration(minutes: 1);

  // Healthcheck
  static const Duration heartbeatInterval = Duration(seconds: 60);
  Timer? _heartbeatTimer;

  /// Getter para verificar si hubo una reconexión reciente
  bool get reconectadoRecientemente => _reconectadoRecientemente;

  /// Getter para verificar estado del circuit breaker
  bool get isCircuitOpen => _circuitOpen;

  factory DatabaseService() => _instance;

  DatabaseService._internal() {
    _startHeartbeat();
    _initializePool();
  }

  /// Inicializa el pool de conexiones
  Future<void> _initializePool() async {
    try {
      while (_connectionPool.length < maxPoolSize) {
        final conn = await _createNewConnection();
        if (conn != null) {
          _connectionPool.add(conn);
        }
      }
      developer.log(
        'Pool de conexiones inicializado con ${_connectionPool.length} conexiones',
      );
    } catch (e) {
      developer.log('Error al inicializar pool de conexiones: $e');
    }
  }

  /// Obtiene una conexión del pool o crea una nueva si es necesario
  Future<MySqlConnection> get connection async {
    // Si hay conexiones disponibles en el pool, usarlas primero
    if (_connectionPool.isNotEmpty) {
      final conn = _connectionPool.removeLast();
      try {
        final isActive = await _testConnection(conn);
        if (isActive) {
          return conn;
        }
        await conn.close().timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        );
      } catch (_) {
        // Ignorar errores al verificar conexiones del pool
      }
    }

    // Si no hay conexiones disponibles en el pool o la obtenida no era válida
    if (_connection == null || await _isConnectionClosed()) {
      return await _getConnection();
    }

    return _connection!;
  }

  /// Libera una conexión devolviéndola al pool si es posible
  Future<void> releaseConnection(MySqlConnection conn) async {
    if (_connectionPool.length < maxPoolSize) {
      _connectionPool.add(conn);
    } else {
      try {
        await conn.close().timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      } catch (e) {
        developer.log('Error al cerrar conexión liberada: $e');
      }
    }
  }

  // Mejorar verificación de conexión
  Future<bool> _testConnection(MySqlConnection conn) async {
    try {
      final results = await conn
          .query('SELECT 1 as test')
          .timeout(const Duration(seconds: 3)); // Aumentar timeout
      return results.isNotEmpty && results.first.fields['test'] == 1;
    } catch (e) {
      developer.log('Error en prueba de conexión: $e');
      return false;
    }
  }

  /// Verifica si la conexión actual está cerrada o en mal estado
  Future<bool> _isConnectionClosed() async {
    if (_connection == null) return true;

    try {
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

  /// Crea una nueva conexión a la base de datos con manejo de errores mejorado
  Future<MySqlConnection?> _createNewConnection() async {
    try {
      final settings = ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'root',
        password: '123456789',
        db: 'Proyecto_Prueba',
        timeout: connectionTimeout,
        maxPacketSize: 67108864, // 64MB según la configuración en el SQL
        useCompression: false,
        useSSL: false,
      );

      final newConnection = await MySqlConnection.connect(settings).timeout(
        connectionTimeout,
        onTimeout:
            () =>
                throw TimeoutException(
                  'Conexión a MySQL excedió el tiempo límite',
                ),
      );

      developer.log('Nueva conexión a MySQL establecida exitosamente');
      return newConnection;
    } catch (e) {
      developer.log('Error al crear nueva conexión: $e');
      return null;
    }
  }

  /// Obtiene una conexión a la base de datos con reintentos y circuit breaker
  Future<MySqlConnection> _getConnection() async {
    // Si hay demasiados fallos consecutivos, esperar más tiempo
    if (_consecutiveFailures > maxConsecutiveFailures) {
      await Future.delayed(const Duration(seconds: 5));
      _consecutiveFailures = maxConsecutiveFailures ~/ 2; // Reducir contador
      developer.log(
        'Demasiados fallos consecutivos, esperando período extendido',
      );
    }

    // Verificar si el circuit breaker está activo
    if (_circuitOpen) {
      if (_circuitResetTime != null &&
          DateTime.now().isAfter(_circuitResetTime!)) {
        _circuitOpen = false;
        _consecutiveFailures = 0;
        developer.log('Circuit breaker reseteado, intentando reconexión');
      } else {
        throw DatabaseException(
          'Conexión a base de datos bloqueada temporalmente por fallos consecutivos',
          originalError: 'Circuit breaker activo hasta $_circuitResetTime',
        );
      }
    }

    // Evitar reconexiones simultáneas
    if (_isReconnecting) {
      developer.log('Reconexión en progreso, esperando...');
      await Future.delayed(const Duration(milliseconds: 700));
      return connection;
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

      // Implementar reintentos con espera exponencial
      int attempts = 0;
      MySqlConnection? newConnection;
      Exception? lastError;

      while (attempts < maxRetries) {
        try {
          newConnection = await _createNewConnection();

          if (newConnection == null) {
            throw Exception('No se pudo crear una nueva conexión');
          }

          _connection = newConnection;
          _restartHeartbeat();
          _marcarReconexionReciente();

          developer.log('Esperando estabilización de conexión...');
          await Future.delayed(const Duration(seconds: 2));
          developer.log('Período de estabilización de conexión completado');

          _consecutiveFailures = 0;
          _isReconnecting = false;
          return _connection!;
        } catch (e) {
          attempts++;
          final delay = Duration(
            milliseconds: initialRetryDelay * (1 << attempts),
          );
          lastError = e is Exception ? e : Exception(e.toString());

          developer.log(
            'Intento $attempts de conexión falló: $e. Reintentando en ${delay.inMilliseconds}ms',
          );

          if (attempts >= maxRetries) {
            _consecutiveFailures++;
            if (_consecutiveFailures >= maxConsecutiveFailures) {
              _circuitOpen = true;
              _circuitResetTime = DateTime.now().add(circuitResetDuration);
              developer.log(
                'Circuit breaker activado por $_consecutiveFailures fallos consecutivos',
              );
            }

            _isReconnecting = false;
            throw DatabaseException(
              'Falló la conexión después de $maxRetries intentos',
              originalError: lastError,
              stackTrace: StackTrace.current,
            );
          }

          await Future.delayed(delay);
        }
      }

      throw DatabaseException(
        'No se pudo establecer conexión tras múltiples intentos',
      );
    } catch (e) {
      _isReconnecting = false;
      if (e is DatabaseException) {
        rethrow;
      }
      throw DatabaseException(
        'Error en proceso de conexión',
        originalError: e,
        stackTrace: StackTrace.current,
      );
    }
  }

  /// Marca la conexión como reconectada recientemente y programa el reset
  void _marcarReconexionReciente() {
    _reconectadoRecientemente = true;
    _reconexionTimer?.cancel();
    _reconexionTimer = Timer(estabilizacionPeriod, () {
      _reconectadoRecientemente = false;
      developer.log('Estado de reconexión reciente reseteado');
    });
  }

  /// Ejecuta una consulta con manejo de errores y reintentos automáticos
  Future<Results> executeQuery(String query, [List<Object?>? params]) async {
    int attempts = 0;
    Exception? lastError;
    MySqlConnection? connToRelease;

    while (attempts < maxRetries) {
      try {
        final conn = await connection;
        connToRelease = conn;

        final result = await conn
            .query(query, params)
            .timeout(
              queryTimeout,
              onTimeout:
                  () =>
                      throw TimeoutException(
                        'Consulta excedió el tiempo límite',
                      ),
            );

        // Si llegamos aquí, la consulta fue exitosa
        if (attempts > 0) {
          // Solo liberar si no es la primera vez, para mantener conexiones estables
          releaseConnection(connToRelease);
          connToRelease = null;
        }

        return result;
      } catch (e) {
        attempts++;
        lastError = e is Exception ? e : Exception(e.toString());

        final isConnectionError =
            e.toString().toLowerCase().contains('closed') ||
            e.toString().toLowerCase().contains('socket') ||
            e.toString().toLowerCase().contains('connection') ||
            e is TimeoutException;

        // Si es error de conexión, intentar recuperarse
        if (isConnectionError) {
          _logger.warning(
            'Error de conexión en consulta (intento $attempts): $e',
          );
          _connection = null; // Forzar nueva conexión
          connToRelease = null; // No intentar liberar una conexión con error

          final backoffDelay = Duration(
            milliseconds: initialRetryDelay * (1 << attempts),
          );
          await Future.delayed(backoffDelay);

          // En error de conexión, continuar con el siguiente intento
          continue;
        }

        // Si no es error de conexión, puede ser error de SQL o de programación
        _logger.severe('Error de consulta no relacionado con conexión: $e');

        // Liberar la conexión si está disponible
        if (connToRelease != null) {
          releaseConnection(connToRelease);
          connToRelease = null;
        }

        // No reintentar errores que no sean de conexión
        throw DatabaseException(
          'Error al ejecutar consulta',
          originalError: e,
          stackTrace: StackTrace.current,
        );
      }
    }

    // Si llegamos aquí, agotamos los reintentos para errores de conexión
    _logger.severe('Consulta falló después de $maxRetries intentos');
    throw DatabaseException(
      'Consulta falló tras múltiples intentos',
      originalError: lastError,
      stackTrace: StackTrace.current,
    );
  }

  /// Realiza una operación con reintentos automáticos
  Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxRetries =
        3, // Ajustado para ser consistente con otras partes del código
    Duration initialDelay = const Duration(
      milliseconds: 2000,
    ), // Ajustado a 2000ms
  }) async {
    int retryCount = 0;
    Exception? lastError;

    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        lastError = e is Exception ? e : Exception(e.toString());

        // Determinar si es un error de conexión que debemos reintentar
        final isConnectionError =
            e.toString().toLowerCase().contains('closed') ||
            e.toString().toLowerCase().contains('socket') ||
            e.toString().toLowerCase().contains('connection') ||
            e is TimeoutException;

        if (!isConnectionError) {
          // No reintentar errores que no son de conexión
          throw DatabaseException(
            'Error en operación de base de datos',
            originalError: e,
            stackTrace: StackTrace.current,
          );
        }

        if (retryCount >= maxRetries) {
          break; // Salir del bucle y lanzar excepción final
        }

        // Retraso exponencial para reintentos de conexión
        final delay = Duration(
          milliseconds: initialDelay.inMilliseconds * (1 << retryCount),
        );
        developer.log(
          'Reintento $retryCount después de ${delay.inMilliseconds}ms debido a: $e',
        );
        await Future.delayed(delay);
      }
    }

    // Este punto solo se alcanza si retryCount >= maxRetries y el error era de conexión
    throw DatabaseException(
      'Operación falló después de $maxRetries intentos',
      originalError: lastError,
      stackTrace: StackTrace.current,
    );
  }

  /// Inicia el mecanismo de heartbeat para mantener la conexión activa
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) async {
      if (_connection == null || _isReconnecting) return;

      try {
        // Verificación de conexión con timeout corto
        await _connection!
            .query('SELECT 1')
            .timeout(
              const Duration(seconds: 3),
              onTimeout:
                  () =>
                      throw TimeoutException('Heartbeat excedió tiempo límite'),
            );
      } catch (e) {
        developer.log('Error en heartbeat: $e');
        _connection = null; // Marcar conexión para renovación

        // Programar reconexión con delay para evitar bloqueo
        Timer(const Duration(seconds: 1), () async {
          try {
            await _getConnection();
          } catch (reconnectError) {
            developer.log(
              'Reconexión tras heartbeat fallido falló: $reconnectError',
            );
          }
        });
      }
    });
  }

  /// Reinicia el mecanismo de heartbeat
  void _restartHeartbeat() {
    _startHeartbeat();
  }

  /// Espera si ha habido una reconexión reciente para estabilizar
  Future<void> esperarEstabilizacion() async {
    if (_reconectadoRecientemente) {
      developer.log('Esperando estabilización de conexión...');

      // Limitar el tiempo máximo de espera a 2 segundos
      final maxWaitTime = const Duration(seconds: 2);
      final startTime = DateTime.now();

      while (_reconectadoRecientemente) {
        // Esperar un período corto
        await Future.delayed(const Duration(milliseconds: 100));

        // Verificar si hemos excedido el tiempo máximo
        if (DateTime.now().difference(startTime) > maxWaitTime) {
          developer.log(
            'Tiempo máximo de estabilización excedido, continuando operación',
          );
          break;
        }
      }
    }
  }

  /// Fuerza el reinicio de la conexión
  Future<void> reiniciarConexion() async {
    developer.log('Reinicio forzado de conexión iniciado');

    // Cerrar todas las conexiones primero
    await closeConnection();

    // Esperar un tiempo prudencial antes de reconectar
    await Future.delayed(const Duration(seconds: 3));

    _consecutiveFailures = 0;
    _circuitOpen = false;
    _isReconnecting = false;

    try {
      await _getConnection();
      await _initializePool();
      developer.log('Reinicio forzado de conexión completado exitosamente');
    } catch (e) {
      developer.log('Error en reinicio forzado de conexión: $e');
    }
  }

  /// Verifica si hay conexión activa actualmente
  Future<bool> isConnected() async {
    if (_connection == null) return false;

    try {
      final results = await _connection!
          .query('SELECT 1 as test')
          .timeout(
            const Duration(seconds: 2),
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

  /// Cierra todas las conexiones de manera ordenada
  Future<void> closeConnection() async {
    _heartbeatTimer?.cancel();
    _reconexionTimer?.cancel();

    // Cerrar conexión principal
    if (_connection != null) {
      try {
        await _connection!.close().timeout(
          const Duration(seconds: 3),
          onTimeout:
              () => developer.log('Cierre de conexión excedió tiempo límite'),
        );
        developer.log('Conexión principal cerrada correctamente');
      } catch (e) {
        developer.log('Error al cerrar conexión principal: $e');
      } finally {
        _connection = null;
      }
    }

    // Cerrar conexiones del pool
    int cerradas = 0;
    for (var conn in _connectionPool) {
      try {
        await conn.close().timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        );
        cerradas++;
      } catch (_) {}
    }
    _connectionPool.clear();

    if (cerradas > 0) {
      developer.log('$cerradas conexiones del pool cerradas correctamente');
    }
  }

  /// Libera recursos y cierra conexiones
  void dispose() {
    _heartbeatTimer?.cancel();
    _reconexionTimer?.cancel();
    closeConnection();
  }
}

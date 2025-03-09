import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  MySqlConnection? _connection;
  final Logger _logger = Logger('DatabaseService');

  // Configuración para reintentos
  static const int maxRetries = 3;
  static const int initialRetryDelay = 500; // milisegundos

  // Flag para detectar reconexión reciente
  bool _reconectadoRecientemente = false;

  // Getter público para verificar estado de reconexión
  bool get reconectadoRecientemente => _reconectadoRecientemente;

  // Heartbeat para mantener conexión activa
  Timer? _heartbeatTimer;
  static const Duration heartbeatInterval = Duration(seconds: 30);

  factory DatabaseService() => _instance;

  DatabaseService._internal() {
    // Iniciar el mecanismo de heartbeat
    _startHeartbeat();
  }

  Future<MySqlConnection> get connection async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        // Verificar si la conexión existe y está activa
        if (_connection != null) {
          try {
            final results = await _connection!.query('SELECT 1 as test');
            if (results.isNotEmpty && results.first.fields['test'] == 1) {
              return _connection!;
            }
          } catch (e) {
            // Ignorar error y reconectar
            _connection = null;
            developer.log(
              'Conexión existente falló, reconectando...',
              error: e,
            );
          }
        }

        // Si no hay conexión o falló la prueba, conectar de nuevo
        await _connect();
        return _connection!;
      } catch (e) {
        retryCount++;
        developer.log(
          'Error de conexión (intento $retryCount/$maxRetries): $e',
          error: e,
        );

        if (retryCount >= maxRetries) {
          throw Exception(
            'No se pudo establecer conexión después de $maxRetries intentos',
          );
        }

        await Future.delayed(
          Duration(milliseconds: initialRetryDelay * (1 << (retryCount - 1))),
        );
      }
    }

    throw Exception('Error inesperado al conectar a la base de datos');
  }

  Future<void> _connect() async {
    final settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: '123456789',
      db: 'Proyecto_Prueba',
      timeout: const Duration(seconds: 30), // Aumentar timeout para operaciones
    );

    try {
      _connection = await MySqlConnection.connect(settings);
      _logger.info('Conexión a MySQL establecida');
      developer.log('Conexión a MySQL establecida exitosamente');

      // Marcar la reconexión reciente y programar su reinicio
      _reconectadoRecientemente = true;
      Future.delayed(const Duration(seconds: 2), () {
        _reconectadoRecientemente = false;
        developer.log('Período de estabilización de conexión completado');
      });

      // Reiniciar el heartbeat después de una reconexión exitosa
      _restartHeartbeat();
    } catch (e) {
      _logger.severe('Error de conexión a MySQL: $e');
      developer.log('Error de conexión a MySQL: $e', error: e);
      rethrow;
    }
  }

  // NUEVO MÉTODO: Reiniciar la conexión forzadamente
  Future<void> reiniciarConexion() async {
    try {
      developer.log(
        'Iniciando reinicio forzado de conexión a la base de datos',
      );

      // Cancelar el heartbeat antes de cerrar
      _heartbeatTimer?.cancel();

      // Cerrar la conexión actual si existe
      if (_connection != null) {
        try {
          await _connection!.close();
          developer.log('Conexión anterior cerrada exitosamente');
        } catch (e) {
          developer.log('Error al cerrar conexión anterior: $e', error: e);
          // Continuar incluso si hay error al cerrar
        }
        _connection = null;
      }

      // Marcar como reconectado recientemente - con tiempo más largo para refresco forzado
      _reconectadoRecientemente = true;

      // Programar el restablecimiento de la bandera después de un tiempo mayor
      // para permitir que las operaciones de refresco tengan tiempo suficiente
      Future.delayed(const Duration(seconds: 10), () {
        if (_reconectadoRecientemente) {
          _reconectadoRecientemente = false;
          developer.log(
            'Bandera de reconexión forzada restablecida después de tiempo extendido',
          );
        }
      });

      // Reiniciar el heartbeat
      _startHeartbeat();

      developer.log('Reinicio forzado de conexión completado');
    } catch (e) {
      developer.log(
        'Error durante reinicio forzado de conexión: $e',
        error: e,
        stackTrace: StackTrace.current,
      );

      // Asegurar que _connection sea null en caso de error
      _connection = null;

      // Reintentar iniciar heartbeat
      _startHeartbeat();
    }
  }

  Future<bool> isConnected() async {
    if (_connection == null) return false;

    try {
      final results = await _connection!.query('SELECT 1 as test');
      return results.isNotEmpty && results.first.fields['test'] == 1;
    } catch (e) {
      developer.log('Error al verificar conexión: $e');
      return false;
    }
  }

  // Heartbeat para mantener la conexión activa
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) async {
      try {
        if (_connection != null) {
          developer.log('Enviando heartbeat a la base de datos...');
          await _connection!.query('SELECT 1');
          developer.log('Heartbeat exitoso, conexión activa');
        }
      } catch (e) {
        developer.log('Error en heartbeat: $e', error: e);
        // Intentar reconectar en el próximo ciclo
        _connection = null;
      }
    });
  }

  void _restartHeartbeat() {
    _startHeartbeat(); // Reinicia el timer del heartbeat
  }

  Future<void> closeConnection() async {
    _heartbeatTimer?.cancel(); // Detener el heartbeat

    if (_connection != null) {
      try {
        await _connection!.close();
        developer.log('Conexión a MySQL cerrada correctamente');
      } catch (e) {
        developer.log('Error al cerrar conexión: $e', error: e);
      } finally {
        _connection = null;
      }
    }
  }

  // Método para liberar recursos al finalizar la aplicación
  void dispose() {
    _heartbeatTimer?.cancel();
    closeConnection();
  }
}

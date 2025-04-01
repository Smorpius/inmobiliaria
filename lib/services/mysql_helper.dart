import 'dart:math';
import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'package:synchronized/synchronized.dart';
import 'package:inmobiliaria/utils/applogger.dart';
import 'package:inmobiliaria/services/db_error_manager.dart';
import 'package:inmobiliaria/services/mysql_error_manager.dart';

/// Excepción personalizada para errores de base de datos.
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

/// Servicio para la gestión de conexiones MySQL con alta tolerancia a fallos y pool de conexiones.
class DatabaseService {
  // Patrón singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    _startHeartbeat();
    _initializePool();
    Future.delayed(const Duration(seconds: 30), iniciarHealthCheckPeriodico);
  }

  // Configuración de reintentos y timeouts
  static const int maxRetries = 2;
  static const int initialRetryDelay = 3000;
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration queryTimeout = Duration(seconds: 45);
  static const Duration estabilizacionPeriod = Duration(seconds: 5);

  // Pool de conexiones
  final List<MySqlConnection> _connectionPool = [];
  static const int maxPoolSize = 3;

  // Conexión principal y estado de reconexión
  MySqlConnection? _connection;
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

  // Heartbeat
  static const Duration heartbeatInterval = Duration(seconds: 30);
  Timer? _heartbeatTimer;
  Timer? _healthCheckTimer;

  // Registro de uso de conexiones
  final Map<int, DateTime> _lastUsedTimestamp = {};

  // Manejador centralizado de errores
  final DbErrorManager _errorManager = DbErrorManager();

  /// Indica si hubo reconexión reciente.
  bool get reconectadoRecientemente => _reconectadoRecientemente;

  /// Indica si el circuit breaker está activo.
  bool get isCircuitOpen => _circuitOpen;

  // =============================================================
  // Métodos públicos de ejecución de operaciones
  // =============================================================

  /// Inicia verificación periódica de la conexión
  void iniciarHealthCheckPeriodico({
    Duration periodo = const Duration(minutes: 2),
  }) {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(periodo, (_) async {
      try {
        if (!await runHealthCheck()) {
          AppLogger.warning('Health check falló, iniciando reinicio completo');
          await _reiniciarCompleto();
        } else {
          AppLogger.info('Health check completado con éxito');
        }
      } catch (e) {
        AppLogger.error('Error en health check periódico: $e');
        try {
          await _reiniciarCompleto();
        } catch (_) {}
      }
    });
  }

  /// Ejecuta un health check completo de la conexión
  Future<bool> runHealthCheck() async {
    if (_connection == null) return false;

    try {
      final isValid = await _testConnection(
        _connection!,
      ).timeout(const Duration(seconds: 2), onTimeout: () => false);

      if (!isValid) {
        AppLogger.warning(
          'Conexión principal inválida detectada en health check',
        );
        return false;
      }

      // Verificación al pool de conexiones
      int conexionesInvalidas = 0;
      final poolCopy = List<MySqlConnection>.from(_connectionPool);

      for (var conn in poolCopy) {
        final valid = await _testConnection(
          conn,
        ).timeout(const Duration(milliseconds: 500), onTimeout: () => false);
        if (!valid) {
          conexionesInvalidas++;
          try {
            await _closeConnectionSafely(conn);
            _connectionPool.remove(conn);
          } catch (_) {}
        }
      }

      if (conexionesInvalidas > 0) {
        AppLogger.info(
          'Se detectaron y cerraron $conexionesInvalidas conexiones inválidas',
        );
      }

      return true;
    } catch (e) {
      AppLogger.warning('Error en health check: $e');
      return false;
    }
  }

  // Agregamos un semáforo para operaciones críticas
  final Map<MySqlConnection, int> _operacionesActivas = {};
  final _semaphore = Lock();

  // Buscar el método withConnection y modificarlo:

  Future<T> withConnection<T>(
    Future<T> Function(MySqlConnection conn) operation,
  ) async {
    return MySqlErrorManager().executeWithCircuitBreaker(
      'database_operation',
      () async {
        MySqlConnection? conn;
        try {
          conn = await _getVerifiedConnection();

          // Registrar inicio de operación con esta conexión
          await _semaphore.synchronized(() {
            _operacionesActivas[conn!] = (_operacionesActivas[conn] ?? 0) + 1;
          });

          // Ejecutar operación con timeout más estricto
          final result = await operation(conn).timeout(
            queryTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Operación excedió el tiempo límite permitido',
              );
            },
          );

          // Verificar que la conexión siga válida después de la operación
          final sigueValida = await _testConnection(
            conn,
          ).timeout(const Duration(milliseconds: 500), onTimeout: () => false);

          await _semaphore.synchronized(() {
            // Reducir contador de operaciones
            final count = (_operacionesActivas[conn!] ?? 1) - 1;
            if (count <= 0) {
              _operacionesActivas.remove(conn);
            } else {
              _operacionesActivas[conn] = count;
            }
          });

          // Si la conexión sigue válida, devolverla al pool
          if (sigueValida) {
            await releaseConnection(conn);
          } else {
            // Si no es válida, cerrarla con seguridad
            await _closeConnectionSafely(conn);
          }

          return result;
        } catch (e) {
          // Clasificar y manejar el error
          final errorClassifier = MySqlErrorManager();
          final errorType = errorClassifier.classifyError(e);

          if (conn != null) {
            if (errorType == ErrorType.connection ||
                errorType == ErrorType.socketClosed) {
              // Marcar explícitamente la conexión como no válida
              await _semaphore.synchronized(() {
                _operacionesActivas.remove(conn);
              });
              try {
                await _closeConnectionSafely(conn);
              } catch (_) {}

              // Forzar reconexión en el próximo intento
              _connection = null;
              unawaited(reiniciarConexion());
            } else {
              try {
                await releaseConnection(conn);
              } catch (_) {}
            }
          }
          // Re-lanzar para manejo superior
          rethrow;
        }
      },
    );
  }

  /// Método auxiliar para detectar errores de conexión
  bool _esErrorDeConexion(Object error) {
    final mensaje = error.toString().toLowerCase();
    return mensaje.contains('socket') ||
        mensaje.contains('closed') ||
        mensaje.contains('connection') ||
        mensaje.contains('mysql') ||
        mensaje.contains('timeout') ||
        mensaje.contains('network') ||
        error is TimeoutException;
  }

  /// Ejecuta una consulta SQL, con manejo robusto de errores de conexión.
  Future<Results> executeQuery(String query, [List<Object?>? params]) async {
    return _errorManager.executeWithErrorHandling(
      'execute_query',
      () async {
        MySqlConnection? conn;
        int intentos = 0;
        final maxIntentos =
            params != null
                ? 3
                : 2; // Más intentos para consultas parametrizadas

        while (intentos < maxIntentos) {
          try {
            // Limpiar conexión previa si existía
            if (conn != null) {
              try {
                await _closeConnectionSafely(conn);
              } catch (_) {}
              conn = null;
            }

            // Obtener conexión fresca
            conn = await _getVerifiedConnection();

            // Verificación de conexión adicional para consultas parametrizadas
            if (params?.isNotEmpty ?? false) {
              bool valida = false;
              try {
                valida = await _testConnection(conn).timeout(
                  const Duration(milliseconds: 800),
                  onTimeout: () => false,
                );
              } catch (_) {
                valida = false;
              }

              if (!valida) {
                AppLogger.warning(
                  'Conexión no válida para consulta parametrizada, reintentando',
                );
                await _closeConnectionSafely(conn);
                conn = null;

                // Reinicio profundo y esperar antes de reintentar
                await _reiniciarCompleto();
                await Future.delayed(
                  Duration(milliseconds: 500 * (intentos + 1)),
                );
                intentos++;
                continue;
              }
            }

            // Ejecutar la consulta con timeout
            final result = await conn
                .query(query, params)
                .timeout(
                  queryTimeout,
                  onTimeout: () {
                    throw TimeoutException(
                      'Consulta excedió el tiempo límite de ${queryTimeout.inSeconds} segundos',
                    );
                  },
                );

            // Marcar conexión como usada
            _updateUsageTimestamp(conn);
            return result;
          } catch (e) {
            intentos++;
            final esErrorDeConexion = _esErrorDeConexion(e);

            if (intentos >= maxIntentos || !esErrorDeConexion) {
              await _handleConnectionError(e, connection: conn);
              conn = null;

              if (!esErrorDeConexion) {
                // Error que no es de conexión, no reintentamos
                rethrow;
              }
            }

            if (intentos < maxIntentos) {
              // Espera exponencial entre intentos
              await Future.delayed(
                Duration(milliseconds: 300 * (1 << intentos)),
              );
            } else {
              rethrow;
            }
          } finally {
            // Asegurar liberación de recursos
            if (conn != null) {
              await releaseConnection(conn);
            }
          }
        }

        // Si llegamos aquí, es porque agotamos los intentos
        throw DatabaseException(
          'No se pudo ejecutar la consulta después de $maxIntentos intentos',
        );
      },
      maxRetries:
          1, // Reducimos los reintentos externos ya que manejamos internamente
      retryDelay: const Duration(milliseconds: 1500),
    );
  }

  /// Ejecuta una operación con reintentos automáticos.
  Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 2000),
  }) async {
    return _errorManager.executeWithErrorHandling(
      'with_retry_operation',
      operation,
      maxRetries: maxRetries,
      retryDelay: initialDelay,
    );
  }

  /// Inicia el health check periódico extendido para validar el estado de la conexión.
  void iniciarHealthCheckPeriodicoExtendido({
    Duration periodo = const Duration(minutes: 3),
  }) {
    Timer.periodic(periodo, (_) async {
      try {
        if (!await runHealthCheck()) {
          AppLogger.warning('Health check falló, forzando reinicio completo');
          await _reiniciarCompleto();
        } else {
          AppLogger.info('Health check completado con éxito');
        }
      } catch (e) {
        AppLogger.error('Error en health check periódico: $e');
        try {
          await _reiniciarCompleto();
        } catch (_) {}
      }
    });
  }

  /// Verifica el estado de la conexión.
  Future<bool> isConnected() async {
    if (_connection == null) return false;
    try {
      final results = await _connection!
          .query('SELECT 1 as test')
          .timeout(
            const Duration(milliseconds: 800),
            onTimeout:
                () =>
                    throw TimeoutException(
                      'Verificación excedió tiempo límite',
                    ),
          );
      if (results.isNotEmpty && results.first.fields['test'] == 1) {
        _updateUsageTimestamp(_connection!);
        return true;
      }
      AppLogger.warning('Conexión respondió con datos incorrectos');
      return false;
    } catch (e) {
      _handleConnectionError(e);
      _iniciarReconexionAsincrona();
      return false;
    }
  }

  /// Ejecuta un health check simple, forzando reinicio si es necesario.
  Future<bool> runBasicHealthCheck() async {
    try {
      if (!await isConnected()) {
        AppLogger.warning('Health check falló, forzando reinicio');
        await reiniciarConexion();
        return await isConnected();
      }
      return true;
    } catch (e) {
      AppLogger.error('Error durante health check: $e');
      return false;
    }
  }

  /// Cierra todos los recursos al finalizar
  void dispose() {
    _healthCheckTimer?.cancel();
    _heartbeatTimer?.cancel();
    _reconexionTimer?.cancel();
    closeConnection();
    _lastUsedTimestamp.clear();
  }

  // =============================================================
  // Métodos de gestión interna de conexiones y pool
  // =============================================================

  /// Inicializa el pool de conexiones.
  Future<void> _initializePool() async {
    try {
      while (_connectionPool.length < maxPoolSize) {
        final conn = await _createNewConnection();
        if (conn != null) {
          _connectionPool.add(conn);
          _updateUsageTimestamp(conn);
        }
      }
      AppLogger.info(
        'Pool de conexiones inicializado con ${_connectionPool.length} conexiones',
      );
    } catch (e) {
      AppLogger.error('Error al inicializar pool de conexiones: $e');
    }
  }

  /// Actualiza el timestamp de uso para una conexión.
  void _updateUsageTimestamp(MySqlConnection conn) {
    _lastUsedTimestamp[conn.hashCode] = DateTime.now();
  }

  /// Obtiene una conexión del pool o crea una nueva.
  Future<MySqlConnection> get connection async {
    if (_connectionPool.isNotEmpty) {
      final pool = List<MySqlConnection>.from(_connectionPool);
      _connectionPool.clear();
      for (var conn in pool) {
        try {
          if (await _testConnection(
            conn,
          ).timeout(const Duration(seconds: 1), onTimeout: () => false)) {
            _updateUsageTimestamp(conn);
            return conn;
          }
          await _closeConnectionSafely(conn);
        } catch (_) {}
      }
    }
    return await _getConnection();
  }

  /// Libera la conexión al pool o la cierra si éste está lleno.
  Future<void> releaseConnection(MySqlConnection conn) async {
    if (_connectionPool.length < maxPoolSize) {
      _connectionPool.add(conn);
      _updateUsageTimestamp(conn);
    } else {
      await _closeConnectionSafely(conn);
    }
  }

  /// Cierra de forma segura una conexión.
  Future<void> _closeConnectionSafely(MySqlConnection conn) async {
    try {
      await conn.close().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {}, // No lanzar excepción en timeout
      );
      _lastUsedTimestamp.remove(conn.hashCode);
    } catch (_) {
      // Ignorar errores al cerrar para evitar cascada de excepciones
      _lastUsedTimestamp.remove(conn.hashCode);
    }
  }

  int _fallosGlobalesConsecutivos = 0;

  void registrarExito() {
    _fallosGlobalesConsecutivos = 0;
  }

  void registrarFallo() {
    _fallosGlobalesConsecutivos++;
    if (_fallosGlobalesConsecutivos >= 5) {
      AppLogger.warning(
        'Detectados múltiples fallos consecutivos, reiniciando todas las conexiones',
      );
      _fallosGlobalesConsecutivos = 0;
      unawaited(_reiniciarCompleto());
    }
  }

  /// Crea una nueva conexión a la base de datos.
  Future<MySqlConnection?> _createNewConnection() async {
    try {
      final settings = ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'root',
        password: '123456789',
        db: 'Proyecto_Prueba',
        timeout: connectionTimeout,
        maxPacketSize: 67108864,
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
      AppLogger.info('Nueva conexión a MySQL establecida exitosamente');
      _updateUsageTimestamp(newConnection);
      return newConnection;
    } catch (e) {
      AppLogger.error('Error al crear nueva conexión: $e');
      return null;
    }
  }

  /// Obtiene o crea una conexión, gestionando reintentos y circuit breaker.
  Future<MySqlConnection> _getConnection() async {
    if (_consecutiveFailures > maxConsecutiveFailures) {
      await Future.delayed(const Duration(seconds: 5));
      _consecutiveFailures = maxConsecutiveFailures ~/ 2;
      AppLogger.warning(
        'Demasiados fallos consecutivos, esperando período extendido',
      );
    }
    if (_circuitOpen) {
      if (_circuitResetTime != null &&
          DateTime.now().isAfter(_circuitResetTime!)) {
        _circuitOpen = false;
        _consecutiveFailures = 0;
        AppLogger.info('Circuit breaker reseteado, intentando reconexión');
      } else {
        throw DatabaseException(
          'Conexión bloqueada por fallos consecutivos',
          originalError: 'Circuit breaker activo hasta $_circuitResetTime',
        );
      }
    }
    if (_isReconnecting) {
      AppLogger.info('Reconexión en progreso, esperando...');
      await Future.delayed(const Duration(milliseconds: 700));
      return connection;
    }
    final now = DateTime.now();
    if (_lastConnectionAttempt != null &&
        now.difference(_lastConnectionAttempt!) < const Duration(seconds: 3)) {
      AppLogger.info('Demasiadas reconexiones, esperando estabilización...');
      await Future.delayed(const Duration(seconds: 1));
    }
    _isReconnecting = true;
    _lastConnectionAttempt = now;
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
        _updateUsageTimestamp(_connection!);
        AppLogger.info('Esperando estabilización de conexión...');
        await Future.delayed(const Duration(seconds: 2));
        AppLogger.info('Período de estabilización completado');
        _consecutiveFailures = 0;
        _isReconnecting = false;
        return _connection!;
      } catch (e) {
        attempts++;
        final delay = Duration(
          milliseconds: initialRetryDelay * (1 << attempts),
        );
        lastError = e is Exception ? e : Exception(e.toString());
        AppLogger.warning(
          'Intento $attempts falló: $e. Reintentando en ${delay.inMilliseconds}ms',
        );
        if (attempts >= maxRetries) {
          _consecutiveFailures++;
          if (_consecutiveFailures >= maxConsecutiveFailures) {
            _circuitOpen = true;
            _circuitResetTime = DateTime.now().add(circuitResetDuration);
            AppLogger.error(
              'Circuit breaker activado por $_consecutiveFailures fallos',
            );
          }
          _isReconnecting = false;
          throw DatabaseException(
            'Falló la conexión tras $maxRetries intentos',
            originalError: lastError,
          );
        }
        await Future.delayed(delay);
      }
    }
    _isReconnecting = false;
    throw DatabaseException(
      'No se pudo establecer conexión tras múltiples intentos',
    );
  }

  /// Verifica la conexión principal o del pool y la reemplaza si es necesario.
  Future<MySqlConnection> _getVerifiedConnection() async {
    // Evitar múltiples verificaciones simultáneas
    if (_isReconnecting) {
      AppLogger.info('Reconexión en progreso, esperando un momento...');
      await Future.delayed(const Duration(milliseconds: 500));
      // Si seguimos en reconexión, intentamos obtener una conexión nueva directamente
      if (_isReconnecting) {
        return await connection;
      }
    }

    // Verificar conexión principal primero
    if (_connection != null) {
      try {
        // Verificación previa para evitar usar un socket cerrado
        final connString = _connection.toString().toLowerCase();
        if (connString.contains('closed') || connString.contains('invalid')) {
          AppLogger.warning(
            'Conexión principal parece estar cerrada, creando nueva',
          );
          _connection = null;
        } else {
          // Probar conexión con timeout limitado
          final isValid = await _testConnection(
            _connection!,
          ).timeout(const Duration(milliseconds: 600), onTimeout: () => false);

          if (isValid) {
            _updateUsageTimestamp(_connection!);
            return _connection!;
          }

          // Si llega aquí, la conexión no es válida
          AppLogger.warning('Conexión principal verificada como inválida');
          try {
            await _closeConnectionSafely(_connection!);
          } catch (_) {}
          _connection = null;
        }
      } catch (e) {
        // Error al verificar conexión principal
        AppLogger.warning(
          'Error al verificar conexión principal: ${e.toString().split('\n').first}',
        );
        try {
          await _closeConnectionSafely(_connection!);
        } catch (_) {}
        _connection = null;
      }
    }

    // Crear nueva conexión con manejo de errores mejorado
    int intentos = 0;
    const maxIntentos = 2;

    while (intentos < maxIntentos) {
      try {
        // Obtener nueva conexión del pool o crear una
        final conn = await connection;

        // Verificar que sea válida antes de usarla
        final isValid = await _testConnection(
          conn,
        ).timeout(const Duration(milliseconds: 700), onTimeout: () => false);

        if (isValid) {
          // Si es la primera conexión exitosa, asignarla como principal
          if (_connection == null) {
            _connection = conn;
            _startHeartbeat();
          }
          return conn;
        }

        // Cerrar conexión inválida con seguridad
        AppLogger.warning(
          'Nueva conexión verificada como inválida, reintentando',
        );
        await _closeConnectionSafely(conn);

        // Pequeña espera antes de reintentar
        await Future.delayed(Duration(milliseconds: 300 * (intentos + 1)));
        intentos++;
      } catch (e) {
        intentos++;
        final errorMsg = e.toString().toLowerCase();

        // Manejar específicamente errores de socket
        if (errorMsg.contains('socket') ||
            errorMsg.contains('closed') ||
            errorMsg.contains('connection')) {
          await Future.delayed(Duration(milliseconds: 500 * intentos));

          if (intentos >= maxIntentos) {
            // Último intento: reiniciar completamente el sistema
            AppLogger.warning(
              'Forzando reinicio completo tras múltiples errores de conexión',
            );
            await reiniciarConexion();
          }
        } else {
          // Para otros tipos de errores
          AppLogger.error(
            'Error al obtener conexión verificada',
            e,
            StackTrace.current,
          );
          if (intentos >= maxIntentos) rethrow;
        }
      }
    }

    // Si agotamos los intentos, último recurso
    AppLogger.warning(
      'Agotados todos los intentos, forzando reinicio y retornando conexión nueva',
    );
    await _reiniciarCompleto();
    return await connection;
  }

  /// Prueba si la conexión está activa de manera segura
  Future<bool> _testConnection(MySqlConnection conn) async {
    try {
      // Verificación preliminar por inspección del objeto
      if (conn.toString().toLowerCase().contains('closed')) {
        return false;
      }

      // Usar consulta mínima con timeout corto
      final results = await conn
          .query('SELECT 1 as test')
          .timeout(
            const Duration(milliseconds: 300),
            onTimeout:
                () => throw TimeoutException('Test connection timed out'),
          );

      // Verificar el resultado
      return results.isNotEmpty && results.first['test'] == 1;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();

      // Lista exhaustiva de patrones de error que indican conexión cerrada
      if (errorStr.contains('cannot write') ||
          errorStr.contains('socket closed') ||
          errorStr.contains('not connected') ||
          errorStr.contains('connection closed') ||
          errorStr.contains('it is closed') ||
          e is TimeoutException) {
        return false;
      }

      return false; // Si hay cualquier error, asumir conexión inválida
    }
  }
  // =============================================================
  // Manejo de errores y reconexiones
  // =============================================================

  /// Maneja errores comunes de conexión y reinicia la conexión según corresponda.
  Future<void> _handleConnectionError(
    Object e, {
    MySqlConnection? connection,
  }) async {
    // Garantizar que se cierran las conexiones problemáticas
    if (connection != null) {
      try {
        await _closeConnectionSafely(connection);
      } catch (_) {}
    }

    final errorStr = e.toString().toLowerCase();

    // Clasificación más precisa de errores
    final esErrorDeSocket =
        errorStr.contains('socket') ||
        errorStr.contains('closed') ||
        errorStr.contains('cannot write');

    final esErrorDeTimeout =
        errorStr.contains('timeout') || e is TimeoutException;

    final esErrorDePreparedStatement =
        _errorManager.isPreparedStatementError(e) ||
        errorStr.contains('prepared') ||
        errorStr.contains('statement');

    final esErrorDeConexionMySQL =
        _errorManager.isMySqlConnectionError(e) ||
        errorStr.contains('mysql') ||
        errorStr.contains('connection');

    // Log apropiado según el tipo de error
    if (esErrorDeSocket) {
      AppLogger.warning(
        'Error de socket detectado: ${e.toString().split('\n').first}',
      );
      _connection = null;
      await _reiniciarCompleto();
    } else if (esErrorDePreparedStatement) {
      AppLogger.warning(
        'Error de prepared statement detectado, reiniciando conexión profunda',
      );
      await _reiniciarConexionCuandoSePreparanConsultas();
    } else if (esErrorDeTimeout) {
      AppLogger.warning(
        'Timeout detectado en operación: ${e.toString().split('\n').first}',
      );
      _connection = null;
      await reiniciarConexion();
    } else if (esErrorDeConexionMySQL) {
      AppLogger.warning(
        'Error de protocolo MySQL detectado: ${e.toString().split('\n').first}',
      );
      await reiniciarConexion();
    } else {
      // Para otros errores, registrar pero posiblemente no requieren reinicio
      AppLogger.warning(
        'Error en operación de base de datos: ${e.toString().split('\n').first}',
      );

      // Verificar estado de conexión principal de todos modos
      if (_connection != null) {
        try {
          final valida = await _testConnection(
            _connection!,
          ).timeout(const Duration(seconds: 1), onTimeout: () => false);
          if (!valida) {
            AppLogger.info(
              'Conexión principal no válida después de error, reiniciando',
            );
            _connection = null;
            await reiniciarConexion();
          }
        } catch (_) {
          // Si falla la verificación, asumir conexión dañada
          _connection = null;
          await reiniciarConexion();
        }
      }
    }
  }

  /// Marca que se ha reconectado recientemente y reinicia el flag tras un período de estabilización.
  void _marcarReconexionReciente() {
    _reconectadoRecientemente = true;
    _reconexionTimer?.cancel();
    _reconexionTimer = Timer(estabilizacionPeriod, () {
      _reconectadoRecientemente = false;
      AppLogger.info('Estado de reconexión reciente reseteado');
    });
  }

  // Agregamos tracking de transacciones
  final Map<MySqlConnection, bool> _transaccionesActivas = {};

  // Método para ejecutar transacciones con seguridad
  Future<T> withTransaction<T>(
    Future<T> Function(MySqlConnection conn) operation,
  ) async {
    return withConnection((conn) async {
      await conn.query('START TRANSACTION');
      _transaccionesActivas[conn] = true;

      try {
        final result = await operation(conn);
        await conn.query('COMMIT');
        _transaccionesActivas.remove(conn);
        return result;
      } catch (e) {
        try {
          // Intentar hacer rollback
          if (_transaccionesActivas.containsKey(conn)) {
            await conn
                .query('ROLLBACK')
                .timeout(
                  const Duration(seconds: 2),
                  onTimeout: () {
                    throw TimeoutException('Rollback operation timed out');
                  },
                );
          }
        } catch (_) {
          // Si falla el rollback, la conexión está comprometida
          await _closeConnectionSafely(conn);
        } finally {
          _transaccionesActivas.remove(conn);
        }
        rethrow;
      }
    });
  }

  /// Reinicia proactivamente el pool de conexiones para evitar conexiones estancadas
  Future<void> reiniciarPoolConexiones() async {
    AppLogger.info('Iniciando reinicio proactivo del pool de conexiones');

    // Cerrar todas las conexiones del pool con seguridad
    final poolCopy = List<MySqlConnection>.from(_connectionPool);
    _connectionPool.clear();

    for (var conn in poolCopy) {
      try {
        await _closeConnectionSafely(conn);
      } catch (_) {}
    }

    // Inicializar pool con nuevas conexiones
    try {
      await _initializePool();
      AppLogger.info('Pool de conexiones reiniciado exitosamente');
    } catch (e) {
      AppLogger.error('Error al reiniciar pool de conexiones: $e');
    }
  }

  /// Reinicia completamente todas las conexiones y el pool.
  Future<void> _reiniciarCompleto() async {
    AppLogger.warning('Iniciando reinicio completo del sistema de conexiones');

    // Cancelar temporizadores existentes
    _healthCheckTimer?.cancel();
    _heartbeatTimer?.cancel();
    _reconexionTimer?.cancel();

    // Cerrar todas las conexiones existentes
    await closeConnection();

    // Resetear contadores y flags
    _consecutiveFailures = 0;
    _circuitOpen = false;
    _isReconnecting = false;
    _lastUsedTimestamp.clear();
    _connectionPool.clear();
    _connection = null;

    // Esperar un poco antes de intentar reconectar
    await Future.delayed(const Duration(seconds: 5));

    try {
      // Crear nueva conexión principal
      final nuevaConexion = await _createNewConnection();
      if (nuevaConexion != null) {
        _connection = nuevaConexion;
        AppLogger.info(
          'Nueva conexión principal establecida tras reinicio completo',
        );

        // Inicializar sistemas de monitoreo
        _startHeartbeat();

        // Inicializar pool asíncronamente sin bloquear
        unawaited(_initializePool());
      }

      // Iniciar verificación periódica
      iniciarHealthCheckPeriodico();

      AppLogger.info(
        'Reinicio completo del sistema de conexiones finalizado con éxito',
      );
    } catch (e) {
      AppLogger.error('Error en reinicio completo del sistema: $e');
      // Intentar de nuevo después de un tiempo
      Timer(const Duration(seconds: 10), _reiniciarCompleto);
    }
  }

  /// Reinicia la conexión con mejor manejo de recursos
  Future<void> reiniciarConexion() async {
    if (_isReconnecting) {
      AppLogger.info('Reconexión ya en progreso, solicitud omitida');
      return;
    }

    _isReconnecting = true;
    AppLogger.info('Iniciando reinicio de conexión');

    try {
      // Cerrar conexiones existentes de manera segura
      await _closeAllConnections();

      _consecutiveFailures = 0;
      _circuitOpen = false;

      // Esperar un momento para asegurar cierre completo de recursos
      await Future.delayed(const Duration(seconds: 1));

      // Crear nueva conexión principal
      final nuevaConexion = await _createNewConnection();
      if (nuevaConexion != null) {
        _connection = nuevaConexion;
        _startHeartbeat();

        // Inicializar pool asíncronamente sin bloquear
        unawaited(_initializePool());
        AppLogger.info('Reconexión exitosa');
      }
    } catch (e) {
      AppLogger.error('Error durante reconexión', e, StackTrace.current);
    } finally {
      _isReconnecting = false;
    }
  }

  // Método auxiliar para cerrar todas las conexiones de forma segura
  Future<void> _closeAllConnections() async {
    if (_connection != null) {
      try {
        await _connection!.close().timeout(
          const Duration(milliseconds: 800),
          onTimeout: () {},
        );
      } catch (_) {}
      _connection = null;
    }

    for (var conn in _connectionPool) {
      try {
        await conn.close().timeout(
          const Duration(milliseconds: 500),
          onTimeout: () {},
        );
      } catch (_) {}
    }
    _connectionPool.clear();
  }

  /// Reconexión profunda para errores en prepared statements.
  Future<void> _reiniciarConexionCuandoSePreparanConsultas() async {
    AppLogger.warning('Iniciando reconexión profunda para prepared statements');
    await closeConnection();
    _consecutiveFailures = 0;
    _circuitOpen = false;
    _isReconnecting = false;
    _lastUsedTimestamp.clear();
    await Future.delayed(const Duration(seconds: 5));
    try {
      final settings = ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'root',
        password: '123456789',
        db: 'Proyecto_Prueba',
        timeout: connectionTimeout,
        maxPacketSize: 67108864,
        useCompression: false,
        useSSL: false,
      );
      final newConnection = await MySqlConnection.connect(settings);
      _connection = newConnection;
      _updateUsageTimestamp(newConnection);
      await _initializePool();
      _restartHeartbeat();
      AppLogger.info('Reconexión profunda completada con éxito');
    } catch (e) {
      AppLogger.error('Error en reconexión profunda: $e');
      Timer(
        const Duration(seconds: 10),
        _reiniciarConexionCuandoSePreparanConsultas,
      );
    }
  }

  /// Inicia reconexión asíncrona sin bloquear el hilo principal.
  void _iniciarReconexionAsincrona() {
    _getConnection().then((_) {}).catchError((error) {
      AppLogger.error('Error en reconexión asíncrona: $error');
    });
  }

  /// Reinicia el heartbeat.
  void _restartHeartbeat() {
    _startHeartbeat();
  }

  /// Inicia el heartbeat con mejor control de errores
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_connection == null || _isReconnecting) return;

      try {
        bool isValid = false;
        try {
          isValid = await _testConnection(
            _connection!,
          ).timeout(const Duration(milliseconds: 800), onTimeout: () => false);
        } catch (_) {
          isValid = false;
        }

        if (!isValid && !_isReconnecting) {
          // Marcar conexión como nula para forzar reconexión
          _connection = null;
          // Iniciar reconexión de forma controlada
          unawaited(
            _getVerifiedConnection()
                .then((conn) {
                  // Actualización silenciosa de la conexión principal
                  _connection ??= conn;
                })
                .catchError((_) {}),
          );
        }

        // Reducir frecuencia de limpieza para evitar sobrecarga
        if (!_isReconnecting && Random().nextInt(5) == 0) {
          await _verificarConexionesInactivas();
        }
      } catch (_) {
        // Ignorar errores en el heartbeat
      }
    });
  }

  /// Verifica y elimina registros de conexiones inactivas.
  Future<void> _verificarConexionesInactivas() async {
    final ahora = DateTime.now();
    final inactivos =
        _lastUsedTimestamp.entries
            .where((e) => ahora.difference(e.value).inMinutes > 10)
            .map((e) => e.key)
            .toList();
    for (var hash in inactivos) {
      _lastUsedTimestamp.remove(hash);
    }
    if (inactivos.isNotEmpty) {
      AppLogger.info(
        'Eliminados ${inactivos.length} registros de conexiones inactivas',
      );
    }
  }

  /// Libera las conexiones que no se han utilizado por un período
  Future<int> releaseUnusedConnections() async {
    final ahora = DateTime.now();
    int liberadas = 0;

    // Identificar conexiones inactivas por más de 5 minutos
    final conexionesInactivas =
        _lastUsedTimestamp.entries
            .where((entry) => ahora.difference(entry.value).inMinutes > 5)
            .map((e) => e.key)
            .toList();

    // Cerrar solo las conexiones del pool que estén inactivas
    final poolCopy = List<MySqlConnection>.from(_connectionPool);
    for (var conn in poolCopy) {
      final connHash = conn.hashCode;
      if (conexionesInactivas.contains(connHash)) {
        try {
          await _closeConnectionSafely(conn);
          _connectionPool.remove(conn);
          _lastUsedTimestamp.remove(connHash);
          liberadas++;
        } catch (_) {
          // Ignorar errores al cerrar conexiones
        }
      }
    }

    if (liberadas > 0) {
      AppLogger.info('Se liberaron $liberadas conexiones inactivas');
    }

    return liberadas;
  }

  /// Limpia las conexiones no utilizadas del pool.
  Future<int> cleanupUnusedConnections() async {
    int cerradas = 0;
    final toRemove = <MySqlConnection>[];
    for (var conn in _connectionPool) {
      try {
        if (!await _testConnection(
          conn,
        ).timeout(const Duration(seconds: 1), onTimeout: () => false)) {
          toRemove.add(conn);
          await _closeConnectionSafely(conn);
          cerradas++;
        }
      } catch (_) {
        toRemove.add(conn);
        cerradas++;
      }
    }
    _connectionPool.removeWhere((conn) => toRemove.contains(conn));
    if (cerradas > 0) {
      AppLogger.info('Limpieza completada: $cerradas conexiones cerradas');
    }
    return cerradas;
  }

  /// Cierra la conexión principal y todas las conexiones del pool.
  Future<void> closeConnection() async {
    _heartbeatTimer?.cancel();
    _reconexionTimer?.cancel();
    if (_connection != null) {
      try {
        await _connection!.close().timeout(
          const Duration(seconds: 3),
          onTimeout: () => AppLogger.info('Cierre excedió tiempo límite'),
        );
        _lastUsedTimestamp.remove(_connection.hashCode);
        AppLogger.info('Conexión principal cerrada');
      } catch (e) {
        AppLogger.error('Error al cerrar conexión principal: $e');
      } finally {
        _connection = null;
      }
    }
    int cerradas = 0;
    for (var conn in _connectionPool) {
      try {
        await conn.close().timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        );
        _lastUsedTimestamp.remove(conn.hashCode);
        cerradas++;
      } catch (_) {}
    }
    _connectionPool.clear();
    if (cerradas > 0) {
      AppLogger.info('$cerradas conexiones del pool cerradas');
    }
  }
}

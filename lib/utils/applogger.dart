import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'package:logging/logging.dart';

enum LogLevel { all, debug, info, warning, error, off }

/// Sistema de logs mejorado con procesamiento asíncrono y robustez adicional
class AppLogger {
  static final Logger _logger = Logger('InmobiliariaApp');
  static bool _initialized = false;
  static LogLevel _currentLevel = LogLevel.info;

  // Sistema anti-repetición: almacena mensajes recientes
  static final HashMap<String, _LogEntry> _recentLogs =
      HashMap<String, _LogEntry>();
  static const int _maxRecentLogsSize = 200; // Aumentar para mayor retención
  static const Duration _logDuplicateTimeout = Duration(
    seconds: 10,
  ); // Aumentar timeout

  // Mapeo de categorías para logs específicos que tienden a repetirse
  static final Map<String, DateTime> _categorizedWarnings = {};
  static const Duration _categoryExpiration = Duration(
    minutes: 10,
  ); // Aumentar expiración

  // Colas asíncronas para mensajes de log no críticos
  static final StreamController<_QueuedLogMessage> _logQueue =
      StreamController<_QueuedLogMessage>.broadcast(
        sync: true,
      ); // sync: true para evitar perder mensajes

  // Colas separadas para diferentes niveles de prioridad
  static final StreamController<_QueuedLogMessage> _errorQueue =
      StreamController<_QueuedLogMessage>.broadcast(
        sync: true,
      ); // sync: true para evitar perder mensajes

  // Función para manejar la salida de logs
  static void Function(String message) logOutput = (String message) {
    stderr.writeln(message);
  };

  /// Inicializa el sistema de logs con procesamiento asíncrono
  static void init({LogLevel level = LogLevel.info}) {
    if (_initialized) return;

    _currentLevel = level;
    Logger.root.level = _convertToLoggingLevel(level);

    // Inicializar sistema asíncrono
    _initAsyncProcessing();

    Logger.root.onRecord.listen(
      (record) {
        if (record.level.value >= Logger.root.level.value) {
          try {
            logOutput('[${record.level.name}] ${record.message}');
          } catch (e) {
            stderr.writeln('Error in logOutput: $e'); // Fallback extremo
          }
        }
      },
      onError: (error) {
        stderr.writeln('Error in Logger.root.onRecord.listen: $error');
      },
    );

    _initialized = true;
    _startLogCleaner();
  }

  /// Inicializa procesamiento asíncrono de logs
  static void _initAsyncProcessing() {
    // Manejar logs normales (bajo impacto) de forma asíncrona con baja prioridad
    _logQueue.stream.listen(
      (message) {
        if (message.level.index <= _currentLevel.index) {
          try {
            final logLevel = _convertToLoggingLevel(message.level);
            _logger.log(
              logLevel,
              message.message,
              message.error,
              message.stackTrace,
            );
          } catch (e) {
            stderr.writeln('Error processing log message: $e');
          }
        }
      },
      onError: (error) {
        stderr.writeln('Error in _logQueue.stream.listen: $error');
      },
    );

    // Manejar errores con alta prioridad
    _errorQueue.stream.listen(
      (message) {
        if (message.level.index <= _currentLevel.index) {
          try {
            // Los errores siempre van a un nivel de severidad
            _logger.severe(message.message, message.error, message.stackTrace);
          } catch (e) {
            stderr.writeln('Error processing error message: $e');
          }
        }
      },
      onError: (error) {
        stderr.writeln('Error in _errorQueue.stream.listen: $error');
      },
    );
  }

  /// Libera recursos explícitamente cuando sea necesario
  static Future<void> dispose() async {
    if (_initialized) {
      _initialized = false;

      // Esperar a que se procesen los logs pendientes antes de cerrar
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Aumentar tiempo de espera

      try {
        if (!_logQueue.isClosed) {
          await _logQueue.close();
        }
        if (!_errorQueue.isClosed) {
          await _errorQueue.close();
        }

        // Registrar que se ha cerrado el logger
        _logger.info('Logger resources released successfully');
      } catch (e) {
        // No podemos usar el logger aquí porque estamos cerrándolo
        stderr.writeln('Error disposing AppLogger: $e');
      }
    }
  }

  /// Método asíncrono para registrar un log
  static Future<void> logAsync({
    required LogLevel level,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    // Solo procesar si el nivel es adecuado
    if (level.index > _currentLevel.index) return;

    // Omitir logs duplicados excepto para errores
    if (level != LogLevel.error && _shouldSkipDuplicateLog(message, level)) {
      return;
    }

    final queuedMessage = _QueuedLogMessage(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    // Los errores van a una cola de alta prioridad
    if (level == LogLevel.error) {
      // Enviar directamente si el StreamController está abierto
      if (!_errorQueue.isClosed) {
        try {
          _errorQueue.add(queuedMessage);
        } catch (e) {
          stderr.writeln('Error adding to _errorQueue: $e');
          _logger.severe(message, error, stackTrace); // Fallback directo
        }
      } else {
        // Fallback si la cola está cerrada
        _logger.severe(message, error, stackTrace);
      }
    } else {
      // Logs normales van a la cola regular
      if (!_logQueue.isClosed) {
        try {
          _logQueue.add(queuedMessage);
        } catch (e) {
          stderr.writeln('Error adding to _logQueue: $e');
        }
      }
    }
  }

  // --- Métodos públicos existentes (mantienen compatibilidad) ---

  /// Registra un mensaje de depuración
  static void debug(String message) {
    if (_currentLevel.index <= LogLevel.debug.index) {
      if (!_shouldSkipDuplicateLog(message, LogLevel.debug)) {
        logAsync(level: LogLevel.debug, message: message);
      }
    }
  }

  /// Registra un mensaje informativo
  static void info(String message) {
    if (_currentLevel.index <= LogLevel.info.index) {
      if (!_shouldSkipDuplicateLog(message, LogLevel.info)) {
        logAsync(level: LogLevel.info, message: message);
      }
    }
  }

  /// Registra una advertencia
  static void warning(String message) {
    if (_currentLevel.index <= LogLevel.warning.index) {
      if (!_shouldSkipDuplicateLog(message, LogLevel.warning)) {
        logAsync(level: LogLevel.warning, message: message);
      }
    }
  }

  /// Registra una advertencia categorizada
  static void categoryWarning(
    String category,
    String message, {
    Duration expiration = const Duration(minutes: 5),
  }) {
    if (_currentLevel.index <= LogLevel.warning.index) {
      if (shouldShowCategorizedWarning(category, expiration: expiration)) {
        logAsync(level: LogLevel.warning, message: "$message [cat: $category]");
      }
    }
  }

  /// Registra un error, siempre se muestran todos los errores
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_currentLevel.index <= LogLevel.error.index) {
      // Los errores tienen prioridad alta y se procesan inmediatamente
      logAsync(
        level: LogLevel.error,
        message: message,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // --- Métodos de utilidad internos ---

  /// Convierte el nivel de log interno al formato de la biblioteca logging
  static Level _convertToLoggingLevel(LogLevel level) {
    switch (level) {
      case LogLevel.all:
        return Level.ALL;
      case LogLevel.debug:
        return Level.FINE;
      case LogLevel.info:
        return Level.INFO;
      case LogLevel.warning:
        return Level.WARNING;
      case LogLevel.error:
        return Level.SEVERE;
      case LogLevel.off:
        return Level.OFF;
    }
  }

  /// Verifica si un log debe ser omitido por ser repetitivo
  static bool _shouldSkipDuplicateLog(String message, LogLevel level) {
    // Los errores nunca se omiten, siempre se muestran
    if (level == LogLevel.error) return false;

    final now = DateTime.now();
    final key = "$level:$message";

    if (_recentLogs.containsKey(key)) {
      final lastLog = _recentLogs[key]!;

      // Si es el mismo mensaje en poco tiempo, incrementar contador y omitir
      if (now.difference(lastLog.timestamp) < _logDuplicateTimeout) {
        lastLog.count++;
        lastLog.timestamp = now;

        // Cada 10 veces que se repite el mismo log, mostrarlo con el contador
        if (lastLog.count % 10 == 0) {
          logAsync(
            level: level,
            message: "$message (repetido ${lastLog.count} veces)",
          );
        }

        return true; // Omitir este log
      }
    }

    // Control de tamaño del mapa de logs recientes
    if (_recentLogs.length > _maxRecentLogsSize) {
      // Estrategia optimizada: eliminar varios registros antiguos de una vez
      _pruneOldLogs();
    }

    // Actualizar el registro de logs recientes
    _recentLogs[key] = _LogEntry(now);
    return false;
  }

  /// Elimina registros antiguos de la caché de logs
  static void _pruneOldLogs() {
    if (_recentLogs.length <= _maxRecentLogsSize) return;

    try {
      final entries =
          _recentLogs.entries.toList()
            ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

      // Eliminar el 25% más antiguo
      final toRemove = (_recentLogs.length * 0.25).ceil();
      for (int i = 0; i < toRemove && i < entries.length; i++) {
        _recentLogs.remove(entries[i].key);
      }
    } catch (e) {
      stderr.writeln('Error pruning old logs: $e');
    }
  }

  /// Determina si una advertencia categorizada debe mostrarse
  static bool shouldShowCategorizedWarning(
    String category, {
    Duration expiration = const Duration(minutes: 5),
  }) {
    final now = DateTime.now();

    if (_categorizedWarnings.containsKey(category)) {
      final lastTime = _categorizedWarnings[category]!;
      if (now.difference(lastTime) < expiration) {
        return false;
      }
    }

    try {
      _categorizedWarnings[category] = now;
    } catch (e) {
      stderr.writeln('Error showing categorized warning: $e');
    }
    return true;
  }

  /// Limpia periódicamente los logs antiguos
  static void _startLogCleaner() {
    Future.delayed(const Duration(minutes: 5), () {
      final now = DateTime.now();

      // Limpieza optimizada: uso de listas temporales para evitar modificaciones concurrentes
      final keysToRemove = <String>[];

      // Limpiar logs recientes (>10 minutos)
      try {
        for (var entry in _recentLogs.entries) {
          if (now.difference(entry.value.timestamp) >
              const Duration(minutes: 10)) {
            keysToRemove.add(entry.key);
          }
        }

        for (var key in keysToRemove) {
          _recentLogs.remove(key);
        }
      } catch (e) {
        stderr.writeln('Error cleaning recent logs: $e');
      }

      // Limpiar advertencias categorizadas (>5 minutos o personalizadas)
      final categoriesToRemove = <String>[];
      try {
        for (var entry in _categorizedWarnings.entries) {
          if (now.difference(entry.value) > _categoryExpiration) {
            categoriesToRemove.add(entry.key);
          }
        }

        for (var key in categoriesToRemove) {
          _categorizedWarnings.remove(key);
        }
      } catch (e) {
        stderr.writeln('Error cleaning categorized warnings: $e');
      }

      // Programar siguiente limpieza solo si la aplicación sigue activa
      if (_initialized) {
        _startLogCleaner();
      }
    });
  }
}

/// Clase para rastrear entradas de log
class _LogEntry {
  DateTime timestamp;
  int count = 1;

  _LogEntry(this.timestamp);
}

/// Modelo para mensajes en cola
class _QueuedLogMessage {
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  _QueuedLogMessage({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    required this.timestamp,
  });
}

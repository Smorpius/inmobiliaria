import 'dart:async';
import 'package:synchronized/synchronized.dart';
import 'package:inmobiliaria/utils/applogger.dart';
import 'package:inmobiliaria/utils/error_handler.dart';

enum ErrorTipo {
  conexion,
  preparedStatement,
  autenticacion,
  transaccion,
  consulta,
  constraint,
  timeout,
  desconocido,
}

class DbErrorManager {
  // Singleton
  static final DbErrorManager _instance = DbErrorManager._internal();
  factory DbErrorManager() => _instance;
  DbErrorManager._internal();

  // Control para evitar logs duplicados
  final Map<String, DateTime> _errorRegistry = {};
  final Lock _lock = Lock();
  Duration _errorThreshold = const Duration(minutes: 2);
  int _maxErrorEntries = 100;

  /// Configura los parámetros de la clase
  void configurar({Duration? errorThreshold, int? maxErrorEntries}) {
    if (errorThreshold != null) _errorThreshold = errorThreshold;
    if (maxErrorEntries != null && maxErrorEntries > 0) {
      _maxErrorEntries = maxErrorEntries;
    }
  }

  /// Detecta errores de conexión MySQL
  bool isMySqlConnectionError(Object error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('socket') ||
        errorStr.contains('connection') ||
        errorStr.contains('closed') ||
        errorStr.contains('mysql') ||
        errorStr.contains('timeout');
  }

  /// Detecta errores de prepared statements
  bool isPreparedStatementError(Object error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('prepare') ||
        errorStr.contains('statement') ||
        errorStr.contains('packet') ||
        errorStr.contains('_bytedata');
  }

  /// Registra un error si no se ha registrado recientemente
  Future<void> logError(
    String errorKey,
    String message,
    Object error,
    StackTrace stack,
  ) async {
    final now = DateTime.now();
    await _lock.synchronized(() async {
      if (_shouldLogError(errorKey, now)) {
        _errorRegistry[errorKey] = now;
        AppLogger.error(message, error, stack);
        _cleanupOldErrors();
      }
    });
  }

  bool _shouldLogError(String errorKey, DateTime now) {
    if (!_errorRegistry.containsKey(errorKey)) return true;
    final lastErrorTime = _errorRegistry[errorKey]!;
    return now.difference(lastErrorTime) > _errorThreshold;
  }

  void _cleanupOldErrors() {
    if (_errorRegistry.length <= _maxErrorEntries) return;
    final entriesToRemove = _errorRegistry.length - (_maxErrorEntries ~/ 2);
    final sortedEntries =
        _errorRegistry.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
    for (var i = 0; i < entriesToRemove; i++) {
      _errorRegistry.remove(sortedEntries[i].key);
    }
  }

  /// Categoriza un error en una de las categorías definidas
  ErrorTipo categorizarError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('timeout')) {
      return ErrorTipo.timeout;
    }

    if (errorStr.contains('cannot write to socket') ||
        errorStr.contains('socket closed') ||
        errorStr.contains('it is closed') ||
        errorStr.contains('connection') ||
        errorStr.contains('conexión') ||
        errorStr.contains('refused')) {
      return ErrorTipo.conexion;
    }

    if (errorStr.contains('prepare')) {
      return ErrorTipo.preparedStatement;
    }

    if (errorStr.contains('access denied') ||
        errorStr.contains('authentication')) {
      return ErrorTipo.autenticacion;
    }

    if (errorStr.contains('transaction') ||
        errorStr.contains('commit') ||
        errorStr.contains('rollback')) {
      return ErrorTipo.transaccion;
    }

    if (errorStr.contains('syntax') ||
        errorStr.contains('unknown column') ||
        errorStr.contains('query')) {
      return ErrorTipo.consulta;
    }

    if (errorStr.contains('constraint') ||
        errorStr.contains('duplicate') ||
        errorStr.contains('foreign key')) {
      return ErrorTipo.constraint;
    }

    return ErrorTipo.desconocido;
  }

  /// Ejecuta una operación con manejo de errores y reintentos
  Future<T> executeWithErrorHandling<T>(
    String operationId,
    Future<T> Function() operation, {
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;

    while (true) {
      try {
        return await operation();
      } catch (e, stack) {
        attempts++;

        final categoria = categorizarError(e);
        final shouldRetry =
            categoria == ErrorTipo.conexion ||
            categoria == ErrorTipo.timeout ||
            categoria == ErrorTipo.preparedStatement;

        if (shouldRetry && attempts <= maxRetries) {
          AppLogger.warning(
            '[Intento $attempts/$maxRetries] Error categorizado como ${categoria.toString().split('.').last}, reintentando...',
          );

          await Future.delayed(retryDelay * attempts);
          continue;
        }

        // Si llegamos aquí, no hay más reintentos o no es un error que debamos reintentar
        ErrorHandler.registrarError(
          'db_error_$operationId',
          'Error de base de datos (${categoria.toString().split('.').last})',
          e,
          stack,
        );

        rethrow;
      }
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inmobiliaria/utils/applogger.dart';
import 'package:inmobiliaria/utils/error_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/utils/circuit_breaker.dart';
import 'package:inmobiliaria/services/mysql_helper.dart';

/// Manejador centralizado de errores MySQL
class MySqlErrorManager {
  // Singleton
  static final MySqlErrorManager _instance = MySqlErrorManager._internal();
  factory MySqlErrorManager() => _instance;
  MySqlErrorManager._internal();

  // Circuit breaker para la conexión MySQL
  final CircuitBreaker _circuitBreaker = CircuitBreaker(
    name: 'mysql-connection',
    resetTimeout: const Duration(minutes: 1),
    failureThreshold: 5,
    onCircuitOpen: () {
      AppLogger.warning('Circuit breaker abierto para conexiones MySQL');
    },
  );

  /// Clasifica un error de MySQL
  ErrorType classifyError(dynamic error) {
    final errorMsg = error.toString().toLowerCase();

    if (errorMsg.contains('socket') ||
        errorMsg.contains('closed') ||
        errorMsg.contains('connection') ||
        errorMsg.contains('cannot write')) {
      return ErrorType.connection;
    }

    if (errorMsg.contains('timeout')) {
      return ErrorType.timeout;
    }

    if (errorMsg.contains('mysql') ||
        errorMsg.contains('packet') ||
        errorMsg.contains('protocol')) {
      return ErrorType.mysqlProtocol;
    }

    if (errorMsg.contains('prepared') || errorMsg.contains('statement')) {
      return ErrorType.preparedStatement;
    }

    if (errorMsg.contains('illegal length')) {
      return ErrorType.socketClosed;
    }

    return ErrorType.unknown;
  }

  /// Ejecuta una operación dentro del circuit breaker
  Future<T> executeWithCircuitBreaker<T>(
    String operationId,
    Future<T> Function() operation, {
    bool handleErrors = true,
  }) async {
    try {
      return await _circuitBreaker.execute(() => operation());
    } catch (e, stack) {
      final errorType = classifyError(e);

      // Registramos el error pero evitamos duplicados
      await ErrorHandler.registrarError(
        'mysql_${operationId}_${errorType.name}',
        'Error MySQL en operación $operationId: ${errorType.name}',
        e,
        stack,
      );

      if (handleErrors) {
        await _handleError(e, errorType);
      }

      rethrow;
    }
  }

  /// Maneja un error específico de MySQL
  Future<void> _handleError(dynamic error, ErrorType type) async {
    switch (type) {
      case ErrorType.connection:
      case ErrorType.socketClosed:
        // Intentar reiniciar conexiones
        await _tryReconnect();
        break;
      case ErrorType.timeout:
        // Esperar antes de reintentar
        await Future.delayed(const Duration(seconds: 2));
        break;
      case ErrorType.mysqlProtocol:
        // Reinicio más profundo para errores de protocolo
        await _tryResetPool();
        break;
      default:
        // Para otros errores, simplemente registrarlos
        break;
    }
  }

  /// Intenta reconectar de forma segura
  Future<void> _tryReconnect() async {
    try {
      final dbService = DatabaseService();
      await dbService.reiniciarConexion();
    } catch (e) {
      AppLogger.warning(
        'Error al intentar reconectar: ${e.toString().split('\n').first}',
      );
    }
  }

  /// Intenta reiniciar el pool de conexiones
  Future<void> _tryResetPool() async {
    try {
      final dbService = DatabaseService();
      await dbService.reiniciarPoolConexiones();
    } catch (e) {
      AppLogger.warning(
        'Error al reiniciar pool: ${e.toString().split('\n').first}',
      );
    }
  }

  /// Muestra un SnackBar informativo con opción de reintentar
  void mostrarErrorMySql(
    BuildContext context,
    WidgetRef ref,
    dynamic error, {
    VoidCallback? onRetry,
    bool mostrarBotonReintentar = true,
  }) {
    if (!context.mounted) return;

    final errorType = classifyError(error);
    final mensaje = _obtenerMensajeAmigable(error, errorType);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _getColorForErrorType(errorType),
        duration: const Duration(seconds: 5),
        action:
            mostrarBotonReintentar && onRetry != null
                ? SnackBarAction(
                  label: 'Reintentar',
                  textColor: Colors.white,
                  onPressed: () async {
                    await _tryReconnect();
                    onRetry();
                  },
                )
                : null,
      ),
    );
  }

  /// Obtiene un mensaje amigable según el tipo de error
  String _obtenerMensajeAmigable(dynamic error, ErrorType type) {
    switch (type) {
      case ErrorType.connection:
      case ErrorType.socketClosed:
        return 'Error de conexión con la base de datos. Verifique su conexión a internet.';
      case ErrorType.timeout:
        return 'La operación tardó demasiado tiempo. Por favor, intente nuevamente.';
      case ErrorType.mysqlProtocol:
        return 'Error de comunicación con la base de datos. Intente nuevamente.';
      case ErrorType.preparedStatement:
        return 'Error en la consulta a la base de datos. Intente nuevamente.';
      default:
        final message = error.toString().split('\n').first;
        return message.length > 100
            ? '${message.substring(0, 97)}...'
            : message;
    }
  }

  /// Obtiene un color según el tipo de error
  Color _getColorForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.connection:
      case ErrorType.socketClosed:
        return Colors.orange;
      case ErrorType.timeout:
        return Colors.amber.shade800;
      case ErrorType.mysqlProtocol:
        return Colors.deepOrange;
      case ErrorType.preparedStatement:
        return Colors.red.shade800;
      default:
        return Colors.red;
    }
  }
}

/// Tipos de error de MySQL
enum ErrorType {
  connection,
  timeout,
  mysqlProtocol,
  preparedStatement,
  socketClosed,
  unknown,
}

/// Provider para el manejador de errores MySQL
final mySqlErrorManagerProvider = Provider<MySqlErrorManager>((ref) {
  return MySqlErrorManager();
});

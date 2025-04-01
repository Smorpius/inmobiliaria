import 'dart:async';
import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../services/mysql_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manejador especializado para errores de conexión a MySQL
class SocketErrorHandler {
  // Singleton
  static final SocketErrorHandler _instance = SocketErrorHandler._internal();
  factory SocketErrorHandler() => _instance;
  SocketErrorHandler._internal();

  // Control para evitar reconexiones duplicadas
  bool _reconectando = false;
  final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _tiempoMinimoDuplicado = Duration(minutes: 1);

  /// Determina si un error es de conexión
  bool isSocketError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('cannot write to socket') ||
        errorStr.contains('it is closed') ||
        (errorStr.contains('socket') && errorStr.contains('closed')) ||
        errorStr.contains('connection refused') ||
        errorStr.contains('connection reset');
  }

  /// Determina si un error es específicamente de MySQL
  bool isMySqlError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('mysql') ||
        errorStr.contains('packet') ||
        errorStr.contains('prepared statement');
  }

  /// Muestra un SnackBar con mensaje amigable y opción de reintentar
  void showErrorSnackbar(
    BuildContext context,
    WidgetRef ref,
    String message, {
    VoidCallback? onRetry,
    Color backgroundColor = Colors.orange,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        action:
            onRetry != null
                ? SnackBarAction(
                  label: 'Reintentar',
                  onPressed: () async {
                    try {
                      await ref
                          .read(databaseServiceProvider)
                          .reiniciarConexion();
                      onRetry();
                    } catch (e) {
                      AppLogger.error('Error al reintentar conexión', e);
                    }
                  },
                )
                : null,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Maneja un error con un enfoque estandarizado
  Future<bool> handleError(
    dynamic error,
    StackTrace stackTrace,
    BuildContext? context,
    WidgetRef? ref,
    String operationName, {
    VoidCallback? onRetry,
  }) async {
    final errorKey = '${operationName}_${error.hashCode}';
    final now = DateTime.now();

    // Evitar logs duplicados del mismo error
    if (_ultimosErrores.containsKey(errorKey) &&
        now.difference(_ultimosErrores[errorKey]!) < _tiempoMinimoDuplicado) {
      _ejecutarReintentoSiEsNecesario(error, ref, onRetry);
      return true;
    }

    _ultimosErrores[errorKey] = now;

    // Registrar el error
    AppLogger.error('Error en operación "$operationName"', error, stackTrace);

    // Si es un error de conexión, intentar reconectar
    if (isSocketError(error) || isMySqlError(error)) {
      await _manejarErrorConexion(context, ref, error, onRetry);
      return true;
    }

    // Mostrar mensaje si hay contexto disponible
    if (context != null && context.mounted && ref != null) {
      showErrorSnackbar(
        context,
        ref,
        _obtenerMensajeFriendly(error.toString()),
        onRetry: onRetry,
        backgroundColor: Colors.red,
      );
    }

    return false;
  }

  /// Maneja específicamente errores de conexión
  Future<void> _manejarErrorConexion(
    BuildContext? context,
    WidgetRef? ref,
    dynamic error,
    VoidCallback? onRetry,
  ) async {
    if (_reconectando) return;

    _reconectando = true;
    try {
      if (ref != null) {
        await ref.read(databaseServiceProvider).reiniciarConexion();

        if (context != null && context.mounted) {
          showErrorSnackbar(
            context,
            ref,
            'La conexión se ha restablecido. Por favor, intente nuevamente.',
            onRetry: onRetry,
          );
        }

        _ejecutarReintentoSiEsNecesario(error, ref, onRetry);
      }
    } catch (e) {
      AppLogger.error('Error al intentar reconectar', e, StackTrace.current);
    } finally {
      _reconectando = false;
    }
  }

  /// Ejecuta el reintento si es necesario
  void _ejecutarReintentoSiEsNecesario(
    dynamic error,
    WidgetRef? ref,
    VoidCallback? onRetry,
  ) {
    if (onRetry != null) {
      final delay =
          isMySqlError(error)
              ? const Duration(seconds: 2)
              : const Duration(milliseconds: 500);

      Future.delayed(delay, onRetry);
    }
  }

  /// Convierte un mensaje de error técnico en uno amigable para el usuario
  String _obtenerMensajeFriendly(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('socket') ||
        errorLower.contains('connection') ||
        errorLower.contains('closed')) {
      return 'Error de conexión con la base de datos. Verifique su conexión a Internet.';
    } else if (errorLower.contains('mysql')) {
      return 'Error en la comunicación con la base de datos. Intente nuevamente.';
    } else if (errorLower.contains('timeout')) {
      return 'La operación tardó demasiado tiempo. Intente nuevamente más tarde.';
    }

    return error.length > 100 ? '${error.substring(0, 97)}...' : error;
  }

  /// Limpia errores antiguos para evitar fugas de memoria
  void cleanupOldErrors() {
    final now = DateTime.now();
    final keysToRemove =
        _ultimosErrores.entries
            .where(
              (entry) =>
                  now.difference(entry.value) > const Duration(minutes: 30),
            )
            .map((entry) => entry.key)
            .toList();

    for (final key in keysToRemove) {
      _ultimosErrores.remove(key);
    }
  }
}

// Provider para acceder al manejador de errores
final socketErrorHandlerProvider = Provider<SocketErrorHandler>((ref) {
  return SocketErrorHandler();
});

// Provider para acceder al servicio de base de datos
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

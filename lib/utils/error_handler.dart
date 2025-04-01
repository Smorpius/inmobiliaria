import 'dart:async';
import 'applogger.dart';
import 'package:synchronized/synchronized.dart';

class ErrorHandler {
  static final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _intervaloMinimo = Duration(minutes: 2);
  static final Lock _lock = Lock();

  /// Registra un error evitando duplicados en un intervalo corto
  static Future<void> registrarError(
    String codigo,
    String mensaje,
    dynamic error,
    StackTrace? stackTrace, {
    bool criticalError = true,
  }) async {
    final errorKey = '$codigo:${error.hashCode}';
    final ahora = DateTime.now();

    await _lock.synchronized(() {
      // Evitar logs duplicados en intervalo corto
      if (_ultimosErrores.containsKey(errorKey) &&
          ahora.difference(_ultimosErrores[errorKey]!) < _intervaloMinimo) {
        return;
      }

      _ultimosErrores[errorKey] = ahora;

      // Limpieza para evitar memory leaks
      _limpiarErroresAntiguos();
    });

    try {
      if (criticalError) {
        AppLogger.error(mensaje, error, stackTrace ?? StackTrace.current);
      } else {
        AppLogger.warning('$mensaje: ${error.toString().split('\n').first}');
      }
    } catch (e) {
      AppLogger.error('Error al registrar el error: $e', e, StackTrace.current);
    }
  }

  /// Limpia registros de errores antiguos
  static void _limpiarErroresAntiguos() {
    try {
      if (_ultimosErrores.length > 50) {
        final keysToRemove = _ultimosErrores.entries
            .toList()
            .sublist(0, 25)
            .map((e) => e.key)
            .toList();

        for (var key in keysToRemove) {
          _ultimosErrores.remove(key);
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error al limpiar errores antiguos: $e',
        e,
        StackTrace.current,
      );
    }
  }

  /// Formatea un error para mostrar al usuario
  static String obtenerMensajeAmigable(dynamic error) {
    try {
      final errorStr = error.toString().toLowerCase();

      if (errorStr.contains('connection') ||
          errorStr.contains('socket') ||
          errorStr.contains('timeout')) {
        return 'Error de conexión. Verifique su conexión a internet e intente nuevamente.';
      } else if (errorStr.contains('mysql') ||
          errorStr.contains('database') ||
          errorStr.contains('sql')) {
        return 'Error en la base de datos. Intente nuevamente más tarde.';
      }

      // Limitar longitud del mensaje
      final mensaje = error.toString().split('\n').first;
      if (mensaje.length > 100) {
        return '${mensaje.substring(0, 97)}...';
      }

      return mensaje;
    } catch (e) {
      AppLogger.error(
        'Error al formatear mensaje amigable: $e',
        e,
        StackTrace.current,
      );
      return 'Ocurrió un error inesperado.';
    }
  }

  /// Ejecuta una operación con reintentos y manejo de errores
  static Future<T> ejecutarConReintentos<T>({
    required Future<T> Function() operacion,
    required String descripcion,
    int maxIntentos = 3,
    Duration delayBase = const Duration(seconds: 1),
    bool reintentarSiErrorConexion = true,
  }) async {
    int intentos = 0;

    while (intentos < maxIntentos) {
      try {
        if (intentos > 0) {
          AppLogger.info(
            'Reintentando $descripcion (${intentos + 1}/$maxIntentos)',
          );
          await Future.delayed(delayBase * intentos);
        }

        return await operacion();
      } catch (e, stack) {
        intentos++;

        final esErrorConexion =
            e.toString().toLowerCase().contains('connection') ||
            e.toString().toLowerCase().contains('socket');

        // Solo reintentar errores de conexión si está configurado así
        if (!reintentarSiErrorConexion && !esErrorConexion) {
          await registrarError('error_operacion', 'Error en $descripcion', e, stack);
          rethrow;
        }

        if (intentos == maxIntentos) {
          await registrarError(
            'error_final',
            'Error final en $descripcion tras $maxIntentos intentos',
            e,
            stack,
          );
          rethrow;
        }

        await registrarError(
          'error_reintento',
          'Error en $descripcion (intento $intentos/$maxIntentos)',
          e,
          stack,
          criticalError: false,
        );
      }
    }

    throw Exception('Error inesperado en $descripcion');
  }
}
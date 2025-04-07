import 'package:logging/logging.dart';

/// Clase para manejar operaciones con un enfoque centralizado de manejo de errores
class OperationHandler {
  static final Logger _logger = Logger('OperationHandler');
  static final Map<String, DateTime> _errorCache = {};

  /// Ejecuta una operación con manejo de errores centralizado
  ///
  /// [operationName] es un nombre descriptivo de la operación que se está realizando
  /// [operation] es la función asíncrona a ejecutar
  /// [errorThreshold] es el tiempo mínimo entre registros del mismo error (para evitar spam en logs)
  /// [shouldRethrow] indica si se debe relanzar la excepción o retornar null en caso de error
  static Future<T> execute<T>({
    required String operationName,
    required Future<T> Function() operation,
    Duration errorThreshold = const Duration(seconds: 5),
    bool shouldRethrow = true,
  }) async {
    try {
      _logger.info('Iniciando operación: $operationName');
      final resultado = await operation();
      _logger.info('Operación completada exitosamente: $operationName');
      return resultado;
    } catch (e, stackTrace) {
      final now = DateTime.now();
      final lastError = _errorCache[operationName];

      // Limitamos la frecuencia de registro de errores similares
      if (lastError == null || now.difference(lastError) > errorThreshold) {
        _errorCache[operationName] = now;
        _logger.severe('Error en operación "$operationName"', e, stackTrace);
      }

      if (shouldRethrow) {
        throw Exception('Error en $operationName: $e');
      }

      // Valor por defecto en caso de error
      return null as T;
    }
  }

  /// Limpia el caché de errores (útil para testing)
  static void clearErrorCache() {
    _errorCache.clear();
  }
}

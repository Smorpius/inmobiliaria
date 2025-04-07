import 'package:logging/logging.dart';

/// Clase abstracta que define la interfaz básica para modelos serializables
///
/// Proporciona estructura común para convertir objetos a mapas (para BD/JSON)
/// y para crear objetos desde mapas de manera segura.
abstract class SerializableModel {
  static final Logger _logger = Logger('SerializableModel');

  /// Convierte el modelo a un mapa para serialización
  Map<String, dynamic> toMap();

  /// Método utilitario para crear objetos desde mapas de manera segura
  ///
  /// [map]: El mapa desde el cual crear el objeto
  /// [constructor]: Función que toma un mapa y devuelve un objeto de tipo T
  static T? fromMapSafe<T>(
    Map<String, dynamic>? map,
    T Function(Map<String, dynamic>) constructor,
  ) {
    if (map == null) return null;
    try {
      return constructor(map);
    } catch (e, stackTrace) {
      _logger.severe('Error creando objeto desde mapa', e, stackTrace);
      return null;
    }
  }

  /// Maneja la conversión de tipos comunes desde la base de datos
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  /// Convierte un valor de la base de datos a booleano (0/1, true/false)
  static bool parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  /// Convierte un valor de la base de datos a entero de manera segura
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    try {
      return int.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  /// Convierte un valor de la base de datos a double de manera segura
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    try {
      return double.parse(value.toString());
    } catch (e) {
      return null;
    }
  }
}

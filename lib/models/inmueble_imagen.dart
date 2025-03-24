import 'dart:developer' as developer;
import 'package:logging/logging.dart';

class InmuebleImagen {
  static final Logger _logger = Logger('InmuebleImagenModel');

  final int? id;
  final int idInmueble;
  final String rutaImagen;
  final String? descripcion;
  final bool esPrincipal;
  final DateTime? fechaCarga;

  // Constructor
  InmuebleImagen({
    this.id,
    required this.idInmueble,
    required this.rutaImagen,
    this.descripcion,
    this.esPrincipal = false,
    this.fechaCarga,
  });

  // Factory constructor mejorado para crear desde Map (DB) con mejor manejo de errores
  factory InmuebleImagen.fromMap(Map<String, dynamic> map) {
    try {
      // Verificación exhaustiva de tipos y conversiones seguras
      int? id =
          map['id_imagen'] is int
              ? map['id_imagen']
              : int.tryParse(map['id_imagen']?.toString() ?? '');

      int? idInmueble =
          map['id_inmueble'] is int
              ? map['id_inmueble']
              : int.tryParse(map['id_inmueble']?.toString() ?? '');

      // Si los ID son inválidos, lanzar una excepción informativa
      if (id == null || idInmueble == null) {
        throw FormatException(
          'ID inválido en datos de imagen: id=$id, idInmueble=$idInmueble',
        );
      }

      // La ruta de imagen debe existir y ser no vacía
      String rutaImagen = map['ruta_imagen']?.toString() ?? '';
      if (rutaImagen.isEmpty) {
        developer.log('Advertencia: imagen con ruta vacía ID=$id');
      }

      // Conversión segura de la fecha
      DateTime? fechaCarga;
      try {
        if (map['fecha_carga'] is DateTime) {
          fechaCarga = map['fecha_carga'];
        } else if (map['fecha_carga'] != null) {
          fechaCarga = DateTime.parse(map['fecha_carga'].toString());
        }
      } catch (e) {
        _logger.warning(
          'Error al parsear fecha_carga: ${map['fecha_carga']}, error: $e',
        );
      }

      // Conversión segura del valor booleano
      bool esPrincipal = false;
      if (map['es_principal'] is bool) {
        esPrincipal = map['es_principal'];
      } else if (map['es_principal'] != null) {
        esPrincipal =
            map['es_principal'] == 1 ||
            map['es_principal'].toString().toLowerCase() == 'true';
      }

      return InmuebleImagen(
        id: id,
        idInmueble: idInmueble,
        rutaImagen: rutaImagen,
        descripcion: map['descripcion']?.toString(),
        esPrincipal: esPrincipal,
        fechaCarga: fechaCarga,
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al procesar datos de imagen: $e');
      developer.log(
        'Error al procesar datos de imagen: $e\nDatos: $map\n$stackTrace',
      );
      throw FormatException('Error al procesar datos de imagen: $e');
    }
  }

  // Convertir a Map para guardar en BD
  Map<String, dynamic> toMap() {
    return {
      'id_imagen': id,
      'id_inmueble': idInmueble,
      'ruta_imagen': rutaImagen,
      'descripcion': descripcion,
      'es_principal': esPrincipal ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'InmuebleImagen{id: $id, idInmueble: $idInmueble, rutaImagen: $rutaImagen, esPrincipal: $esPrincipal}';
  }
}

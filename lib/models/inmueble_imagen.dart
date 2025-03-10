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

  // Factory constructor para crear desde Map (DB)
  factory InmuebleImagen.fromMap(Map<String, dynamic> map) {
    DateTime? fechaCarga;
    try {
      if (map['fecha_carga'] != null) {
        fechaCarga =
            map['fecha_carga'] is DateTime
                ? map['fecha_carga']
                : DateTime.parse(map['fecha_carga']);
      }
    } catch (e) {
      _logger.warning(
        'Error al parsear fecha_carga: ${map['fecha_carga']}, error: $e',
      );
    }

    return InmuebleImagen(
      id: map['id_imagen'],
      idInmueble: map['id_inmueble'],
      rutaImagen: map['ruta_imagen'],
      descripcion: map['descripcion'],
      esPrincipal: map['es_principal'] == 1 || map['es_principal'] == true,
      fechaCarga: fechaCarga,
    );
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
}

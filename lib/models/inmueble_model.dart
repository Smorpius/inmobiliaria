import 'package:logging/logging.dart';

class Inmueble {
  static final Logger _logger = Logger('InmuebleModel');

  final int? id;
  final String nombre;
  final int? idDireccion;
  final double montoTotal;
  final int? idEstado;
  final int? idCliente;
  final DateTime? fechaRegistro;

  Inmueble({
    this.id,
    required this.nombre,
    this.idDireccion,
    required this.montoTotal,
    this.idEstado,
    this.idCliente,
    this.fechaRegistro,
  });

  factory Inmueble.fromMap(Map<String, dynamic> map) {
    // Log informativo con los datos recibidos
    _logger.info('Procesando datos del inmueble: $map');

    // Manejo seguro del monto total
    double montoTotal;
    try {
      if (map['monto_total'] == null) {
        montoTotal = 0.0;
        _logger.warning('Advertencia: monto_total es nulo, usando 0.0');
      } else if (map['monto_total'] is String) {
        montoTotal = double.parse(map['monto_total']);
      } else if (map['monto_total'] is int) {
        montoTotal = (map['monto_total'] as int).toDouble();
      } else {
        montoTotal = (map['monto_total'] as double?) ?? 0.0;
      }
    } catch (e) {
      _logger.severe(
        'Error al convertir monto_total: ${map['monto_total']}, error: $e',
      );
      montoTotal = 0.0;
    }

    // Convertir fechaRegistro con manejo seguro
    DateTime? fechaRegistro;
    try {
      if (map['fecha_registro'] != null) {
        if (map['fecha_registro'] is DateTime) {
          fechaRegistro = map['fecha_registro'] as DateTime;
        } else if (map['fecha_registro'] is String) {
          fechaRegistro = DateTime.parse(map['fecha_registro']);
        }
      }
    } catch (e) {
      _logger.severe(
        'Error al parsear fecha_registro: ${map['fecha_registro']}, error: $e',
      );
      fechaRegistro = null;
    }

    return Inmueble(
      id:
          map['id_inmueble'] is int
              ? map['id_inmueble']
              : (map['id_inmueble'] is String
                  ? int.tryParse(map['id_inmueble'])
                  : null),
      nombre: (map['nombre_inmueble'] as String?) ?? 'Sin nombre',
      idDireccion:
          map['id_direccion'] is int
              ? map['id_direccion']
              : (map['id_direccion'] is String
                  ? int.tryParse(map['id_direccion'])
                  : null),
      montoTotal: montoTotal,
      idEstado:
          map['id_estado'] is int
              ? map['id_estado']
              : (map['id_estado'] is String
                  ? int.tryParse(map['id_estado'])
                  : 1),
      idCliente:
          map['id_cliente'] is int
              ? map['id_cliente']
              : (map['id_cliente'] is String
                  ? int.tryParse(map['id_cliente'])
                  : null),
      fechaRegistro: fechaRegistro,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_inmueble': id,
      'nombre_inmueble': nombre,
      'id_direccion': idDireccion,
      'monto_total': montoTotal,
      'id_estado': idEstado,
      'id_cliente': idCliente,
    };
  }

  @override
  String toString() {
    return 'Inmueble{id: $id, nombre: $nombre, montoTotal: $montoTotal, idCliente: $idCliente, fechaRegistro: $fechaRegistro}';
  }
}

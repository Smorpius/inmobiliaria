import 'package:logging/logging.dart';

class ClienteInmueble {
  static final Logger _logger = Logger('ClienteInmueble');

  final int? id;
  final int idCliente;
  final int idInmueble;
  final DateTime fechaAdquisicion;

  ClienteInmueble({
    this.id,
    required this.idCliente,
    required this.idInmueble,
    required this.fechaAdquisicion,
  });

  factory ClienteInmueble.fromMap(Map<String, dynamic> map) {
    DateTime? fechaAdquisicion;
    try {
      if (map['fecha_adquisicion'] != null) {
        fechaAdquisicion =
            map['fecha_adquisicion'] is DateTime
                ? map['fecha_adquisicion']
                : DateTime.parse(map['fecha_adquisicion'].toString());
      }
    } catch (e) {
      _logger.warning('Error al parsear fecha_adquisicion: $e');
      fechaAdquisicion = DateTime.now();
    }

    return ClienteInmueble(
      id: map['id'],
      idCliente: map['id_cliente'],
      idInmueble: map['id_inmueble'],
      fechaAdquisicion: fechaAdquisicion ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_cliente': idCliente,
      'id_inmueble': idInmueble,
      'fecha_adquisicion': fechaAdquisicion.toIso8601String().split('T')[0],
    };
  }

  @override
  String toString() {
    return 'ClienteInmueble{id: $id, idCliente: $idCliente, idInmueble: $idInmueble, fechaAdquisicion: $fechaAdquisicion}';
  }
}

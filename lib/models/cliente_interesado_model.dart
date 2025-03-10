import 'package:logging/logging.dart';

class ClienteInteresado {
  static final Logger _logger = Logger('ClienteInteresado');

  final int? id;
  final int idInmueble;
  final int idCliente;
  final DateTime fechaInteres;
  final String? comentarios;

  // Propiedades del cliente asociado
  final String nombreCliente;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String telefono;
  final String? correo;

  ClienteInteresado({
    this.id,
    required this.idInmueble,
    required this.idCliente,
    required this.fechaInteres,
    this.comentarios,
    required this.nombreCliente,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    required this.telefono,
    this.correo,
  });

  factory ClienteInteresado.fromMap(Map<String, dynamic> map) {
    DateTime fechaInteres;
    try {
      if (map['fecha_interes'] is DateTime) {
        fechaInteres = map['fecha_interes'];
      } else {
        fechaInteres = DateTime.parse(map['fecha_interes'].toString());
      }
    } catch (e) {
      _logger.warning('Error al parsear fecha_interes: $e');
      fechaInteres = DateTime.now();
    }

    return ClienteInteresado(
      id: map['id'],
      idInmueble: map['id_inmueble'],
      idCliente: map['id_cliente'],
      fechaInteres: fechaInteres,
      comentarios: map['comentarios'],
      nombreCliente: map['nombre'] ?? '',
      apellidoPaterno: map['apellido_paterno'] ?? '',
      apellidoMaterno: map['apellido_materno'],
      telefono: map['telefono_cliente'] ?? '',
      correo: map['correo_cliente'],
    );
  }

  String get nombreCompleto =>
      '$nombreCliente $apellidoPaterno${apellidoMaterno != null ? ' $apellidoMaterno' : ''}';

  @override
  String toString() {
    return 'ClienteInteresado{id: $id, idInmueble: $idInmueble, cliente: $nombreCompleto, fecha: $fechaInteres}';
  }
}

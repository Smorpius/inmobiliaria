import 'package:logging/logging.dart';

class Cliente {
  static final Logger _logger = Logger('Cliente');

  final int? id;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final int? idDireccion;
  final String telefono;
  final String rfc;
  final String curp;
  final String tipoCliente;
  final String? correo;
  final int? idEstado;
  final DateTime? fechaRegistro;
  final String? estadoCliente;

  // Campos completos de dirección según la nueva estructura de la DB
  final String? calle;
  final String? numero;
  final String? colonia;
  final String? ciudad;
  final String? estadoGeografico;
  final String? codigoPostal;
  final String? referencias;

  Cliente({
    this.id,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    this.idDireccion,
    required this.telefono,
    required this.rfc,
    required this.curp,
    this.tipoCliente = 'comprador',
    this.correo,
    this.idEstado,
    this.fechaRegistro,
    this.estadoCliente,
    this.calle,
    this.numero,
    this.colonia,
    this.ciudad,
    this.estadoGeografico,
    this.codigoPostal,
    this.referencias,
  });

  factory Cliente.fromMap(Map<String, dynamic> map) {
    DateTime? fechaRegistro;
    try {
      if (map['fecha_registro'] != null) {
        if (map['fecha_registro'] is DateTime) {
          fechaRegistro = map['fecha_registro'];
        } else {
          fechaRegistro = DateTime.parse(map['fecha_registro'].toString());
        }
      }
    } catch (e) {
      _logger.warning('Error al parsear fecha_registro: $e');
    }

    return Cliente(
      id: map['id_cliente'],
      nombre: map['nombre'] ?? '',
      apellidoPaterno: map['apellido_paterno'] ?? '',
      apellidoMaterno: map['apellido_materno'],
      idDireccion: map['id_direccion'],
      telefono: map['telefono_cliente'] ?? '',
      rfc: map['rfc'] ?? '',
      curp: map['curp'] ?? '',
      tipoCliente: map['tipo_cliente'] ?? 'comprador',
      correo: map['correo_cliente'],
      idEstado: map['id_estado'],
      fechaRegistro: fechaRegistro,
      estadoCliente: map['estado_cliente'],
      // Campos de dirección completos
      calle: map['calle'],
      numero: map['numero'],
      colonia: map['colonia'],
      ciudad: map['ciudad'],
      estadoGeografico: map['estado_geografico'],
      codigoPostal: map['codigo_postal'],
      referencias: map['referencias'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_cliente': id,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'id_direccion': idDireccion,
      'telefono_cliente': telefono,
      'rfc': rfc,
      'curp': curp,
      'tipo_cliente': tipoCliente,
      'correo_cliente': correo,
      'id_estado': idEstado,
    };
  }

  // Propiedad para obtener el nombre completo
  String get nombreCompleto =>
      '$nombre $apellidoPaterno${apellidoMaterno != null ? ' $apellidoMaterno' : ''}';

  // Propiedad mejorada para obtener la dirección completa con todos los campos
  String get direccionCompleta {
    final List<String> partes = [];

    if (calle != null && calle!.isNotEmpty) {
      String parte = calle!;
      if (numero != null && numero!.isNotEmpty) parte += ' $numero';
      partes.add(parte);
    }

    if (colonia != null && colonia!.isNotEmpty) {
      partes.add('Col. $colonia');
    }

    if (ciudad != null && ciudad!.isNotEmpty) {
      String parte = ciudad!;
      if (estadoGeografico != null && estadoGeografico!.isNotEmpty) {
        parte += ', $estadoGeografico';
      }
      partes.add(parte);
    }

    if (codigoPostal != null && codigoPostal!.isNotEmpty) {
      partes.add('C.P. $codigoPostal');
    }

    return partes.isNotEmpty ? partes.join(', ') : 'Dirección no disponible';
  }

  String get estado => estadoCliente ?? (idEstado == 1 ? 'Activo' : 'Inactivo');

  @override
  String toString() {
    return 'Cliente{id: $id, nombre: $nombreCompleto, telefono: $telefono, RFC: $rfc, CURP: $curp, tipo: $tipoCliente}';
  }
}

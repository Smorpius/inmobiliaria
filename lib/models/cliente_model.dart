class Cliente {
  final int? id;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final int? idDireccion;
  final String telefono;
  final String rfc;
  final String curp;
  final String tipoCliente; // Nuevo campo
  final String? correo;
  final int? idEstado;
  final DateTime? fechaRegistro;

  // Campos para mostrar la dirección completa
  final String? calle;
  final String? numero;
  final String? ciudad;
  final String? codigoPostal;

  Cliente({
    this.id,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    this.idDireccion,
    required this.telefono,
    required this.rfc,
    required this.curp,
    this.tipoCliente = 'comprador', // Valor predeterminado
    this.correo,
    this.idEstado,
    this.fechaRegistro,
    this.calle,
    this.numero,
    this.ciudad,
    this.codigoPostal,
  });

  // Método fromMap actualizado para la nueva estructura
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id_cliente'],
      nombre: map['nombre'],
      apellidoPaterno: map['apellido_paterno'],
      apellidoMaterno: map['apellido_materno'],
      idDireccion: map['id_direccion'],
      telefono: map['telefono_cliente'] ?? '',
      rfc: map['rfc'],
      curp: map['curp'],
      tipoCliente: map['tipo_cliente'] ?? 'comprador',
      correo: map['correo_cliente'],
      idEstado: map['id_estado'],
      fechaRegistro:
          map['fecha_registro'] != null
              ? DateTime.parse(map['fecha_registro'].toString())
              : null,
      calle: map['calle'],
      numero: map['numero'],
      ciudad: map['ciudad'],
      codigoPostal: map['codigo_postal'],
    );
  }

  // Método toMap actualizado
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
      'fecha_registro': fechaRegistro?.toIso8601String(),
    };
  }

  // Propiedad para obtener el nombre completo
  String get nombreCompleto =>
      '$nombre $apellidoPaterno${apellidoMaterno != null ? ' $apellidoMaterno' : ''}';

  // Propiedad para obtener la dirección completa
  String get direccionCompleta =>
      calle != null && ciudad != null
          ? '$calle${numero != null ? ' $numero' : ''}, $ciudad${codigoPostal != null ? ', CP: $codigoPostal' : ''}'
          : 'Dirección no disponible';

  @override
  String toString() {
    return 'Cliente{id: $id, nombre: $nombreCompleto, telefono: $telefono, RFC: $rfc, CURP: $curp}';
  }
}

class Cliente {
  final int? id;
  final String nombre;
  final int? idDireccion;
  final String telefono;
  final String rfc;
  final String curp;
  final String? correo;

  Cliente({
    this.id,
    required this.nombre,
    this.idDireccion,
    required this.telefono,
    required this.rfc,
    required this.curp,
    this.correo,
  });

  // Convertir de Map a Cliente
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id_cliente'],
      nombre: map['nombre_cliente'],
      idDireccion: map['id_direccion'],
      telefono: map['telefono_cliente'],
      rfc: map['rfc'],
      curp: map['curp'],
      correo: map['correo_cliente'],
    );
  }

  // Convertir de Cliente a Map
  Map<String, dynamic> toMap() {
    return {
      'id_cliente': id,
      'nombre_cliente': nombre,
      'id_direccion': idDireccion,
      'telefono_cliente': telefono,
      'rfc': rfc,
      'curp': curp,
      'correo_cliente': correo,
    };
  }

  @override
  String toString() {
    return 'Cliente{id: $id, nombre: $nombre, telefono: $telefono, RFC: $rfc, CURP: $curp}';
  }
}

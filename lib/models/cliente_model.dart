// lib/models/cliente_model.dart
class Cliente {
  final int? id;
  final String nombre;
  final String direccion;
  final String telefono;
  final String rfc;
  final String curp;

  Cliente({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.rfc,
    required this.curp,
  });

  // Convertir de Map a Cliente
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['ID_Cliente'],
      nombre: map['nombre_cliente'],
      direccion: map['direccion_cliente'],
      telefono: map['numero_telf'],
      rfc: map['RFC'],
      curp: map['CURP'],
    );
  }

  // Convertir de Cliente a Map
  Map<String, dynamic> toMap() {
    return {
      'ID_Cliente': id,
      'nombre_cliente': nombre,
      'direccion_cliente': direccion,
      'numero_telf': telefono,
      'RFC': rfc,
      'CURP': curp,
    };
  }

  @override
  String toString() {
    return 'Cliente{id: $id, nombre: $nombre, direccion: $direccion, telefono: $telefono, RFC: $rfc, CURP: $curp}';
  }
}

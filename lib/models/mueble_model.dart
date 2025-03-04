class Mueble {
  final int? id;
  final String nombre;
  final int? idDireccion; // Changed from direccion
  final double montoTotal;
  final int? idEstado; // Added state
  final int? idCliente;

  Mueble({
    this.id,
    required this.nombre,
    this.idDireccion,
    required this.montoTotal,
    this.idEstado,
    this.idCliente,
  });

  // Updated fromMap to match SQL schema
  factory Mueble.fromMap(Map<String, dynamic> map) {
    return Mueble(
      id: map['id_mueble'], // Updated column name
      nombre: map['nombre_mueble'], // Updated column name
      idDireccion: map['id_direccion'], // Changed to use direccion ID
      montoTotal: map['monto_total'], // Hyphenated
      idEstado: map['id_estado'], // Added state
      idCliente: map['id_cliente'],
    );
  }

  // Updated toMap to match SQL schema
  Map<String, dynamic> toMap() {
    return {
      'id_mueble': id,
      'nombre_mueble': nombre,
      'id_direccion': idDireccion,
      'monto_total': montoTotal,
      'id_estado': idEstado,
      'id_cliente': idCliente,
    };
  }

  @override
  String toString() {
    return 'Mueble{id: $id, nombre: $nombre, montoTotal: $montoTotal, idCliente: $idCliente}';
  }
}

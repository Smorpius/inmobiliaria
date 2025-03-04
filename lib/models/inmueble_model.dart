class Inmueble {
  final int? id;
  final String nombre;
  final int? idDireccion; // Changed from direccion
  final double montoTotal;
  final int? idEstado; // Added state
  final int? idCliente;

  Inmueble({
    this.id,
    required this.nombre,
    this.idDireccion,
    required this.montoTotal,
    this.idEstado,
    this.idCliente,
  });

  // Updated fromMap to match SQL schema
  factory Inmueble.fromMap(Map<String, dynamic> map) {
    return Inmueble(
      id: map['id_inmueble'], // Updated column name
      nombre: map['nombre_inmueble'], // Updated column name
      idDireccion: map['id_direccion'], // Changed to use direccion ID
      montoTotal: map['monto_total'], // Hyphenated
      idEstado: map['id_estado'], // Added state
      idCliente: map['id_cliente'],
    );
  }

  // Updated toMap to match SQL schema
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
    return 'Inmueble{id: $id, nombre: $nombre, montoTotal: $montoTotal, idCliente: $idCliente}';
  }
}

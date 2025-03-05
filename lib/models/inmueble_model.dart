class Inmueble {
  final int? id;
  final String nombre;
  final int? idDireccion;
  final double montoTotal;
  final int? idEstado;
  final int? idCliente;
  final DateTime? fechaRegistro; // Nuevo campo

  Inmueble({
    this.id,
    required this.nombre,
    this.idDireccion,
    required this.montoTotal,
    this.idEstado,
    this.idCliente,
    this.fechaRegistro, // Incluido en el constructor
  });

  factory Inmueble.fromMap(Map<String, dynamic> map) {
    return Inmueble(
      id: map['id_inmueble'],
      nombre: map['nombre_inmueble'],
      idDireccion: map['id_direccion'],
      montoTotal: map['monto_total'],
      idEstado: map['id_estado'],
      idCliente: map['id_cliente'],
      fechaRegistro:
          map['fecha_registro'] != null
              ? DateTime.parse(map['fecha_registro'])
              : null,
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
      // No incluimos fecha_registro en toMap() porque se establece automáticamente
    };
  }

  @override
  String toString() {
    return 'Inmueble{id: $id, nombre: $nombre, montoTotal: $montoTotal, idCliente: $idCliente, fechaRegistro: $fechaRegistro}';
  }
}

// lib/models/mueble_model.dart
class Mueble {
  final int? id;
  final String nombre;
  final String direccion;
  final double montoTotal;
  final String estatusProducto;
  final int idCliente;

  Mueble({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.montoTotal,
    required this.estatusProducto,
    required this.idCliente,
  });

  // Convertir de Map a Mueble
  factory Mueble.fromMap(Map<String, dynamic> map) {
    return Mueble(
      id: map['ID_muebles'],
      nombre: map['nombre_mueble'],
      direccion: map['direccion'],
      montoTotal: map['monto_total'],
      estatusProducto: map['estatus_producto'],
      idCliente: map['id_cliente'],
    );
  }

  // Convertir de Mueble a Map
  Map<String, dynamic> toMap() {
    return {
      'ID_muebles': id,
      'nombre_mueble': nombre,
      'direccion': direccion,
      'monto_total': montoTotal,
      'estatus_producto': estatusProducto,
      'id_cliente': idCliente,
    };
  }

  @override
  String toString() {
    return 'Mueble{id: $id, nombre: $nombre, direccion: $direccion, montoTotal: $montoTotal, estatusProducto: $estatusProducto, idCliente: $idCliente}';
  }
}

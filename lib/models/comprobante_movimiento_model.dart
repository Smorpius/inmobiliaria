class ComprobanteMovimiento {
  final int? id;
  final int idMovimiento;
  final String rutaImagen;
  final String? descripcion;
  final bool esPrincipal;
  final DateTime fechaCarga;

  ComprobanteMovimiento({
    this.id,
    required this.idMovimiento,
    required this.rutaImagen,
    this.descripcion,
    this.esPrincipal = false,
    DateTime? fechaCarga,
  }) : fechaCarga = fechaCarga ?? DateTime.now();

  factory ComprobanteMovimiento.fromMap(Map<String, dynamic> map) {
    return ComprobanteMovimiento(
      id: map['id_comprobante'],
      idMovimiento: map['id_movimiento'],
      rutaImagen: map['ruta_imagen'],
      descripcion: map['descripcion'],
      esPrincipal: map['es_principal'] == 1 || map['es_principal'] == true,
      fechaCarga:
          map['fecha_carga'] is DateTime
              ? map['fecha_carga']
              : DateTime.parse(map['fecha_carga']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_comprobante': id,
      'id_movimiento': idMovimiento,
      'ruta_imagen': rutaImagen,
      'descripcion': descripcion,
      'es_principal': esPrincipal ? 1 : 0,
    };
  }
}

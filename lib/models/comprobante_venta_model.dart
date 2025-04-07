import 'comprobante_base_model.dart';
import 'package:logging/logging.dart';

/// Modelo que representa un comprobante o documento adjunto a una venta
class ComprobanteVenta extends ComprobanteBase {
  static final Logger _logger = Logger('ComprobanteVentaModel');

  final int idVenta;

  ComprobanteVenta({
    super.id,
    required this.idVenta,
    required super.rutaArchivo,
    required super.tipoArchivo,
    super.descripcion,
    super.esPrincipal = false,
    super.fechaCarga,
  });

  /// Crea un objeto ComprobanteVenta desde un mapa (para deserialización desde BD)
  factory ComprobanteVenta.fromMap(Map<String, dynamic> map) {
    try {
      return ComprobanteVenta(
        id: map['id_comprobante'],
        idVenta: map['id_venta'],
        rutaArchivo: map['ruta_archivo'],
        tipoArchivo: map['tipo_archivo'] ?? 'imagen',
        descripcion: map['descripcion'],
        esPrincipal: map['es_principal'] == 1 || map['es_principal'] == true,
        fechaCarga:
            map['fecha_carga'] is DateTime
                ? map['fecha_carga']
                : DateTime.parse(map['fecha_carga'].toString()),
      );
    } catch (e) {
      _logger.severe('Error al crear ComprobanteVenta desde Map: $e');
      rethrow;
    }
  }

  /// Convierte el objeto a un mapa para serialización
  @override
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id_comprobante': id,
      'id_venta': idVenta,
      'ruta_archivo': rutaArchivo,
      'tipo_archivo': tipoArchivo,
      'descripcion': descripcion,
      'es_principal': esPrincipal ? 1 : 0,
    };
  }

  /// Crea una copia de este comprobante con los campos que se especifican modificados
  ComprobanteVenta copyWith({
    int? id,
    int? idVenta,
    String? rutaArchivo,
    String? tipoArchivo,
    String? descripcion,
    bool? esPrincipal,
    DateTime? fechaCarga,
  }) {
    return ComprobanteVenta(
      id: id ?? this.id,
      idVenta: idVenta ?? this.idVenta,
      rutaArchivo: rutaArchivo ?? this.rutaArchivo,
      tipoArchivo: tipoArchivo ?? this.tipoArchivo,
      descripcion: descripcion ?? this.descripcion,
      esPrincipal: esPrincipal ?? this.esPrincipal,
      fechaCarga: fechaCarga ?? this.fechaCarga,
    );
  }

  /// Obtiene la fecha de registro formateada (alias de fechaCarga)
  String get fechaRegistro => fechaFormateada;

  @override
  String toString() =>
      'ComprobanteVenta{id: $id, idVenta: $idVenta, tipo: $tipoArchivo, principal: $esPrincipal}';
}

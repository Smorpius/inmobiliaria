import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

/// Modelo que representa un comprobante o documento adjunto a una venta
class ComprobanteVenta {
  static final Logger _logger = Logger('ComprobanteVentaModel');

  final int? id;
  final int idVenta;
  final String rutaArchivo;
  final String tipoArchivo; // 'imagen', 'pdf', 'documento'
  final String? descripcion;
  final bool esPrincipal;
  final DateTime fechaCarga;

  ComprobanteVenta({
    this.id,
    required this.idVenta,
    required this.rutaArchivo,
    required this.tipoArchivo,
    this.descripcion,
    this.esPrincipal = false,
    DateTime? fechaCarga,
  }) : fechaCarga = fechaCarga ?? DateTime.now();

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

  /// Obtiene la extensión del archivo desde la ruta
  String get extension {
    final parts = rutaArchivo.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Determina si el archivo es una imagen basado en su extensión o tipo
  bool get esImagen {
    if (tipoArchivo == 'imagen') return true;
    final ext = extension;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  /// Determina si el archivo es un PDF
  bool get esPDF {
    if (tipoArchivo == 'pdf') return true;
    return extension == 'pdf';
  }

  /// Obtiene la fecha de registro formateada (alias de fechaCarga)
  String get fechaRegistro {
    return DateFormat('dd/MM/yyyy HH:mm').format(fechaCarga);
  }

  @override
  String toString() =>
      'ComprobanteVenta{id: $id, idVenta: $idVenta, tipo: $tipoArchivo, principal: $esPrincipal}';
}

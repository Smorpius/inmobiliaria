import 'package:intl/intl.dart';

/// Clase base abstracta para todos los tipos de comprobantes
abstract class ComprobanteBase {
  final int? id;
  final String rutaArchivo;
  final String tipoArchivo; // 'imagen', 'pdf', 'documento'
  final String? descripcion;
  final bool esPrincipal;
  final DateTime fechaCarga;

  ComprobanteBase({
    this.id,
    required this.rutaArchivo,
    required this.tipoArchivo,
    this.descripcion,
    this.esPrincipal = false,
    DateTime? fechaCarga,
  }) : fechaCarga = fechaCarga ?? DateTime.now();

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

  /// Obtiene la fecha de registro formateada
  String get fechaFormateada {
    return DateFormat('dd/MM/yyyy HH:mm').format(fechaCarga);
  }

  /// Define método abstracto que debe implementarse en las clases derivadas
  Map<String, dynamic> toMap();
}

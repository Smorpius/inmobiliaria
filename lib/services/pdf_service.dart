import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:inmobiliaria/utils/applogger.dart';

/// Servicio para la generación y guardado de archivos PDF
class PdfService {
  /// Crea un documento PDF con la configuración básica
  static Future<pw.Document> crearDocumento() async {
    final pdf = pw.Document(
      title: 'Reporte Inmobiliaria',
      author: 'Sistema Inmobiliario',
      creator: 'Aplicación Inmobiliaria',
      producer: 'Flutter PDF',
      subject: 'Reporte Generado',
      // Configuración para asegurar compatibilidad con acentos y símbolos
      version: PdfVersion.pdf_1_5,
      compress: true,
    );

    return pdf;
  }

  /// Guarda un documento PDF en el almacenamiento local y retorna su ruta
  static Future<String> guardarDocumento(
    pw.Document pdf,
    String nombreBase,
  ) async {
    try {
      // Obtener directorio para guardar documentos
      final Directory dir = await _obtenerDirectorioDocumentos();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${nombreBase}_$timestamp.pdf';
      final String filePath = '${dir.path}/$fileName';

      // Guardar el archivo
      final File file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      AppLogger.info('PDF guardado exitosamente en: $filePath');
      return filePath;
    } catch (e, stackTrace) {
      AppLogger.error('Error al guardar PDF', e, stackTrace);
      throw Exception('Error al guardar el documento PDF: $e');
    }
  }

  /// Obtiene el directorio apropiado según la plataforma
  static Future<Directory> _obtenerDirectorioDocumentos() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        return await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          final inmobiliariaDir = Directory(
            '${downloadsDir.path}/Inmobiliaria/Reportes',
          );
          if (!await inmobiliariaDir.exists()) {
            await inmobiliariaDir.create(recursive: true);
          }
          return inmobiliariaDir;
        } else {
          final tempDir = await getTemporaryDirectory();
          return tempDir;
        }
      } else {
        // Fallback para otras plataformas
        return await getTemporaryDirectory();
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al obtener directorio de documentos',
        e,
        stackTrace,
      );

      // Usar directorio temporal como respaldo
      final tempDir = await getTemporaryDirectory();
      return tempDir;
    }
  }
}

import 'dart:io';
import 'package:pdf/pdf.dart';
import '../utils/applogger.dart';
import '../utils/pdf_font_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

/// Servicio para generar documentos PDF con soporte Unicode
class PdfService {
  /// Crea un documento PDF básico con el tema que soporta caracteres Unicode
  static Future<pw.Document> crearDocumento() async {
    try {
      // Obtener el tema con soporte Unicode
      final theme = await PdfFontHelper.getThemeData();

      // Crear el documento con el tema aplicado
      final pdf = pw.Document(theme: theme);
      return pdf;
    } catch (e, stack) {
      AppLogger.error('Error al crear documento PDF', e, stack);
      throw Exception('Error al crear documento PDF: $e');
    }
  }

  /// Guarda un documento PDF en el almacenamiento del dispositivo y devuelve la ruta
  static Future<String> guardarDocumento(
    pw.Document pdf,
    String nombreArchivo,
  ) async {
    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/$nombreArchivo.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e, stack) {
      AppLogger.error('Error al guardar documento PDF', e, stack);
      throw Exception('Error al guardar documento PDF: $e');
    }
  }

  /// Crea un PDF con un encabezado y contenido básico
  static Future<pw.Document> crearDocumentoConContenido({
    required String titulo,
    required String contenido,
    String? subtitulo,
    PdfColor? colorEncabezado,
  }) async {
    final pdf = await crearDocumento();
    final unicodeStyle = await PdfFontHelper.getTextStyle();
    final titleStyle = await PdfFontHelper.getTextStyle(
      fontSize: 24,
      color: colorEncabezado ?? PdfColors.blue800,
      fontWeight: pw.FontWeight.bold,
    );
    final subtitleStyle = await PdfFontHelper.getTextStyle(
      fontSize: 16,
      color: PdfColors.grey700,
    );

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                title: titulo,
                child: pw.Text(titulo, style: titleStyle),
              ),
              if (subtitulo != null)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Text(subtitulo, style: subtitleStyle),
                ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Paragraph(text: contenido, style: unicodeStyle),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Crea un texto con soporte Unicode
  static Future<pw.Text> createUnicodeText(
    String text, {
    double? fontSize,
    PdfColor? color,
    pw.FontWeight? fontWeight,
    pw.TextAlign? textAlign,
  }) async {
    final style = await PdfFontHelper.getTextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );

    return pw.Text(text, style: style, textAlign: textAlign);
  }
}

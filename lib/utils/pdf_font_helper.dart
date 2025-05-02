import 'package:pdf/pdf.dart';
import '../utils/applogger.dart';
import 'package:pdf/widgets.dart' as pw;

/// Helper para gestionar fuentes en PDFs con soporte completo para Unicode
class PdfFontHelper {
  static pw.Font? _font;
  static bool _initialized = false;

  /// Inicializa la fuente para su uso posterior
  static Future<void> init() async {
    if (!_initialized) {
      try {
        // Usamos Helvetica directamente (incorporada en el paquete PDF)
        _font = pw.Font.helvetica();
        _initialized = true;
        AppLogger.info(
          'Fuente para PDF inicializada correctamente (Helvetica)',
        );
      } catch (e, stack) {
        AppLogger.error('Error al inicializar fuente para PDF', e, stack);
        _font = null;
        _initialized = true;
      }
    }
  }

  /// Obtiene un estilo de texto con soporte para caracteres especiales
  static Future<pw.TextStyle> getTextStyle({
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor color = PdfColors.black,
    pw.FontStyle fontStyle = pw.FontStyle.normal,
  }) async {
    final font = await _getDefaultFont();
    return pw.TextStyle(
      font: font,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
    );
  }

  /// Obtiene la fuente cargada en caché para uso eficiente
  static Future<pw.Font> getCachedFont() async {
    return await _getDefaultFont();
  }

  /// Método interno para obtener la fuente por defecto de manera segura
  static Future<pw.Font> _getDefaultFont() async {
    try {
      if (!_initialized) {
        await init();
      }

      if (_font != null) {
        return _font!;
      } else {
        return pw.Font.helvetica();
      }
    } catch (e) {
      AppLogger.error('Error al recuperar fuente: $e');
      return pw.Font.helvetica();
    }
  }

  /// Genera un tema completo para el documento con soporte Unicode
  static Future<pw.ThemeData> getThemeData() async {
    final font = await _getDefaultFont();
    return pw.ThemeData.withFont(
      base: font,
      bold: font,
      italic: font,
      boldItalic: font,
    );
  }
}

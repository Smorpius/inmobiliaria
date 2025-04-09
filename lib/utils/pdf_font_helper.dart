import 'dart:async';
import 'package:pdf/pdf.dart';
import '../utils/applogger.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Clase utilitaria para manejar las fuentes en documentos PDF,
/// utilizando fuentes que tienen soporte Unicode completo
class PdfFontHelper {
  static pw.Font? _cachedFont;
  static pw.ThemeData? _cachedTheme;
  static bool _isLoading = false;
  static bool _isInitialized = false;
  static final Completer<pw.Font> _fontCompleter = Completer<pw.Font>();

  /// Inicializa y precarga la fuente para mejorar el rendimiento
  static Future<void> init() async {
    if (!_isInitialized && !_isLoading) {
      try {
        _isLoading = true;
        await getFont().timeout(
          Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Timeout loading PDF fonts'),
        );
        _isInitialized = true;
        _isLoading = false;
        AppLogger.info('PdfFontHelper inicializado correctamente');
      } catch (e, stackTrace) {
        _isLoading = false;
        AppLogger.error('Error al inicializar PdfFontHelper', e, stackTrace);
      }
    }
    return;
  }

  /// Obtiene la fuente Roboto-Regular para usar en documentos PDF
  static Future<pw.Font> getFont() async {
    if (_cachedFont != null) return _cachedFont!;

    if (_isLoading) {
      // Si ya estamos cargando la fuente, esperar a que termine
      return _fontCompleter.future;
    }

    try {
      _isLoading = true;
      AppLogger.info('Cargando fuente Roboto para PDFs');

      // Intentar cargar la fuente desde el bundle
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      _cachedFont = pw.Font.ttf(fontData.buffer.asByteData());

      // Completar el futuro para cualquiera que esté esperando
      if (!_fontCompleter.isCompleted) {
        _fontCompleter.complete(_cachedFont!);
      }

      _isLoading = false;
      _isInitialized = true;
      return _cachedFont!;
    } catch (e, stackTrace) {
      _isLoading = false;
      AppLogger.error('Error al cargar fuente para PDFs', e, stackTrace);

      // Intentar usar una fuente de respaldo si la principal falla
      try {
        final defaultFont = pw.Font.helvetica();
        _cachedFont = defaultFont;

        if (!_fontCompleter.isCompleted) {
          _fontCompleter.complete(defaultFont);
        }

        return defaultFont;
      } catch (e2) {
        AppLogger.error('Error al cargar fuente de respaldo', e2, stackTrace);
        if (!_fontCompleter.isCompleted) {
          _fontCompleter.completeError(e2);
        }
        throw Exception('No se pudo cargar ninguna fuente para PDFs: $e2');
      }
    }
  }

  /// Crea un tema de PDF con soporte Unicode utilizando la fuente Roboto-Regular para todo el texto
  static Future<pw.ThemeData> getThemeData() async {
    if (_cachedTheme != null) return _cachedTheme!;

    final font = await getFont();
    _cachedTheme = pw.ThemeData.withFont(
      base: font,
      bold: font, // Usar la misma fuente para negrita por ahora
      italic: font, // Usar la misma fuente para cursiva por ahora
      boldItalic: font, // Usar la misma fuente para negrita cursiva por ahora
    );
    return _cachedTheme!;
  }

  /// Crea un estilo de texto con soporte Unicode para usar en widgets de texto específicos
  static Future<pw.TextStyle> getTextStyle({
    double? fontSize,
    PdfColor? color,
    pw.FontWeight? fontWeight,
    pw.FontStyle? fontStyle,
  }) async {
    final font = await getFont();
    return pw.TextStyle(
      font: font,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );
  }

  /// Método para obtener la fuente cacheada o cargarla si aún no existe
  /// Versión síncrona para usar en callbacks que no pueden ser asíncronos
  static pw.Font? getCachedFont() {
    if (_cachedFont != null) return _cachedFont;

    // Si la fuente no está cargada, intentar cargar la fuente por defecto
    // Esto es un fallback que debería usarse solo si getFont() no se llamó antes
    if (!_isInitialized && !_isLoading) {
      AppLogger.warning(
        'Se intentó obtener font sin inicializar - cargando font por defecto',
      );
      // Iniciar carga asíncrona pero no esperar resultado
      getFont();
      // Mientras tanto devolver una fuente de respaldo
      try {
        return pw.Font.helvetica();
      } catch (e) {
        AppLogger.error('Error al crear fuente de respaldo', e);
        return null;
      }
    }

    return null;
  }

  /// Verifica si la fuente ya está cargada y lista para usar
  static bool get isReady => _cachedFont != null;
}

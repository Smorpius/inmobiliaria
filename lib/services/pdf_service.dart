import 'dart:io';
import 'package:pdf/pdf.dart';
import 'directory_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:inmobiliaria/utils/applogger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Servicio para la generación y guardado de archivos PDF
class PdfService {
  /// Ruta relativa para reportes
  static const String _rutaRelativaReportes = 'assets/documentos/reportes';

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
      final String filePath = path.join(dir.path, fileName);

      // Asegurar que el directorio exista
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

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

  /// Guarda un contrato PDF directamente en la ruta final
  static Future<String> guardarContratoPDF(
    pw.Document pdf,
    String nombreBase,
    String tipoContrato, // 'venta' o 'renta'
  ) async {
    final dirType = 'contratos_$tipoContrato';
    AppLogger.info(
      'Iniciando guardado de contrato tipo: $tipoContrato en dirType: $dirType',
    );

    // Generar nombre de archivo único con timestamp
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String fileName = '${nombreBase}_$timestamp.pdf';

    String rutaCompleta = ''; // Inicializar ruta

    try {
      // Obtener la ruta completa del archivo usando DirectoryService
      rutaCompleta = await DirectoryService.getFullPath(fileName, dirType);

      AppLogger.info('Intentando guardar contrato en: $rutaCompleta');

      // Guardar el archivo
      final File file = File(rutaCompleta);
      final bytes = await pdf.save(); // Generar bytes del PDF

      // Escribir los bytes en el archivo
      await file.writeAsBytes(bytes, flush: true);
      AppLogger.info('Archivo escrito en: $rutaCompleta');

      // Verificar que el archivo se guardó correctamente y tiene contenido
      if (!await file.exists()) {
        AppLogger.error(
          '¡Fallo crítico! El archivo no existe después de intentar escribirlo en: $rutaCompleta',
        );
        throw Exception(
          'Error: El archivo no existe después de guardarlo en $rutaCompleta',
        );
      }
      final fileSize = await file.length();
      if (fileSize == 0) {
        AppLogger.error(
          '¡Fallo crítico! El archivo guardado está vacío en: $rutaCompleta',
        );
        throw Exception(
          'Error: El archivo guardado está vacío en $rutaCompleta',
        );
      }
      AppLogger.info(
        'Archivo verificado. Tamaño: $fileSize bytes en: $rutaCompleta',
      );

      // Obtener la ruta relativa usando DirectoryService
      final String rutaRelativa = DirectoryService.getRelativePath(
        rutaCompleta,
        dirType,
      );

      AppLogger.info(
        'Contrato guardado exitosamente. Ruta completa: $rutaCompleta, Ruta relativa: $rutaRelativa',
      );

      return rutaRelativa; // Devolver la ruta relativa para la base de datos
    } catch (e, stackTrace) {
      // SIN FALLBACK A TEMPORAL - Queremos ver el error original
      AppLogger.error(
        'Error CRÍTICO al guardar contrato PDF en "$rutaCompleta"',
        e,
        stackTrace,
      );
      // Relanzar la excepción para que sea manejada por el código que llama
      throw Exception(
        'Fallo al guardar contrato en $rutaCompleta: ${e.toString()}',
      );
    }
  }

  /// Obtiene el directorio apropiado según la plataforma
  static Future<Directory> _obtenerDirectorioDocumentos() async {
    try {
      // Obtener la ruta base de la aplicación
      final Directory appDir = await _obtenerDirectorioRaizAplicacion();

      // Construir la ruta completa usando la ruta relativa
      final Directory dirReportes = Directory(
        path.join(appDir.path, _rutaRelativaReportes),
      );

      // Crear el directorio si no existe
      if (!await dirReportes.exists()) {
        await dirReportes.create(recursive: true);
      }

      return dirReportes;
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener directorio de reportes', e, stackTrace);

      // Intento alternativo: usar directorio dentro del proyecto
      try {
        // Mantener compatibilidad con plataformas móviles/web si es necesario
        if (Platform.isIOS || Platform.isAndroid) {
          final appDir = await getApplicationDocumentsDirectory();
          final reportesDir = Directory('${appDir.path}/reportes');
          if (!await reportesDir.exists()) {
            await reportesDir.create(recursive: true);
          }
          return reportesDir;
        } else {
          // Otro intento alternativo para escritorio
          final tempDir = await getTemporaryDirectory();
          final backupDir = Directory('${tempDir.path}/Inmobiliaria/Reportes');
          if (!await backupDir.exists()) {
            await backupDir.create(recursive: true);
          }
          return backupDir;
        }
      } catch (fallbackError, fallbackStack) {
        AppLogger.error(
          'Error crítico al crear directorio alternativo para reportes',
          fallbackError,
          fallbackStack,
        );
        // Último recurso: usar directorio temporal
        final tempDir = await getTemporaryDirectory();
        return tempDir;
      }
    }
  }

  /// Obtiene el directorio raíz de la aplicación según la plataforma
  static Future<Directory> _obtenerDirectorioRaizAplicacion() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'La funcionalidad de archivos no está disponible en Web',
      );
    }

    if (Platform.isAndroid || Platform.isIOS) {
      // Para móviles, usar el directorio de la aplicación
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Para escritorio, intentar obtener el directorio del ejecutable
      try {
        // Obtener el directorio donde se está ejecutando la aplicación
        final String exePath = Platform.resolvedExecutable;
        final String exeDir = path.dirname(exePath);

        // Navegar hacia arriba para llegar a la raíz del proyecto
        // Asumimos que los binarios están en build/windows/runner/Release o similar
        final String projectRoot = exeDir.split('build').first;
        return Directory(projectRoot);
      } catch (e) {
        AppLogger.error(
          'Error al obtener directorio raíz en escritorio',
          e,
          StackTrace.current,
        );
        // Como respaldo, usar el directorio de documentos
        return await getApplicationDocumentsDirectory();
      }
    } else {
      // Para otras plataformas, usar el directorio de documentos
      return await getApplicationDocumentsDirectory();
    }
  }
}

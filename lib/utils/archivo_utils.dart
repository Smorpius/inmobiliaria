import 'dart:io';
import '../utils/applogger.dart';
import 'package:path/path.dart' as path;

/// Clase de utilidades para manejo de archivos y rutas
class ArchivoUtils {
  static const String _dirComprobantes = 'comprobantes';
  static const String _dirContratos = 'contratos';
  static const String _dirTemp = 'temp';

  /// Ruta base absoluta para documentos (ajustar según tu entorno)
  static const String _rutaBaseDocumentos =
      r'C:/Ingenieria de Software/inmobiliaria/assets/documentos';

  /// Normaliza una ruta de archivo para garantizar consistencia
  static String normalizarRuta(String rutaArchivo) {
    if (rutaArchivo.isEmpty) return '';

    // Convertir a formato estándar con barras diagonales forward
    String normalizada = rutaArchivo
        .replaceAll('\\\\', '/')
        .replaceAll('\\', '/');

    // Eliminar caracteres problemáticos y espacios extras
    normalizada = normalizada.trim().replaceAll('//', '/').replaceAll(' ', '_');

    // Extraer nombre del archivo si está dentro de un directorio conocido
    final directoriosConocidos = [_dirComprobantes, _dirContratos, _dirTemp];
    for (final dir in directoriosConocidos) {
      if (normalizada.contains('$dir/')) {
        final partes = normalizada.split('$dir/');
        if (partes.length > 1) {
          // Tomar la última parte después del directorio conocido
          normalizada = '$dir/${partes.last}';
          break;
        }
      }
    }

    // Si no tiene un prefijo de directorio conocido, añadir el directorio por defecto
    if (!normalizada.startsWith('/') &&
        !directoriosConocidos.any((dir) => normalizada.startsWith('$dir/'))) {
      normalizada = '$_dirComprobantes/$normalizada';
    }

    // Eliminar duplicados de directorios
    for (final dir in directoriosConocidos) {
      final patronDuplicado = '$dir/$dir/';
      while (normalizada.contains(patronDuplicado)) {
        normalizada = normalizada.replaceAll(patronDuplicado, '$dir/');
      }
    }

    return normalizada;
  }

  /// Obtiene la ruta completa de un archivo desde una ruta relativa
  static Future<String> obtenerRutaCompleta(String rutaRelativa) async {
    final rutaNormalizada = normalizarRuta(rutaRelativa);
    return path.join(_rutaBaseDocumentos, rutaNormalizada);
  }

  /// Verifica la existencia de un archivo, intentando múltiples ubicaciones si es necesario
  static Future<bool> verificarExistenciaArchivo(String rutaRelativa) async {
    try {
      final rutaNormalizada = normalizarRuta(rutaRelativa);
      final nombreArchivo = path.basename(rutaRelativa);

      // Lista de posibles ubicaciones a probar en orden de prioridad
      final ubicaciones = [
        // 1. Ruta normalizada completa
        path.join(_rutaBaseDocumentos, rutaNormalizada),

        // 2. Solo el nombre del archivo en la raíz
        path.join(_rutaBaseDocumentos, nombreArchivo),

        // 3. El nombre del archivo en cada directorio conocido
        path.join(_rutaBaseDocumentos, _dirComprobantes, nombreArchivo),
        path.join(_rutaBaseDocumentos, _dirContratos, nombreArchivo),
        path.join(_rutaBaseDocumentos, _dirTemp, nombreArchivo),

        // 4. Buscar en subdirectorios comunes
        path.join(
          _rutaBaseDocumentos,
          _dirComprobantes,
          'movimientos',
          nombreArchivo,
        ),
        path.join(
          _rutaBaseDocumentos,
          _dirComprobantes,
          'ventas',
          nombreArchivo,
        ),
        path.join(
          _rutaBaseDocumentos,
          _dirComprobantes,
          'rentas',
          nombreArchivo,
        ),
      ];

      // Registrar para depuración con nivel detalle disminuido
      AppLogger.info(
        'Verificando archivo en múltiples ubicaciones: $nombreArchivo',
      );

      // Verificar cada ubicación
      for (final ubicacion in ubicaciones) {
        final archivo = File(ubicacion);
        if (await archivo.exists()) {
          AppLogger.info('Archivo encontrado en: $ubicacion');
          return true;
        }
      }

      AppLogger.warning(
        'No se pudo encontrar el archivo en ninguna ubicación: $rutaRelativa',
      );
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al verificar existencia de archivo',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Busca un archivo por su nombre en múltiples ubicaciones y devuelve la ruta completa
  static Future<String?> buscarArchivoPorNombre(String nombreArchivo) async {
    try {
      // Lista de posibles directorios donde buscar
      final directorios = [
        _rutaBaseDocumentos,
        path.join(_rutaBaseDocumentos, _dirComprobantes),
        path.join(_rutaBaseDocumentos, _dirContratos),
        path.join(_rutaBaseDocumentos, _dirTemp),
        path.join(_rutaBaseDocumentos, _dirComprobantes, 'movimientos'),
        path.join(_rutaBaseDocumentos, _dirComprobantes, 'ventas'),
        path.join(_rutaBaseDocumentos, _dirComprobantes, 'rentas'),
      ];

      // Buscar en todos los directorios
      for (final directorio in directorios) {
        final dir = Directory(directorio);
        if (!(await dir.exists())) continue;

        final archivos = await dir.list().toList();
        for (final archivo in archivos) {
          if (archivo is File && path.basename(archivo.path) == nombreArchivo) {
            return archivo.path;
          }
        }
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Error al buscar archivo por nombre', e, stackTrace);
      return null;
    }
  }

  /// Guarda un archivo en una ubicación permanente y devuelve la ruta relativa normalizada
  static Future<String> guardarArchivoPermanente(
    File archivoTemporal,
    String nombreBase, {
    String? subDirectorio,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(archivoTemporal.path).toLowerCase();

      // Sanear el nombre base eliminando caracteres especiales
      final nombreBaseSaneado = nombreBase
          .replaceAll(RegExp(r'[^\w\s.-]'), '')
          .replaceAll(' ', '_');

      // Crear un nombre único
      final nombreUnico = '${nombreBaseSaneado}_$timestamp$extension';

      // Definir el directorio de destino
      String directorioDestino;
      if (subDirectorio != null && subDirectorio.isNotEmpty) {
        directorioDestino = path.join(
          _rutaBaseDocumentos,
          _dirComprobantes,
          subDirectorio,
        );
      } else {
        directorioDestino = path.join(_rutaBaseDocumentos, _dirComprobantes);
      }

      // Asegurar que el directorio exista
      final directorio = Directory(directorioDestino);
      if (!await directorio.exists()) {
        await directorio.create(recursive: true);
      }

      // Ruta completa del archivo destino
      final rutaDestino = path.join(directorioDestino, nombreUnico);

      // Copiar archivo con verificación
      await archivoTemporal.copy(rutaDestino);
      final archivoFinal = File(rutaDestino);

      if (!await archivoFinal.exists()) {
        throw Exception(
          'Error al guardar: el archivo no se copió correctamente',
        );
      }

      // Calcular y retornar ruta relativa normalizada
      final rutaRelativa =
          '$_dirComprobantes/${subDirectorio != null ? "$subDirectorio/" : ""}$nombreUnico';
      return normalizarRuta(rutaRelativa);
    } catch (e, stack) {
      AppLogger.error('Error al guardar archivo permanente', e, stack);
      throw Exception('No se pudo guardar el archivo: $e');
    }
  }

  /// Verifica si el nombre de archivo es un PDF
  static bool esPDF(String rutaArchivo) {
    return path.extension(rutaArchivo).toLowerCase() == '.pdf';
  }

  /// Obtiene el tipo MIME basado en la extensión del archivo
  static String obtenerTipoMIME(String rutaArchivo) {
    final ext = path.extension(rutaArchivo).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }
}

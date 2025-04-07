import 'dart:io';
import '../utils/applogger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Clase de utilidades para manejo de archivos y rutas
class ArchivoUtils {
  /// Normaliza una ruta de archivo para garantizar consistencia
  static String normalizarRuta(String rutaArchivo) {
    // Convertir a formato estándar con barras diagonales forward
    String normalizada = rutaArchivo
        .replaceAll('\\\\', '/')
        .replaceAll('\\', '/');

    // Asegurarse que tiene el prefijo correcto
    if (!normalizada.startsWith('/') &&
        !normalizada.startsWith('comprobantes/') &&
        normalizada.contains('comprobantes/')) {
      normalizada = 'comprobantes/${normalizada.split('comprobantes/')[1]}';
    }

    // Si no tiene el prefijo comprobantes/ y no es una ruta absoluta, añadirlo
    if (!normalizada.startsWith('/') &&
        !normalizada.startsWith('comprobantes/') &&
        normalizada.isNotEmpty) {
      normalizada = 'comprobantes/$normalizada';
    }

    // Eliminar duplicados de "comprobantes/comprobantes/"
    while (normalizada.contains('comprobantes/comprobantes/')) {
      normalizada = normalizada.replaceAll(
        'comprobantes/comprobantes/',
        'comprobantes/',
      );
    }

    return normalizada;
  }

  /// Obtiene la ruta completa de un archivo desde una ruta relativa
  static Future<String> obtenerRutaCompleta(String rutaRelativa) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final rutaNormalizada = normalizarRuta(rutaRelativa);
    return path.join(baseDir.path, rutaNormalizada);
  }

  /// Verifica la existencia de un archivo, intentando múltiples ubicaciones si es necesario
  static Future<bool> verificarExistenciaArchivo(String rutaRelativa) async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final rutaNormalizada = normalizarRuta(rutaRelativa);

      // Lista de posibles ubicaciones a probar
      final ubicaciones = [
        path.join(baseDir.path, rutaNormalizada),
        path.join(baseDir.path, path.basename(rutaRelativa)),
        path.join(baseDir.path, 'comprobantes', path.basename(rutaRelativa)),
      ];

      // Registrar para depuración
      AppLogger.info(
        'Buscando archivo en múltiples ubicaciones: $rutaRelativa',
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
    } catch (e) {
      AppLogger.error('Error al verificar existencia de archivo', e);
      return false;
    }
  }

  /// Guarda un archivo en una ubicación permanente y devuelve la ruta relativa normalizada
  static Future<String> guardarArchivoPermanente(
    File archivoTemporal,
    String nombreBase, {
    String? subDirectorio,
  }) async {
    try {
      // Obtener directorio base
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(archivoTemporal.path).toLowerCase();

      // Crear un nombre único
      final nombreUnico = '${nombreBase}_$timestamp$extension';

      // Definir el directorio de destino
      String directorioDestino;
      if (subDirectorio != null && subDirectorio.isNotEmpty) {
        directorioDestino = path.join(
          appDir.path,
          'comprobantes',
          subDirectorio,
        );
      } else {
        directorioDestino = path.join(appDir.path, 'comprobantes');
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
          'comprobantes/${subDirectorio != null ? "$subDirectorio/" : ""}$nombreUnico';
      return normalizarRuta(rutaRelativa);
    } catch (e, stack) {
      AppLogger.error('Error al guardar archivo permanente', e, stack);
      throw Exception('No se pudo guardar el archivo: $e');
    }
  }
}

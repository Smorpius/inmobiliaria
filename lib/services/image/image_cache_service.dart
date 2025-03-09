import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';

/// Servicio para el manejo de caché de imágenes
class ImageCacheService {
  final _uuid = const Uuid();

  // Tiempo máximo de vida de archivos en caché (7 días)
  final Duration _maxCacheAge = const Duration(days: 7);

  /// Obtiene el directorio de caché
  Future<Directory> get _cacheDir async {
    final Directory cacheDir = await getTemporaryDirectory();
    final String cachePath = '${cacheDir.path}/image_cache';
    final Directory dir = Directory(cachePath);

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
  }

  /// Guarda una imagen en caché y retorna la ruta
  Future<String> cacheImage(File imageFile) async {
    try {
      final String fileName = '${_uuid.v4()}${extension(imageFile.path)}';
      final Directory dir = await _cacheDir;
      final String cachePath = '${dir.path}/$fileName';

      // Copiar archivo a caché
      await imageFile.copy(cachePath);

      developer.log('Imagen cacheada: $cachePath');
      return cachePath;
    } catch (e) {
      developer.log('Error al cachear imagen: $e', error: e);
      return imageFile.path; // Retornar el original en caso de error
    }
  }

  /// Verifica si una imagen ya está en caché
  Future<String?> getCachedImage(String originalPath) async {
    try {
      final Directory dir = await _cacheDir;
      final List<FileSystemEntity> files = await dir.list().toList();

      // Buscar por nombre de archivo
      final String fileName = basename(originalPath);
      for (final file in files) {
        if (file is File && basename(file.path) == fileName) {
          developer.log('Imagen encontrada en caché: ${file.path}');
          return file.path;
        }
      }

      // Si no se encuentra, verificar contenido (más lento)
      final File originalFile = File(originalPath);
      if (await originalFile.exists()) {
        final List<int> originalBytes = await originalFile.readAsBytes();

        for (final file in files) {
          if (file is File) {
            final List<int> cachedBytes = await File(file.path).readAsBytes();
            if (originalBytes.length == cachedBytes.length) {
              developer.log('Posible coincidencia en caché: ${file.path}');
              return file.path;
            }
          }
        }
      }

      return null; // No encontrado en caché
    } catch (e) {
      developer.log('Error al verificar caché: $e', error: e);
      return null;
    }
  }

  /// Limpia archivos antiguos del caché
  Future<void> cleanCache() async {
    try {
      developer.log('Limpiando caché de imágenes antiguas...');
      final Directory dir = await _cacheDir;
      final List<FileSystemEntity> files = await dir.list().toList();

      int deletedCount = 0;
      final DateTime now = DateTime.now();

      for (final file in files) {
        if (file is File) {
          final FileStat stats = await file.stat();
          final Duration age = now.difference(stats.modified);

          if (age > _maxCacheAge) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      developer.log('Caché limpiado: $deletedCount archivos eliminados');
    } catch (e) {
      developer.log('Error al limpiar caché: $e', error: e);
    }
  }

  /// Programa limpieza periódica del caché
  void scheduleCacheCleanup() {
    try {
      // Limpieza inmediata
      cleanCache();

      // Programar limpieza periódica (cada semana)
      Timer.periodic(const Duration(days: 7), (timer) {
        developer.log('Ejecutando limpieza programada de caché');
        cleanCache();
      });

      developer.log('Programación de limpieza de caché configurada');
    } catch (e) {
      developer.log('Error al configurar limpieza de caché: $e', error: e);
    }
  }
}

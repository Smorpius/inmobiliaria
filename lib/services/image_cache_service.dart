import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:inmobiliaria/services/mysql_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inmobiliaria/utils/applogger.dart';

/// Servicio mejorado para gestionar el caché de imágenes con integración a base de datos
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  late DatabaseService _db;

  // Control para evitar logs duplicados
  bool _procesandoError = false;

  // Cache en memoria optimizado con límite de tamaño
  final Map<String, String> _memoryCache = {};
  final int _maxMemoryCacheSize = 200;

  // Directorio base para caché de imágenes
  static const String _baseCacheDirectory = 'image_cache';

  // Tiempo de expiración por defecto
  static const Duration _defaultExpiration = Duration(days: 7);

  factory ImageCacheService({DatabaseService? dbService}) {
    if (dbService != null) {
      _instance._db = dbService;
    }
    return _instance;
  }

  ImageCacheService._internal() : _db = DatabaseService() {
    AppLogger.info('ImageCacheService inicializado');
    _initCacheCleanupTimer();
  }

  /// Iniciar temporizador para limpieza periódica de caché
  void _initCacheCleanupTimer() {
    Timer.periodic(const Duration(hours: 24), (_) {
      cleanCache();
    });
  }

  /// Genera una clave única para el caché
  String _generateCacheKey(String imagePath) {
    var bytes = utf8.encode(imagePath);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Guarda una referencia a la imagen en la base de datos
  Future<bool> registrarImagenEnCache(
    String originalPath,
    String cachePath,
  ) async {
    try {
      final String cacheKey = _generateCacheKey(originalPath);

      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL GuardarImagenCache(?, ?, ?, @resultado)', [
            cacheKey,
            originalPath,
            cachePath,
          ]);

          final result = await conn.query('SELECT @resultado as exito');
          final bool exito = result.isNotEmpty && result.first['exito'] == 1;

          await conn.query('COMMIT');

          if (exito) {
            AppLogger.info('Imagen registrada en caché: $cacheKey');
          } else {
            AppLogger.warning(
              'No se pudo registrar la imagen en caché: $cacheKey',
            );
          }

          return exito;
        } catch (e) {
          await conn.query('ROLLBACK');
          rethrow;
        }
      });
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al registrar imagen en caché', e, stackTrace);
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Guarda una imagen en caché físico y base de datos
  Future<String?> cacheImage(File imageFile) async {
    try {
      final String originalPath = imageFile.path;
      final String cacheKey = _generateCacheKey(originalPath);

      // Verificar si ya está en caché de memoria
      if (_memoryCache.containsKey(cacheKey)) {
        final String? cachedPath = _memoryCache[cacheKey];
        if (cachedPath != null && await File(cachedPath).exists()) {
          return cachedPath;
        }
      }

      // Crear directorio de caché si no existe
      final Directory cacheDir = await getTemporaryDirectory();
      final String cacheDirPath = path.join(cacheDir.path, _baseCacheDirectory);
      final Directory cacheDirectory = await Directory(
        cacheDirPath,
      ).create(recursive: true);

      // Generar ruta para archivo en caché
      final String targetPath = path.join(
        cacheDirectory.path,
        '$cacheKey${path.extension(originalPath)}',
      );

      // Copiar archivo a caché
      await imageFile.copy(targetPath);

      // Guardar en caché de memoria (manejo LRU para evitar fugas de memoria)
      _manageMemoryCache(cacheKey, targetPath);

      // Registrar en base de datos usando un procedimiento almacenado
      await registrarImagenEnCache(originalPath, targetPath);

      return targetPath;
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al guardar imagen en caché', e, stackTrace);
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Controla el tamaño del caché en memoria y aplica política LRU
  void _manageMemoryCache(String key, String value) {
    // Si el caché está lleno, remover la entrada más antigua
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      final String keyToRemove = _memoryCache.keys.first;
      _memoryCache.remove(keyToRemove);
    }

    // Agregar nueva entrada
    _memoryCache[key] = value;
  }

  /// Obtiene una imagen desde el caché
  Future<String?> getCachedImage(String originalPath) async {
    try {
      final String cacheKey = _generateCacheKey(originalPath);

      // 1. Verificar primero en caché de memoria (más rápido)
      if (_memoryCache.containsKey(cacheKey)) {
        final String cachedPath = _memoryCache[cacheKey]!;
        if (await File(cachedPath).exists()) {
          return cachedPath;
        }
      }

      // 2. Si no está en memoria, buscar en la base de datos
      return await _db.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerImagenCache(?)', [
          cacheKey,
        ]);

        if (results.isEmpty || results.first['ruta_cache'] == null) {
          return null;
        }

        final String cachedPath = results.first['ruta_cache'] as String;

        // Verificar si el archivo sigue existiendo físicamente
        if (await File(cachedPath).exists()) {
          // Actualizar caché en memoria
          _manageMemoryCache(cacheKey, cachedPath);
          return cachedPath;
        }

        // Si el archivo ya no existe, eliminarlo de la base de datos
        await conn.query('CALL EliminarImagenCache(?)', [cacheKey]);
        return null;
      });
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al recuperar imagen de caché', e, stackTrace);
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Elimina una entrada específica del caché
  Future<bool> removeFromCache(String originalPath) async {
    try {
      final String cacheKey = _generateCacheKey(originalPath);

      // Eliminar de la caché en memoria
      final String? cachedPath = _memoryCache.remove(cacheKey);

      // Eliminar archivo físico si existe
      if (cachedPath != null && await File(cachedPath).exists()) {
        await File(cachedPath).delete();
      }

      // Eliminar de la base de datos
      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL EliminarImagenCache(?)', [cacheKey]);
          await conn.query('COMMIT');
          AppLogger.info('Imagen eliminada del caché: $cacheKey');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          rethrow;
        }
      });
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al eliminar imagen del caché', e, stackTrace);
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Limpia el caché de imágenes antiguas
  Future<int> cleanCache({Duration maxAge = const Duration(days: 7)}) async {
    try {
      AppLogger.info('Iniciando limpieza de caché de imágenes');
      int removedCount = 0;

      // Limpiar caché en base de datos
      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Llamar a procedimiento almacenado para limpiar caché antiguo
          await conn.query(
            'CALL LimpiarImagenesCacheAntiguas(?, @cantidad_eliminada)',
            [maxAge.inHours],
          );

          final result = await conn.query(
            'SELECT @cantidad_eliminada as count',
          );
          removedCount = result.isNotEmpty ? result.first['count'] as int : 0;

          await conn.query('COMMIT');

          // También limpiar archivos huérfanos del sistema de archivos
          await _cleanOrphanedCacheFiles();

          // Limpieza de memoria caché
          _memoryCache.clear();

          AppLogger.info(
            'Limpieza de caché completada: $removedCount entradas eliminadas',
          );
          return removedCount;
        } catch (e) {
          await conn.query('ROLLBACK');
          rethrow;
        }
      });
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al limpiar caché de imágenes', e, stackTrace);
        _procesandoError = false;
      }
      return 0;
    }
  }

  /// Limpia archivos de caché huérfanos del sistema de archivos
  Future<int> _cleanOrphanedCacheFiles() async {
    try {
      int removedCount = 0;
      final Directory cacheDir = await getTemporaryDirectory();
      final String cacheDirPath = path.join(cacheDir.path, _baseCacheDirectory);
      final Directory cacheDirectory = Directory(cacheDirPath);

      if (!await cacheDirectory.exists()) {
        return 0;
      }

      final DateTime now = DateTime.now();
      final List<FileSystemEntity> files = await cacheDirectory.list().toList();

      for (var file in files) {
        if (file is File) {
          try {
            final FileStat stats = await file.stat();
            final Duration age = now.difference(stats.modified);

            if (age > _defaultExpiration) {
              await file.delete();
              removedCount++;
            }
          } catch (e) {
            // Ignorar errores individuales para continuar con otros archivos
            AppLogger.warning(
              'Error al procesar archivo de caché: ${file.path}',
            );
          }
        }
      }

      AppLogger.info(
        'Limpieza de archivos huérfanos completada: $removedCount archivos eliminados',
      );
      return removedCount;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al limpiar archivos de caché huérfanos',
        e,
        stackTrace,
      );
      return 0;
    }
  }

  /// Obtiene estadísticas del caché
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      int fileCount = 0;
      int totalSize = 0;

      // Estadísticas de archivos físicos
      final Directory cacheDir = await getTemporaryDirectory();
      final String cacheDirPath = path.join(cacheDir.path, _baseCacheDirectory);
      final Directory cacheDirectory = Directory(cacheDirPath);

      if (await cacheDirectory.exists()) {
        final List<FileSystemEntity> files =
            await cacheDirectory.list().toList();

        for (var file in files) {
          if (file is File) {
            fileCount++;
            totalSize += await file.length();
          }
        }
      }

      // Estadísticas de caché en base de datos
      final int dbEntries = await _db.withConnection((conn) async {
        final results = await conn.query(
          'CALL ObtenerEstadisticasImagenCache()',
        );
        return results.isNotEmpty ? results.first['total'] as int : 0;
      });

      return {
        'memoryCacheEntries': _memoryCache.length,
        'fileCount': fileCount,
        'totalSizeBytes': totalSize,
        'dbEntries': dbEntries,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al obtener estadísticas del caché',
          e,
          stackTrace,
        );
        _procesandoError = false;
      }

      return {
        'error': 'Error al obtener estadísticas',
        'memoryCacheEntries': _memoryCache.length,
      };
    }
  }

  /// Libera recursos utilizados por el servicio
  void dispose() {
    _memoryCache.clear();
    AppLogger.info('ImageCacheService: recursos liberados');
  }
}

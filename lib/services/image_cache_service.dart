import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar el caché de imágenes y optimizar el rendimiento
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();

  factory ImageCacheService() {
    return _instance;
  }

  ImageCacheService._internal() {
    debugPrint('ImageCacheService inicializado');
  }

  // Caché en memoria para acceso rápido
  final Map<String, String> _memoryCache = {};

  // Generar clave de caché para una imagen
  String _generateCacheKey(String imagePath) {
    var bytes = utf8.encode(imagePath);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Guardar una imagen en caché
  Future<String> cacheImage(File imageFile) async {
    try {
      final String originalPath = imageFile.path;
      final String cacheKey = _generateCacheKey(originalPath);

      // Verificar si ya está en caché
      if (_memoryCache.containsKey(cacheKey)) {
        return _memoryCache[cacheKey]!;
      }

      // Guardar en directorio de caché
      final Directory cacheDir = await getTemporaryDirectory();
      final String cachePath = '${cacheDir.path}/img_cache';

      // Crear directorio si no existe
      final Directory cacheDirFinal = await Directory(
        cachePath,
      ).create(recursive: true);

      // Copiar archivo a caché con nombre único
      final String targetPath = '${cacheDirFinal.path}/$cacheKey.jpg';
      await imageFile.copy(targetPath);

      // Guardar en memoria
      _memoryCache[cacheKey] = targetPath;

      // Guardar referencia en SharedPreferences para persistencia
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('img_cache_$cacheKey', targetPath);

      return targetPath;
    } catch (e) {
      debugPrint('Error al guardar imagen en caché: $e');
      return imageFile.path; // Devolver ruta original si hay error
    }
  }

  // Obtener imagen de caché
  Future<String?> getCachedImage(String originalPath) async {
    try {
      final String cacheKey = _generateCacheKey(originalPath);

      // Verificar memoria caché primero
      if (_memoryCache.containsKey(cacheKey)) {
        return _memoryCache[cacheKey];
      }

      // Verificar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? cachedPath = prefs.getString('img_cache_$cacheKey');

      if (cachedPath != null && File(cachedPath).existsSync()) {
        _memoryCache[cacheKey] = cachedPath; // Guardar en memoria
        return cachedPath;
      }

      return null;
    } catch (e) {
      debugPrint('Error al recuperar imagen de caché: $e');
      return null;
    }
  }

  // Limpiar imágenes no usadas
  Future<void> cleanCache({Duration maxAge = const Duration(days: 30)}) async {
    try {
      final Directory cacheDir = await getTemporaryDirectory();
      final String cachePath = '${cacheDir.path}/img_cache';

      final Directory cacheDirectory = Directory(cachePath);
      if (!cacheDirectory.existsSync()) return;

      final DateTime now = DateTime.now();
      final List<FileSystemEntity> files = cacheDirectory.listSync();

      for (var file in files) {
        if (file is File) {
          final FileStat stats = file.statSync();
          final Duration age = now.difference(stats.modified);

          if (age > maxAge) {
            await file.delete();

            // Eliminar referencia de memoria
            _memoryCache.removeWhere((key, value) => value == file.path);

            // Eliminar referencia de SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            final keys = prefs.getKeys().where(
              (key) => key.startsWith('img_cache_'),
            );
            for (var key in keys) {
              if (prefs.getString(key) == file.path) {
                await prefs.remove(key);
              }
            }
          }
        }
      }

      debugPrint('Limpieza de caché completada');
    } catch (e) {
      debugPrint('Error al limpiar caché: $e');
    }
  }
}

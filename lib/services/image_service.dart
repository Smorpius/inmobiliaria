import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart' as crypto;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inmobiliaria/utils/applogger.dart';
import 'package:inmobiliaria/services/mysql_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final DatabaseService _db = DatabaseService();

  // Variable para prevenir logs duplicados
  bool _procesandoError = false;

  // Cache Manager para imágenes
  late final CacheManager _inmuebleCacheManager;

  // Caché en memoria para imágenes con política LRU implícita
  final Map<String, Uint8List> _memoryImageCache = {};

  // Caché de rutas para evitar búsquedas repetitivas
  final Map<String, String> _pathCache = {};
  final int _maxPathCacheSize = 100;

  // Formatos soportados para imágenes
  final List<String> _supportedFormats = ['.jpg', '.jpeg', '.png'];

  // Límite mínimo de calidad para compresión
  static const int _minQuality = 50;

  /// Constructor e inicialización del servicio.
  ImageService() {
    _inmuebleCacheManager = CacheManager(
      Config(
        'inmueble_images_cache',
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 200,
      ),
    );

    // Programar limpieza periódica
    scheduleCacheCleanup();
    AppLogger.info('ImageService inicializado');
  }

  //=============================================================================
  // SECCIÓN: SELECCIÓN DE IMÁGENES
  //=============================================================================

  /// Carga una imagen desde la galería o cámara según la fuente especificada.
  Future<File?> cargarImagenDesdeDispositivo(ImageSource source) async {
    switch (source) {
      case ImageSource.gallery:
        return pickImageFromGallery();
      case ImageSource.camera:
        return takePhoto();
    }
  }

  /// Selecciona una imagen desde la galería del dispositivo.
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al seleccionar imagen de galería', e);
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Toma una foto usando la cámara del dispositivo.
  Future<File?> takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al tomar foto', e);
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Selecciona y optimiza una imagen desde la fuente especificada.
  ///
  /// [source]: Fuente de la imagen (galería o cámara).
  /// [maxWidth]: Ancho máximo de la imagen.
  /// [maxHeight]: Alto máximo de la imagen.
  /// [quality]: Calidad inicial de la imagen (0-100).
  Future<File?> pickImage(
    ImageSource source, {
    double? maxWidth,
    double? maxHeight,
    int? quality,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: quality,
      );

      if (pickedFile == null) return null;

      final File file = File(pickedFile.path);
      return await optimizeImage(file);
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al seleccionar imagen', e);
        _procesandoError = false;
      }
      return null;
    }
  }

  //=============================================================================
  // SECCIÓN: VALIDACIÓN Y VERIFICACIÓN
  //=============================================================================

  /// Verifica si el formato del archivo es soportado.
  bool isFormatSupported(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return _supportedFormats.contains(ext);
  }

  /// Verifica si una imagen es válida (existe y es accesible).
  Future<bool> isValidImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;

    try {
      final file = File(imagePath);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      return bytes.isNotEmpty;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al verificar imagen', e);
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Obtiene un objeto File a partir de una ruta si es válida.
  Future<File?> getImageFile(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;

    try {
      final file = File(imagePath);
      if (await file.exists()) return file;
      return null;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al obtener archivo de imagen', e);
        _procesandoError = false;
      }
      return null;
    }
  }

  //=============================================================================
  // SECCIÓN: OPTIMIZACIÓN Y PROCESAMIENTO
  //=============================================================================

  /// Optimiza una imagen reduciendo su tamaño manteniendo calidad aceptable.
  Future<File> optimizeImage(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      if (fileSize < 1024 * 1024) return imageFile;

      AppLogger.info('Optimizando imagen de ${fileSize ~/ 1024}KB');

      int quality = 85;
      if (fileSize > 5 * 1024 * 1024) {
        quality = 65;
      } else if (fileSize > 3 * 1024 * 1024) {
        quality = 75;
      }
      quality = quality.clamp(_minQuality, 100);

      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'optimized_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
      );

      if (result == null) {
        AppLogger.warning('No se pudo optimizar la imagen');
        return imageFile;
      }

      final newSize = await result.length();
      AppLogger.info(
        'Imagen optimizada: ${newSize ~/ 1024}KB (reducción: ${((fileSize - newSize) / fileSize * 100).toStringAsFixed(1)}%)',
      );
      return File(result.path);
    } catch (e) {
      AppLogger.categoryWarning(
        'image_optimization',
        'Error al optimizar imagen: $e',
      );
      return imageFile;
    }
  }

  /// Redimensiona una imagen a las dimensiones especificadas.
  Future<File?> resizeImage(File imageFile, int width, int height) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'resized_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        minWidth: width,
        minHeight: height,
        quality: 90,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al redimensionar imagen', e);
        _procesandoError = false;
      }
      return null;
    }
  }

  //=============================================================================
  // SECCIÓN: ALMACENAMIENTO Y GESTIÓN DE ARCHIVOS
  //=============================================================================

  /// Guarda una imagen optimizada para un inmueble y retorna su ruta relativa.
  Future<String?> guardarImagenInmueble(File? imageFile, int idInmueble) async {
    if (imageFile == null) return null;
    if (idInmueble <= 0) {
      AppLogger.error('ID de inmueble inválido: $idInmueble');
      return null;
    }

    try {
      final File optimizedImage = await optimizeImage(imageFile);
      final appDocDir = await getApplicationDocumentsDirectory();
      final categoria = 'inmuebles/$idInmueble';
      final categoryDir = Directory(path.join(appDocDir.path, categoria));

      await categoryDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(optimizedImage.path);
      final fileName = 'inmueble_$timestamp$extension';
      final savedFilePath = path.join(categoryDir.path, fileName);

      await optimizedImage.copy(savedFilePath);
      final rutaRelativa = path.join(categoria, fileName);

      // Registrar imagen en base de datos usando procedimiento almacenado
      await registrarImagenEnBaseDeDatos(idInmueble, rutaRelativa);

      // Actualizar caché local
      await _saveCachedImageReference(idInmueble, rutaRelativa);

      AppLogger.info('Imagen guardada en: $rutaRelativa');
      return rutaRelativa;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al guardar imagen', e);
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Registra una imagen en la base de datos usando procedimiento almacenado
  Future<bool> registrarImagenEnBaseDeDatos(
    int idInmueble,
    String rutaRelativa,
  ) async {
    try {
      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Llamar al procedimiento con los parámetros correctos - No tiene variable de salida
          await conn.query('CALL GuardarImagenInmueble(?, ?, ?, ?)', [
            idInmueble,
            rutaRelativa,
            'Imagen de inmueble',
            0, // No es principal por defecto
          ]);

          // Obtener el ID insertado con LAST_INSERT_ID()
          final idResult = await conn.query('SELECT LAST_INSERT_ID() as id');

          if (idResult.isEmpty || idResult.first['id'] == null) {
            await conn.query('ROLLBACK');
            AppLogger.warning('No se pudo obtener ID de imagen registrada');
            return false;
          }

          await conn.query('COMMIT');
          AppLogger.info(
            'Imagen registrada en BD con ID: ${idResult.first['id']}',
          );
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          if (!_procesandoError) {
            _procesandoError = true;
            AppLogger.error('Error al registrar imagen en base de datos', e);
            _procesandoError = false;
          }
          return false;
        }
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error de conexión al registrar imagen', e);
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Guarda una imagen genérica con categoría y prefijo.
  Future<String?> saveImage(
    File imageFile,
    String category,
    String prefix,
  ) async {
    try {
      final File optimizedImage = await optimizeImage(imageFile);
      final appDocDir = await getApplicationDocumentsDirectory();
      final categoryDir = Directory(path.join(appDocDir.path, category));

      await categoryDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(optimizedImage.path);
      final fileName = '${prefix}_$timestamp$extension';
      final savedFilePath = path.join(categoryDir.path, fileName);

      await optimizedImage.copy(savedFilePath);
      final rutaRelativa = path.join(category, fileName);

      AppLogger.info('Imagen guardada en: $rutaRelativa');
      return rutaRelativa;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al guardar imagen', e);
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Elimina una imagen específica de un inmueble.
  Future<bool> eliminarImagenInmueble(String? rutaRelativa) async {
    if (rutaRelativa == null || rutaRelativa.isEmpty) return true;

    try {
      // Eliminar de cachés
      final cacheKey = _generateCacheKey(rutaRelativa);
      _memoryImageCache.remove(cacheKey);
      _pathCache.remove(rutaRelativa);

      // Eliminar archivo físico
      final String? rutaCompleta = await obtenerRutaCompletaImagen(
        rutaRelativa,
      );
      if (rutaCompleta != null) {
        final file = File(rutaCompleta);
        if (await file.exists()) await file.delete();
      }

      // Eliminar de la base de datos usando procedimiento almacenado
      await eliminarImagenDeBaseDeDatos(rutaRelativa);

      AppLogger.info('Imagen eliminada: $rutaRelativa');
      return true;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al eliminar imagen: $rutaRelativa', e);
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Elimina una imagen de la base de datos usando procedimiento almacenado
  Future<bool> eliminarImagenDeBaseDeDatos(String rutaRelativa) async {
    try {
      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Buscar ID de la imagen por ruta
          final results = await conn.query(
            'SELECT id_imagen FROM inmuebles_imagenes WHERE ruta_imagen = ?',
            [rutaRelativa],
          );

          if (results.isEmpty) {
            await conn.query('COMMIT');
            return true; // No existía en la BD
          }

          final idImagen = results.first['id_imagen'];
          // Usar el procedimiento almacenado para eliminar la imagen
          await conn.query('CALL EliminarImagenInmueble(?)', [idImagen]);

          await conn.query('COMMIT');
          AppLogger.info('Imagen eliminada de la BD: ID=$idImagen');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          if (!_procesandoError) {
            _procesandoError = true;
            AppLogger.error('Error al eliminar imagen de la BD', e);
            _procesandoError = false;
          }
          return false;
        }
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error de conexión al eliminar imagen', e);
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Elimina una imagen (método compatible).
  Future<bool> deleteImage(String? rutaRelativa) async {
    return eliminarImagenInmueble(rutaRelativa);
  }

  /// Elimina todas las imágenes asociadas a un inmueble.
  Future<bool> eliminarImagenesInmueble(int idInmueble) async {
    try {
      // 1. Obtener todas las rutas de imágenes almacenadas
      final imagenes = await getCachedImagesFor(idInmueble);

      // 2. Eliminar imágenes físicamente una por una
      for (final imagen in imagenes) {
        await eliminarImagenInmueble(imagen);
      }

      // 3. Asegurarse de eliminar todos los registros de BD usando procedimiento
      await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL LimpiarImagenesPorInmueble(?)', [idInmueble]);
          await conn.query('COMMIT');
          AppLogger.info(
            'Eliminadas todas las imágenes de inmueble $idInmueble de la BD',
          );
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error('Error al limpiar registros de imágenes', e);
        }
      });

      // 4. Eliminar directorio físico
      final appDocDir = await getApplicationDocumentsDirectory();
      final dirPath = path.join(
        appDocDir.path,
        'inmuebles',
        idInmueble.toString(),
      );
      final dir = Directory(dirPath);

      if (await dir.exists()) await dir.delete(recursive: true);

      // 5. Limpiar caché local
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('inmueble_$idInmueble');

      return true;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al eliminar imágenes de inmueble', e);
        _procesandoError = false;
      }
      return false;
    }
  }

  //=============================================================================
  // SECCIÓN: CACHÉ Y OPTIMIZACIÓN DE RENDIMIENTO
  //=============================================================================

  /// Genera una clave única para el caché basada en la ruta de la imagen.
  String _generateCacheKey(String imagePath) {
    var bytes = utf8.encode(imagePath);
    var digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  /// Guarda la referencia de una imagen en SharedPreferences.
  Future<void> _saveCachedImageReference(
    int idInmueble,
    String rutaImagen,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = 'inmueble_$idInmueble';
      final List<String> rutas = prefs.getStringList(key) ?? [];

      if (!rutas.contains(rutaImagen)) {
        rutas.add(rutaImagen);
        await prefs.setStringList(key, rutas);
      }
    } catch (e) {
      AppLogger.categoryWarning(
        'cache_reference',
        'Error al guardar referencia de caché: $e',
      );
    }
  }

  /// Obtiene las rutas de imágenes cacheadas para un inmueble.
  Future<List<String>> getCachedImagesFor(int idInmueble) async {
    try {
      // Primero intentar obtener de SharedPreferences (caché local)
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = 'inmueble_$idInmueble';
      final localCache = prefs.getStringList(key) ?? [];

      // Si hay caché local, usar eso
      if (localCache.isNotEmpty) {
        return localCache;
      }

      // Si no hay caché local, consultar la base de datos
      try {
        return await _db.withConnection((conn) async {
          final results = await conn.query('CALL ObtenerImagenesInmueble(?)', [
            idInmueble,
          ]);

          if (results.isEmpty) return <String>[];

          final List<String> rutas = [];
          for (var row in results) {
            if (row['ruta_imagen'] != null) {
              rutas.add(row['ruta_imagen'] as String);
            }
          }

          // Actualizar caché local
          if (rutas.isNotEmpty) {
            await prefs.setStringList(key, rutas);
          }

          return rutas;
        });
      } catch (e) {
        AppLogger.warning('Error al consultar imágenes de DB: $e');
        return [];
      }
    } catch (e) {
      AppLogger.categoryWarning(
        'cached_images',
        'Error al obtener imágenes cacheadas: $e',
      );
      return [];
    }
  }

  /// Convierte una ruta relativa en una ruta completa.
  Future<String?> obtenerRutaCompletaImagen(String? rutaRelativa) async {
    if (rutaRelativa == null || rutaRelativa.isEmpty) return null;

    // Verificar primero en caché de rutas
    if (_pathCache.containsKey(rutaRelativa)) {
      return _pathCache[rutaRelativa];
    }

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final rutaCompleta = path.join(appDocDir.path, rutaRelativa);

      if (rutaCompleta.contains('..')) {
        AppLogger.warning('Ruta no segura detectada: $rutaCompleta');
        return null;
      }

      // Guardar en caché para futuras consultas
      _managePathCache(rutaRelativa, rutaCompleta);

      return rutaCompleta;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al obtener ruta completa', e);
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Gestiona el caché de rutas para evitar operaciones repetitivas
  void _managePathCache(String rutaRelativa, String rutaCompleta) {
    // Si el caché está lleno, remover una entrada aleatoria
    if (_pathCache.length >= _maxPathCacheSize) {
      final keyToRemove = _pathCache.keys.first;
      _pathCache.remove(keyToRemove);
    }
    _pathCache[rutaRelativa] = rutaCompleta;
  }

  /// Programa una limpieza periódica del caché.
  void scheduleCacheCleanup() {
    Timer.periodic(const Duration(days: 1), (timer) async {
      try {
        await _inmuebleCacheManager.emptyCache();

        // Limpiar caché de memoria si es muy grande
        if (_memoryImageCache.length > 100) {
          final keysToRemove = _memoryImageCache.keys.take(50).toList();
          for (String key in keysToRemove) {
            _memoryImageCache.remove(key);
          }
          AppLogger.info(
            'Caché de memoria limpiada. Elementos: ${_memoryImageCache.length}',
          );
        }

        // Limpiar caché de rutas
        if (_pathCache.length > 50) {
          _pathCache.clear();
        }

        // Limpiar archivos temporales
        final tempDir = await getTemporaryDirectory();
        try {
          final now = DateTime.now();
          final entities = await tempDir.list().toList();
          int eliminados = 0;

          for (var entity in entities) {
            if (entity is File) {
              final stat = await entity.stat();
              if (now.difference(stat.modified) > const Duration(days: 7)) {
                await entity.delete();
                eliminados++;
              }
            }
          }

          if (eliminados > 0) {
            AppLogger.info(
              'Limpieza de archivos temporales: $eliminados archivos eliminados',
            );
          }

          // Ejecutar limpieza de imágenes huérfanas en la base de datos
          await limpiarImagenesHuerfanas();
        } catch (e) {
          AppLogger.warning('Error en limpieza de archivos temporales: $e');
        }
      } catch (e) {
        AppLogger.categoryWarning(
          'cache_cleanup',
          'Error en limpieza programada de caché: $e',
          expiration: const Duration(hours: 12),
        );
      }
    });
  }

  /// Limpia imágenes huérfanas de la base de datos
  Future<int> limpiarImagenesHuerfanas() async {
    try {
      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query(
            'CALL LimpiarImagenesHuerfanas(@imagenes_eliminadas)',
          );

          final result = await conn.query(
            'SELECT @imagenes_eliminadas as eliminadas',
          );
          final int eliminadas = result.first['eliminadas'] as int? ?? 0;

          await conn.query('COMMIT');
          if (eliminadas > 0) {
            AppLogger.info('Imágenes huérfanas eliminadas: $eliminadas');
          }
          return eliminadas;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.warning('Error al limpiar imágenes huérfanas: $e');
          return 0;
        }
      });
    } catch (e) {
      AppLogger.categoryWarning(
        'orphaned_images',
        'Error al conectar para limpiar imágenes huérfanas: $e',
        expiration: const Duration(hours: 12),
      );
      return 0;
    }
  }

  //=============================================================================
  // SECCIÓN: VISUALIZACIÓN DE IMÁGENES
  //=============================================================================

  /// Carga y muestra una imagen en la interfaz de usuario.
  Widget cargarImagen({
    required String? rutaImagen,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (rutaImagen == null || rutaImagen.isEmpty) {
      return errorWidget ??
          const Icon(Icons.image_not_supported, color: Colors.grey);
    }

    return FutureBuilder<String?>(
      future: Future.any([
        obtenerRutaCompletaImagen(rutaImagen),
        Future.delayed(const Duration(seconds: 5), () => null), // Timeout
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ??
              const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return errorWidget ??
              const Icon(Icons.broken_image, color: Colors.grey);
        }

        return Image.file(
          File(snapshot.data!),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            AppLogger.categoryWarning(
              'image_load',
              'Error al cargar imagen: $rutaImagen',
            );
            return errorWidget ??
                const Icon(Icons.error_outline, color: Colors.red);
          },
        );
      },
    );
  }

  /// Precarga imágenes de un inmueble en el caché de memoria.
  Future<void> precargarImagenesInmueble(
    int idInmueble,
    List<String> rutas,
  ) async {
    try {
      int cargadas = 0;
      for (var rutaRelativa in rutas) {
        final rutaCompleta = await obtenerRutaCompletaImagen(rutaRelativa);
        if (rutaCompleta != null) {
          try {
            final file = File(rutaCompleta);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final cacheKey = _generateCacheKey(rutaRelativa);
              _memoryImageCache[cacheKey] = bytes;
              cargadas++;
            }
          } catch (e) {
            // Ignorar errores individuales para no interrumpir la precarga
          }
        }
      }
      if (cargadas > 0) {
        AppLogger.info(
          '$cargadas imágenes precargadas para inmueble $idInmueble',
        );
      }
    } catch (e) {
      AppLogger.categoryWarning(
        'preload_images',
        'Error al precargar imágenes: $e',
      );
    }
  }

  /// Convierte una imagen a formato base64.
  Future<String?> imageToBase64(File imageFile) async {
    try {
      final optimizedImage = await optimizeImage(imageFile);
      final bytes = await optimizedImage.readAsBytes();
      final base64String = base64Encode(bytes);

      final String extension = path
          .extension(imageFile.path)
          .toLowerCase()
          .replaceAll('.', '');
      return 'data:image/$extension;base64,$base64String';
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al convertir imagen a base64', e);
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Libera los recursos utilizados por el servicio.
  void dispose() {
    _memoryImageCache.clear();
    _pathCache.clear();
    AppLogger.info('ImageService: recursos liberados');
  }

  /// Obtiene el tamaño total del almacenamiento de imágenes (en bytes).
  Future<int> getTotalStorageSize() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final inmueblesDir = Directory(path.join(appDocDir.path, 'inmuebles'));
      if (!await inmueblesDir.exists()) return 0;

      int totalSize = 0;
      await for (var entity in inmueblesDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al calcular tamaño de almacenamiento', e);
        _procesandoError = false;
      }
      return 0;
    }
  }
}

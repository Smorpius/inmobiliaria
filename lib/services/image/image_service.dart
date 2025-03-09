import 'dart:io';
import 'dart:async';
import 'image_cache_service.dart';
import 'image_picker_service.dart';
import 'image_storage_service.dart';
import 'image_display_service.dart';
import 'dart:developer' as developer;
import 'image_processor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'image_conversion_service.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Clase fachada que coordina todos los servicios de imágenes
class ImageService {
  final ImagePickerService _pickerService = ImagePickerService();
  final ImageProcessorService _processorService = ImageProcessorService();
  final ImageStorageService _storageService = ImageStorageService();
  final ImageConversionService _conversionService = ImageConversionService();
  final ImageDisplayService _displayService = ImageDisplayService();
  final ImageCacheService _cacheService = ImageCacheService();

  // Valores predeterminados para procesamiento de imágenes
  final int _maxWidth = 800;
  final int _maxHeight = 800;
  final int _quality = 85;

  // Formatos soportados (extensiones)
  final List<String> _supportedFormats = ['.jpg', '.jpeg', '.png'];

  // Tamaño máximo por defecto (5MB)
  final int _maxFileSize = 5 * 1024 * 1024;

  /// Constructor
  ImageService() {
    developer.log('ImageService inicializado');
    _cleanupTempFiles(); // Limpiar archivos temporales al iniciar
  }

  /// Programa la limpieza periódica del caché
  void scheduleCacheCleanup() {
    _cacheService.scheduleCacheCleanup();
  }

  /// Verifica si el formato de la imagen es soportado
  bool _isFormatSupported(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return _supportedFormats.contains(ext);
  }

  /// Verifica tamaño de archivo
  Future<bool> _isFileSizeValid(File file, [int? maxSize]) async {
    try {
      final size = await file.length();
      return size <= (maxSize ?? _maxFileSize);
    } catch (e) {
      developer.log('Error al verificar tamaño de archivo: $e', error: e);
      return false;
    }
  }

  /// Selecciona una imagen desde la cámara o galería y la optimiza
  Future<File?> pickImage(
    ImageSource source, {
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? maxFileSize,
  }) async {
    try {
      // Paso 1: Seleccionar imagen
      final File? originalFile = await _pickerService.pickImage(source);
      if (originalFile == null) return null;

      // Verificar formato soportado
      if (!_isFormatSupported(originalFile.path)) {
        throw UnsupportedError(
          'Formato de imagen no soportado. Use formatos: ${_supportedFormats.join(", ")}',
        );
      }

      // Verificar tamaño
      if (!await _isFileSizeValid(originalFile, maxFileSize)) {
        throw const FileSizeException(
          'El archivo excede el tamaño máximo permitido',
        );
      }

      // Paso 2: Procesar imagen
      final File? processedFile = await _processorService.processImage(
        originalFile,
        maxWidth: maxWidth?.toInt() ?? _maxWidth,
        maxHeight: maxHeight?.toInt() ?? _maxHeight,
        quality: imageQuality ?? _quality,
      );

      if (processedFile == null) {
        developer.log(
          'Advertencia: No se pudo procesar la imagen, usando original',
        );
        return originalFile; // Fallback al original
      }

      // Guardar en memoria temporal para acceso rápido
      final String cachedPath = await _cacheService.cacheImage(processedFile);

      // Registrar información sobre optimización
      await _processorService.logOptimizationDetails(
        originalFile,
        File(cachedPath),
      );

      return File(cachedPath);
    } on PlatformException catch (e) {
      developer.log('Error de plataforma en pickImage: $e', error: e);
      throw PlatformImageException(
        'Error al acceder a ${source == ImageSource.gallery ? "galería" : "cámara"}: ${e.message}',
      );
    } on UnsupportedError catch (e) {
      developer.log('Formato no soportado: $e', error: e);
      rethrow; // Propagar para manejo específico
    } on FileSizeException catch (e) {
      developer.log('Archivo demasiado grande: $e', error: e);
      rethrow; // Propagar para manejo específico
    } catch (e) {
      developer.log('Error en pickImage: $e', error: e);
      throw ImageServiceException('Error al seleccionar imagen: $e');
    }
  }

  /// Selecciona una imagen desde la galería
  Future<File?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? maxFileSize,
  }) async {
    return pickImage(
      ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      maxFileSize: maxFileSize,
    );
  }

  /// Toma una imagen con la cámara
  Future<File?> takePhoto({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? maxFileSize,
  }) async {
    return pickImage(
      ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      maxFileSize: maxFileSize,
    );
  }

  /// Comprime una imagen existente
  Future<File?> compressImage(
    File imageFile, {
    int? quality,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // Verificar existencia del archivo
      if (!await imageFile.exists()) {
        throw FileSystemException('El archivo a comprimir no existe');
      }

      // Verificar formato soportado
      if (!_isFormatSupported(imageFile.path)) {
        throw UnsupportedError(
          'Formato no soportado para compresión: ${path.extension(imageFile.path)}',
        );
      }

      // Verificar si la compresión es necesaria
      final fileSize = await imageFile.length();
      if (fileSize < 500 * 1024) {
        // Si es menor a 500KB, no comprimir
        return imageFile;
      }

      // Comprimir la imagen
      final File? compressedFile = await _processorService.processImage(
        imageFile,
        maxWidth: maxWidth ?? _maxWidth,
        maxHeight: maxHeight ?? _maxHeight,
        quality: quality ?? _quality,
      );

      if (compressedFile == null) {
        developer.log('No se pudo comprimir la imagen, devolviendo original');
        return imageFile;
      }

      // Verificar que la compresión fue efectiva
      final compressedSize = await compressedFile.length();
      if (compressedSize >= fileSize) {
        developer.log(
          'La compresión no redujo el tamaño, devolviendo original',
        );
        return imageFile;
      }

      // Registrar resultados de la compresión
      developer.log(
        'Imagen comprimida: ${fileSize}B → ${compressedSize}B (${(compressedSize / fileSize * 100).toStringAsFixed(1)}%)',
      );

      return compressedFile;
    } catch (e) {
      developer.log('Error al comprimir imagen: $e', error: e);
      // En caso de error, retornar null para manejo específico
      return null;
    }
  }

  /// Procesa una imagen existente (redimensiona y comprime)
  Future<String?> processImage(String path) async {
    try {
      // Verificar que la ruta existe
      if (path.isEmpty) {
        throw ArgumentError('La ruta de imagen no puede estar vacía');
      }

      final imageFile = File(path);
      if (!await imageFile.exists()) {
        throw FileSystemException('El archivo de imagen no existe: $path');
      }

      // Verificar primero en caché
      final String? cachedPath = await _cacheService.getCachedImage(path);
      if (cachedPath != null) {
        final cachedFile = File(cachedPath);
        if (await cachedFile.exists()) {
          return cachedPath;
        }
      }

      // Procesar la imagen
      final File? processedFile = await _processorService.processImage(
        imageFile,
      );
      if (processedFile == null) return path;

      // Guardar permanentemente
      final String? savedPath = await _storageService.saveImagePermanently(
        processedFile,
      );
      if (savedPath == null) return processedFile.path;

      // Guardar en caché
      final File savedFile = File(savedPath);
      return await _cacheService.cacheImage(savedFile);
    } on ArgumentError catch (e) {
      developer.log('Error de argumento: $e', error: e);
      return null;
    } on FileSystemException catch (e) {
      developer.log('Error de sistema de archivos: $e', error: e);
      return null;
    } catch (e) {
      developer.log('Error al procesar imagen: $e', error: e);
      return null;
    }
  }

  /// Obtiene un objeto File a partir de una ruta
  Future<File?> getImageFile(String? imagePath) async {
    try {
      if (imagePath == null || imagePath.isEmpty) {
        return null;
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        developer.log('Advertencia: El archivo no existe: $imagePath');
        return null;
      }

      return file;
    } catch (e) {
      developer.log('Error al obtener archivo de imagen: $e', error: e);
      return null;
    }
  }

  /// Guarda una imagen con manejo de errores mejorado
  Future<String?> saveImage(
    File imageFile,
    String category,
    String prefix,
  ) async {
    try {
      // Verificar que el archivo existe
      if (!await imageFile.exists()) {
        throw FileSystemException('El archivo a guardar no existe');
      }

      // Crear directorio de categoría si no existe
      final appDocDir = await getApplicationDocumentsDirectory();
      final categoryDir = Directory(path.join(appDocDir.path, category));

      if (!await categoryDir.exists()) {
        await categoryDir.create(recursive: true);
      }

      // Verificar espacio disponible
      final diskSpace = await _getFreeDiskSpace();
      final fileSize = await imageFile.length();

      if (diskSpace != null && fileSize > diskSpace) {
        throw const InsufficientStorageException(
          'Espacio insuficiente para guardar la imagen',
        );
      }

      // Generar nombre único para la imagen
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${prefix}_$timestamp${path.extension(imageFile.path)}';
      final savedFile = File(path.join(categoryDir.path, fileName));

      // Copiar la imagen con manejo de errores
      try {
        await imageFile.copy(savedFile.path);
      } catch (e) {
        developer.log(
          'Error al copiar imagen, intentando método alternativo: $e',
          error: e,
        );
        // Intentar método alternativo
        final bytes = await imageFile.readAsBytes();
        await savedFile.writeAsBytes(bytes);
      }

      // Verificar que el archivo se guardó correctamente
      if (!await savedFile.exists()) {
        throw FileSystemException('No se pudo crear el archivo guardado');
      }

      developer.log('Imagen guardada exitosamente en: ${savedFile.path}');
      return savedFile.path;
    } on FileSystemException catch (e) {
      developer.log('Error de sistema de archivos: $e', error: e);
      return null;
    } on InsufficientStorageException catch (e) {
      developer.log('Error de almacenamiento: $e', error: e);
      return null;
    } catch (e) {
      developer.log('Error al guardar imagen: $e', error: e);
      return null;
    }
  }

  /// Método auxiliar para verificar espacio disponible
  Future<int?> _getFreeDiskSpace() async {
    try {
      // Esta es una implementación simplificada. En un caso real
      // necesitarías usar un plugin específico de plataforma
      // No usamos appDocDir directamente para evitar el warning
      await getApplicationDocumentsDirectory(); // Solo para verificar que podemos acceder al sistema de archivos

      // Asumimos espacio disponible
      return 1024 * 1024 * 100; // 100MB
    } catch (e) {
      developer.log('Error al verificar espacio en disco: $e', error: e);
      return null;
    }
  }

  /// Convierte imagen a base64 para almacenamiento en BD
  Future<String?> imageToBase64(String path) async {
    try {
      if (path.isEmpty) {
        throw ArgumentError('La ruta de imagen no puede estar vacía');
      }

      final file = File(path);
      if (!await file.exists()) {
        throw FileSystemException('El archivo no existe: $path');
      }

      return await _conversionService.imageToBase64(file);
    } on ArgumentError catch (e) {
      developer.log('Error de argumento: $e', error: e);
      return null;
    } on FileSystemException catch (e) {
      developer.log('Error de sistema de archivos: $e', error: e);
      return null;
    } catch (e) {
      developer.log('Error al convertir imagen a Base64: $e', error: e);
      return null;
    }
  }

  /// Obtiene una imagen desde Base64 (para mostrarla desde la BD)
  Future<File?> base64ToImageFile(String base64Image) async {
    try {
      if (base64Image.isEmpty) {
        throw ArgumentError('La cadena Base64 no puede estar vacía');
      }

      final File? file = await _conversionService.base64ToImageFile(
        base64Image,
      );
      if (file == null) {
        throw FormatException('No se pudo convertir la cadena Base64 a imagen');
      }

      // Cachear para acceso rápido
      final String cachedPath = await _cacheService.cacheImage(file);
      return File(cachedPath);
    } on ArgumentError catch (e) {
      developer.log('Error de argumento: $e', error: e);
      return null;
    } on FormatException catch (e) {
      developer.log('Error de formato: $e', error: e);
      return null;
    } catch (e) {
      developer.log('Error al convertir Base64 a imagen: $e', error: e);
      return null;
    }
  }

  /// Elimina una imagen del almacenamiento
  Future<bool> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }

    try {
      return await _storageService.deleteImage(imagePath);
    } catch (e) {
      developer.log('Error al eliminar imagen: $e', error: e);
      return false;
    }
  }

  /// Limpia archivos temporales creados por el servicio
  Future<void> _cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final imageDir = Directory('${tempDir.path}/images');

      if (await imageDir.exists()) {
        // Eliminar archivos más antiguos que 1 día
        final oneDay = const Duration(days: 1);
        final now = DateTime.now();

        final entities = await imageDir.list().toList();
        for (var entity in entities) {
          if (entity is File) {
            final stat = await entity.stat();
            final fileAge = now.difference(stat.modified);

            if (fileAge > oneDay) {
              try {
                await entity.delete();
                developer.log('Archivo temporal eliminado: ${entity.path}');
              } catch (e) {
                developer.log(
                  'No se pudo eliminar archivo temporal: ${entity.path}',
                  error: e,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error al limpiar archivos temporales: $e', error: e);
    }
  }

  /// Obtiene un widget para mostrar una imagen desde una ruta
  Widget getImageWidget({
    required String? imagePath,
    double width = 100,
    double height = 100,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    try {
      return _displayService.getImageWidget(
        imagePath: imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder ?? const CircularProgressIndicator(),
        errorWidget:
            errorWidget ?? const Icon(Icons.broken_image, color: Colors.red),
      );
    } catch (e) {
      developer.log('Error al crear widget de imagen: $e', error: e);
      return errorWidget ??
          const Icon(Icons.error_outline, color: Colors.red, size: 40);
    }
  }

  /// Verifica si una imagen es válida (existe y tiene formato correcto)
  Future<bool> isValidImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return false;
      }

      return _isFormatSupported(imagePath);
    } catch (e) {
      developer.log('Error al verificar validez de imagen: $e', error: e);
      return false;
    }
  }
}

/// Excepción personalizada para tamaño de archivo
class FileSizeException implements Exception {
  final String message;
  const FileSizeException(this.message);

  @override
  String toString() => 'FileSizeException: $message';
}

/// Excepción personalizada para almacenamiento insuficiente
class InsufficientStorageException implements Exception {
  final String message;
  const InsufficientStorageException(this.message);

  @override
  String toString() => 'InsufficientStorageException: $message';
}

/// Excepción personalizada para errores de imagen de plataforma
class PlatformImageException implements Exception {
  final String message;
  const PlatformImageException(this.message);

  @override
  String toString() => 'PlatformImageException: $message';
}

/// Excepción genérica del servicio de imágenes
class ImageServiceException implements Exception {
  final String message;
  const ImageServiceException(this.message);

  @override
  String toString() => 'ImageServiceException: $message';
}

import 'dart:io';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio mejorado para gestionar operaciones con imágenes
class ImageService {
  final ImagePicker _picker = ImagePicker();

  // Configuración para gestión de errores
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(milliseconds: 300);

  /// Implementación de método de reintentos para operaciones con imágenes
  Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 300),
  }) async {
    int retryCount = 0;
    Exception? lastError;

    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        lastError = e is Exception ? e : Exception(e.toString());

        if (retryCount >= maxRetries) {
          break; // Salir del bucle y lanzar excepción final
        }

        // Retraso exponencial para reintentos
        final delay = Duration(
          milliseconds: initialDelay.inMilliseconds * (1 << retryCount),
        );
        developer.log(
          'Reintento $retryCount de operación con imagen después de ${delay.inMilliseconds}ms debido a: $e',
        );
        await Future.delayed(delay);
      }
    }

    developer.log(
      'Operación con imagen falló después de $maxRetries intentos',
      error: lastError,
    );
    throw lastError ?? Exception('Error desconocido en operación con imagen');
  }

  /// Selecciona una imagen desde la galería o cámara con reintentos
  Future<File?> pickImage(ImageSource source) async {
    try {
      return await withRetry(
        operation: () async {
          final XFile? pickedFile = await _picker.pickImage(
            source: source,
            maxWidth: 1200,
            maxHeight: 1200,
            imageQuality: 85,
          );

          if (pickedFile != null) {
            final file = File(pickedFile.path);
            // Verificar que el archivo realmente existe
            if (await file.exists()) {
              return file;
            } else {
              throw Exception(
                'El archivo seleccionado no existe en la ruta especificada',
              );
            }
          }
          return null;
        },
        maxRetries: maxRetries,
      );
    } catch (e) {
      developer.log('Error al seleccionar imagen: $e', error: e);
      return null;
    }
  }

  /// Guarda una imagen en el almacenamiento de la aplicación con reintentos
  Future<String?> saveImage(
    File? imageFile,
    String category,
    String prefix,
  ) async {
    if (imageFile == null) {
      developer.log('Error: Intento de guardar una imagen nula');
      return null;
    }

    try {
      return await withRetry(
        operation: () async {
          // Verificar que el archivo de origen existe
          if (!await imageFile.exists()) {
            throw Exception('El archivo de origen no existe');
          }

          // Crear directorio de categoría si no existe
          final appDocDir = await getApplicationDocumentsDirectory();
          final categoryDir = Directory(path.join(appDocDir.path, category));

          if (!await categoryDir.exists()) {
            await categoryDir.create(recursive: true);
          }

          // Generar nombre único para la imagen
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName =
              '${prefix}_$timestamp${path.extension(imageFile.path)}';
          final savedFile = File(path.join(categoryDir.path, fileName));

          // Copiar la imagen al directorio específico
          await imageFile.copy(savedFile.path);

          // Verificar que la imagen se guardó correctamente
          if (!await savedFile.exists()) {
            throw Exception('La imagen no se guardó correctamente');
          }

          return savedFile.path;
        },
      );
    } catch (e) {
      developer.log('Error al guardar imagen: $e', error: e);
      return null;
    }
  }

  /// Elimina una imagen con verificación mejorada
  Future<bool> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return true;

    try {
      return await withRetry(
        operation: () async {
          final file = File(imagePath);
          if (await file.exists()) {
            await file.delete();

            // Verificar que se eliminó correctamente
            bool deleted = !await file.exists();
            if (!deleted) {
              throw Exception('No se pudo eliminar la imagen: $imagePath');
            }
            return true;
          }
          return true; // Si no existe, consideramos exitosa la operación
        },
      );
    } catch (e) {
      developer.log('Error al eliminar imagen: $e', error: e);
      return false;
    }
  }

  /// Limpia imágenes antiguas del caché
  void scheduleCacheCleanup() {
    developer.log('Limpieza de caché programada');
    // Implementación mejorada para limpiar imágenes antiguas
    Timer.periodic(const Duration(days: 1), (timer) async {
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final now = DateTime.now();
        final maxAge = const Duration(days: 30);

        // Limpiar directorios temporales
        final tempDir = Directory(path.join(appDocDir.path, 'temp'));
        if (await tempDir.exists()) {
          await _cleanDirectoryOldFiles(tempDir, now, maxAge);
        }
      } catch (e) {
        developer.log('Error en limpieza programada: $e');
      }
    });
  }

  /// Limpia archivos antiguos de un directorio
  Future<void> _cleanDirectoryOldFiles(
    Directory dir,
    DateTime now,
    Duration maxAge,
  ) async {
    try {
      final entities = await dir.list().toList();
      for (var entity in entities) {
        if (entity is File) {
          final stat = await entity.stat();
          final fileAge = now.difference(stat.modified);
          if (fileAge > maxAge) {
            try {
              await entity.delete();
              developer.log('Archivo eliminado por antigüedad: ${entity.path}');
            } catch (e) {
              developer.log('Error al eliminar archivo antiguo: $e');
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error al limpiar directorio: $e');
    }
  }

  /// Obtiene un objeto File desde una ruta con validación mejorada
  Future<File?> getImageFile(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      developer.log('Ruta de imagen vacía o nula');
      return null;
    }

    try {
      return await withRetry(
        operation: () async {
          final file = File(imagePath);
          if (await file.exists()) {
            return file;
          }
          developer.log('Imagen no encontrada en: $imagePath');
          return null;
        },
      );
    } catch (e) {
      developer.log('Error al obtener archivo de imagen: $e', error: e);
      return null;
    }
  }

  /// Comprime una imagen si es necesario (método de utilidad)
  Future<File?> compressImage(File? imageFile) async {
    if (imageFile == null) return null;

    try {
      // Por ahora devolvemos el archivo original
      // Implementación futura: comprimir imagen
      return imageFile;
    } catch (e) {
      developer.log('Error al comprimir imagen: $e', error: e);
      return imageFile; // En caso de error devolvemos el original
    }
  }

  /// Método mejorado para cargar una imagen desde la galería o cámara
  Future<File?> cargarImagenDesdeDispositivo(ImageSource source) async {
    try {
      developer.log('Seleccionando imagen desde: ${source.toString()}');

      // Usar el método existente para seleccionar la imagen con reintentos
      File? selectedImage = await pickImage(source);

      if (selectedImage == null) {
        developer.log('No se seleccionó ninguna imagen');
        return null;
      }

      // Comprimir la imagen si es necesario
      File? compressedImage = await compressImage(selectedImage);
      return compressedImage ?? selectedImage;
    } catch (e) {
      developer.log('Error al cargar imagen desde dispositivo: $e', error: e);
      return null;
    }
  }

  /// Método mejorado para guardar la imagen en el almacenamiento
  Future<String?> guardarImagenInmueble(File? imagen, int idInmueble) async {
    if (imagen == null) {
      developer.log(
        'Error: Se intentó guardar una imagen nula para inmueble ID: $idInmueble',
      );
      return null;
    }

    try {
      developer.log('Guardando imagen para inmueble ID: $idInmueble');

      // Validar ID de inmueble
      if (idInmueble <= 0) {
        throw Exception('ID de inmueble inválido: $idInmueble');
      }

      // Crear nombre de categoría basado en el ID del inmueble
      final String categoria = 'inmuebles/$idInmueble';
      final String prefijo = 'inmueble';

      // Usar el método existente para guardar la imagen
      final String? rutaCompleta = await saveImage(imagen, categoria, prefijo);

      if (rutaCompleta == null) {
        developer.log('Error al guardar la imagen del inmueble');
        return null;
      }

      // Para facilitar portabilidad, guardamos una ruta relativa en la BD
      final appDocDir = await getApplicationDocumentsDirectory();
      String rutaRelativa = rutaCompleta.replaceFirst('${appDocDir.path}/', '');

      developer.log('Imagen guardada con ruta relativa: $rutaRelativa');
      return rutaRelativa;
    } catch (e) {
      developer.log('Error al guardar imagen de inmueble: $e', error: e);
      return null;
    }
  }

  /// Obtiene la ruta completa desde una ruta relativa almacenada
  Future<String?> obtenerRutaCompletaImagen(String? rutaRelativa) async {
    if (rutaRelativa == null || rutaRelativa.isEmpty) {
      developer.log('Advertencia: Ruta relativa vacía o nula');
      return null;
    }

    try {
      return await withRetry(
        operation: () async {
          final appDocDir = await getApplicationDocumentsDirectory();
          final rutaCompleta = path.join(appDocDir.path, rutaRelativa);

          final file = File(rutaCompleta);
          if (await file.exists()) {
            return rutaCompleta;
          }

          developer.log('Advertencia: La imagen no existe en: $rutaCompleta');
          return null;
        },
      );
    } catch (e) {
      developer.log('Error al obtener ruta completa: $e', error: e);
      return null;
    }
  }

  /// Elimina todas las imágenes asociadas a un inmueble
  Future<bool> eliminarImagenesInmueble(int idInmueble) async {
    if (idInmueble <= 0) {
      developer.log(
        'Error: ID de inmueble inválido para eliminación de imágenes: $idInmueble',
      );
      return false;
    }

    try {
      developer.log(
        'Eliminando todas las imágenes del inmueble ID: $idInmueble',
      );

      return await withRetry(
        operation: () async {
          final appDocDir = await getApplicationDocumentsDirectory();
          final directorioInmueble = Directory(
            path.join(appDocDir.path, 'inmuebles/$idInmueble'),
          );

          if (await directorioInmueble.exists()) {
            await directorioInmueble.delete(recursive: true);

            // Verificar que se eliminó correctamente
            bool deleted = !await directorioInmueble.exists();
            if (!deleted) {
              throw Exception('No se pudo eliminar el directorio de imágenes');
            }
          }

          return true;
        },
      );
    } catch (e) {
      developer.log('Error al eliminar imágenes del inmueble: $e', error: e);
      return false;
    }
  }

  /// Elimina una imagen específica de un inmueble
  Future<bool> eliminarImagenInmueble(String? rutaRelativa) async {
    if (rutaRelativa == null || rutaRelativa.isEmpty) {
      return true; // Si no hay ruta, consideramos éxito
    }

    try {
      final rutaCompleta = await obtenerRutaCompletaImagen(rutaRelativa);
      if (rutaCompleta == null) return true;

      return await deleteImage(rutaCompleta);
    } catch (e) {
      developer.log('Error al eliminar imagen específica: $e', error: e);
      return false;
    }
  }

  /// Carga y verifica una imagen con reintentos
  Future<Image?> cargarImagen(String? rutaImagen) async {
    if (rutaImagen == null || rutaImagen.isEmpty) {
      return null;
    }

    try {
      return await withRetry(
        operation: () async {
          final file = File(rutaImagen);
          // Verificar que el archivo existe
          if (!await file.exists()) {
            developer.log('Imagen no encontrada: $rutaImagen');
            return null;
          }

          // Verificar tamaño mínimo para considerar un archivo válido
          if ((await file.length()) < 100) {
            // Mínimo 100 bytes
            developer.log(
              'Archivo de imagen demasiado pequeño para ser válido: $rutaImagen',
            );
            return null;
          }

          // Verificación segura del formato
          try {
            final bytes = await file.readAsBytes();
            // Comprobar si tiene suficientes bytes para verificar formato
            if (bytes.length < 8) {
              throw Exception('Archivo de imagen incompleto o corrupto');
            }

            // Verificar firmas de formato común de imagen
            bool isValidImageFormat = false;

            // JPEG: FF D8 FF
            if (bytes.length > 2 &&
                bytes[0] == 0xFF &&
                bytes[1] == 0xD8 &&
                bytes[2] == 0xFF) {
              isValidImageFormat = true;
            }
            // PNG: 89 50 4E 47 0D 0A 1A 0A
            else if (bytes.length > 7 &&
                bytes[0] == 0x89 &&
                bytes[1] == 0x50 &&
                bytes[2] == 0x4E &&
                bytes[3] == 0x47) {
              isValidImageFormat = true;
            }
            // GIF: 47 49 46 38
            else if (bytes.length > 3 &&
                bytes[0] == 0x47 &&
                bytes[1] == 0x49 &&
                bytes[2] == 0x46 &&
                bytes[3] == 0x38) {
              isValidImageFormat = true;
            }

            if (!isValidImageFormat) {
              developer.log(
                'Formato de archivo no reconocido como imagen válida: $rutaImagen',
              );
              return null;
            }

            return Image.file(file);
          } catch (e) {
            developer.log('Error al verificar o cargar imagen: $e', error: e);
            return null;
          }
        },
        maxRetries: maxRetries,
      );
    } catch (e) {
      developer.log('Error al cargar imagen $rutaImagen: $e');
      // En caso de error, intentar cargar una imagen por defecto
      try {
        return Image.asset('assets/default_image.png');
      } catch (_) {
        return null;
      }
    }
  }
}

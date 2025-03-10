import 'dart:io';
import 'dart:developer' as developer;
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio para gestionar operaciones con imágenes
/// Implementación independiente sin dependencias a otros servicios
class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Selecciona una imagen desde la galería o cámara
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      developer.log('Error al seleccionar imagen: $e', error: e);
      return null;
    }
  }

  /// Guarda una imagen en el almacenamiento de la aplicación
  Future<String?> saveImage(
    File imageFile,
    String category,
    String prefix,
  ) async {
    try {
      // Crear directorio de categoría si no existe
      final appDocDir = await getApplicationDocumentsDirectory();
      final categoryDir = Directory(path.join(appDocDir.path, category));

      if (!await categoryDir.exists()) {
        await categoryDir.create(recursive: true);
      }

      // Generar nombre único para la imagen
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${prefix}_$timestamp${path.extension(imageFile.path)}';
      final savedFile = File(path.join(categoryDir.path, fileName));

      // Copiar la imagen al directorio específico
      await imageFile.copy(savedFile.path);

      return savedFile.path;
    } catch (e) {
      developer.log('Error al guardar imagen: $e', error: e);
      return null;
    }
  }

  /// Elimina una imagen
  Future<bool> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return true;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error al eliminar imagen: $e', error: e);
      return false;
    }
  }

  /// Limpia imágenes antiguas del caché (por implementar)
  void scheduleCacheCleanup() {
    // Esta función puede implementarse en el futuro para limpiar imágenes antiguas
    developer.log('Limpieza de caché programada');
  }

  /// Obtiene un objeto File desde una ruta
  Future<File?> getImageFile(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      developer.log('Error al obtener archivo de imagen: $e', error: e);
      return null;
    }
  }

  /// Comprime una imagen si es necesario (método de utilidad)
  Future<File?> compressImage(File imageFile) async {
    // Por implementar: lógica de compresión de imágenes
    // Por ahora retornamos el archivo original
    return imageFile;
  }

  /// NUEVOS MÉTODOS PARA GESTIÓN DE IMÁGENES DE INMUEBLES ///

  /// Método para cargar una imagen desde la galería o cámara
  /// Además de seleccionar la imagen, la comprime si es necesario
  Future<File?> cargarImagenDesdeDispositivo(ImageSource source) async {
    try {
      developer.log('Seleccionando imagen desde: ${source.toString()}');

      // Usar el método existente para seleccionar la imagen
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

  /// Método para guardar la imagen en el almacenamiento específico para inmuebles
  /// Retorna la ruta relativa que debe guardarse en la base de datos
  Future<String?> guardarImagenInmueble(File imagen, int idInmueble) async {
    try {
      developer.log('Guardando imagen para inmueble ID: $idInmueble');

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
      // Esto evita problemas con diferentes rutas en distintos dispositivos
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
  Future<String?> obtenerRutaCompletaImagen(String rutaRelativa) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final rutaCompleta = path.join(appDocDir.path, rutaRelativa);

      final file = File(rutaCompleta);
      if (await file.exists()) {
        return rutaCompleta;
      }

      developer.log('Advertencia: La imagen no existe en: $rutaCompleta');
      return null;
    } catch (e) {
      developer.log('Error al obtener ruta completa: $e', error: e);
      return null;
    }
  }

  /// Elimina todas las imágenes asociadas a un inmueble
  Future<bool> eliminarImagenesInmueble(int idInmueble) async {
    try {
      developer.log(
        'Eliminando todas las imágenes del inmueble ID: $idInmueble',
      );

      final appDocDir = await getApplicationDocumentsDirectory();
      final directorioInmueble = Directory(
        path.join(appDocDir.path, 'inmuebles/$idInmueble'),
      );

      if (await directorioInmueble.exists()) {
        await directorioInmueble.delete(recursive: true);
        return true;
      }

      return true; // Si no existe el directorio, consideramos éxito
    } catch (e) {
      developer.log('Error al eliminar imágenes del inmueble: $e', error: e);
      return false;
    }
  }

  /// Elimina una imagen específica de un inmueble
  Future<bool> eliminarImagenInmueble(String rutaRelativa) async {
    try {
      final rutaCompleta = await obtenerRutaCompletaImagen(rutaRelativa);
      if (rutaCompleta == null) return true; // Si no existe, consideramos éxito

      return await deleteImage(rutaCompleta);
    } catch (e) {
      developer.log('Error al eliminar imagen específica: $e', error: e);
      return false;
    }
  }
}

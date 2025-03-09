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
}

import 'dart:io';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';

/// Servicio responsable del almacenamiento persistente de imágenes
class ImageStorageService {
  final _uuid = const Uuid();

  /// Guarda una imagen en almacenamiento permanente con nombre único
  Future<String?> saveImagePermanently(File imageFile) async {
    try {
      developer.log('Guardando imagen permanentemente: ${imageFile.path}');

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String appDirPath = appDir.path;

      // Crear subdirectorio si no existe
      final Directory imageDir = Directory('$appDirPath/images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // Generar nombre único para la imagen
      final String fileName = '${_uuid.v4()}${extension(imageFile.path)}';
      final String permanentPath = '${imageDir.path}/$fileName';

      // Copiar el archivo
      await imageFile.copy(permanentPath);

      developer.log('Imagen guardada permanentemente en: $permanentPath');
      return permanentPath;
    } catch (e) {
      developer.log('Error al guardar imagen permanentemente: $e', error: e);
      return null;
    }
  }

  /// Guarda una imagen en un directorio temporal
  Future<String?> saveToTemp(File imageFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = '${_uuid.v4()}${extension(imageFile.path)}';
      final tempPath = '${tempDir.path}/$fileName';

      await imageFile.copy(tempPath);

      developer.log('Imagen guardada temporalmente en: $tempPath');
      return tempPath;
    } catch (e) {
      developer.log('Error al guardar imagen temporalmente: $e', error: e);
      return null;
    }
  }

  /// Guarda una imagen en una categoría específica
  Future<String?> saveImageToCategory(File imageFile, String category) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String categoryPath = '${appDir.path}/$category';

      // Crear el directorio de categoría si no existe
      final Directory categoryDir = Directory(categoryPath);
      if (!await categoryDir.exists()) {
        await categoryDir.create(recursive: true);
      }

      // Generar nombre único para la imagen
      final String fileName = '${_uuid.v4()}${extension(imageFile.path)}';
      final String savePath = '$categoryPath/$fileName';

      // Copiar el archivo
      await imageFile.copy(savePath);

      developer.log('Imagen guardada en categoría $category: $savePath');
      return savePath;
    } catch (e) {
      developer.log('Error al guardar imagen en categoría: $e', error: e);
      return null;
    }
  }

  /// Elimina una imagen del almacenamiento
  Future<bool> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return true;
    }

    try {
      developer.log('Eliminando imagen: $imagePath');
      final File file = File(imagePath);

      if (await file.exists()) {
        await file.delete();
        developer.log('Imagen eliminada exitosamente');
        return true;
      }

      developer.log('La imagen no existe en la ruta especificada');
      return false;
    } catch (e) {
      developer.log('Error al eliminar imagen: $e', error: e);
      return false;
    }
  }
}

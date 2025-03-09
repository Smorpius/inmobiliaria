import 'dart:io';
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';

/// Servicio responsable de la selección de imágenes desde diferentes fuentes
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Selecciona una imagen de la galería o cámara
  Future<File?> pickImage(
    ImageSource source, {
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      developer.log('Seleccionando imagen desde: $source');

      final XFile? pickedImage = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedImage == null) {
        developer.log('Selección de imagen cancelada por el usuario');
        return null;
      }

      developer.log('Imagen seleccionada: ${pickedImage.path}');
      return File(pickedImage.path);
    } catch (e) {
      developer.log('Error al seleccionar imagen: $e', error: e);
      return null;
    }
  }

  /// Toma una foto con la cámara
  Future<File?> takePhoto({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    return pickImage(
      ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Selecciona una imagen de la galería
  Future<File?> pickFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    return pickImage(
      ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }
}

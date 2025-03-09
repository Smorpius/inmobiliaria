import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:image/image.dart' as img;

/// Servicio responsable del procesamiento y optimización de imágenes
class ImageProcessorService {
  // Valores predeterminados
  final int _defaultMaxWidth = 800;
  final int _defaultMaxHeight = 800;
  final int _defaultQuality = 85;

  /// Procesa y optimiza una imagen (redimensiona y comprime)
  Future<File?> processImage(
    File imageFile, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    try {
      developer.log('Procesando imagen: ${imageFile.path}');

      final width = maxWidth ?? _defaultMaxWidth;
      final height = maxHeight ?? _defaultMaxHeight;
      final imgQuality = quality ?? _defaultQuality;

      developer.log(
        'Parámetros: width=$width, height=$height, quality=$imgQuality',
      );

      final Uint8List bytes = await imageFile.readAsBytes();

      // Decodificar la imagen
      final img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        developer.log(
          'No se pudo decodificar la imagen',
          error: 'Formato no compatible',
        );
        return null;
      }

      // Redimensionar manteniendo proporción si es necesario
      img.Image resizedImage = originalImage;
      if (originalImage.width > width || originalImage.height > height) {
        developer.log(
          'Redimensionando imagen de ${originalImage.width}x${originalImage.height}',
        );

        double ratioX = width / originalImage.width;
        double ratioY = height / originalImage.height;
        double ratio = ratioX < ratioY ? ratioX : ratioY;

        int newWidth = (originalImage.width * ratio).round();
        int newHeight = (originalImage.height * ratio).round();

        resizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );

        developer.log(
          'Imagen redimensionada a ${resizedImage.width}x${resizedImage.height}',
        );
      }

      // Comprimir la imagen
      final List<int> compressedBytes = img.encodeJpg(
        resizedImage,
        quality: imgQuality,
      );
      developer.log('Imagen comprimida: ${compressedBytes.length} bytes');

      // Guardar la imagen procesada en la misma ubicación
      await imageFile.writeAsBytes(compressedBytes);

      developer.log('Imagen procesada guardada en: ${imageFile.path}');
      return imageFile;
    } catch (e) {
      developer.log('Error al procesar imagen: $e', error: e);
      return null;
    }
  }

  /// Compara y reporta la optimización realizada
  Future<void> logOptimizationDetails(File original, File optimized) async {
    try {
      final originalSize = await original.length();
      final optimizedSize = await optimized.length();
      final savingsPercent = ((originalSize - optimizedSize) /
              originalSize *
              100)
          .toStringAsFixed(2);

      developer.log('=== OPTIMIZACIÓN DE IMAGEN ===');
      developer.log(
        'Original: ${original.path} (${_formatFileSize(originalSize)})',
      );
      developer.log(
        'Optimizado: ${optimized.path} (${_formatFileSize(optimizedSize)})',
      );
      developer.log('Reducción: $savingsPercent% de ahorro');
      developer.log('=============================');
    } catch (e) {
      developer.log('Error al registrar detalles de optimización: $e');
    }
  }

  /// Formatea el tamaño de archivo para mejor legibilidad
  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    }
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

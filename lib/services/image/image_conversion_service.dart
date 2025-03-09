import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';

/// Servicio responsable de la conversión entre formatos de imagen
class ImageConversionService {
  final _uuid = const Uuid();

  /// Convierte imagen a base64 para almacenamiento en BD
  Future<String?> imageToBase64(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        developer.log('El archivo no existe: ${imageFile.path}');
        return null;
      }

      final Uint8List bytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(bytes);

      developer.log(
        'Imagen convertida a Base64 (${base64Image.length} caracteres)',
      );
      return base64Image;
    } catch (e) {
      developer.log('Error al convertir imagen a Base64: $e', error: e);
      return null;
    }
  }

  /// Obtiene una imagen desde Base64 (para mostrarla desde la BD)
  Future<File?> base64ToImageFile(String base64Image) async {
    try {
      final Uint8List bytes = base64Decode(base64Image);

      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/${_uuid.v4()}.jpg';

      final File file = File(tempPath);
      await file.writeAsBytes(bytes);

      developer.log('Imagen convertida de Base64 a archivo: ${file.path}');
      return file;
    } catch (e) {
      developer.log('Error al convertir Base64 a imagen: $e', error: e);
      return null;
    }
  }
}

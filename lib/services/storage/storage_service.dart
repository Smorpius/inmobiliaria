import 'dart:io';

/// Interfaz abstracta para servicios de almacenamiento
/// Esta interfaz permite cambiar fácilmente entre almacenamiento local y en la nube
abstract class StorageService {
  /// Guarda una imagen y devuelve su ruta o URI
  Future<String?> saveImage(File image, String folder, String fileName);

  /// Recupera una imagen como un File desde su ruta o URI
  Future<File?> getImage(String path);

  /// Elimina una imagen del almacenamiento
  Future<bool> deleteImage(String path);

  /// Comprueba si una imagen existe
  Future<bool> imageExists(String path);

  /// Obtiene la URL para mostrar una imagen (importante para implementaciones en la nube)
  Future<String> getImageUrl(String path);
}

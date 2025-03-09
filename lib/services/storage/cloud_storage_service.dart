import 'dart:io';
import 'storage_service.dart';

/// Implementación placeholder para almacenamiento en la nube
/// Esta clase se implementará en el futuro cuando migres a un servicio en la nube
class CloudStorageService implements StorageService {
  @override
  Future<String?> saveImage(File image, String folder, String fileName) async {
    // Aquí implementarías la lógica para subir a Firebase Storage, AWS S3, etc.
    throw UnimplementedError('Cloud storage no implementado todavía');
  }

  @override
  Future<File?> getImage(String path) async {
    throw UnimplementedError('Cloud storage no implementado todavía');
  }

  @override
  Future<bool> deleteImage(String path) async {
    throw UnimplementedError('Cloud storage no implementado todavía');
  }

  @override
  Future<bool> imageExists(String path) async {
    throw UnimplementedError('Cloud storage no implementado todavía');
  }

  @override
  Future<String> getImageUrl(String path) async {
    throw UnimplementedError('Cloud storage no implementado todavía');
  }
}

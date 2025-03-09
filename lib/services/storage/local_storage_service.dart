import 'dart:io';
import 'storage_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalStorageService implements StorageService {
  final _uuid = const Uuid();

  /// Directorio base para almacenar imágenes
  Future<Directory> get _baseDir async {
    // En desarrollo, usamos la carpeta del proyecto
    if (kDebugMode) {
      final appDir = await getApplicationDocumentsDirectory();
      final projectDir = Directory('${appDir.path}/inmobiliaria_images');
      if (!await projectDir.exists()) {
        await projectDir.create(recursive: true);
      }
      return projectDir;
    } else {
      // En producción, usamos el directorio de documentos de la app
      final appDir = await getApplicationDocumentsDirectory();
      return appDir;
    }
  }

  @override
  Future<String?> saveImage(File image, String folder, String fileName) async {
    try {
      // Crear el directorio completo si no existe
      final baseDirectory = await _baseDir;
      final folderDir = Directory('${baseDirectory.path}/$folder');
      
      if (!await folderDir.exists()) {
        await folderDir.create(recursive: true);
      }
      
      // Generar un nombre único con timestamp y uuid
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(image.path);
      final uniqueFileName = '${fileName}_${_uuid.v4()}_$timestamp$extension';
      
      // Ruta completa del archivo
      final destinationPath = '${folderDir.path}/$uniqueFileName';
      
      // Copiar el archivo a la ubicación de destino
      await image.copy(destinationPath);
      developer.log('Imagen guardada localmente en: $destinationPath');
      
      // Devolver la ruta para guardarla en la base de datos
      return destinationPath;
    } catch (e) {
      developer.log('Error al guardar imagen localmente: $e', error: e);
      return null;
    }
  }

  @override
  Future<File?> getImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      developer.log('Error al recuperar imagen: $e', error: e);
      return null;
    }
  }

  @override
  Future<bool> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        developer.log('Imagen eliminada: $path');
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error al eliminar imagen: $e', error: e);
      return false;
    }
  }

  @override
  Future<bool> imageExists(String path) async {
    if (path.isEmpty) return false;
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      developer.log('Error al verificar existencia de imagen: $e', error: e);
      return false;
    }
  }

  @override
  Future<String> getImageUrl(String path) async {
    // En almacenamiento local, la ruta del sistema de archivos es la URL
    return path;
  }
}
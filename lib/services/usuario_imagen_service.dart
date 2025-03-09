import 'dart:io';
import 'image_service.dart';
import '../models/usuario.dart';
import '../models/empleado.dart';
import 'dart:developer' as developer;

/// Servicio para manejar las imágenes de usuarios y empleados
class UsuarioImagenService {
  final ImageService _imageService = ImageService();

  /// Carpeta para imágenes de perfil de usuarios
  static const String usuarioFolder = 'usuarios';

  /// Carpeta para imágenes de empleados
  static const String empleadoFolder = 'empleados';

  /// Guarda una imagen para un usuario
  /// Retorna la ruta de la imagen guardada
  Future<String?> saveUsuarioImage(File imageFile, int usuarioId) async {
    try {
      return await _imageService.saveImage(
        imageFile,
        usuarioFolder,
        'usuario_$usuarioId',
      );
    } catch (e) {
      developer.log('Error al guardar imagen de usuario: $e', error: e);
      return null;
    }
  }

  /// Guarda una imagen para un empleado
  /// Retorna la ruta de la imagen guardada
  Future<String?> saveEmpleadoImage(File imageFile, int empleadoId) async {
    try {
      return await _imageService.saveImage(
        imageFile,
        empleadoFolder,
        'empleado_$empleadoId',
      );
    } catch (e) {
      developer.log('Error al guardar imagen de empleado: $e', error: e);
      return null;
    }
  }

  /// Elimina la imagen de un usuario
  Future<bool> deleteUsuarioImage(String? imagePath) async {
    return await _imageService.deleteImage(imagePath);
  }

  /// Elimina la imagen de un empleado
  Future<bool> deleteEmpleadoImage(String? imagePath) async {
    return await _imageService.deleteImage(imagePath);
  }

  /// Actualiza un usuario con una nueva imagen
  /// Si la imagen es nueva, elimina la anterior
  Future<Usuario> updateUsuarioWithImage(
    Usuario usuario,
    File? newImageFile,
  ) async {
    if (newImageFile == null) {
      return usuario;
    }

    try {
      // Eliminar imagen anterior si existe
      if (usuario.imagenPerfil != null && usuario.imagenPerfil!.isNotEmpty) {
        await deleteUsuarioImage(usuario.imagenPerfil);
      }

      // Guardar nueva imagen
      final savedPath = await saveUsuarioImage(
        newImageFile,
        usuario.id ?? 0,
      );

      // Crear un nuevo objeto con la imagen actualizada
      return Usuario(
        id: usuario.id,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        nombreUsuario: usuario.nombreUsuario,
        contrasena: usuario.contrasena,
        correo: usuario.correo,
        imagenPerfil: savedPath, // Actualizado con la nueva ruta
        idEstado: usuario.idEstado,
        estadoNombre: usuario.estadoNombre,
      );
    } catch (e) {
      developer.log('Error al actualizar imagen de usuario: $e', error: e);
      return usuario;
    }
  }

  /// Actualiza un empleado con una nueva imagen
  Future<Empleado> updateEmpleadoWithImage(
    Empleado empleado,
    File? newImageFile,
  ) async {
    if (newImageFile == null) {
      return empleado;
    }

    try {
      // Eliminar imagen anterior si existe
      if (empleado.imagenEmpleado != null &&
          empleado.imagenEmpleado!.isNotEmpty) {
        await deleteEmpleadoImage(empleado.imagenEmpleado);
      }

      // Guardar nueva imagen
      final savedPath = await saveEmpleadoImage(
        newImageFile,
        empleado.id ?? 0,
      );

      // Crear un nuevo objeto con la imagen actualizada
      return Empleado(
        id: empleado.id,
        idUsuario: empleado.idUsuario,
        claveSistema: empleado.claveSistema,
        nombre: empleado.nombre,
        apellidoPaterno: empleado.apellidoPaterno,
        apellidoMaterno: empleado.apellidoMaterno,
        telefono: empleado.telefono,
        correo: empleado.correo,
        direccion: empleado.direccion,
        cargo: empleado.cargo,
        sueldoActual: empleado.sueldoActual,
        fechaContratacion: empleado.fechaContratacion,
        imagenEmpleado: savedPath, // Actualizado con la nueva ruta
        idEstado: empleado.idEstado,
        estadoNombre: empleado.estadoNombre,
      );
    } catch (e) {
      developer.log('Error al actualizar imagen de empleado: $e', error: e);
      return empleado;
    }
  }
}
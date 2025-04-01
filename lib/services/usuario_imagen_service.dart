import 'dart:io';
import 'mysql_helper.dart';
import 'image_service.dart';
import '../models/usuario.dart';
import '../models/empleado.dart';
import '../utils/applogger.dart';

/// Servicio mejorado para manejar las imágenes de usuarios y empleados
class UsuarioImagenService {
  final ImageService _imageService;
  final DatabaseService _db;

  // Control para evitar logs duplicados
  bool _procesandoError = false;

  /// Carpeta para imágenes de perfil de usuarios
  static const String usuarioFolder = 'usuarios';

  /// Carpeta para imágenes de empleados
  static const String empleadoFolder = 'empleados';

  // Constructor con inyección de dependencias para facilitar pruebas
  UsuarioImagenService({ImageService? imageService, DatabaseService? dbService})
    : _imageService = imageService ?? ImageService(),
      _db = dbService ?? DatabaseService();

  /// Guarda una imagen para un usuario y actualiza su registro
  Future<String?> saveUsuarioImage(File imageFile, int usuarioId) async {
    try {
      // Guardar archivo físico primero
      final rutaRelativa = await _imageService.saveImage(
        imageFile,
        usuarioFolder,
        'usuario_$usuarioId',
      );

      if (rutaRelativa != null) {
        // Actualizar referencia en base de datos usando procedimiento almacenado
        final actualizado = await _actualizarReferenciaImagenUsuario(
          usuarioId,
          rutaRelativa,
        );
        if (actualizado) {
          AppLogger.info('Imagen de usuario guardada: $rutaRelativa');
          return rutaRelativa;
        } else {
          // Si falla la actualización en BD, eliminar el archivo
          await _imageService.deleteImage(rutaRelativa);
          return null;
        }
      }
      return null;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al guardar imagen de usuario',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Guarda una imagen para un empleado y actualiza su registro
  Future<String?> saveEmpleadoImage(File imageFile, int empleadoId) async {
    try {
      // Guardar archivo físico primero
      final rutaRelativa = await _imageService.saveImage(
        imageFile,
        empleadoFolder,
        'empleado_$empleadoId',
      );

      if (rutaRelativa != null && empleadoId > 0) {
        // Actualizar referencia en base de datos usando procedimiento almacenado
        final actualizado = await _actualizarReferenciaImagenEmpleado(
          empleadoId,
          rutaRelativa,
        );
        if (actualizado) {
          AppLogger.info('Imagen de empleado guardada: $rutaRelativa');
          return rutaRelativa;
        } else {
          // Si falla la actualización en BD, eliminar el archivo
          await _imageService.deleteImage(rutaRelativa);
          return null;
        }
      }
      return rutaRelativa;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al guardar imagen de empleado',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Actualiza la referencia de imagen de un usuario en la base de datos
  Future<bool> _actualizarReferenciaImagenUsuario(
    int idUsuario,
    String rutaImagen,
  ) async {
    // Solo intentar actualizar si el ID del usuario es válido
    if (idUsuario <= 0) return false;

    try {
      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Buscar primero el usuario para obtener datos actuales
          final userResult = await conn.query('CALL ObtenerUsuarioPorId(?)', [
            idUsuario,
          ]);

          if (userResult.isEmpty) {
            await conn.query('ROLLBACK');
            AppLogger.warning('No se encontró usuario con ID: $idUsuario');
            return false;
          }

          // Los campos necesarios para ActualizarUsuario
          final usuario = userResult.first.fields;

          // Usar el procedimiento almacenado ActualizarUsuario con todos los parámetros requeridos
          await conn.query('CALL ActualizarUsuario(?, ?, ?, ?, ?, ?, ?)', [
            idUsuario,
            usuario['nombre'] ?? '',
            usuario['apellido'] ?? '',
            usuario['nombre_usuario'] ?? '',
            null, // Mantener la contraseña actual (null = no cambiar)
            usuario['correo_cliente'],
            rutaImagen, // Nueva ruta de imagen
          ]);

          await conn.query('COMMIT');
          AppLogger.info(
            'Referencia de imagen actualizada para usuario ID: $idUsuario',
          );
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          if (!_procesandoError) {
            _procesandoError = true;
            AppLogger.error(
              'Error al actualizar referencia de imagen de usuario',
              e,
              StackTrace.current,
            );
            _procesandoError = false;
          }
          return false;
        }
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error de conexión', e, StackTrace.current);
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Actualiza la referencia de imagen de un empleado en la base de datos
  Future<bool> _actualizarReferenciaImagenEmpleado(
    int idEmpleado,
    String rutaImagen,
  ) async {
    // Solo intentar actualizar si el ID del empleado es válido
    if (idEmpleado <= 0) return false;

    try {
      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Buscar primero el empleado para obtener datos actuales
          final empResult = await conn.query('CALL ObtenerEmpleadoUsuario(?)', [
            idEmpleado,
          ]);

          if (empResult.isEmpty) {
            await conn.query('ROLLBACK');
            AppLogger.warning('No se encontró empleado con ID: $idEmpleado');
            return false;
          }

          // Los campos necesarios para ActualizarUsuarioEmpleado
          final empleado = empResult.first.fields;
          final idUsuario = empleado['id_usuario'];

          // Usar el procedimiento almacenado ActualizarUsuarioEmpleado
          await conn.query(
            'CALL ActualizarUsuarioEmpleado(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
              idUsuario,
              idEmpleado,
              empleado['nombre'] ?? '',
              empleado['apellido'] ?? '',
              empleado['nombre_usuario'] ?? '',
              null, // Mantener contraseña actual
              empleado['correo'] ?? '',
              empleado['imagen_perfil'], // Mantener imagen de perfil actual
              empleado['clave_sistema'] ?? '',
              empleado['apellido_materno'] ?? '',
              empleado['telefono'] ?? '',
              empleado['direccion'] ?? '',
              empleado['cargo'] ?? '',
              empleado['sueldo_actual'] ?? 0.0,
              rutaImagen, // Nueva imagen de empleado
            ],
          );

          await conn.query('COMMIT');
          AppLogger.info(
            'Referencia de imagen actualizada para empleado ID: $idEmpleado',
          );
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          if (!_procesandoError) {
            _procesandoError = true;
            AppLogger.error(
              'Error al actualizar referencia de imagen de empleado',
              e,
              StackTrace.current,
            );
            _procesandoError = false;
          }
          return false;
        }
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error de conexión', e, StackTrace.current);
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Elimina la imagen de un usuario
  Future<bool> deleteUsuarioImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return true;

    try {
      // Eliminar el archivo físico mediante ImageService
      final eliminado = await _imageService.deleteImage(imagePath);

      if (eliminado) {
        AppLogger.info('Imagen de usuario eliminada: $imagePath');
      } else {
        AppLogger.warning(
          'No se pudo eliminar la imagen de usuario: $imagePath',
        );
      }

      return eliminado;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al eliminar imagen de usuario',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Elimina la imagen de un empleado
  Future<bool> deleteEmpleadoImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return true;

    try {
      // Eliminar el archivo físico mediante ImageService
      final eliminado = await _imageService.deleteImage(imagePath);

      if (eliminado) {
        AppLogger.info('Imagen de empleado eliminada: $imagePath');
      } else {
        AppLogger.warning(
          'No se pudo eliminar la imagen de empleado: $imagePath',
        );
      }

      return eliminado;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al eliminar imagen de empleado',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Actualiza un usuario con una nueva imagen
  /// Si la imagen es nueva, elimina la anterior
  Future<Usuario> updateUsuarioWithImage(
    Usuario usuario,
    File? newImageFile,
  ) async {
    if (newImageFile == null || usuario.id == null) {
      return usuario;
    }

    try {
      // Eliminar imagen anterior si existe
      if (usuario.imagenPerfil != null && usuario.imagenPerfil!.isNotEmpty) {
        await deleteUsuarioImage(usuario.imagenPerfil);
      }

      // Guardar nueva imagen
      final savedPath = await saveUsuarioImage(newImageFile, usuario.id!);

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
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al actualizar imagen de usuario',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return usuario;
    }
  }

  /// Actualiza un empleado con una nueva imagen
  /// Si la imagen es nueva, elimina la anterior
  Future<Empleado> updateEmpleadoWithImage(
    Empleado empleado,
    File? newImageFile,
  ) async {
    if (newImageFile == null || empleado.id == null) {
      return empleado;
    }

    try {
      // Eliminar imagen anterior si existe
      if (empleado.imagenEmpleado != null &&
          empleado.imagenEmpleado!.isNotEmpty) {
        await deleteEmpleadoImage(empleado.imagenEmpleado);
      }

      // Guardar nueva imagen
      final savedPath = await saveEmpleadoImage(newImageFile, empleado.id!);

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
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al actualizar imagen de empleado',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return empleado;
    }
  }

  /// Obtiene la ruta de imagen de un usuario por su ID
  Future<String?> getUsuarioImagePath(int idUsuario) async {
    try {
      return await _db.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerUsuarioPorId(?)', [
          idUsuario,
        ]);

        if (results.isEmpty) return null;

        return results.first.fields['imagen_perfil'] as String?;
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al obtener ruta de imagen de usuario',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Obtiene la ruta de imagen de un empleado por su ID
  Future<String?> getEmpleadoImagePath(int idEmpleado) async {
    try {
      return await _db.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerEmpleadoUsuario(?)', [
          idEmpleado,
        ]);

        if (results.isEmpty) return null;

        return results.first.fields['imagen_empleado'] as String?;
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al obtener ruta de imagen de empleado',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Limpia imágenes huérfanas que ya no están asociadas a usuarios o empleados
  Future<int> limpiarImagenesHuerfanas() async {
    try {
      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Usar el procedimiento existente para limpiar imágenes huérfanas
          await conn.query(
            'CALL LimpiarImagenesHuerfanas(@imagenes_eliminadas)',
          );

          final result = await conn.query(
            'SELECT @imagenes_eliminadas as eliminadas',
          );
          final int eliminadas =
              result.isNotEmpty ? (result.first['eliminadas'] as int? ?? 0) : 0;

          await conn.query('COMMIT');

          if (eliminadas > 0) {
            AppLogger.info(
              'Limpieza de imágenes huérfanas: $eliminadas eliminadas',
            );
          }

          return eliminadas;
        } catch (e) {
          await conn.query('ROLLBACK');
          if (!_procesandoError) {
            _procesandoError = true;
            AppLogger.error(
              'Error al limpiar imágenes huérfanas',
              e,
              StackTrace.current,
            );
            _procesandoError = false;
          }
          return 0;
        }
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error de conexión al limpiar imágenes huérfanas',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return 0;
    }
  }
}

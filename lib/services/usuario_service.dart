import 'mysql_helper.dart';
import '../models/usuario.dart';
import '../utils/applogger.dart';

class UsuarioService {
  final DatabaseService _db;

  // Control para evitar logs duplicados
  bool _procesandoError = false;

  UsuarioService(this._db);

  /// Verifica si un nombre de usuario ya existe, excluyendo opcionalmente un ID de usuario
  Future<bool> existeNombreUsuario(
    String nombreUsuario, {
    int? idExcluido,
  }) async {
    try {
      AppLogger.info(
        'Verificando si existe el nombre de usuario: $nombreUsuario${idExcluido != null ? ' (excluyendo ID: $idExcluido)' : ''}',
      );

      return await _db.withConnection((conn) async {
        // Usar el procedimiento almacenado correspondiente según si tenemos un ID para excluir
        if (idExcluido != null) {
          // Procedimiento para verificar nombre de usuario excluyendo un ID
          await conn.query(
            'CALL VerificarNombreUsuarioExisteExcluyendoId(?, ?, @existe)',
            [nombreUsuario, idExcluido],
          );
        } else {
          // Procedimiento para verificar nombre de usuario sin exclusión
          await conn.query('CALL VerificarNombreUsuarioExiste(?, @existe)', [
            nombreUsuario,
          ]);
        }

        // Recuperar el valor de la variable de salida @existe
        final resultadoQuery = await conn.query('SELECT @existe as existe');

        if (resultadoQuery.isEmpty) {
          AppLogger.warning(
            'No se obtuvieron resultados al verificar nombre de usuario',
          );
          return false;
        }

        final existe = resultadoQuery.first.fields['existe'] == 1;

        AppLogger.info('Nombre usuario "$nombreUsuario" existe: $existe');
        return existe;
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al verificar existencia de nombre de usuario',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return false; // En caso de error, es más seguro devolver false
    }
  }

  /// Verifica las credenciales de un usuario usando procedimiento almacenado
  Future<bool> verificarCredenciales(
    String nombreUsuario,
    String password,
  ) async {
    try {
      AppLogger.info('Verificando credenciales para usuario: $nombreUsuario');

      return await _db.withConnection((conn) async {
        // Llamar al procedimiento almacenado con variable de salida
        await conn.query('CALL VerificarCredenciales(?, ?, @existe)', [
          nombreUsuario,
          password,
        ]);

        // Obtención del resultado
        final resultadoQuery = await conn.query('SELECT @existe as existe');
        final credencialesValidas =
            resultadoQuery.isNotEmpty &&
            resultadoQuery.first.fields['existe'] == 1;

        AppLogger.info(
          'Resultado de verificación para $nombreUsuario: ${credencialesValidas ? 'válidas' : 'inválidas'}',
        );

        return credencialesValidas;
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al verificar credenciales',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Obtiene un usuario específico por ID utilizando procedimiento almacenado
  Future<Usuario?> getUsuarioPorId(int id) async {
    try {
      AppLogger.info('Buscando usuario con ID: $id');

      return await _db.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerUsuarioPorId(?)', [id]);

        if (results.isEmpty) {
          AppLogger.info('No se encontró usuario con ID: $id');
          return null;
        }

        return Usuario.fromMap(results.first.fields);
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al obtener usuario por ID',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Obtiene todos los usuarios activos utilizando procedimiento almacenado
  Future<List<Usuario>> obtenerUsuarios() async {
    try {
      AppLogger.info('Consultando todos los usuarios');

      return await _db.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerUsuarios()');

        if (results.isEmpty) {
          AppLogger.info('No se encontraron usuarios');
          return [];
        }

        final List<Usuario> usuariosList = [];
        for (var row in results) {
          try {
            final usuario = Usuario.fromMap(row.fields);
            usuariosList.add(usuario);
          } catch (e) {
            AppLogger.warning(
              'Error al procesar usuario: ${row.fields['nombre_usuario'] ?? "desconocido"}: $e',
            );
          }
        }

        return usuariosList;
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al obtener usuarios', e, StackTrace.current);
        _procesandoError = false;
      }
      return [];
    }
  }

  /// Actualiza el perfil de un usuario utilizando procedimiento almacenado
  Future<bool> actualizarPerfilUsuario(Usuario usuario) async {
    try {
      if (usuario.id == null) {
        throw Exception('ID de usuario no proporcionado');
      }

      AppLogger.info('Actualizando perfil de usuario ID: ${usuario.id}');

      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Verificar que el nombre de usuario no esté en uso por otro usuario
          if (usuario.nombreUsuario.isNotEmpty) {
            await conn.query(
              'CALL VerificarNombreUsuarioExisteExcluyendoId(?, ?, @existe)',
              [usuario.nombreUsuario, usuario.id],
            );

            final existeResult = await conn.query('SELECT @existe as existe');
            if (existeResult.isNotEmpty &&
                existeResult.first.fields['existe'] == 1) {
              await conn.query('ROLLBACK');
              throw Exception(
                'El nombre de usuario ya está en uso por otro usuario',
              );
            }
          }

          // Actualizar usuario usando el procedimiento almacenado
          await conn.query('CALL ActualizarUsuario(?, ?, ?, ?, ?, ?, ?)', [
            usuario.id,
            usuario.nombre,
            usuario.apellido,
            usuario.nombreUsuario,
            usuario.contrasena.isNotEmpty ? usuario.contrasena : null,
            usuario.correo,
            usuario.imagenPerfil,
          ]);

          await conn.query('COMMIT');
          AppLogger.info('Perfil de usuario actualizado exitosamente');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          if (!_procesandoError) {
            _procesandoError = true;
            AppLogger.error(
              'Error al actualizar perfil de usuario',
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
        AppLogger.error(
          'Error al procesar actualización de perfil',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Verifica la conexión a la base de datos
  Future<bool> verificarConexion() async {
    try {
      return await _db.withConnection((conn) async {
        try {
          final results = await conn.query('CALL VerificarConexion()');

          if (results.isEmpty) {
            // Método alternativo por seguridad
            final testResult = await conn.query('SELECT 1 as test');
            return testResult.isNotEmpty;
          }

          return results.first.fields['test'] == 1;
        } catch (e) {
          AppLogger.warning('Error en verificación de conexión: $e');
          return false;
        }
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al verificar conexión a la base de datos',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return false;
    }
  }
}

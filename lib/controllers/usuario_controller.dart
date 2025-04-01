import '../models/usuario.dart';
import '../utils/applogger.dart';
import '../services/mysql_helper.dart';

class UsuarioController {
  final DatabaseService _dbService;

  // Control para evitar logs duplicados en consola
  bool _procesandoError = false;

  UsuarioController({DatabaseService? dbService})
    : _dbService = dbService ?? DatabaseService();

  // Método auxiliar para ejecutar operaciones con manejo de errores consistente
  Future<T> _ejecutarOperacion<T>(
    String descripcion,
    Future<T> Function() operacion,
  ) async {
    try {
      AppLogger.info('Iniciando operación: $descripcion');
      final resultado = await operacion();
      AppLogger.info('Operación completada: $descripcion');
      return resultado;
    } catch (e, stackTrace) {
      // Evitar logs duplicados para el mismo error
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error en operación "$descripcion"', e, stackTrace);
        _procesandoError = false;
      }
      throw Exception('Error en $descripcion: $e');
    }
  }

  // Crear un nuevo usuario usando procedimiento almacenado
  Future<int> insertUsuario(Usuario usuario) async {
    return _ejecutarOperacion('insertar usuario', () async {
      return await _dbService.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Verificar si el nombre de usuario ya existe
          await conn.query('CALL VerificarNombreUsuarioExiste(?, @existe)', [
            usuario.nombreUsuario,
          ]);

          final existeResult = await conn.query('SELECT @existe as existe');
          if (existeResult.isNotEmpty &&
              existeResult.first.fields['existe'] == 1) {
            await conn.query('ROLLBACK');
            throw Exception('El nombre de usuario ya existe');
          }

          // Llamar al procedimiento almacenado para crear usuario
          await conn
              .query('CALL CrearUsuario(?, ?, ?, ?, ?, ?, @id_usuario_out)', [
                usuario.nombre,
                usuario.apellido,
                usuario.nombreUsuario,
                usuario.contrasena,
                usuario.correo,
                usuario.imagenPerfil,
              ]);

          // Obtener el ID generado
          final idResult = await conn.query('SELECT @id_usuario_out as id');

          if (idResult.isEmpty || idResult.first['id'] == null) {
            AppLogger.warning(
              'No se pudo obtener ID con variable OUT, intentando con LAST_INSERT_ID()',
            );

            final altResult = await conn.query('SELECT LAST_INSERT_ID() as id');
            if (altResult.isEmpty || altResult.first['id'] == null) {
              await conn.query('ROLLBACK');
              throw Exception('No se pudo obtener ID del usuario creado');
            }

            final idUsuario = altResult.first['id'] as int;
            await conn.query('COMMIT');
            AppLogger.info('Usuario insertado con ID alternativo: $idUsuario');
            return idUsuario;
          }

          final idUsuario = idResult.first['id'] as int;
          await conn.query('COMMIT');
          AppLogger.info('Usuario insertado con ID: $idUsuario');
          return idUsuario;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error('Error al insertar usuario', e, StackTrace.current);
          rethrow;
        }
      });
    });
  }

  // Obtener todos los usuarios usando procedimiento almacenado
  Future<List<Usuario>> getUsuarios() async {
    return _ejecutarOperacion('obtener usuarios', () async {
      return await _dbService.withConnection((conn) async {
        AppLogger.info('Consultando todos los usuarios');
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
              'Error al procesar usuario: ${row.fields['nombre_usuario']}: $e',
            );
          }
        }

        return usuariosList;
      });
    });
  }

  // Obtener un usuario por ID usando procedimiento almacenado
  Future<Usuario?> getUsuario(int id) async {
    return _ejecutarOperacion('obtener usuario por ID', () async {
      return await _dbService.withConnection((conn) async {
        AppLogger.info('Buscando usuario con ID: $id');
        final results = await conn.query('CALL ObtenerUsuarioPorId(?)', [id]);

        if (results.isEmpty) {
          AppLogger.info('No se encontró usuario con ID: $id');
          return null;
        }

        return Usuario.fromMap(results.first.fields);
      });
    });
  }

  // Verificar credenciales de usuario usando procedimiento almacenado
  Future<bool> verificarCredenciales(String username, String password) async {
    return _ejecutarOperacion('verificar credenciales', () async {
      return await _dbService.withConnection((conn) async {
        AppLogger.info('Verificando credenciales para usuario: $username');

        // Llamar al procedimiento con variable de salida
        await conn.query('CALL VerificarCredenciales(?, ?, @existe)', [
          username,
          password,
        ]);

        // Obtención del resultado
        final resultadoQuery = await conn.query('SELECT @existe as existe');
        final credencialesValidas =
            resultadoQuery.isNotEmpty &&
            resultadoQuery.first.fields['existe'] == 1;

        AppLogger.info(
          'Resultado de verificación de credenciales para $username: ${credencialesValidas ? 'válidas' : 'inválidas'}',
        );

        return credencialesValidas;
      });
    });
  }

  // Actualizar un usuario usando procedimiento almacenado
  Future<int> updateUsuario(Usuario usuario) async {
    return _ejecutarOperacion('actualizar usuario', () async {
      if (usuario.id == null) {
        throw Exception('ID de usuario no proporcionado');
      }

      return await _dbService.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Si el nombre de usuario cambió, verificar que no exista
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

          var result = await conn
              .query('CALL ActualizarUsuario(?, ?, ?, ?, ?, ?, ?)', [
                usuario.id,
                usuario.nombre,
                usuario.apellido,
                usuario.nombreUsuario,
                usuario.contrasena.isNotEmpty ? usuario.contrasena : null,
                usuario.correo,
                usuario.imagenPerfil,
              ]);

          await conn.query('COMMIT');
          AppLogger.info('Usuario actualizado exitosamente: ID=${usuario.id}');
          return result.affectedRows ?? 0;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error('Error al actualizar usuario', e, StackTrace.current);
          rethrow;
        }
      });
    });
  }

  // Inactivar un usuario usando procedimiento almacenado
  Future<int> inactivarUsuario(int id) async {
    return _ejecutarOperacion('inactivar usuario', () async {
      return await _dbService.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          var result = await conn.query('CALL InactivarUsuario(?)', [id]);
          await conn.query('COMMIT');

          AppLogger.info('Usuario inactivado: ID=$id');
          return result.affectedRows ?? 0;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error('Error al inactivar usuario', e, StackTrace.current);
          rethrow;
        }
      });
    });
  }

  // Reactivar un usuario usando procedimiento almacenado
  Future<int> reactivarUsuario(int id) async {
    return _ejecutarOperacion('reactivar usuario', () async {
      return await _dbService.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          var result = await conn.query('CALL ReactivarUsuario(?)', [id]);
          await conn.query('COMMIT');

          AppLogger.info('Usuario reactivado: ID=$id');
          return result.affectedRows ?? 0;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error('Error al reactivar usuario', e, StackTrace.current);
          rethrow;
        }
      });
    });
  }

  // Verificar si un nombre de usuario ya existe
  Future<bool> existeNombreUsuario(
    String nombreUsuario, {
    int? idExcluido,
  }) async {
    return _ejecutarOperacion(
      'verificar existencia de nombre de usuario',
      () async {
        return await _dbService.withConnection((conn) async {
          if (idExcluido != null) {
            await conn.query(
              'CALL VerificarNombreUsuarioExisteExcluyendoId(?, ?, @existe)',
              [nombreUsuario, idExcluido],
            );
          } else {
            await conn.query('CALL VerificarNombreUsuarioExiste(?, @existe)', [
              nombreUsuario,
            ]);
          }

          final resultadoQuery = await conn.query('SELECT @existe as existe');
          final existe =
              resultadoQuery.isNotEmpty &&
              resultadoQuery.first.fields['existe'] == 1;

          AppLogger.info(
            'El nombre de usuario "$nombreUsuario" ${existe ? "ya existe" : "está disponible"}',
          );
          return existe;
        });
      },
    );
  }
}

import 'mysql_helper.dart';
import 'dart:developer' as developer;

class UsuarioService {
  final DatabaseService _db;

  UsuarioService(this._db);

  /// Verifica si un nombre de usuario ya existe, excluyendo opcionalmente un ID de usuario
  Future<bool> existeNombreUsuario(
    String nombreUsuario, {
    int? idExcluido,
  }) async {
    try {
      developer.log(
        'Verificando si existe el nombre de usuario: $nombreUsuario${idExcluido != null ? ' (excluyendo ID: $idExcluido)' : ''}',
      );

      final conn = await _db.connection;

      // Consulta diferente según si tenemos un ID para excluir
      final results =
          idExcluido != null
              ? await conn.query(
                'SELECT COUNT(*) as count FROM usuarios WHERE nombre_usuario = ? AND id_usuario <> ?',
                [nombreUsuario, idExcluido],
              )
              : await conn.query(
                'SELECT COUNT(*) as count FROM usuarios WHERE nombre_usuario = ?',
                [nombreUsuario],
              );

      if (results.isEmpty) {
        developer.log(
          'No se obtuvieron resultados al verificar nombre de usuario',
        );
        return false;
      }

      int count = results.first.fields['count'] as int;
      developer.log('Nombre usuario "$nombreUsuario" existe: ${count > 0}');
      return count > 0;
    } catch (e) {
      developer.log(
        'Error al verificar existencia de nombre de usuario: $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false; // En caso de error, es más seguro devolver false
    }
  }
}

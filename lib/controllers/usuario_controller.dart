import 'package:mysql1/mysql1.dart';
import '../models/usuario_model.dart';
import '../services/mysql_helper.dart';

class UsuarioController {
  final DatabaseService _dbService = DatabaseService();

  Future<int> insertUsuario(Usuario usuario) async {
    final conn = await _dbService.connection;

    try {
      // Use prepared statement with named parameters
      var result = await conn.query('CALL CrearUsuario(?, ?, ?, ?)', [
        usuario.nombre,
        usuario.apellido,
        usuario.nombreUsuario,
        usuario.contrasena,
      ]);

      return result.insertId ?? -1;
    } catch (e) {
      print('Error al insertar usuario: $e');
      return -1;
    }
  }

  Future<List<Usuario>> getUsuarios() async {
    final conn = await _dbService.connection;

    var results = await conn.query('SELECT * FROM usuarios');

    return results.map((row) => Usuario.fromMap(row.fields)).toList();
  }

  Future<Usuario?> getUsuario(int id) async {
    final conn = await _dbService.connection;

    var results = await conn.query(
      'SELECT * FROM usuarios WHERE id_usuario = ?',
      [id],
    );

    return results.isNotEmpty ? Usuario.fromMap(results.first.fields) : null;
  }

  Future<bool> verificarCredenciales(String username, String password) async {
    final conn = await _dbService.connection;

    var results = await conn.query(
      'SELECT * FROM usuarios WHERE nombre_usuario = ? AND contraseña_usuario = ?',
      [username, password],
    );

    return results.isNotEmpty;
  }

  // New method to update user
  Future<int> updateUsuario(Usuario usuario) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn.query('CALL ActualizarUsuario(?, ?, ?, ?, ?)', [
        usuario.id,
        usuario.nombre,
        usuario.apellido,
        usuario.nombreUsuario,
        usuario.contrasena,
      ]);

      return result.affectedRows ?? 0;
    } catch (e) {
      print('Error al actualizar usuario: $e');
      return 0;
    }
  }

  // New method to inactivate user
  Future<int> inactivarUsuario(int id) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn.query('CALL InactivarUsuario(?)', [id]);

      return result.affectedRows ?? 0;
    } catch (e) {
      print('Error al inactivar usuario: $e');
      return 0;
    }
  }
}

import 'package:mysql1/mysql1.dart';
import '../models/usuario_model.dart';
import '../services/database_service.dart';

class UsuarioController {
  final DatabaseService _dbService = DatabaseService();

  Future<int> insertUsuario(Usuario usuario) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn.query(
        'INSERT INTO usuarios (nombre, apellido, nombre_usuario, contraseña_usuario, correo_cliente) VALUES (?, ?, ?, ?, ?)',
        [
          usuario.nombre,
          usuario.apellido,
          usuario.nombreUsuario,
          usuario.contrasena,
          usuario.correo,
        ],
      );

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
}

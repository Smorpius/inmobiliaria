import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../models/usuario_model.dart';
// lib/controllers/usuario_controller.dart

class UsuarioController {
  final dbHelper = DatabaseHelper();

  // Crear un nuevo usuario
  Future<int> insertUsuario(Usuario usuario) async {
    final db = await dbHelper.database;
    return await db.insert('Usuarios', usuario.toMap());
  }

  // Obtener todos los usuarios
  Future<List<Usuario>> getUsuarios() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('Usuarios');

    return List.generate(maps.length, (i) {
      return Usuario.fromMap(maps[i]);
    });
  }

  // Obtener un usuario por ID
  Future<Usuario?> getUsuario(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Usuarios',
      where: 'id_usuario = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    }
    return null;
  }

  // Buscar usuario por nombre de usuario
  Future<Usuario?> findUsuarioByUsername(String username) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Usuarios',
      where: 'nombre_usuario = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    }
    return null;
  }

  // Actualizar usuario
  Future<int> updateUsuario(Usuario usuario) async {
    final db = await dbHelper.database;
    return await db.update(
      'Usuarios',
      usuario.toMap(),
      where: 'id_usuario = ?',
      whereArgs: [usuario.id],
    );
  }

  // Eliminar usuario
  Future<int> deleteUsuario(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Usuarios',
      where: 'id_usuario = ?',
      whereArgs: [id],
    );
  }

  // Verificar credenciales para inicio de sesión
  Future<bool> verificarCredenciales(String username, String password) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'Usuarios',
      where: 'nombre_usuario = ? AND contraseña_usuario = ?',
      whereArgs: [username, password],
    );

    return result.isNotEmpty;
  }
}

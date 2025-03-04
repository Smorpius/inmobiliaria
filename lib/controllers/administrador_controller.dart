import 'package:sqflite/sqflite.dart';
import '../services/mysql_helper.dart';
import '../models/administrador_model.dart';
// lib/controllers/administrador_controller.dart

class AdministradorController {
  final dbHelper = DatabaseHelper();

  // Verificar credenciales de administrador
  Future<bool> verificarCredenciales(
    String nombreAdmin,
    String contrasena,
  ) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'ADMINISTRADOR',
      where: 'NombreAdmin = ? AND Contraseña = ?',
      whereArgs: [nombreAdmin, contrasena],
    );

    return result.isNotEmpty;
  }

  // Obtener todos los administradores
  Future<List<Administrador>> getAdministradores() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('ADMINISTRADOR');

    return List.generate(maps.length, (i) {
      return Administrador.fromMap(maps[i]);
    });
  }

  // Insertar nuevo administrador
  Future<int> insertAdministrador(Administrador administrador) async {
    final db = await dbHelper.database;
    return await db.insert('ADMINISTRADOR', administrador.toMap());
  }

  // Actualizar contraseña del administrador
  Future<int> updateContrasena(
    String nombreAdmin,
    String nuevaContrasena,
  ) async {
    final db = await dbHelper.database;
    return await db.update(
      'ADMINISTRADOR',
      {'Contraseña': nuevaContrasena},
      where: 'NombreAdmin = ?',
      whereArgs: [nombreAdmin],
    );
  }
}

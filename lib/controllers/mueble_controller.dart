import 'database_helper.dart';
import '../models/mueble_model.dart';
import 'package:sqflite/sqflite.dart';
// lib/controllers/mueble_controller.dart

class MuebleController {
  final dbHelper = DatabaseHelper();

  // Crear un nuevo mueble
  Future<int> insertMueble(Mueble mueble) async {
    final db = await dbHelper.database;
    return await db.insert('MUEBLES', mueble.toMap());
  }

  // Obtener todos los muebles
  Future<List<Mueble>> getMuebles() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('MUEBLES');

    return List.generate(maps.length, (i) {
      return Mueble.fromMap(maps[i]);
    });
  }

  // Obtener un mueble por ID
  Future<Mueble?> getMueble(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'MUEBLES',
      where: 'ID_muebles = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Mueble.fromMap(maps.first);
    }
    return null;
  }

  // Obtener muebles por cliente
  Future<List<Mueble>> getMueblesByCliente(int clienteId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'MUEBLES',
      where: 'id_cliente = ?',
      whereArgs: [clienteId],
    );

    return List.generate(maps.length, (i) {
      return Mueble.fromMap(maps[i]);
    });
  }

  // Actualizar mueble
  Future<int> updateMueble(Mueble mueble) async {
    final db = await dbHelper.database;
    return await db.update(
      'MUEBLES',
      mueble.toMap(),
      where: 'ID_muebles = ?',
      whereArgs: [mueble.id],
    );
  }

  // Eliminar mueble
  Future<int> deleteMueble(int id) async {
    final db = await dbHelper.database;
    return await db.delete('MUEBLES', where: 'ID_muebles = ?', whereArgs: [id]);
  }
}

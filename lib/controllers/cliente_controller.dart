import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cliente_model.dart';
// lib/controllers/cliente_controller.dart

class ClienteController {
  final dbHelper = DatabaseHelper();

  // Crear un nuevo cliente
  Future<int> insertCliente(Cliente cliente) async {
    final db = await dbHelper.database;
    return await db.insert('Clientes', cliente.toMap());
  }

  // Obtener todos los clientes
  Future<List<Cliente>> getClientes() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('Clientes');

    return List.generate(maps.length, (i) {
      return Cliente.fromMap(maps[i]);
    });
  }

  // Obtener un cliente por ID
  Future<Cliente?> getCliente(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Clientes',
      where: 'ID_Cliente = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Cliente.fromMap(maps.first);
    }
    return null;
  }

  // Buscar clientes por nombre
  Future<List<Cliente>> searchClientesByName(String name) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Clientes',
      where: 'nombre_cliente LIKE ?',
      whereArgs: ['%$name%'],
    );

    return List.generate(maps.length, (i) {
      return Cliente.fromMap(maps[i]);
    });
  }

  // Actualizar cliente
  Future<int> updateCliente(Cliente cliente) async {
    final db = await dbHelper.database;
    return await db.update(
      'Clientes',
      cliente.toMap(),
      where: 'ID_Cliente = ?',
      whereArgs: [cliente.id],
    );
  }

  // Eliminar cliente
  Future<int> deleteCliente(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Clientes',
      where: 'ID_Cliente = ?',
      whereArgs: [id],
    );
  }
}

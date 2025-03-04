import '../models/cliente_model.dart';
import '../services/mysql_helper.dart';

class ClienteController {
  final DatabaseService _dbService = DatabaseService();

  // Crear un nuevo cliente
  Future<int> insertCliente(Cliente cliente) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn.query(
        'INSERT INTO clientes (nombre_cliente, id_direccion, telefono_cliente, rfc, curp, correo_cliente) VALUES (?, ?, ?, ?, ?, ?)',
        [
          cliente.nombre,
          cliente.idDireccion,
          cliente.telefono,
          cliente.rfc,
          cliente.curp,
          cliente.correo,
        ],
      );

      return result.insertId ?? -1;
    } catch (e) {
      print('Error al insertar cliente: $e');
      return -1;
    }
  }

  // Obtener todos los clientes
  Future<List<Cliente>> getClientes() async {
    final conn = await _dbService.connection;

    var results = await conn.query('SELECT * FROM clientes');

    return results.map((row) => Cliente.fromMap(row.fields)).toList();
  }

  // Obtener un cliente por ID
  Future<Cliente?> getCliente(int id) async {
    final conn = await _dbService.connection;

    var results = await conn.query(
      'SELECT * FROM clientes WHERE id_cliente = ?',
      [id],
    );

    return results.isNotEmpty ? Cliente.fromMap(results.first.fields) : null;
  }

  // Buscar clientes por nombre
  Future<List<Cliente>> searchClientesByName(String name) async {
    final conn = await _dbService.connection;

    var results = await conn.query(
      'SELECT * FROM clientes WHERE nombre_cliente LIKE ?',
      ['%$name%'],
    );

    return results.map((row) => Cliente.fromMap(row.fields)).toList();
  }

  // Actualizar cliente
  Future<int> updateCliente(Cliente cliente) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn.query(
        'UPDATE clientes SET nombre_cliente = ?, id_direccion = ?, telefono_cliente = ?, rfc = ?, curp = ?, correo_cliente = ? WHERE id_cliente = ?',
        [
          cliente.nombre,
          cliente.idDireccion,
          cliente.telefono,
          cliente.rfc,
          cliente.curp,
          cliente.correo,
          cliente.id,
        ],
      );

      return result.affectedRows ?? 0;
    } catch (e) {
      print('Error al actualizar cliente: $e');
      return 0;
    }
  }

  // Eliminar cliente
  Future<int> deleteCliente(int id) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn.query(
        'DELETE FROM clientes WHERE id_cliente = ?',
        [id],
      );

      return result.affectedRows ?? 0;
    } catch (e) {
      print('Error al eliminar cliente: $e');
      return 0;
    }
  }
}

import '../models/cliente_model.dart';
import '../services/mysql_helper.dart';

class ClienteController {
  final DatabaseService _dbService = DatabaseService();

  // Crear un nuevo cliente usando un stored procedure
  Future<int> insertCliente(Cliente cliente) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn.query('CALL CrearCliente(?, ?, ?, ?, ?, ?)', [
        cliente.nombre,
        cliente.telefono,
        cliente.rfc,
        cliente.curp,
        cliente.correo,
        cliente.idDireccion,
      ]);

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

  // Obtener un cliente por RFC (usando el stored procedure del SQL)
  Future<Cliente?> getClientePorRFC(String rfc) async {
    final conn = await _dbService.connection;

    var results = await conn.query('CALL BuscarClientePorRFC(?)', [rfc]);

    return results.isNotEmpty ? Cliente.fromMap(results.first.fields) : null;
  }

  // Actualizar cliente usando stored procedure
  Future<int> updateCliente(Cliente cliente) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn
          .query('CALL ActualizarCliente(?, ?, ?, ?, ?, ?)', [
            cliente.id,
            cliente.nombre,
            cliente.telefono,
            cliente.rfc,
            cliente.curp,
            cliente.correo,
          ]);

      return result.affectedRows ?? 0;
    } catch (e) {
      print('Error al actualizar cliente: $e');
      return 0;
    }
  }

  // Inactivar cliente
  Future<int> inactivarCliente(int id) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn.query('CALL InactivarCliente(?)', [id]);

      return result.affectedRows ?? 0;
    } catch (e) {
      print('Error al inactivar cliente: $e');
      return 0;
    }
  }
}

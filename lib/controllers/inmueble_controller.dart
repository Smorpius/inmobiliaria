import '../models/inmueble_model.dart';
import '../services/mysql_helper.dart';

class InmuebleController {
  final dbHelper = DatabaseService();

  // Crear un nuevo inmueble
  Future<int> insertInmueble(Inmueble inmueble) async {
    final db = await dbHelper.connection;
    final result = await db.query(
      'INSERT INTO INMUEBLES (nombre_inmueble, id_direccion, monto_total, id_estado, id_cliente) VALUES (?, ?, ?, ?, ?)',
      [
        inmueble.nombre,
        inmueble.idDireccion,
        inmueble.montoTotal,
        inmueble.idEstado,
        inmueble.idCliente,
      ],
    );
    return result.affectedRows ?? 0;
  }

  // Obtener todos los inmuebles
  Future<List<Inmueble>> getInmuebles() async {
    final db = await dbHelper.connection;
    final results = await db.query('SELECT * FROM INMUEBLES');

    return results.map((row) => Inmueble.fromMap(row.fields)).toList();
  }

  // Obtener un inmueble por ID
  Future<Inmueble?> getInmueble(int id) async {
    final db = await dbHelper.connection;
    final results = await db.query(
      'SELECT * FROM INMUEBLES WHERE ID_inmuebles = ?',
      [id],
    );

    if (results.isNotEmpty) {
      return Inmueble.fromMap(results.first.fields);
    }
    return null;
  }

  // Obtener inmuebles por cliente
  Future<List<Inmueble>> getInmueblesByCliente(int clienteId) async {
    final db = await dbHelper.connection;
    final results = await db.query(
      'SELECT * FROM INMUEBLES WHERE id_cliente = ?',
      [clienteId],
    );

    return results.map((row) => Inmueble.fromMap(row.fields)).toList();
  }

  // Actualizar inmueble
  Future<int> updateInmueble(Inmueble inmueble) async {
    final db = await dbHelper.connection;
    final result = await db.query(
      'UPDATE INMUEBLES SET nombre_inmueble = ?, id_direccion = ?, monto_total = ?, id_estado = ?, id_cliente = ? WHERE ID_inmuebles = ?',
      [
        inmueble.nombre,
        inmueble.idDireccion,
        inmueble.montoTotal,
        inmueble.idEstado,
        inmueble.idCliente,
        inmueble.id,
      ],
    );
    return result.affectedRows ?? 0;
  }

  // Eliminar inmueble
  Future<int> deleteInmueble(int id) async {
    final db = await dbHelper.connection;
    final result = await db.query(
      'DELETE FROM INMUEBLES WHERE ID_inmuebles = ?',
      [id],
    );
    return result.affectedRows ?? 0;
  }
}

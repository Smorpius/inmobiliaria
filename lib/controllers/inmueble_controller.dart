import 'dart:async';
import 'package:logging/logging.dart';
import '../models/inmueble_model.dart';
import '../services/mysql_helper.dart';

class InmuebleController {
  final DatabaseService dbHelper;
  final Logger _logger = Logger('InmuebleController');

  InmuebleController({DatabaseService? dbService})
    : dbHelper = dbService ?? DatabaseService();

  Future<List<Inmueble>> getInmuebles() async {
    try {
      _logger.info('Iniciando consulta de inmuebles...');
      final db = await dbHelper.connection;

      final results = await db.query('''
        SELECT 
          i.id_inmueble, 
          i.nombre_inmueble, 
          i.id_direccion, 
          i.monto_total, 
          i.id_estado, 
          i.id_cliente,
          i.fecha_registro
        FROM inmuebles i
        WHERE i.id_estado = 1
        ORDER BY i.fecha_registro DESC
      ''');

      _logger.info('Resultados obtenidos: ${results.length} inmuebles');

      if (results.isNotEmpty) {
        _logger.info('Primer registro: ${results.first.fields}');
      }

      final List<Inmueble> inmuebles = [];

      for (var row in results) {
        try {
          final inmueble = Inmueble.fromMap(row.fields);
          inmuebles.add(inmueble);
          _logger.fine('Inmueble procesado: $inmueble');
        } catch (e) {
          _logger.warning(
            'Error procesando inmueble: ${row.fields}, error: $e',
          );
        }
      }

      _logger.info('Inmuebles procesados: ${inmuebles.length}');
      return inmuebles;
    } catch (e) {
      _logger.severe('Error al obtener inmuebles: $e');
      _logger.severe('Error detallado al obtener inmuebles: $e');
      return [];
    }
  }

  Future<int> insertInmueble(Inmueble inmueble) async {
    try {
      _logger.info('Insertando inmueble: $inmueble');
      final db = await dbHelper.connection;

      final result = await db.query(
        '''
        INSERT INTO inmuebles (
          nombre_inmueble, 
          id_direccion, 
          monto_total, 
          id_estado, 
          id_cliente,
          fecha_registro
        ) VALUES (?, ?, ?, ?, ?, NOW())
      ''',
        [
          inmueble.nombre,
          inmueble.idDireccion,
          inmueble.montoTotal,
          inmueble.idEstado ?? 1,
          inmueble.idCliente,
        ],
      );

      _logger.info(
        'Inmueble insertado: ID=${result.insertId}, Filas afectadas=${result.affectedRows}',
      );
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al insertar inmueble: $e');
      throw Exception('Error al insertar inmueble: $e');
    }
  }

  Future<int> updateInmueble(Inmueble inmueble) async {
    try {
      _logger.info('Actualizando inmueble: $inmueble');
      final db = await dbHelper.connection;

      final result = await db.query(
        '''
        UPDATE inmuebles
        SET 
          nombre_inmueble = ?,
          monto_total = ?,
          id_estado = ?,
          id_cliente = ?
        WHERE id_inmueble = ?
      ''',
        [
          inmueble.nombre,
          inmueble.montoTotal,
          inmueble.idEstado ?? 1,
          inmueble.idCliente,
          inmueble.id,
        ],
      );

      _logger.info(
        'Inmueble actualizado: ID=${inmueble.id}, Filas afectadas=${result.affectedRows}',
      );
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al actualizar inmueble: $e');
      throw Exception('Error al actualizar inmueble: $e');
    }
  }

  Future<int> deleteInmueble(int id) async {
    try {
      _logger.info('Eliminando inmueble con ID: $id');
      final db = await dbHelper.connection;

      final result = await db.query(
        'DELETE FROM inmuebles WHERE id_inmueble = ?',
        [id],
      );

      _logger.info(
        'Inmueble eliminado: ID=$id, Filas afectadas=${result.affectedRows}',
      );
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al eliminar inmueble: $e');
      throw Exception('Error al eliminar inmueble: $e');
    }
  }

  Future<bool> verificarExistenciaInmueble(int id) async {
    try {
      _logger.info('Verificando existencia del inmueble con ID: $id');
      final db = await dbHelper.connection;

      final result = await db.query(
        'SELECT COUNT(*) as count FROM inmuebles WHERE id_inmueble = ?',
        [id],
      );

      final int count = result.first.fields['count'] as int;
      _logger.info('¿Inmueble $id existe? ${count > 0}');
      return count > 0;
    } catch (e) {
      _logger.warning('Error al verificar existencia de inmueble: $e');
      return false;
    }
  }
}

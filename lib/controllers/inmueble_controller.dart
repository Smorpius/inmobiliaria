import 'dart:async';
import '../models/inmueble_model.dart';
import '../services/mysql_helper.dart';
import 'package:logging/logging.dart'; // Importar paquete de logging

class InmuebleController {
  final DatabaseService dbHelper;
  final Logger _logger = Logger('InmuebleController'); // Crear instancia de logger

  // Constructor con inyección de dependencias para facilitar pruebas unitarias
  InmuebleController({DatabaseService? dbService}) 
      : dbHelper = dbService ?? DatabaseService();

  // Crear un nuevo inmueble usando SQL directo
  Future<int> insertInmueble(Inmueble inmueble) async {
    try {
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
    } catch (e) {
      _logger.severe('Error al insertar inmueble: $e');
      rethrow; // Propagar el error para manejo en la UI
    }
  }

  // Crear un nuevo inmueble usando el procedimiento almacenado
  Future<int> insertInmuebleUsingStoredProc(
      String nombre,
      String calle,
      String numero,
      String ciudad,
      int idEstado,
      String codigoPostal,
      double montoTotal,
      String estatusInmueble,
      int? idCliente) async {
    try {
      final db = await dbHelper.connection;
      final result = await db.query(
        'CALL CrearInmueble(?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          nombre,
          calle,
          numero,
          ciudad,
          idEstado,
          codigoPostal,
          montoTotal,
          estatusInmueble,
          idCliente
        ],
      );
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al insertar inmueble con procedimiento: $e');
      rethrow;
    }
  }

  // Obtener todos los inmuebles
  Future<List<Inmueble>> getInmuebles() async {
    try {
      final db = await dbHelper.connection;
      final results = await db.query('SELECT * FROM INMUEBLES');
      return results.map((row) => Inmueble.fromMap(row.fields)).toList();
    } catch (e) {
      _logger.warning('Error al obtener inmuebles: $e');
      return []; // Retornar lista vacía en caso de error
    }
  }

  // Obtener un inmueble por ID
  Future<Inmueble?> getInmueble(int id) async {
    try {
      final db = await dbHelper.connection;
      final results = await db.query(
        'SELECT * FROM INMUEBLES WHERE id_inmueble = ?',
        [id],
      );

      if (results.isNotEmpty) {
        return Inmueble.fromMap(results.first.fields);
      }
      return null;
    } catch (e) {
      _logger.warning('Error al obtener inmueble por ID: $e');
      return null;
    }
  }

  // Obtener inmuebles por cliente usando procedimiento almacenado
  Future<List<Inmueble>> getInmueblesByCliente(int clienteId) async {
    try {
      final db = await dbHelper.connection;
      final results = await db.query(
        'CALL BuscarInmueblePorCliente(?)',
        [clienteId],
      );

      // Corregido: Tratamos results como un conjunto de resultados
      if (results.isNotEmpty) {
        // Para procedimientos almacenados, necesitamos acceder a los resultados de manera diferente
        // Dependiendo de la estructura exacta de la respuesta, ajustar según sea necesario
        return results.fold<List<Inmueble>>([], (list, resultSet) {
          list.addAll(resultSet.map((row) => Inmueble.fromMap(row.fields)));
          return list;
        });
      }
      return [];
    } catch (e) {
      _logger.warning('Error al obtener inmuebles por cliente: $e');
      return [];
    }
  }

  // Método alternativo usando SQL directo si hay problemas con el proc almacenado
  Future<List<Inmueble>> getInmueblesByClienteSQL(int clienteId) async {
    try {
      final db = await dbHelper.connection;
      final results = await db.query(
        'SELECT * FROM INMUEBLES WHERE id_cliente = ?',
        [clienteId],
      );
      return results.map((row) => Inmueble.fromMap(row.fields)).toList();
    } catch (e) {
      _logger.warning('Error al obtener inmuebles por cliente: $e');
      return [];
    }
  }

  // Actualizar inmueble usando SQL directo
  Future<int> updateInmueble(Inmueble inmueble) async {
    try {
      if (inmueble.id == null) {
        throw Exception("No se puede actualizar un inmueble sin ID");
      }
      
      final db = await dbHelper.connection;
      final result = await db.query(
        'UPDATE INMUEBLES SET nombre_inmueble = ?, id_direccion = ?, monto_total = ?, id_estado = ?, id_cliente = ? WHERE id_inmueble = ?',
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
    } catch (e) {
      _logger.severe('Error al actualizar inmueble: $e');
      rethrow;
    }
  }

  // Actualizar inmueble usando procedimiento almacenado
  Future<int> updateInmuebleUsingStoredProc(
      int idInmueble,
      String nombre,
      String calle,
      String numero,
      String ciudad,
      int idEstado,
      double montoTotal,
      int? idCliente) async {
    try {
      final db = await dbHelper.connection;
      final result = await db.query(
        'CALL ActualizarInmueble(?, ?, ?, ?, ?, ?, ?, ?)',
        [
          idInmueble,
          nombre,
          calle,
          numero,
          ciudad,
          idEstado,
          montoTotal,
          idCliente
        ],
      );
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al actualizar inmueble con procedimiento: $e');
      rethrow;
    }
  }

  // Eliminar inmueble
  Future<int> deleteInmueble(int id) async {
    try {
      final db = await dbHelper.connection;
      final result = await db.query(
        'DELETE FROM INMUEBLES WHERE id_inmueble = ?',
        [id],
      );
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al eliminar inmueble: $e');
      rethrow;
    }
  }
  
  // Obtener inmuebles con detalles de dirección (join)
  Future<List<Map<String, dynamic>>> getInmueblesConDireccion() async {
    try {
      final db = await dbHelper.connection;
      final results = await db.query('''
        SELECT i.*, d.calle, d.numero, d.ciudad, d.codigo_postal, e.nombre_estado
        FROM INMUEBLES i
        LEFT JOIN direcciones d ON i.id_direccion = d.id_direccion
        LEFT JOIN estados e ON i.id_estado = e.id_estado
      ''');
      
      return results.map((row) => {...row.fields}).toList();
    } catch (e) {
      _logger.warning('Error al obtener inmuebles con dirección: $e');
      return [];
    }
  }
  
  // Cambiar estado del inmueble (útil para marcar como vendido/disponible)
  Future<int> cambiarEstadoInmueble(int idInmueble, int nuevoEstadoId) async {
    try {
      final db = await dbHelper.connection;
      final result = await db.query(
        'UPDATE INMUEBLES SET id_estado = ? WHERE id_inmueble = ?',
        [nuevoEstadoId, idInmueble],
      );
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al cambiar estado del inmueble: $e');
      rethrow;
    }
  }
}
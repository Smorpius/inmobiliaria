import 'package:logging/logging.dart';
import '../models/cliente_model.dart';
import '../services/mysql_helper.dart';
import '../vistas/clientes/cliente_inmueble.dart'; // Importación añadida

class ClienteController {
  final DatabaseService _dbService = DatabaseService();
  final Logger _logger = Logger('ClienteController');

  // Crear un nuevo cliente con los campos de dirección completos
  Future<int> insertCliente(Cliente cliente) async {
    final conn = await _dbService.connection;

    try {
      // Llamar al procedimiento almacenado con todos los parámetros requeridos
      var result = await conn.query(
        'CALL CrearCliente(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          cliente.nombre,
          cliente.apellidoPaterno,
          cliente.apellidoMaterno ?? '',
          // Campos de dirección completos
          cliente.calle ?? '',
          cliente.numero ?? '',
          cliente.colonia ?? '',
          cliente.ciudad ?? '',
          cliente.estadoGeografico ?? '',
          cliente.codigoPostal ?? '',
          cliente.referencias ?? '',
          // Resto de campos del cliente
          cliente.telefono,
          cliente.rfc,
          cliente.curp,
          cliente.correo ?? '',
          cliente.tipoCliente,
        ],
      );

      _logger.info('Cliente insertado exitosamente con ID: ${result.insertId}');
      await getClientes(); // Actualizar la lista de clientes
      return result.insertId ?? -1;
    } catch (e) {
      _logger.severe('Error al insertar cliente: $e');
      throw Exception('Error al insertar cliente: $e');
    }
  }

  // Obtener todos los clientes activos con datos completos de dirección
  Future<List<Cliente>> getClientes() async {
    final conn = await _dbService.connection;

    try {
      final results = await conn.query('''
        SELECT 
          c.*,
          d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
          d.codigo_postal, d.referencias,
          e.nombre_estado AS estado_cliente
        FROM clientes c
        JOIN direcciones d ON c.id_direccion = d.id_direccion
        JOIN estados e ON c.id_estado = e.id_estado
        WHERE e.nombre_estado = 'activo'
      ''');

      _logger.info('Clientes activos obtenidos: ${results.length}');

      if (results.isEmpty) return [];

      final List<Cliente> clientesList = [];

      for (var row in results) {
        try {
          final cliente = Cliente.fromMap(row.fields);
          clientesList.add(cliente);
        } catch (e) {
          _logger.warning(
            'Error al procesar cliente: ${row.fields['id_cliente']}: $e',
          );
        }
      }

      return clientesList;
    } catch (e) {
      _logger.severe('Error al obtener clientes activos: $e');
      throw Exception('Error al obtener clientes: $e');
    }
  }

  // Obtener clientes inactivos con datos completos de dirección
  Future<List<Cliente>> getClientesInactivos() async {
    final conn = await _dbService.connection;

    try {
      final results = await conn.query('''
        SELECT 
          c.*,
          d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
          d.codigo_postal, d.referencias,
          e.nombre_estado AS estado_cliente
        FROM clientes c
        JOIN direcciones d ON c.id_direccion = d.id_direccion
        JOIN estados e ON c.id_estado = e.id_estado
        WHERE e.nombre_estado = 'inactivo'
      ''');

      _logger.info('Clientes inactivos obtenidos: ${results.length}');

      if (results.isEmpty) return [];

      final List<Cliente> clientesList = [];

      for (var row in results) {
        try {
          final cliente = Cliente.fromMap(row.fields);
          clientesList.add(cliente);
        } catch (e) {
          _logger.warning(
            'Error al procesar cliente inactivo: ${row.fields['id_cliente']}: $e',
          );
        }
      }

      return clientesList;
    } catch (e) {
      _logger.severe('Error al obtener clientes inactivos: $e');
      throw Exception('Error al obtener clientes inactivos: $e');
    }
  }

  // Actualizar cliente con campos de dirección completos
  Future<int> updateCliente(Cliente cliente) async {
    final conn = await _dbService.connection;

    try {
      if (cliente.id == null) {
        throw Exception('ID de cliente no proporcionado');
      }

      var result = await conn.query(
        'CALL ActualizarCliente(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          cliente.id,
          cliente.nombre,
          cliente.apellidoPaterno,
          cliente.apellidoMaterno ?? '',
          cliente.telefono,
          cliente.rfc,
          cliente.curp,
          cliente.correo ?? '',
          // Campos de dirección completos
          cliente.calle ?? '',
          cliente.numero ?? '',
          cliente.colonia ?? '',
          cliente.ciudad ?? '',
          cliente.estadoGeografico ?? '',
          cliente.codigoPostal ?? '',
          cliente.tipoCliente,
        ],
      );

      _logger.info('Cliente actualizado exitosamente: ID=${cliente.id}');
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al actualizar cliente: $e');
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  // Inactivar cliente
  Future<int> inactivarCliente(int id) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn.query('CALL InactivarCliente(?)', [id]);
      _logger.info('Cliente inactivado: ID=$id');
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al inactivar cliente: $e');
      throw Exception('Error al inactivar cliente: $e');
    }
  }

  // Reactivar cliente
  Future<int> reactivarCliente(int id) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn.query('CALL ReactivarCliente(?)', [id]);
      _logger.info('Cliente reactivado: ID=$id');
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al reactivar cliente: $e');
      throw Exception('Error al reactivar cliente: $e');
    }
  }

  // Buscar cliente por RFC
  Future<Cliente?> getClientePorRFC(String rfc) async {
    final conn = await _dbService.connection;

    try {
      final results = await conn.query(
        '''
        SELECT 
          c.*,
          d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
          d.codigo_postal, d.referencias,
          e.nombre_estado AS estado_cliente
        FROM clientes c
        JOIN direcciones d ON c.id_direccion = d.id_direccion
        JOIN estados e ON c.id_estado = e.id_estado
        WHERE c.rfc = ?
      ''',
        [rfc],
      );

      if (results.isEmpty) return null;
      return Cliente.fromMap(results.first.fields);
    } catch (e) {
      _logger.severe('Error al buscar cliente por RFC: $e');
      throw Exception('Error al buscar cliente por RFC: $e');
    }
  }

  // Buscar clientes por nombre
  Future<List<Cliente>> buscarClientesPorNombre(String texto) async {
    final conn = await _dbService.connection;

    try {
      final results = await conn.query(
        '''
        SELECT 
          c.*,
          d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
          d.codigo_postal, d.referencias,
          e.nombre_estado AS estado_cliente
        FROM clientes c
        JOIN direcciones d ON c.id_direccion = d.id_direccion
        JOIN estados e ON c.id_estado = e.id_estado
        WHERE CONCAT(c.nombre, ' ', c.apellido_paterno, ' ', IFNULL(c.apellido_materno, '')) 
              LIKE CONCAT('%', ?, '%')
      ''',
        [texto],
      );

      if (results.isEmpty) return [];

      final List<Cliente> clientesList = [];
      for (var row in results) {
        try {
          final cliente = Cliente.fromMap(row.fields);
          clientesList.add(cliente);
        } catch (e) {
          _logger.warning(
            'Error al procesar cliente en búsqueda: ${row.fields['id_cliente']}: $e',
          );
        }
      }

      return clientesList;
    } catch (e) {
      _logger.severe('Error al buscar clientes por nombre: $e');
      throw Exception('Error al buscar clientes por nombre: $e');
    }
  }

  // Obtener inmuebles asociados a un cliente
  Future<List<Map<String, dynamic>>> getInmueblesPorCliente(
    int idCliente,
  ) async {
    final conn = await _dbService.connection;

    try {
      final results = await conn.query(
        '''
        SELECT 
          i.*,
          d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
          d.codigo_postal, d.referencias,
          e.nombre_estado AS estado_inmueble
        FROM inmuebles i
        JOIN direcciones d ON i.id_direccion = d.id_direccion
        JOIN estados e ON i.id_estado = e.id_estado
        WHERE i.id_cliente = ?
      ''',
        [idCliente],
      );

      if (results.isEmpty) return [];

      return results.map((row) => row.fields).toList();
    } catch (e) {
      _logger.severe('Error al obtener inmuebles por cliente: $e');
      throw Exception('Error al buscar inmuebles por cliente: $e');
    }
  }

  // NUEVOS MÉTODOS PARA LA RELACIÓN CLIENTE-INMUEBLE

  // Asignar un inmueble a un cliente
  Future<bool> asignarInmuebleACliente(
    int idCliente,
    int idInmueble, [
    DateTime? fechaAdquisicion,
  ]) async {
    final conn = await _dbService.connection;
    final fecha = fechaAdquisicion ?? DateTime.now();

    try {
      // Verificar si el inmueble ya está asignado a otro cliente
      final existeAsignacion = await conn.query(
        'SELECT id FROM cliente_inmueble WHERE id_inmueble = ?',
        [idInmueble],
      );

      if (existeAsignacion.isNotEmpty) {
        _logger.warning('El inmueble ya está asignado a otro cliente');
        return false;
      }

      await conn.query(
        'INSERT INTO cliente_inmueble (id_cliente, id_inmueble, fecha_adquisicion) VALUES (?, ?, ?)',
        [idCliente, idInmueble, fecha.toIso8601String().split('T')[0]],
      );

      _logger.info('Inmueble $idInmueble asignado al cliente $idCliente');
      return true;
    } catch (e) {
      _logger.severe('Error al asignar inmueble a cliente: $e');
      throw Exception('Error al asignar inmueble: $e');
    }
  }

  // Eliminar asignación de inmueble a cliente
  Future<bool> desasignarInmuebleDeCliente(int idInmueble) async {
    final conn = await _dbService.connection;

    try {
      final result = await conn.query(
        'DELETE FROM cliente_inmueble WHERE id_inmueble = ?',
        [idInmueble],
      );

      _logger.info(
        'Inmueble $idInmueble desasignado. Filas afectadas: ${result.affectedRows}',
      );
      return result.affectedRows! > 0;
    } catch (e) {
      _logger.severe('Error al desasignar inmueble: $e');
      throw Exception('Error al desasignar inmueble: $e');
    }
  }

  // Obtener todos los inmuebles asignados a un cliente
  Future<List<ClienteInmueble>> getInmueblesAsignados(int idCliente) async {
    final conn = await _dbService.connection;

    try {
      final results = await conn.query(
        'SELECT * FROM cliente_inmueble WHERE id_cliente = ?',
        [idCliente],
      );

      if (results.isEmpty) return [];

      return results.map((row) => ClienteInmueble.fromMap(row.fields)).toList();
    } catch (e) {
      _logger.severe('Error al obtener inmuebles asignados: $e');
      throw Exception('Error al obtener inmuebles asignados: $e');
    }
  }

  // Obtener cliente asignado a un inmueble
  Future<ClienteInmueble?> getClienteDeInmueble(int idInmueble) async {
    final conn = await _dbService.connection;

    try {
      final results = await conn.query(
        'SELECT * FROM cliente_inmueble WHERE id_inmueble = ?',
        [idInmueble],
      );

      if (results.isEmpty) return null;

      return ClienteInmueble.fromMap(results.first.fields);
    } catch (e) {
      _logger.severe('Error al obtener cliente de inmueble: $e');
      throw Exception('Error al obtener cliente de inmueble: $e');
    }
  }
}

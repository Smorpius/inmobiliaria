import 'dart:developer' as developer;
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
      _logger.info(
        'Iniciando inserción de cliente: ${cliente.nombre} ${cliente.apellidoPaterno}',
      );
      developer.log(
        'Guardando cliente en BD: ${cliente.nombre}, Estado: ${cliente.idEstado ?? 1}',
      );

      // CORRECCIÓN: Añadir variable OUT al final de la llamada
      await conn.query(
        'CALL CrearCliente(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @id_cliente_out)',
        [
          cliente.nombre,
          cliente.apellidoPaterno,
          cliente.apellidoMaterno ?? '',
          cliente.calle ?? '',
          cliente.numero ?? '',
          cliente.colonia ?? '',
          cliente.ciudad ?? '',
          cliente.estadoGeografico ?? '',
          cliente.codigoPostal ?? '',
          cliente.referencias ?? '',
          cliente.telefono,
          cliente.rfc,
          cliente.curp,
          cliente.correo ?? '',
          cliente.tipoCliente,
        ],
      );

      // Obtener el ID generado usando la variable OUT
      final idResult = await conn.query('SELECT @id_cliente_out as id');

      if (idResult.isEmpty || idResult.first.fields['id'] == null) {
        developer.log(
          'No se pudo obtener ID mediante variable OUT, intentando con LAST_INSERT_ID()',
        );
        final altResult = await conn.query('SELECT LAST_INSERT_ID() as id');

        if (altResult.isEmpty || altResult.first.fields['id'] == null) {
          developer.log('No se pudo obtener ID del cliente creado');
          return -1;
        }

        final idCliente = altResult.first.fields['id'] as int;
        developer.log('Cliente insertado con ID alternativo: $idCliente');
        return idCliente;
      }

      final idCliente = idResult.first.fields['id'] as int;
      developer.log(
        'Cliente insertado con ID: $idCliente, Estado: ${cliente.idEstado ?? 1}',
      );

      // Forzar actualización inmediata
      await Future.delayed(const Duration(milliseconds: 300));
      await getClientes();

      return idCliente;
    } catch (e) {
      _logger.severe('Error al insertar cliente: $e');
      developer.log('Error al insertar cliente: $e');
      throw Exception('Error al insertar cliente: $e');
    }
  }

  // Obtener todos los clientes activos con datos completos de dirección
  Future<List<Cliente>> getClientes() async {
    final conn = await _dbService.connection;

    try {
      developer.log('Consultando clientes activos...');
      final results = await conn.query('''
        SELECT 
          c.*,
          d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
          d.codigo_postal, d.referencias,
          e.nombre_estado AS estado_cliente
        FROM clientes c
        LEFT JOIN direcciones d ON c.id_direccion = d.id_direccion
        LEFT JOIN estados e ON c.id_estado = e.id_estado
        WHERE c.id_estado = 1
        ORDER BY c.fecha_registro DESC
      ''');

      developer.log('Clientes activos recibidos de BD: ${results.length}');

      if (results.isEmpty) return [];

      final List<Cliente> clientesList = [];

      // Depurar los datos recibidos
      if (results.isNotEmpty) {
        developer.log('Datos del primer cliente: ${results.first.fields}');
      }

      for (var row in results) {
        try {
          developer.log(
            'Intentando procesar cliente: ${row.fields['nombre']} ${row.fields['apellido_paterno']}',
          );
          final cliente = Cliente.fromMap(row.fields);
          clientesList.add(cliente);
          developer.log('Cliente procesado exitosamente: ${cliente.nombre}');
        } catch (e) {
          _logger.warning(
            'Error al procesar cliente: ${row.fields['nombre']}: $e',
          );
          developer.log('ERROR al procesar cliente: $e', error: e);
        }
      }

      developer.log('Clientes activos procesados: ${clientesList.length}');
      if (clientesList.isNotEmpty) {
        developer.log(
          'Primer cliente activo: ID=${clientesList.first.id}, Nombre=${clientesList.first.nombre}',
        );
      }

      return clientesList;
    } catch (e) {
      _logger.severe('Error al obtener clientes activos: $e');
      developer.log('ERROR AL OBTENER CLIENTES ACTIVOS: $e', error: e);
      throw Exception('Error al obtener clientes: $e');
    }
  }

  // Obtener clientes inactivos con datos completos de dirección
  Future<List<Cliente>> getClientesInactivos() async {
    final conn = await _dbService.connection;

    try {
      developer.log('Consultando clientes inactivos...');
      // Usar consulta directa para mayor control
      final results = await conn.query('''
        SELECT 
          c.*,
          d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
          d.codigo_postal, d.referencias,
          e.nombre_estado AS estado_cliente
        FROM clientes c
        LEFT JOIN direcciones d ON c.id_direccion = d.id_direccion
        LEFT JOIN estados e ON c.id_estado = e.id_estado
        WHERE c.id_estado != 1
        ORDER BY c.fecha_registro DESC
      ''');

      developer.log('Clientes inactivos recibidos de BD: ${results.length}');

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

      developer.log('Clientes inactivos procesados: ${clientesList.length}');
      if (clientesList.isNotEmpty) {
        developer.log(
          'Primer cliente inactivo: ID=${clientesList.first.id}, Estado=${clientesList.first.idEstado}',
        );
      }

      return clientesList;
    } catch (e) {
      _logger.severe('Error al obtener clientes inactivos: $e');
      developer.log('ERROR AL OBTENER CLIENTES INACTIVOS: $e');
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

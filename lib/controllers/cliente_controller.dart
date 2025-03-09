import 'package:logging/logging.dart';
import '../models/cliente_model.dart';
import '../services/mysql_helper.dart';

class ClienteController {
  final DatabaseService _dbService = DatabaseService();
  final Logger _logger = Logger('ClienteController');

  // Crear un nuevo cliente usando el stored procedure actualizado
  Future<int> insertCliente(Cliente cliente) async {
    final conn = await _dbService.connection;

    try {
      // Llamar al procedimiento almacenado con todos los parámetros requeridos
      var result = await conn.query(
        'CALL CrearCliente(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          cliente.nombre, // p_nombre
          cliente.apellidoPaterno, // p_apellido_paterno
          cliente.apellidoMaterno ?? '', // p_apellido_materno
          cliente.calle ??
              'Calle por defecto', // Usar valor del formulario si está disponible
          cliente.numero ??
              'S/N', // Usar valor del formulario si está disponible
          cliente.ciudad ??
              'Ciudad por defecto', // Usar valor del formulario si está disponible
          cliente.codigoPostal ??
              '00000', // Usar valor del formulario si está disponible
          cliente.telefono, // p_telefono_cliente
          cliente.rfc, // p_rfc
          cliente.curp, // p_curp
          cliente.correo, // p_correo_cliente
          cliente.tipoCliente, // p_tipo_cliente
        ],
      );

      _logger.info('Cliente insertado exitosamente');

      // Después de insertar el cliente, cargamos todos los clientes para refrescar la vista
      await getClientes();

      return result.insertId ?? -1;
    } catch (e) {
      _logger.severe('Error al insertar cliente: $e');
      throw Exception('Error al insertar cliente: $e');
    }
  }

  // Obtener todos los clientes usando la nueva estructura
  Future<List<Cliente>> getClientes() async {
    final conn = await _dbService.connection;

    try {
      // Usar el procedimiento almacenado actualizado
      final results = await conn.query('CALL LeerClientes()');

      _logger.info(
        'Tipo de resultados: ${results.runtimeType}, longitud: ${results.length}',
      );

      if (results.isEmpty) {
        _logger.info('No se encontraron clientes');
        return [];
      }

      final List<Cliente> clientesList = [];

      for (var row in results) {
        try {
          _logger.info('Procesando fila: ${row.toString()}');
          // Convertir directamente el resultado a Cliente
          final cliente = Cliente.fromMap(row.fields);
          clientesList.add(cliente);
        } catch (e) {
          _logger.severe('Error al procesar cliente: $e');
          // Continuar con el siguiente cliente en caso de error
          continue;
        }
      }

      _logger.info('Clientes procesados correctamente: ${clientesList.length}');
      return clientesList;
    } catch (e) {
      _logger.severe('Error al obtener clientes: $e');
      throw Exception('Error al obtener clientes: $e');
    }
  }

  // NUEVO: Método para obtener clientes inactivos (CORREGIDO)
  Future<List<Cliente>> getClientesInactivos() async {
    final conn = await _dbService.connection;

    try {
      // Consulta que filtra por clientes inactivos
      final results = await conn.query(
        'SELECT c.*, d.calle, d.numero, d.ciudad, d.codigo_postal, e.nombre_estado AS estado_cliente '
        'FROM clientes c '
        'JOIN direcciones d ON c.id_direccion = d.id_direccion '
        'JOIN estados e ON c.id_estado = e.id_estado '
        'WHERE e.nombre_estado = "inactivo"',
      );

      if (results.isEmpty) {
        _logger.info('No se encontraron clientes inactivos');
        return [];
      }

      final List<Cliente> clientesList = [];

      for (var row in results) {
        try {
          final cliente = Cliente.fromMap(row.fields);
          clientesList.add(cliente);
        } catch (e) {
          _logger.severe('Error al procesar cliente inactivo: $e');
          continue;
        }
      }

      return clientesList;
    } catch (e) {
      _logger.severe('Error al obtener clientes inactivos: $e');
      throw Exception('Error al obtener clientes inactivos: $e');
    }
  }

  // Actualizar cliente con la nueva estructura
  Future<int> updateCliente(Cliente cliente) async {
    final conn = await _dbService.connection;

    try {
      if (cliente.id == null) {
        throw Exception('ID de cliente no proporcionado');
      }

      var result = await conn.query(
        'CALL ActualizarCliente(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          cliente.id, // p_id_cliente
          cliente.nombre, // p_nombre
          cliente.apellidoPaterno, // p_apellido_paterno
          cliente.apellidoMaterno ?? '', // p_apellido_materno
          cliente.telefono, // p_telefono_cliente
          cliente.rfc, // p_rfc
          cliente.curp, // p_curp
          cliente.correo, // p_correo_cliente
          cliente.calle ??
              'Calle por defecto', // Usar valor del formulario si está disponible
          cliente.numero ??
              'S/N', // Usar valor del formulario si está disponible
          cliente.ciudad ??
              'Ciudad por defecto', // Usar valor del formulario si está disponible
          cliente.codigoPostal ??
              '00000', // Usar valor del formulario si está disponible
          cliente.tipoCliente, // p_tipo_cliente
        ],
      );

      _logger.info('Cliente actualizado exitosamente');

      // Después de actualizar el cliente, cargamos todos los clientes para refrescar la vista
      await getClientes();

      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al actualizar cliente: $e');
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  // Inactivar cliente (no cambia)
  Future<int> inactivarCliente(int id) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn.query('CALL InactivarCliente(?)', [id]);

      _logger.info('Cliente inactivado exitosamente');

      // Después de inactivar el cliente, cargamos todos los clientes para refrescar la vista
      await getClientes();

      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al inactivar cliente: $e');
      throw Exception('Error al inactivar cliente: $e');
    }
  }

  // Reactivar cliente (ya existía pero agregamos logging)
  Future<int> reactivarCliente(int id) async {
    final conn = await _dbService.connection;

    try {
      var result = await conn.query('CALL ReactivarCliente(?)', [id]);

      _logger.info('Cliente reactivado exitosamente');

      // Después de reactivar el cliente, refrescamos la vista de clientes inactivos
      await getClientesInactivos();

      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al reactivar cliente: $e');
      throw Exception('Error al reactivar cliente: $e');
    }
  }

  // Resto de métodos sin cambios...
  Future<Cliente?> getClientePorRFC(String rfc) async {
    final conn = await _dbService.connection;
    // Implementación sin cambios...
    try {
      final results = await conn.query('CALL BuscarClientePorRFC(?)', [rfc]);
      if (results.isEmpty) return null;
      return Cliente.fromMap(results.first.fields);
    } catch (e) {
      _logger.severe('Error al buscar cliente por RFC: $e');
      throw Exception('Error al buscar cliente por RFC: $e');
    }
  }

  Future<List<Cliente>> buscarClientesPorNombre(String texto) async {
    final conn = await _dbService.connection;
    // Implementación sin cambios...
    try {
      final results = await conn.query('CALL BuscarClientePorNombre(?)', [
        texto,
      ]);
      if (results.isEmpty) return [];

      final List<Cliente> clientesList = [];
      for (var row in results) {
        try {
          final cliente = Cliente.fromMap(row.fields);
          clientesList.add(cliente);
        } catch (e) {
          _logger.severe('Error al procesar cliente: $e');
          continue;
        }
      }

      return clientesList;
    } catch (e) {
      _logger.severe('Error al buscar clientes por nombre: $e');
      throw Exception('Error al buscar clientes por nombre: $e');
    }
  }

  Future<List<dynamic>> getInmueblesPorCliente(int idCliente) async {
    final conn = await _dbService.connection;
    // Implementación sin cambios...
    try {
      final results = await conn.query('CALL BuscarInmueblePorCliente(?)', [
        idCliente,
      ]);
      if (results.isEmpty) return [];
      return results.map((row) => row.fields).toList();
    } catch (e) {
      _logger.severe('Error al buscar inmuebles por cliente: $e');
      throw Exception('Error al buscar inmuebles por cliente: $e');
    }
  }
}

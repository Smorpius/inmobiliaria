import 'package:logging/logging.dart';
import '../models/cliente_model.dart';
import '../services/mysql_helper.dart';

class ClienteController {
  final DatabaseService _dbService = DatabaseService();
  final Logger _logger = Logger('ClienteController');

  // Crear un nuevo cliente usando el stored procedure
  Future<int> insertCliente(Cliente cliente) async {
    final conn = await _dbService.connection;

    try {
      // Llamar al procedimiento almacenado con todos los parámetros requeridos
      var result = await conn.query(
        'CALL CrearCliente(?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          cliente.nombre, // p_nombre_cliente
          'Calle por defecto', // p_direccion_calle (valor por defecto)
          'S/N', // p_direccion_numero (valor por defecto)
          'Ciudad por defecto', // p_direccion_ciudad (valor por defecto)
          '00000', // p_direccion_codigo_postal (valor por defecto)
          cliente.telefono, // p_telefono_cliente
          cliente.rfc, // p_rfc
          cliente.curp, // p_curp
          cliente.correo, // p_correo_cliente
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

  // Obtener todos los clientes usando el stored procedure
  Future<List<Cliente>> getClientes() async {
    final conn = await _dbService.connection;

    try {
      // Usar una consulta directa en lugar del procedimiento para depuración
      final results = await conn.query('''
        SELECT 
          c.*,
          d.calle,
          d.numero,
          d.ciudad,
          d.codigo_postal,
          e.nombre_estado AS estado_cliente
        FROM clientes c
        JOIN direcciones d ON c.id_direccion = d.id_direccion
        JOIN estados e ON c.id_estado = e.id_estado
        WHERE c.id_estado = 1
      ''');

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

  // Actualizar cliente usando el stored procedure
  Future<int> updateCliente(Cliente cliente) async {
    final conn = await _dbService.connection;

    try {
      if (cliente.id == null) {
        throw Exception('ID de cliente no proporcionado');
      }

      var result = await conn.query(
        'CALL ActualizarCliente(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          cliente.id, // p_id_cliente
          cliente.nombre, // p_nombre_cliente
          cliente.telefono, // p_telefono_cliente
          cliente.rfc, // p_rfc
          cliente.curp, // p_curp
          cliente.correo, // p_correo_cliente
          'Calle por defecto', // p_direccion_calle (usar datos reales si están disponibles)
          'S/N', // p_direccion_numero
          'Ciudad por defecto', // p_direccion_ciudad
          '00000', // p_direccion_codigo_postal
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

  // Inactivar cliente usando el stored procedure
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

  // Obtener un cliente por RFC usando el stored procedure
  Future<Cliente?> getClientePorRFC(String rfc) async {
    final conn = await _dbService.connection;

    try {
      // Usar consulta directa en lugar del procedimiento para mayor compatibilidad
      final results = await conn.query(
        '''
        SELECT 
          c.*,
          d.calle, 
          d.numero, 
          d.ciudad, 
          d.codigo_postal,
          e.nombre_estado AS estado_cliente
        FROM clientes c
        JOIN direcciones d ON c.id_direccion = d.id_direccion
        JOIN estados e ON c.id_estado = e.id_estado
        WHERE c.rfc = ?
        ''',
        [rfc],
      );

      if (results.isEmpty) {
        return null;
      }

      return Cliente.fromMap(results.first.fields);
    } catch (e) {
      _logger.severe('Error al buscar cliente por RFC: $e');
      throw Exception('Error al buscar cliente por RFC: $e');
    }
  }
}

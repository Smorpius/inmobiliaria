import '../utils/applogger.dart';
import '../models/cliente_model.dart';
import '../services/mysql_helper.dart';

class ClienteController {
  final DatabaseService _dbService;

  // Constructor con inyección de dependencia
  ClienteController({DatabaseService? dbService})
    : _dbService = dbService ?? DatabaseService();

  // Método auxiliar para ejecutar operaciones con manejo de errores consistente
  Future<T> _ejecutarOperacion<T>(
    String descripcion,
    Future<T> Function() operacion,
  ) async {
    try {
      AppLogger.info('Iniciando operación: $descripcion');
      final resultado = await operacion();
      AppLogger.info('Operación completada: $descripcion');
      return resultado;
    } catch (e, stackTrace) {
      AppLogger.error('Error en operación "$descripcion"', e, stackTrace);
      throw Exception('Error en $descripcion: $e');
    }
  }

  // Crear un nuevo cliente usando el procedimiento almacenado con validaciones mejoradas
  Future<int> insertCliente(Cliente cliente) async {
    return _ejecutarOperacion('insertar cliente', () async {
      // Validación de campos obligatorios
      if (cliente.nombre.isEmpty || cliente.apellidoPaterno.isEmpty) {
        throw Exception('El nombre y apellido paterno son obligatorios');
      }

      if (cliente.rfc.isEmpty || cliente.rfc.length != 13) {
        throw Exception('El RFC debe tener exactamente 13 caracteres');
      }

      if (cliente.curp.isEmpty || cliente.curp.length != 18) {
        throw Exception('El CURP debe tener exactamente 18 caracteres');
      }

      // Verificar si el correo ya existe (si se proporciona)
      if (cliente.correo != null && cliente.correo!.isNotEmpty) {
        final clientesExistentes = await _dbService.withConnection((
          conn,
        ) async {
          return await conn.query(
            'SELECT id_cliente FROM clientes WHERE correo_cliente = ? AND id_cliente != ?',
            [cliente.correo, cliente.id ?? 0],
          );
        });

        if (clientesExistentes.isNotEmpty) {
          throw Exception('Ya existe un cliente con este correo electrónico');
        }
      }

      // Iniciar transacción para asegurar consistencia
      return await _dbService.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Primero creamos la dirección si hay datos de dirección
          int? idDireccion;
          if (cliente.calle != null &&
              cliente.ciudad != null &&
              cliente.estadoGeografico != null) {
            final direccionResult = await conn.query(
              'INSERT INTO direcciones(calle, numero, colonia, ciudad, estado_geografico, codigo_postal, referencias) '
              'VALUES(?, ?, ?, ?, ?, ?, ?)',
              [
                cliente.calle,
                cliente.numero,
                cliente.colonia,
                cliente.ciudad,
                cliente.estadoGeografico,
                cliente.codigoPostal,
                cliente.referencias,
              ],
            );
            idDireccion = direccionResult.insertId;
          }

          // Ahora registramos el cliente con la dirección asociada
          final result = await conn.query(
            'INSERT INTO clientes(nombre, apellido_paterno, apellido_materno, id_direccion, '
            'telefono_cliente, rfc, curp, tipo_cliente, correo_cliente) '
            'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
              cliente.nombre,
              cliente.apellidoPaterno,
              cliente.apellidoMaterno,
              idDireccion,
              cliente.telefono,
              cliente.rfc,
              cliente.curp,
              cliente.tipoCliente,
              cliente.correo,
            ],
          );

          await conn.query('COMMIT');
          AppLogger.info('Cliente registrado con ID: ${result.insertId}');
          return result.insertId!;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error('Error al insertar cliente', e, StackTrace.current);

          // Devolver mensajes de error más específicos
          if (e.toString().contains('idx_clientes_correo')) {
            throw Exception(
              'El correo electrónico ya está en uso por otro cliente',
            );
          }
          throw Exception('Error al insertar cliente: $e');
        }
      });
    });
  }

  // Obtener todos los clientes activos usando el procedimiento almacenado
  Future<List<Cliente>> getClientes() async {
    return _ejecutarOperacion('obtener clientes activos', () async {
      return await _dbService.withConnection((conn) async {
        AppLogger.info('Consultando clientes activos');
        final results = await conn.query('CALL ObtenerClientesActivos()');

        AppLogger.info('Clientes activos recibidos: ${results.length}');

        if (results.isEmpty) return [];

        final List<Cliente> clientesList = [];
        for (var row in results) {
          try {
            final cliente = Cliente.fromMap(row.fields);
            clientesList.add(cliente);
          } catch (e) {
            AppLogger.warning(
              'Error al procesar cliente: ${row.fields['nombre']}: $e',
            );
          }
        }

        return clientesList;
      });
    });
  }

  // Obtener clientes inactivos usando el procedimiento almacenado
  Future<List<Cliente>> getClientesInactivos() async {
    return _ejecutarOperacion('obtener clientes inactivos', () async {
      return await _dbService.withConnection((conn) async {
        AppLogger.info('Consultando clientes inactivos');
        final results = await conn.query('CALL ObtenerClientesInactivos()');

        if (results.isEmpty) return [];

        final List<Cliente> clientesList = [];
        for (var row in results) {
          try {
            final cliente = Cliente.fromMap(row.fields);
            clientesList.add(cliente);
          } catch (e) {
            AppLogger.warning(
              'Error al procesar cliente inactivo: ${row.fields['id_cliente']}: $e',
            );
          }
        }

        return clientesList;
      });
    });
  }

  // Obtener cliente por ID usando el procedimiento almacenado
  Future<Cliente?> getClientePorId(int id) async {
    return _ejecutarOperacion('obtener cliente por ID', () async {
      return await _dbService.withConnection((conn) async {
        AppLogger.info('Buscando cliente con ID: $id');
        final results = await conn.query('CALL ObtenerClientePorId(?)', [id]);

        if (results.isEmpty) {
          AppLogger.info('No se encontró cliente con ID: $id');
          return null;
        }

        return Cliente.fromMap(results.first.fields);
      });
    });
  }

  // Actualizar cliente usando el procedimiento almacenado con manejo transaccional mejorado
  Future<int> updateCliente(Cliente cliente) async {
    return _ejecutarOperacion('actualizar cliente', () async {
      // Validación de campos obligatorios
      // También funciona bien
      if (cliente.id == null || (cliente.id ?? 0) <= 0) {
        throw Exception('ID de cliente inválido');
      }

      if (cliente.nombre.isEmpty || cliente.apellidoPaterno.isEmpty) {
        throw Exception('El nombre y apellido paterno son obligatorios');
      }

      if (cliente.rfc.isEmpty || cliente.rfc.length != 13) {
        throw Exception('El RFC debe tener exactamente 13 caracteres');
      }

      if (cliente.curp.isEmpty || cliente.curp.length != 18) {
        throw Exception('El CURP debe tener exactamente 18 caracteres');
      }

      // Verificar si el correo ya existe excluyendo el cliente actual
      if (cliente.correo != null && cliente.correo!.isNotEmpty) {
        final clientesExistentes = await _dbService.withConnection((
          conn,
        ) async {
          return await conn.query(
            'SELECT id_cliente FROM clientes WHERE correo_cliente = ? AND id_cliente != ?',
            [cliente.correo, cliente.id],
          );
        });

        if (clientesExistentes.isNotEmpty) {
          throw Exception('Ya existe otro cliente con este correo electrónico');
        }
      }

      // Iniciar transacción para asegurar consistencia
      return await _dbService.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Primero verificamos si ya tiene una dirección asociada
          final clienteActual = await conn.query(
            'SELECT id_direccion FROM clientes WHERE id_cliente = ?',
            [cliente.id],
          );

          if (clienteActual.isEmpty) {
            await conn.query('ROLLBACK');
            throw Exception('Cliente no encontrado');
          }

          int? idDireccion = clienteActual.first['id_direccion'];

          // Si tiene datos de dirección, actualizamos o creamos la dirección
          if (cliente.calle != null &&
              cliente.ciudad != null &&
              cliente.estadoGeografico != null) {
            if (idDireccion != null) {
              // Actualizar dirección existente
              await conn.query(
                'UPDATE direcciones SET calle = ?, numero = ?, colonia = ?, ciudad = ?, '
                'estado_geografico = ?, codigo_postal = ?, referencias = ? WHERE id_direccion = ?',
                [
                  cliente.calle,
                  cliente.numero,
                  cliente.colonia,
                  cliente.ciudad,
                  cliente.estadoGeografico,
                  cliente.codigoPostal,
                  cliente.referencias,
                  idDireccion,
                ],
              );
            } else {
              // Crear nueva dirección
              final direccionResult = await conn.query(
                'INSERT INTO direcciones(calle, numero, colonia, ciudad, estado_geografico, codigo_postal, referencias) '
                'VALUES(?, ?, ?, ?, ?, ?, ?)',
                [
                  cliente.calle,
                  cliente.numero,
                  cliente.colonia,
                  cliente.ciudad,
                  cliente.estadoGeografico,
                  cliente.codigoPostal,
                  cliente.referencias,
                ],
              );
              idDireccion = direccionResult.insertId;
            }
          }

          // Actualizar datos del cliente
          final result = await conn.query(
            'UPDATE clientes SET nombre = ?, apellido_paterno = ?, apellido_materno = ?, '
            'id_direccion = ?, telefono_cliente = ?, rfc = ?, curp = ?, tipo_cliente = ?, '
            'correo_cliente = ? WHERE id_cliente = ?',
            [
              cliente.nombre,
              cliente.apellidoPaterno,
              cliente.apellidoMaterno,
              idDireccion,
              cliente.telefono,
              cliente.rfc,
              cliente.curp,
              cliente.tipoCliente,
              cliente.correo,
              cliente.id,
            ],
          );

          await conn.query('COMMIT');
          AppLogger.info('Cliente actualizado con ID: ${cliente.id}');
          return result.affectedRows ?? 0;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error('Error al actualizar cliente', e, StackTrace.current);

          // Devolver mensajes de error más específicos
          if (e.toString().contains('idx_clientes_correo')) {
            throw Exception(
              'El correo electrónico ya está en uso por otro cliente',
            );
          }
          throw Exception('Error al actualizar cliente: $e');
        }
      });
    });
  }

  // Inactivar cliente usando el procedimiento almacenado
  Future<int> inactivarCliente(int id) async {
    return _ejecutarOperacion('inactivar cliente', () async {
      return await _dbService.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          var result = await conn.query('CALL InactivarCliente(?)', [id]);
          await conn.query('COMMIT');

          AppLogger.info('Cliente inactivado: ID=$id');
          return result.affectedRows ?? 0;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error('Error al inactivar cliente', e, StackTrace.current);
          rethrow;
        }
      });
    });
  }

  // Reactivar cliente usando el procedimiento almacenado
  Future<int> reactivarCliente(int id) async {
    return _ejecutarOperacion('reactivar cliente', () async {
      return await _dbService.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          var result = await conn.query('CALL ReactivarCliente(?)', [id]);
          await conn.query('COMMIT');

          AppLogger.info('Cliente reactivado: ID=$id');
          return result.affectedRows ?? 0;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error('Error al reactivar cliente', e, StackTrace.current);
          rethrow;
        }
      });
    });
  }

  // Obtener inmuebles asociados a un cliente usando el procedimiento almacenado
  Future<List<Map<String, dynamic>>> getInmueblesPorCliente(
    int idCliente,
  ) async {
    return _ejecutarOperacion('obtener inmuebles por cliente', () async {
      return await _dbService.withConnection((conn) async {
        AppLogger.info(
          'Consultando inmuebles asociados al cliente: $idCliente',
        );
        final results = await conn.query('CALL ObtenerInmueblesPorCliente(?)', [
          idCliente,
        ]);

        if (results.isEmpty) {
          AppLogger.info(
            'No se encontraron inmuebles para el cliente: $idCliente',
          );
          return [];
        }

        return results.map((row) => row.fields).toList();
      });
    });
  }

  // Asignar un inmueble a un cliente usando el procedimiento almacenado
  Future<bool> asignarInmuebleACliente(
    int idCliente,
    int idInmueble, [
    DateTime? fechaAdquisicion,
  ]) async {
    return _ejecutarOperacion('asignar inmueble a cliente', () async {
      return await _dbService.withConnection((conn) async {
        final fecha = fechaAdquisicion ?? DateTime.now();
        final fechaStr = fecha.toIso8601String().split('T')[0];

        AppLogger.info(
          'Asignando inmueble $idInmueble al cliente $idCliente (fecha: $fechaStr)',
        );

        await conn.query('START TRANSACTION');
        try {
          // Llamada al procedimiento almacenado con variable de salida
          await conn.query(
            'CALL AsignarInmuebleACliente(?, ?, ?, @resultado)',
            [idCliente, idInmueble, fechaStr],
          );

          // Obtención del resultado
          final resultadoQuery = await conn.query('SELECT @resultado as exito');
          final exito =
              resultadoQuery.isNotEmpty &&
              resultadoQuery.first.fields['exito'] == 1;

          await conn.query('COMMIT');

          if (exito) {
            AppLogger.info(
              'Inmueble $idInmueble asignado exitosamente al cliente $idCliente',
            );
          } else {
            AppLogger.warning(
              'No se pudo asignar el inmueble $idInmueble (posiblemente ya asignado)',
            );
          }

          return exito;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error('Error al asignar inmueble', e, StackTrace.current);
          rethrow;
        }
      });
    });
  }

  // Eliminar asignación de inmueble a cliente usando el procedimiento almacenado
  Future<bool> desasignarInmuebleDeCliente(int idInmueble) async {
    return _ejecutarOperacion('desasignar inmueble de cliente', () async {
      return await _dbService.withConnection((conn) async {
        AppLogger.info('Desasignando inmueble: $idInmueble');

        await conn.query('START TRANSACTION');
        try {
          // Llamada al procedimiento almacenado con variable de salida
          await conn.query('CALL DesasignarInmuebleDeCliente(?, @resultado)', [
            idInmueble,
          ]);

          // Obtención del resultado
          final resultadoQuery = await conn.query('SELECT @resultado as exito');
          final exito =
              resultadoQuery.isNotEmpty &&
              resultadoQuery.first.fields['exito'] == 1;

          await conn.query('COMMIT');

          if (exito) {
            AppLogger.info('Inmueble $idInmueble desasignado exitosamente');
          } else {
            AppLogger.info(
              'El inmueble $idInmueble no estaba asignado a ningún cliente',
            );
          }

          return exito;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error(
            'Error al desasignar inmueble',
            e,
            StackTrace.current,
          );
          rethrow;
        }
      });
    });
  }
}

import 'dart:async';
import 'mysql_helper.dart';
import '../utils/applogger.dart';
import '../models/proveedor.dart';

class ProveedoresService {
  final DatabaseService _db;

  // Control para evitar errores duplicados
  bool _procesandoError = false;

  ProveedoresService([DatabaseService? db]) : _db = db ?? DatabaseService();

  /// Obtiene la lista de todos los proveedores usando procedimiento almacenado
  Future<List<Proveedor>> obtenerProveedores() async {
    try {
      return await _db.withConnection((conn) async {
        AppLogger.info('Consultando lista completa de proveedores');
        final results = await conn.query('CALL ObtenerProveedores()');

        if (results.isEmpty) {
          AppLogger.info('No se encontraron proveedores');
          return [];
        }

        return results.map((row) => Proveedor.fromMap(row.fields)).toList();
      });
    } catch (e) {
      _manejarError('obtener proveedores', e);
      throw Exception('Error al obtener la lista de proveedores: $e');
    }
  }

  /// Asegura que exista un usuario administrador para las operaciones de auditoría
  Future<int> _asegurarUsuarioAdministrador(int? usuarioModificacion) async {
    try {
      return await _db.withConnection((conn) async {
        final idUsuario = usuarioModificacion ?? 1;

        // Verificar si existe el usuario usando procedimiento almacenado
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL VerificarUsuarioExiste(?, @existe)', [
            idUsuario,
          ]);
          final verificacion = await conn.query('SELECT @existe as existe');

          if (verificacion.isEmpty || verificacion.first['existe'] != 1) {
            AppLogger.warning(
              'ATENCIÓN: No existe usuario con ID=$idUsuario en la base de datos',
            );
            AppLogger.info('Creando usuario administrador automáticamente...');

            // Reiniciar variable de salida
            await conn.query('SET @id_admin_out = 0');

            // Crear usuario administrador usando procedimiento almacenado
            await conn.query(
              'CALL CrearUsuarioAdministrador(?, ?, ?, ?, ?, @id_admin_out)',
              [
                'Administrador',
                'Sistema',
                'admin',
                'admin123',
                'admin@sistema.com',
              ],
            );

            await conn.query('COMMIT');
            AppLogger.info('Usuario administrador creado exitosamente');
            return 1;
          }

          await conn.query('COMMIT');
          return idUsuario;
        } catch (e) {
          await conn.query('ROLLBACK');
          rethrow;
        }
      });
    } catch (e) {
      _manejarError('verificar usuario administrador', e);
      return 1; // En caso de error, devolver el ID por defecto
    }
  }

  /// Crea un nuevo proveedor usando procedimiento almacenado con reintentos automáticos
  Future<Proveedor> crearProveedor(
    Proveedor proveedor, {
    int? usuarioModificacion,
  }) async {
    int intentos = 0;
    const maxIntentos = 3;

    while (intentos < maxIntentos) {
      try {
        // Verificar la conexión antes de intentar la operación
        try {
          await verificarConexion();
        } catch (e) {
          AppLogger.warning('La conexión parece estar fallando: $e');
          await Future.delayed(Duration(seconds: 2));
        }

        // Utilizar withTransaction para manejo más robusto de la transacción
        return await _db.withTransaction((conn) async {
          AppLogger.info(
            'Iniciando creación de proveedor (intento ${intentos + 1}): ${proveedor.nombre}',
          );

          // Reinicia la variable de salida
          await conn.query('SET @p_id_proveedor_out = 0');

          // Llamada al procedimiento almacenado - CORREGIDO: Eliminado parámetro de usuario
          await conn.query(
            'CALL CrearProveedor(?, ?, ?, ?, ?, ?, ?, @p_id_proveedor_out)',
            [
              proveedor.nombre,
              proveedor.nombreEmpresa,
              proveedor.nombreContacto,
              proveedor.direccion,
              proveedor.telefono,
              proveedor.correo,
              proveedor.tipoServicio,
            ],
          );

          // Obtiene el ID del proveedor creado
          final result = await conn.query('SELECT @p_id_proveedor_out AS id');
          if (result.isEmpty || result.first['id'] == null) {
            throw Exception('No se pudo obtener el ID del proveedor creado');
          }

          final idNuevoProveedor = result.first['id'] as int;
          AppLogger.info(
            'Proveedor creado exitosamente con ID: $idNuevoProveedor',
          );

          return proveedor.copyWith(idProveedor: idNuevoProveedor);
        });
      } catch (e) {
        intentos++;
        _manejarError('crear proveedor (intento $intentos)', e);

        // Determinar si es un error temporal
        bool esErrorTemporal = _esErrorTemporal(e);

        if (intentos >= maxIntentos || !esErrorTemporal) {
          AppLogger.error(
            'Todos los intentos de crear proveedor fallaron o no es un error temporal',
          );
          throw Exception('Error al crear proveedor: $e');
        }

        // Esperar con backoff exponencial antes de reintentar
        final tiempoEspera = Duration(seconds: 2 * (1 << intentos));
        AppLogger.info('Reintentando en ${tiempoEspera.inSeconds} segundos...');
        await Future.delayed(tiempoEspera);
      }
    }

    // Esta línea no debería alcanzarse, pero por seguridad
    throw Exception(
      "No se pudo crear el proveedor después de múltiples intentos",
    );
  }

  /// Determina si un error es temporal y se puede reintentar
  bool _esErrorTemporal(dynamic e) {
    final error = e.toString().toLowerCase();
    return error.contains('timeout') ||
        error.contains('connection') ||
        error.contains('socket') ||
        error.contains('mysql') ||
        error.contains('network') ||
        error.contains('recurso ocupado') ||
        error.contains('deadlock') ||
        error.contains('no se pudo conectar');
  }

  /// Actualiza un proveedor existente usando procedimiento almacenado
  Future<void> actualizarProveedor(
    Proveedor proveedor, {
    int? usuarioModificacion,
  }) async {
    try {
      return await _db.withTransaction((conn) async {
        AppLogger.info('Actualizando proveedor ID: ${proveedor.idProveedor}');

        final idUsuarioReal = await _asegurarUsuarioAdministrador(
          usuarioModificacion,
        );

        await conn
            .query('CALL ActualizarProveedor(?, ?, ?, ?, ?, ?, ?, ?, ?)', [
              proveedor.idProveedor,
              proveedor.nombre,
              proveedor.nombreEmpresa,
              proveedor.nombreContacto,
              proveedor.direccion,
              proveedor.telefono,
              proveedor.correo,
              proveedor.tipoServicio,
              idUsuarioReal,
            ]);

        AppLogger.info(
          'Proveedor ${proveedor.idProveedor} actualizado exitosamente',
        );
      });
    } catch (e) {
      _manejarError('actualizar proveedor', e);
      throw Exception('Error al actualizar proveedor: $e');
    }
  }

  /// Obtiene una conexión activa a la base de datos
  Future<dynamic> verificarConexion() async {
    try {
      // Verificar que la conexión esté activa con un query simple
      final conn = await _db.connection;
      final result = await conn.query('SELECT 1 as test');
      await _db.releaseConnection(conn);

      if (result.isEmpty || result.first['test'] != 1) {
        throw Exception('La conexión no está respondiendo correctamente');
      }

      return true;
    } catch (e) {
      _manejarError('verificar conexión', e);
      throw Exception('Error al establecer conexión con la base de datos: $e');
    }
  }

  /// Inactiva un proveedor usando procedimiento almacenado
  Future<void> inactivarProveedor(
    int idProveedor, {
    int? usuarioModificacion,
  }) async {
    try {
      return await _db.withTransaction((conn) async {
        AppLogger.info('Inactivando proveedor con ID: $idProveedor');

        final idUsuarioReal = await _asegurarUsuarioAdministrador(
          usuarioModificacion,
        );

        // Usar el procedimiento almacenado para inactivar proveedor
        await conn.query('CALL InactivarProveedor(?, ?)', [
          idProveedor,
          idUsuarioReal,
        ]);

        AppLogger.info('Proveedor ID:$idProveedor inactivado correctamente');
      });
    } catch (e) {
      _manejarError('inactivar proveedor', e);
      throw Exception('Error al inactivar proveedor: $e');
    }
  }

  /// Busca proveedores según un término de búsqueda usando procedimiento almacenado
  Future<List<Proveedor>> buscarProveedores(String termino) async {
    try {
      return await _db.withConnection((conn) async {
        AppLogger.info('Buscando proveedores con término: "$termino"');

        final result = await conn.query('CALL BuscarProveedores(?)', [termino]);

        final proveedores =
            result.map((row) {
              final map = <String, dynamic>{};
              for (var field in row.fields.keys) {
                map[field] = row[field];
              }
              // Asegurarse de que el campo estado_proveedor se maneje correctamente
              if (map.containsKey('estado_proveedor')) {
                map['nombre_estado'] = map['estado_proveedor'];
              }
              return Proveedor.fromMap(map);
            }).toList();

        AppLogger.info('Búsqueda completada: ${proveedores.length} resultados');
        return proveedores;
      });
    } catch (e) {
      _manejarError('buscar proveedores', e);
      throw Exception('Error al buscar proveedores: $e');
    }
  }

  /// Reactiva un proveedor usando procedimiento almacenado
  Future<void> reactivarProveedor(
    int idProveedor, {
    int? usuarioModificacion,
  }) async {
    try {
      return await _db.withTransaction((conn) async {
        AppLogger.info('Reactivando proveedor con ID: $idProveedor');

        final idUsuarioReal = await _asegurarUsuarioAdministrador(
          usuarioModificacion,
        );

        // Usar el procedimiento almacenado para reactivar proveedor
        await conn.query('CALL ReactivarProveedor(?, ?)', [
          idProveedor,
          idUsuarioReal,
        ]);

        AppLogger.info('Proveedor ID:$idProveedor reactivado correctamente');
      });
    } catch (e) {
      _manejarError('reactivar proveedor', e);
      throw Exception('Error al reactivar proveedor: $e');
    }
  }

  /// Método auxiliar para manejar errores evitando duplicados
  void _manejarError(String operacion, dynamic error) {
    if (!_procesandoError) {
      _procesandoError = true;
      AppLogger.error(
        'Error en operación "$operacion"',
        error,
        StackTrace.current,
      );
      _procesandoError = false;
    }
  }
}

/// Extensión para facilitar la creación de copias de Proveedor
extension ProveedorExtension on Proveedor {
  Proveedor copyWith({
    int? idProveedor,
    String? nombre,
    String? nombreEmpresa,
    String? nombreContacto,
    String? direccion,
    String? telefono,
    String? correo,
    String? tipoServicio,
    int? idEstado,
  }) {
    return Proveedor(
      idProveedor: idProveedor ?? this.idProveedor,
      nombre: nombre ?? this.nombre,
      nombreEmpresa: nombreEmpresa ?? this.nombreEmpresa,
      nombreContacto: nombreContacto ?? this.nombreContacto,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      tipoServicio: tipoServicio ?? this.tipoServicio,
      idEstado: idEstado ?? this.idEstado,
    );
  }
}

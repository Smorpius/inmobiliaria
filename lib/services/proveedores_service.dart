import 'dart:async';
import 'mysql_helper.dart';
import '../models/proveedor.dart';
import 'dart:developer' as developer;

class ProveedoresService {
  final DatabaseService _db;

  ProveedoresService([DatabaseService? db]) : _db = db ?? DatabaseService();

  /// Obtiene la lista de todos los proveedores
  Future<List<Proveedor>> obtenerProveedores() async {
    try {
      final conn = await _db.connection;
      final result = await conn.query('CALL ObtenerProveedores()');

      return result.map((row) {
        final map = <String, dynamic>{};
        for (var field in row.fields.keys) {
          map[field] = row[field];
        }
        return Proveedor.fromMap(map);
      }).toList();
    } catch (e) {
      developer.log('Error al obtener proveedores: $e', error: e);
      rethrow;
    }
  }

  /// Asegura que exista un usuario administrador para las operaciones de auditoría
  Future<int> _asegurarUsuarioAdministrador(int? usuarioModificacion) async {
    try {
      final conn = await _db.connection;
      final idUsuario = usuarioModificacion ?? 1;

      // Verificar si existe el usuario
      final verificacion = await conn.query(
        'SELECT id_usuario FROM usuarios WHERE id_usuario = ?',
        [idUsuario],
      );

      if (verificacion.isEmpty) {
        developer.log(
          'ATENCIÓN: No existe usuario con ID=$idUsuario en la base de datos',
        );
        developer.log('Creando usuario administrador automáticamente...');

        await conn.query('''
          INSERT INTO usuarios (
            id_usuario, 
            nombre, 
            apellido, 
            nombre_usuario, 
            contraseña_usuario, 
            correo_cliente,
            id_estado
          ) 
          VALUES (1, 'Administrador', 'Sistema', 'admin', 'admin123', 'admin@sistema.com', 1)
          ON DUPLICATE KEY UPDATE id_usuario = 1
        ''');

        developer.log(
          'Usuario administrador creado con credenciales completas',
        );
        return 1;
      }

      return idUsuario;
    } catch (e) {
      developer.log('Error verificando usuario: $e', error: e);
      return 1;
    }
  }

  /// Crea un nuevo proveedor
  Future<Proveedor> crearProveedor(
    Proveedor proveedor, {
    int? usuarioModificacion,
  }) async {
    try {
      final conn = await _db.connection;
      int idNuevoProveedor;

      try {
        developer.log('Intentando crear proveedor: ${proveedor.nombre}');

        // Verifica o crea el usuario para la auditoría
        final idUsuarioReal = await _asegurarUsuarioAdministrador(
          usuarioModificacion,
        );

        // Reinicia la variable de salida
        await conn.query('SET @p_id_proveedor_out = 0');

        // Llamada al procedimiento almacenado
        await conn.query(
          '''
          CALL CrearProveedor(?, ?, ?, ?, ?, ?, ?, ?, @p_id_proveedor_out)
        ''',
          [
            proveedor.nombre,
            proveedor.nombreEmpresa,
            proveedor.nombreContacto,
            proveedor.direccion,
            proveedor.telefono,
            proveedor.correo,
            proveedor.tipoServicio,
            idUsuarioReal,
          ],
        );

        // Obtiene el ID del proveedor creado
        final result = await conn.query('SELECT @p_id_proveedor_out AS id');
        if (result.isEmpty || result.first['id'] == null) {
          throw Exception('No se pudo obtener el ID del proveedor creado');
        }

        idNuevoProveedor = result.first['id'] as int;
        developer.log('Proveedor creado con ID: $idNuevoProveedor');
      } catch (e) {
        developer.log('Error SQL específico: $e', error: e);
        throw Exception('Error en la operación de base de datos: $e');
      }

      return proveedor.copyWith(idProveedor: idNuevoProveedor);
    } catch (e) {
      developer.log('Error detallado al crear proveedor: $e', error: e);
      rethrow;
    }
  }

  /// Actualiza un proveedor existente
  Future<void> actualizarProveedor(
    Proveedor proveedor, {
    int? usuarioModificacion,
  }) async {
    try {
      final conn = await _db.connection;
      final idUsuarioReal = await _asegurarUsuarioAdministrador(
        usuarioModificacion,
      );

      await conn.query('CALL ActualizarProveedor(?, ?, ?, ?, ?, ?, ?, ?, ?)', [
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
    } catch (e) {
      developer.log('Error al actualizar proveedor: $e', error: e);
      rethrow;
    }
  }

  /// Obtiene una conexión activa a la base de datos
  Future<dynamic> verificarConexion() async {
    try {
      return await _db.connection;
    } catch (e) {
      developer.log('Error al obtener conexión: $e', error: e);
      rethrow;
    }
  }

  /// Inactiva un proveedor
  Future<void> inactivarProveedor(
    int idProveedor, {
    int? usuarioModificacion,
  }) async {
    try {
      final conn = await _db.connection;
      final idUsuarioReal = await _asegurarUsuarioAdministrador(
        usuarioModificacion,
      );

      // CORREGIDO: Eliminar usuario_modificacion del UPDATE
      developer.log(
        'Inactivando proveedor con ID: $idProveedor (cambiando estado a 2)',
      );
      await conn.query(
        '''
        UPDATE proveedores 
        SET id_estado = 2, 
            fecha_modificacion = NOW() 
        WHERE id_proveedor = ?
        ''',
        [idProveedor],
      );

      // Actualizar tabla historial_proveedores para auditoría
      try {
        // Obtener estado anterior
        final estadoAnteriorResult = await conn.query(
          'SELECT id_estado FROM proveedores WHERE id_proveedor = ?',
          [idProveedor],
        );

        // CORREGIDO: Usar isNotEmpty en lugar de !isEmpty
        if (estadoAnteriorResult.isNotEmpty) {
          final estadoAnterior = estadoAnteriorResult.first['id_estado'] as int;

          // Registrar en historial
          await conn.query(
            '''
            INSERT INTO historial_proveedores
            (id_proveedor, id_estado_anterior, id_estado_nuevo, usuario_modificacion)
            VALUES (?, ?, 2, ?)
            ''',
            [idProveedor, estadoAnterior, idUsuarioReal],
          );
        }
      } catch (historialError) {
        developer.log(
          'Advertencia: No se pudo actualizar el historial: $historialError',
          error: historialError,
        );
        // No interrumpimos la operación principal si falla el historial
      }

      // Verificar que el proveedor siga existiendo pero con estado inactivo
      final check = await conn.query(
        'SELECT id_estado FROM proveedores WHERE id_proveedor = ?',
        [idProveedor],
      );

      if (check.isEmpty) {
        developer.log(
          'ERROR: El proveedor ID:$idProveedor no existe después de inactivarlo',
        );
        throw Exception(
          'El proveedor fue eliminado en lugar de ser inactivado',
        );
      } else {
        developer.log(
          'Proveedor ID:$idProveedor inactivado correctamente, estado actual: ${check.first['id_estado']}',
        );
      }
    } catch (e) {
      developer.log('Error al inactivar proveedor: $e', error: e);
      rethrow;
    }
  }

  /// Busca proveedores según un término de búsqueda
  Future<List<Proveedor>> buscarProveedores(String termino) async {
    try {
      final conn = await _db.connection;
      developer.log('Buscando proveedores con término: "$termino"');

      final result = await conn.query('CALL BuscarProveedores(?)', [termino]);

      final proveedores =
          result.map((row) {
            // Mapeo completo para incluir todos los campos de tu procedimiento
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

      developer.log('Proveedores encontrados: ${proveedores.length}');
      return proveedores;
    } catch (e) {
      developer.log('Error al buscar proveedores: $e', error: e);
      rethrow;
    }
  }

  /// Reactiva un proveedor
  Future<void> reactivarProveedor(
    int idProveedor, {
    int? usuarioModificacion,
  }) async {
    try {
      final conn = await _db.connection;
      final idUsuarioReal = await _asegurarUsuarioAdministrador(
        usuarioModificacion,
      );

      // CORREGIDO: Eliminar usuario_modificacion del UPDATE
      developer.log(
        'Reactivando proveedor con ID: $idProveedor (cambiando estado a 1)',
      );
      await conn.query(
        '''
        UPDATE proveedores 
        SET id_estado = 1, 
            fecha_modificacion = NOW() 
        WHERE id_proveedor = ?
        ''',
        [idProveedor],
      );

      // Actualizar tabla historial_proveedores para auditoría
      try {
        // Obtener estado anterior
        final estadoAnteriorResult = await conn.query(
          'SELECT id_estado FROM proveedores WHERE id_proveedor = ?',
          [idProveedor],
        );

        // CORREGIDO: Usar isNotEmpty en lugar de !isEmpty
        if (estadoAnteriorResult.isNotEmpty) {
          final estadoAnterior = estadoAnteriorResult.first['id_estado'] as int;

          // Registrar en historial
          await conn.query(
            '''
            INSERT INTO historial_proveedores
            (id_proveedor, id_estado_anterior, id_estado_nuevo, usuario_modificacion)
            VALUES (?, ?, 1, ?)
            ''',
            [idProveedor, estadoAnterior, idUsuarioReal],
          );
        }
      } catch (historialError) {
        developer.log(
          'Advertencia: No se pudo actualizar el historial: $historialError',
          error: historialError,
        );
        // No interrumpimos la operación principal si falla el historial
      }

      // Verificar que el proveedor siga existiendo pero con estado activo
      final check = await conn.query(
        'SELECT id_estado FROM proveedores WHERE id_proveedor = ?',
        [idProveedor],
      );

      if (check.isEmpty) {
        developer.log(
          'ERROR: El proveedor ID:$idProveedor no existe después de reactivarlo',
        );
        throw Exception('El proveedor no pudo ser reactivado');
      } else {
        developer.log(
          'Proveedor ID:$idProveedor reactivado correctamente, estado actual: ${check.first['id_estado']}',
        );
      }
    } catch (e) {
      developer.log('Error al reactivar proveedor: $e', error: e);
      rethrow;
    }
  }
}

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

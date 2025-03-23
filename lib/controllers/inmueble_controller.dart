import 'dart:async';
import 'package:intl/intl.dart';
import '../models/venta_model.dart';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';
import '../models/inmueble_model.dart';
import '../services/mysql_helper.dart';
import '../models/inmueble_imagen.dart';
import '../models/inmueble_proveedor_servicio.dart';

class InmuebleController {
  final DatabaseService dbHelper;
  final Logger _logger = Logger('InmuebleController');

  InmuebleController({DatabaseService? dbService})
    : dbHelper = dbService ?? DatabaseService();

  Future<List<Inmueble>> getInmuebles() async {
    try {
      _logger.info('Iniciando consulta de inmuebles...');
      developer.log('Consultando todos los inmuebles...');
      final db = await dbHelper.connection;

      // Usar LEFT JOIN para no perder registros si falta alguna relación
      final results = await db.query('''
        SELECT 
          i.*,
          d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
          d.codigo_postal, d.referencias,
          e.nombre_estado AS estado_inmueble
        FROM inmuebles i
        LEFT JOIN direcciones d ON i.id_direccion = d.id_direccion
        LEFT JOIN estados e ON i.id_estado = e.id_estado
        ORDER BY i.fecha_registro DESC
      ''');

      if (results.isEmpty) return [];

      final List<Inmueble> inmuebles = [];

      for (var row in results) {
        try {
          final inmueble = Inmueble.fromMap(row.fields);
          inmuebles.add(inmueble);
        } catch (e) {
          _logger.warning('Error procesando inmueble: $e');
          developer.log('Error al procesar inmueble: $e');
        }
      }

      return inmuebles;
    } catch (e) {
      _logger.severe('Error al obtener inmuebles: $e');
      throw Exception('Error al obtener inmuebles: $e');
    }
  }

  Future<int> insertInmueble(Inmueble inmueble) async {
    try {
      if (inmueble.id != null) {
        throw Exception('No se puede insertar un inmueble con ID');
      }

      developer.log('Insertando inmueble: ${inmueble.nombre}');
      final estadoInmueble = inmueble.idEstado ?? 3;

      final db = await dbHelper.connection;

      // Usar el procedimiento actualizado con los nuevos campos financieros
      await db.query(
        'CALL CrearInmueble(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @id_inmueble_out)',
        [
          inmueble.nombre,
          inmueble.calle ?? '',
          inmueble.numero ?? '',
          inmueble.colonia ?? '',
          inmueble.ciudad ?? '',
          inmueble.estadoGeografico ?? '',
          inmueble.codigoPostal ?? '',
          inmueble.referencias ?? '',
          inmueble.montoTotal,
          inmueble.tipoInmueble,
          inmueble.tipoOperacion,
          inmueble.precioVenta,
          inmueble.precioRenta,
          estadoInmueble,
          inmueble.idCliente,
          inmueble.idEmpleado,
          inmueble.caracteristicas,
          inmueble.costoCliente ?? 0.0, // Nuevo parámetro
          inmueble.costoServicios ?? 0.0, // Nuevo parámetro
        ],
      );

      // Obtener el ID generado por el procedimiento almacenado
      final idResult = await db.query('SELECT @id_inmueble_out as id');

      if (idResult.isEmpty || idResult.first.fields['id'] == null) {
        throw Exception('No se pudo obtener el ID del inmueble creado');
      }

      final inmuebleId = idResult.first.fields['id'] as int;

      // Esperar a que la transacción se complete
      await Future.delayed(const Duration(milliseconds: 300));

      return inmuebleId;
    } catch (e) {
      _logger.severe('Error al insertar inmueble: $e');
      throw Exception('Error al insertar inmueble: $e');
    }
  }

  Future<int> updateInmueble(Inmueble inmueble) async {
    try {
      if (inmueble.id == null) {
        throw Exception('No se puede actualizar un inmueble sin ID');
      }

      _logger.info('Actualizando inmueble: $inmueble');
      final db = await dbHelper.connection;

      // Usar el procedimiento actualizado con los nuevos campos financieros
      final result = await db.query(
        'CALL ActualizarInmueble(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          inmueble.id, // p_id_inmueble
          inmueble.nombre, // p_nombre_inmueble
          inmueble.calle, // p_direccion_calle
          inmueble.numero, // p_direccion_numero
          inmueble.colonia, // p_direccion_colonia
          inmueble.ciudad, // p_direccion_ciudad
          inmueble.estadoGeografico, // p_direccion_estado_geografico
          inmueble.codigoPostal, // p_direccion_codigo_postal
          inmueble.referencias, // p_direccion_referencias
          inmueble.montoTotal, // p_monto_total
          inmueble.tipoInmueble, // p_tipo_inmueble
          inmueble.tipoOperacion, // p_tipo_operacion
          inmueble.precioVenta, // p_precio_venta
          inmueble.precioRenta, // p_precio_renta
          inmueble.idEstado, // p_id_estado
          inmueble.idCliente, // p_id_cliente
          inmueble.idEmpleado, // p_id_empleado
          inmueble.caracteristicas, // p_caracteristicas
          inmueble.costoCliente ?? 0.0, // p_costo_cliente - Nuevo
          inmueble.costoServicios ?? 0.0, // p_costo_servicios - Nuevo
        ],
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

      // Primero obtener el id_direccion para eliminar después
      final direccionQuery = await db.query(
        'SELECT id_direccion FROM inmuebles WHERE id_inmueble = ?',
        [id],
      );

      int? idDireccion;
      if (direccionQuery.isNotEmpty) {
        idDireccion = direccionQuery.first.fields['id_direccion'] as int?;
      }

      // Eliminar primero los registros relacionados
      await db.query(
        'DELETE FROM inmuebles_clientes_interesados WHERE id_inmueble = ?',
        [id],
      );

      await db.query('DELETE FROM inmuebles_imagenes WHERE id_inmueble = ?', [
        id,
      ]);

      // Eliminar servicios de proveedores asociados
      await db.query(
        'DELETE FROM inmueble_proveedor_servicio WHERE id_inmueble = ?',
        [id],
      );

      // Luego eliminar el inmueble
      final result = await db.query(
        'DELETE FROM inmuebles WHERE id_inmueble = ?',
        [id],
      );

      // Finalmente eliminar la dirección si existe
      if (idDireccion != null) {
        await db.query('DELETE FROM direcciones WHERE id_direccion = ?', [
          idDireccion,
        ]);
      }

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

  // Método para buscar inmuebles por criterios
  Future<List<Inmueble>> buscarInmuebles({
    String? tipo,
    String? operacion,
    double? precioMin,
    double? precioMax,
    String? ciudad,
    int? idEstado,
  }) async {
    try {
      _logger.info('Buscando inmuebles con criterios específicos');
      final db = await dbHelper.connection;

      String query = '''
        SELECT 
          i.*,
          d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
          d.codigo_postal, d.referencias,
          e.nombre_estado AS estado_inmueble
        FROM inmuebles i
        LEFT JOIN direcciones d ON i.id_direccion = d.id_direccion
        LEFT JOIN estados e ON i.id_estado = e.id_estado
        WHERE 1=1
      ''';

      List<Object> params = [];

      if (tipo != null && tipo.isNotEmpty) {
        query += ' AND i.tipo_inmueble = ?';
        params.add(tipo);
      }

      if (operacion != null && operacion.isNotEmpty) {
        query += ' AND i.tipo_operacion = ?';
        params.add(operacion);
      }

      if (precioMin != null) {
        query += ' AND i.monto_total >= ?';
        params.add(precioMin);
      }

      if (precioMax != null) {
        query += ' AND i.monto_total <= ?';
        params.add(precioMax);
      }

      if (ciudad != null && ciudad.isNotEmpty) {
        query += ' AND d.ciudad LIKE ?';
        params.add('%$ciudad%');
      }

      if (idEstado != null) {
        query += ' AND i.id_estado = ?';
        params.add(idEstado);
      }

      query += ' ORDER BY i.fecha_registro DESC';

      final results = await db.query(query, params);

      final List<Inmueble> inmuebles = [];
      for (var row in results) {
        try {
          inmuebles.add(Inmueble.fromMap(row.fields));
        } catch (e) {
          _logger.warning('Error procesando inmueble en búsqueda: $e');
        }
      }

      return inmuebles;
    } catch (e) {
      _logger.severe('Error al buscar inmuebles: $e');
      throw Exception('Error en la búsqueda de inmuebles: $e');
    }
  }

  // Método para obtener los clientes interesados en un inmueble
  Future<List<Map<String, dynamic>>> getClientesInteresados(
    int idInmueble,
  ) async {
    try {
      _logger.info('Obteniendo clientes interesados en inmueble: $idInmueble');
      final db = await dbHelper.connection;

      final results = await db.query(
        '''
        SELECT 
          ci.id, ci.id_inmueble, ci.id_cliente, ci.fecha_interes, ci.comentarios,
          c.nombre, c.apellido_paterno, c.apellido_materno, c.telefono_cliente, c.correo_cliente
        FROM inmuebles_clientes_interesados ci
        JOIN clientes c ON ci.id_cliente = c.id_cliente
        WHERE ci.id_inmueble = ?
        ORDER BY ci.fecha_interes DESC
      ''',
        [idInmueble],
      );

      return results.map((row) => row.fields).toList();
    } catch (e) {
      _logger.severe('Error al obtener clientes interesados: $e');
      throw Exception('Error al obtener clientes interesados: $e');
    }
  }

  // Método para registrar un cliente interesado
  Future<int> registrarClienteInteresado(
    int idInmueble,
    int idCliente,
    String? comentarios,
  ) async {
    try {
      _logger.info(
        'Registrando cliente $idCliente interesado en inmueble $idInmueble',
      );
      final db = await dbHelper.connection;

      final result = await db.query(
        '''
        INSERT INTO inmuebles_clientes_interesados (id_inmueble, id_cliente, comentarios)
        VALUES (?, ?, ?)
        ''',
        [idInmueble, idCliente, comentarios],
      );

      return result.insertId ?? -1;
    } catch (e) {
      _logger.severe('Error al registrar cliente interesado: $e');
      throw Exception('Error al registrar cliente interesado: $e');
    }
  }

  // Método para registrar una venta
  Future<int> registrarVenta(Venta venta) async {
    try {
      _logger.info('Registrando venta para inmueble: ${venta.idInmueble}');
      final db = await dbHelper.connection;

      await db.query('CALL CrearVenta(?, ?, ?, ?, ?, ?, @id_venta_out)', [
        venta.idCliente,
        venta.idInmueble,
        venta.fechaVenta.toIso8601String().split('T')[0],
        venta.ingreso,
        venta.comisionProveedores,
        venta.utilidadNeta,
      ]);

      final result = await db.query('SELECT @id_venta_out as id');
      return result.first.fields['id'] as int;
    } catch (e) {
      _logger.severe('Error al registrar venta: $e');
      throw Exception('Error al registrar venta: $e');
    }
  }

  // Método para obtener todas las ventas
  Future<List<Venta>> getVentas() async {
    try {
      _logger.info('Obteniendo lista de ventas');
      final db = await dbHelper.connection;

      final results = await db.query('CALL ObtenerVentas()');

      // Corrección para evitar los errores de operador []
      if (results.isEmpty) return [];

      // Convertir directamente los resultados a lista de Venta
      return results.map((row) => Venta.fromMap(row.fields)).toList();
    } catch (e) {
      _logger.severe('Error al obtener ventas: $e');
      throw Exception('Error al obtener ventas: $e');
    }
  }

  // MÉTODOS PARA GESTIÓN DE IMÁGENES

  // Obtener imágenes de un inmueble
  Future<List<InmuebleImagen>> getImagenesInmueble(int idInmueble) async {
    try {
      _logger.info('Obteniendo imágenes del inmueble: $idInmueble');
      final db = await dbHelper.connection;

      final results = await db.query(
        '''
        SELECT * FROM inmuebles_imagenes 
        WHERE id_inmueble = ? 
        ORDER BY es_principal DESC, fecha_carga DESC
        ''',
        [idInmueble],
      );

      return results.map((row) => InmuebleImagen.fromMap(row.fields)).toList();
    } catch (e) {
      _logger.severe('Error al obtener imágenes del inmueble: $e');
      throw Exception('Error al obtener imágenes del inmueble: $e');
    }
  }

  // Obtener la imagen principal de un inmueble
  Future<InmuebleImagen?> getImagenPrincipal(int idInmueble) async {
    try {
      _logger.info('Obteniendo imagen principal del inmueble: $idInmueble');
      final db = await dbHelper.connection;

      final results = await db.query(
        '''
        SELECT * FROM inmuebles_imagenes 
        WHERE id_inmueble = ? AND es_principal = 1
        LIMIT 1
        ''',
        [idInmueble],
      );

      if (results.isEmpty) return null;
      return InmuebleImagen.fromMap(results.first.fields);
    } catch (e) {
      _logger.severe('Error al obtener imagen principal: $e');
      throw Exception('Error al obtener imagen principal: $e');
    }
  }

  // Agregar imagen a un inmueble
  Future<int> agregarImagenInmueble(InmuebleImagen imagen) async {
    try {
      _logger.info('Agregando imagen al inmueble: ${imagen.idInmueble}');
      final db = await dbHelper.connection;

      // Si la imagen es principal, primero desmarcar otras como principal
      if (imagen.esPrincipal) {
        await db.query(
          'UPDATE inmuebles_imagenes SET es_principal = 0 WHERE id_inmueble = ?',
          [imagen.idInmueble],
        );
      }

      final result = await db.query(
        '''
        INSERT INTO inmuebles_imagenes 
        (id_inmueble, ruta_imagen, descripcion, es_principal, fecha_carga) 
        VALUES (?, ?, ?, ?, NOW())
        ''',
        [
          imagen.idInmueble,
          imagen.rutaImagen,
          imagen.descripcion,
          imagen.esPrincipal ? 1 : 0,
        ],
      );

      return result.insertId ?? -1;
    } catch (e) {
      _logger.severe('Error al agregar imagen al inmueble: $e');
      throw Exception('Error al agregar imagen al inmueble: $e');
    }
  }

  // Marcar imagen como principal
  Future<bool> marcarImagenComoPrincipal(int idImagen, int idInmueble) async {
    try {
      _logger.info(
        'Marcando imagen $idImagen como principal para inmueble $idInmueble',
      );
      final db = await dbHelper.connection;

      // Primero desmarcar todas las imágenes del inmueble
      await db.query(
        'UPDATE inmuebles_imagenes SET es_principal = 0 WHERE id_inmueble = ?',
        [idInmueble],
      );

      // Luego marcar la imagen seleccionada como principal
      final result = await db.query(
        'UPDATE inmuebles_imagenes SET es_principal = 1 WHERE id_imagen = ? AND id_inmueble = ?',
        [idImagen, idInmueble],
      );

      _logger.info(
        'Imagen actualizada como principal: ${result.affectedRows} filas',
      );
      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      _logger.severe('Error al marcar imagen como principal: $e');
      throw Exception('Error al marcar imagen como principal: $e');
    }
  }

  // Eliminar imagen
  Future<bool> eliminarImagenInmueble(int idImagen) async {
    try {
      _logger.info('Eliminando imagen con ID: $idImagen');
      final db = await dbHelper.connection;

      // Verificar si es imagen principal antes de eliminar
      final checkResult = await db.query(
        'SELECT es_principal, id_inmueble FROM inmuebles_imagenes WHERE id_imagen = ?',
        [idImagen],
      );

      if (checkResult.isEmpty) {
        _logger.warning('No se encontró la imagen a eliminar: $idImagen');
        return false;
      }

      final bool esPrincipal = checkResult.first.fields['es_principal'] == 1;
      final int idInmueble = checkResult.first.fields['id_inmueble'] as int;

      // Eliminar la imagen
      final result = await db.query(
        'DELETE FROM inmuebles_imagenes WHERE id_imagen = ?',
        [idImagen],
      );

      // Si era la imagen principal, asignar otra como principal si existe
      if (esPrincipal) {
        final restantes = await db.query(
          'SELECT id_imagen FROM inmuebles_imagenes WHERE id_inmueble = ? LIMIT 1',
          [idInmueble],
        );

        if (restantes.isNotEmpty) {
          await marcarImagenComoPrincipal(
            restantes.first.fields['id_imagen'] as int,
            idInmueble,
          );
        }
      }

      _logger.info('Imagen eliminada: ${result.affectedRows} filas');
      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      _logger.severe('Error al eliminar imagen: $e');
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  // Actualizar descripción de imagen
  Future<bool> actualizarDescripcionImagen(
    int idImagen,
    String nuevaDescripcion,
  ) async {
    try {
      _logger.info('Actualizando descripción de imagen: $idImagen');
      final db = await dbHelper.connection;

      final result = await db.query(
        'UPDATE inmuebles_imagenes SET descripcion = ? WHERE id_imagen = ?',
        [nuevaDescripcion, idImagen],
      );

      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      _logger.severe('Error al actualizar descripción de imagen: $e');
      throw Exception('Error al actualizar descripción de imagen: $e');
    }
  }

  // MÉTODOS PARA GESTIÓN DE SERVICIOS DE PROVEEDORES

  // Método para obtener los servicios de proveedores para un inmueble
  Future<List<InmuebleProveedorServicio>> getServiciosProveedores(
    int idInmueble,
  ) async {
    try {
      _logger.info(
        'Obteniendo servicios de proveedores para inmueble: $idInmueble',
      );
      developer.log(
        'Consultando servicios de proveedores para inmueble: $idInmueble',
      );
      final db = await dbHelper.connection;

      final results = await db.query(
        'CALL ObtenerServiciosProveedorPorInmueble(?)',
        [idInmueble],
      );

      if (results.isEmpty) return [];

      final List<InmuebleProveedorServicio> servicios = [];
      for (var row in results) {
        try {
          final servicio = InmuebleProveedorServicio.fromMap(row.fields);
          servicios.add(servicio);
        } catch (e) {
          _logger.warning('Error procesando servicio: $e');
          developer.log('Error al procesar servicio de proveedor: $e');
        }
      }

      return servicios;
    } catch (e) {
      _logger.severe('Error al obtener servicios de proveedores: $e');
      throw Exception('Error al obtener servicios de proveedores: $e');
    }
  }

  // Método para asignar un proveedor a un inmueble
  Future<int> asignarProveedorAInmueble(
    InmuebleProveedorServicio servicio,
  ) async {
    try {
      _logger.info(
        'Asignando proveedor ${servicio.idProveedor} a inmueble ${servicio.idInmueble}',
      );
      developer.log(
        'Asignando proveedor a inmueble - Detalle: ${servicio.servicioDetalle}',
      );
      final db = await dbHelper.connection;

      await db.query(
        'CALL AsignarProveedorAInmueble(?, ?, ?, ?, ?, ?, @id_servicio_out)',
        [
          servicio.idInmueble,
          servicio.idProveedor,
          servicio.servicioDetalle,
          servicio.costo,
          DateFormat('yyyy-MM-dd').format(servicio.fechaAsignacion),
          servicio.fechaServicio != null
              ? DateFormat('yyyy-MM-dd').format(servicio.fechaServicio!)
              : null,
        ],
      );

      final result = await db.query('SELECT @id_servicio_out as id');
      final id = result.first.fields['id'] as int;

      _logger.info('Proveedor asignado correctamente, ID: $id');
      return id;
    } catch (e) {
      _logger.severe('Error al asignar proveedor a inmueble: $e');
      throw Exception('Error al asignar proveedor a inmueble: $e');
    }
  }

  // Método para eliminar una asignación de proveedor
  Future<bool> eliminarAsignacionProveedor(int id) async {
    try {
      _logger.info('Eliminando asignación de proveedor ID: $id');
      developer.log('Eliminando servicio de proveedor con ID: $id');
      final db = await dbHelper.connection;

      await db.query('CALL EliminarServicioProveedor(?)', [id]);

      _logger.info('Asignación de proveedor eliminada correctamente');
      return true;
    } catch (e) {
      _logger.severe('Error al eliminar asignación de proveedor: $e');
      throw Exception('Error al eliminar asignación de proveedor: $e');
    }
  }
}

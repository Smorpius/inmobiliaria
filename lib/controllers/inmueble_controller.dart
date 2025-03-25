import 'dart:io';
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

  // Configuración para reintentos
  static const int _maxReintentos = 3;
  static const Duration _delayBase = Duration(milliseconds: 500);

  InmuebleController({DatabaseService? dbService})
    : dbHelper = dbService ?? DatabaseService();

  /// Ejecuta una operación con manejo de reintentos
  Future<T> _ejecutarConReintentos<T>(
    String operacion,
    Future<T> Function() funcion,
  ) async {
    int intentos = 0;
    Exception? ultimoError;

    while (intentos < _maxReintentos) {
      try {
        // Esperamos estabilización si hubo reconexión reciente
        await dbHelper.esperarEstabilizacion();

        // Ejecutar la operación
        return await funcion();
      } catch (e) {
        intentos++;
        ultimoError = e is Exception ? e : Exception(e.toString());
        _logger.warning('Error en $operacion (intento $intentos): $e');

        final esErrorConexion =
            e.toString().toLowerCase().contains('socket') ||
            e.toString().toLowerCase().contains('connection') ||
            e.toString().toLowerCase().contains('closed');

        if (esErrorConexion) {
          // Espera exponencial entre reintentos para errores de conexión
          final espera = Duration(
            milliseconds: _delayBase.inMilliseconds * (1 << intentos),
          );
          developer.log(
            'Reintentando $operacion en ${espera.inMilliseconds}ms...',
          );
          await Future.delayed(espera);

          // Forzar reconexión a la base de datos
          try {
            await dbHelper.reiniciarConexion();
          } catch (reconnectError) {
            _logger.warning('Error al reconectar: $reconnectError');
          }
        } else {
          // Para otros tipos de errores, no reintentar
          _logger.severe('Error crítico en $operacion: $e');
          rethrow;
        }
      }
    }

    // Si llegamos aquí es porque se agotaron los reintentos
    throw ultimoError ??
        Exception(
          'Error desconocido en $operacion después de $_maxReintentos intentos',
        );
  }

  /// Método para recalcular las finanzas de todos los inmuebles
  Future<bool> recalcularFinanzas() async {
    return _ejecutarConReintentos('recalcular finanzas inmuebles', () async {
      _logger.info('Iniciando recálculo de finanzas para todos los inmuebles');
      developer.log('Ejecutando procedimiento de recálculo de finanzas');

      final db = await dbHelper.connection;

      // Ejecutar el procedimiento almacenado sin parámetros
      await db.query('CALL RecalcularFinanzasInmuebles()');

      _logger.info('Recálculo de finanzas completado exitosamente');
      return true;
    });
  }

  Future<List<Inmueble>> getInmuebles() async {
    return _ejecutarConReintentos('obtener inmuebles', () async {
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
    });
  }

  /// Método para ordenar inmuebles por margen de utilidad (de mayor a menor rentabilidad)
  List<Inmueble> ordenarPorMargenUtilidad(List<Inmueble> inmuebles) {
    // Crear una copia para no modificar la lista original
    final inmueblesOrdenados = List<Inmueble>.from(inmuebles);

    // Ordenar la lista por margen de utilidad de mayor a menor
    inmueblesOrdenados.sort(
      (a, b) => (b.margenUtilidad ?? 0).compareTo(a.margenUtilidad ?? 0),
    );

    return inmueblesOrdenados;
  }

  Future<int> insertInmueble(Inmueble inmueble) async {
    return _ejecutarConReintentos('insertar inmueble', () async {
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
          inmueble.costoCliente ?? 0.0,
          inmueble.costoServicios ?? 0.0,
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
    });
  }

  Future<int> updateInmueble(Inmueble inmueble) async {
    return _ejecutarConReintentos('actualizar inmueble', () async {
      if (inmueble.id == null) {
        throw Exception('No se puede actualizar un inmueble sin ID');
      }

      _logger.info('Actualizando inmueble: $inmueble');
      final db = await dbHelper.connection;

      // Usar el procedimiento actualizado con los nuevos campos financieros
      final result = await db.query(
        'CALL ActualizarInmueble(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          inmueble.id,
          inmueble.nombre,
          inmueble.calle,
          inmueble.numero,
          inmueble.colonia,
          inmueble.ciudad,
          inmueble.estadoGeografico,
          inmueble.codigoPostal,
          inmueble.referencias,
          inmueble.montoTotal,
          inmueble.tipoInmueble,
          inmueble.tipoOperacion,
          inmueble.precioVenta,
          inmueble.precioRenta,
          inmueble.idEstado,
          inmueble.idCliente,
          inmueble.idEmpleado,
          inmueble.caracteristicas,
          inmueble.costoCliente ?? 0.0,
          inmueble.costoServicios ?? 0.0,
        ],
      );

      return result.affectedRows ?? 0;
    });
  }

  /// Método para actualizar la utilidad de una venta considerando gastos adicionales
  Future<bool> actualizarUtilidadVenta(
    int idVenta,
    double gastosAdicionales,
  ) async {
    return _ejecutarConReintentos('actualizar utilidad venta', () async {
      _logger.info(
        'Actualizando utilidad de venta ID: $idVenta con gastos adicionales: $gastosAdicionales',
      );
      final db = await dbHelper.connection;

      await db.query('CALL ActualizarUtilidadVenta(?, ?)', [
        idVenta,
        gastosAdicionales,
      ]);

      _logger.info('Utilidad de venta actualizada correctamente');
      return true;
    });
  }

  Future<int> deleteInmueble(int id) async {
    return _ejecutarConReintentos('eliminar inmueble', () async {
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
    });
  }

  Future<bool> verificarExistenciaInmueble(int id) async {
    return _ejecutarConReintentos('verificar existencia inmueble', () async {
      _logger.info('Verificando existencia del inmueble con ID: $id');
      final db = await dbHelper.connection;

      final result = await db.query(
        'SELECT COUNT(*) as count FROM inmuebles WHERE id_inmueble = ?',
        [id],
      );

      final int count = result.first.fields['count'] as int;
      _logger.info('¿Inmueble $id existe? ${count > 0}');
      return count > 0;
    });
  }

  Future<List<Inmueble>> buscarInmuebles({
    String? tipo,
    String? operacion,
    double? precioMin,
    double? precioMax,
    String? ciudad,
    int? idEstado,
    double? margenMin, // Nuevo parámetro para filtrar por margen mínimo
  }) async {
    return _ejecutarConReintentos('buscar inmuebles', () async {
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

      // Nuevo filtro por margen de utilidad mínimo
      if (margenMin != null && margenMin > 0) {
        query += ' AND i.margen_utilidad >= ?';
        params.add(margenMin);
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
    });
  }

  Future<List<Map<String, dynamic>>> getClientesInteresados(
    int idInmueble,
  ) async {
    return _ejecutarConReintentos('obtener clientes interesados', () async {
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
    });
  }

  Future<int> registrarClienteInteresado(
    int idInmueble,
    int idCliente,
    String? comentarios,
  ) async {
    return _ejecutarConReintentos('registrar cliente interesado', () async {
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
    });
  }

  Future<int> registrarVenta(Venta venta) async {
    return _ejecutarConReintentos('registrar venta', () async {
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
    });
  }

  Future<List<Venta>> getVentas() async {
    return _ejecutarConReintentos('obtener ventas', () async {
      _logger.info('Obteniendo lista de ventas');
      final db = await dbHelper.connection;

      final results = await db.query('CALL ObtenerVentas()');

      if (results.isEmpty) return [];
      return results.map((row) => Venta.fromMap(row.fields)).toList();
    });
  }

  // MÉTODOS PARA GESTIÓN DE IMÁGENES

  Future<List<InmuebleImagen>> getImagenesInmueble(int idInmueble) async {
    return _ejecutarConReintentos('obtener imágenes inmueble', () async {
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

      List<InmuebleImagen> imagenes = [];
      for (var row in results) {
        try {
          Map<String, dynamic> datosSanitizados = {};
          final datos = row.fields;

          if (datos['id_imagen'] is int) {
            datosSanitizados['id_imagen'] = datos['id_imagen'];
          } else if (datos['id_imagen'] != null) {
            final idParsed = int.tryParse(datos['id_imagen'].toString().trim());
            if (idParsed == null) continue;
            datosSanitizados['id_imagen'] = idParsed;
          } else {
            continue;
          }

          if (datos['id_inmueble'] is int) {
            datosSanitizados['id_inmueble'] = datos['id_inmueble'];
          } else {
            final idParsed = int.tryParse(
              datos['id_inmueble'].toString().trim(),
            );
            if (idParsed != idInmueble) continue;
            datosSanitizados['id_inmueble'] = idParsed;
          }

          datosSanitizados['ruta_imagen'] =
              datos['ruta_imagen']?.toString() ?? '';
          datosSanitizados['descripcion'] = datos['descripcion']?.toString();
          datosSanitizados['es_principal'] =
              datos['es_principal'] == 1 ||
              datos['es_principal'].toString().toLowerCase() == 'true';

          if (datos['fecha_carga'] != null) {
            try {
              if (datos['fecha_carga'] is DateTime) {
                datosSanitizados['fecha_carga'] = datos['fecha_carga'];
              } else {
                datosSanitizados['fecha_carga'] = DateTime.parse(
                  datos['fecha_carga'].toString(),
                );
              }
            } catch (e) {
              _logger.warning(
                'Error al parsear fecha: $e, usando fecha actual',
              );
              datosSanitizados['fecha_carga'] = DateTime.now();
            }
          }

          if (datosSanitizados['ruta_imagen'].isNotEmpty) {
            imagenes.add(InmuebleImagen.fromMap(datosSanitizados));
          }
        } catch (e) {
          _logger.warning('Error al procesar imagen: $e');
        }
      }

      return imagenes;
    });
  }

  Future<InmuebleImagen?> getImagenPrincipal(int idInmueble) async {
    return _ejecutarConReintentos('obtener imagen principal', () async {
      _logger.info('Obteniendo imagen principal para inmueble: $idInmueble');
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

      try {
        return InmuebleImagen.fromMap(results.first.fields);
      } catch (e) {
        _logger.warning('Error procesando imagen principal: $e');
        return null;
      }
    });
  }

  Future<int> agregarImagenInmueble(InmuebleImagen imagen) async {
    return _ejecutarConReintentos('agregar imagen inmueble', () async {
      _logger.info('Agregando imagen al inmueble: ${imagen.idInmueble}');
      final db = await dbHelper.connection;

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
    });
  }

  Future<bool> marcarImagenComoPrincipal(int idImagen, int idInmueble) async {
    return _ejecutarConReintentos('marcar imagen como principal', () async {
      _logger.info(
        'Marcando imagen $idImagen como principal para inmueble $idInmueble',
      );
      final db = await dbHelper.connection;

      // Verificamos primero que la imagen exista y pertenezca al inmueble
      final checkResult = await db.query(
        'SELECT COUNT(*) as count FROM inmuebles_imagenes WHERE id_imagen = ? AND id_inmueble = ?',
        [idImagen, idInmueble],
      );

      final int count = checkResult.first.fields['count'] as int;
      if (count == 0) {
        _logger.warning(
          'La imagen $idImagen no pertenece al inmueble $idInmueble',
        );
        return false;
      }

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

      return (result.affectedRows ?? 0) > 0;
    });
  }

  Future<bool> eliminarImagenInmueble(int idImagen) async {
    return _ejecutarConReintentos('eliminar imagen inmueble', () async {
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

      return (result.affectedRows ?? 0) > 0;
    });
  }

  Future<bool> actualizarDescripcionImagen(
    int idImagen,
    String nuevaDescripcion,
  ) async {
    return _ejecutarConReintentos('actualizar descripción imagen', () async {
      _logger.info('Actualizando descripción de imagen: $idImagen');
      final db = await dbHelper.connection;

      final result = await db.query(
        'UPDATE inmuebles_imagenes SET descripcion = ? WHERE id_imagen = ?',
        [nuevaDescripcion, idImagen],
      );

      return (result.affectedRows ?? 0) > 0;
    });
  }

  // MÉTODOS PARA SERVICIOS DE PROVEEDORES

  Future<List<InmuebleProveedorServicio>> getServiciosProveedores(
    int idInmueble,
  ) async {
    return _ejecutarConReintentos('obtener servicios proveedores', () async {
      _logger.info(
        'Obteniendo servicios de proveedores para inmueble: $idInmueble',
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
        }
      }

      return servicios;
    });
  }

  Future<int> asignarProveedorAInmueble(
    InmuebleProveedorServicio servicio,
  ) async {
    return _ejecutarConReintentos('asignar proveedor a inmueble', () async {
      _logger.info(
        'Asignando proveedor ${servicio.idProveedor} a inmueble ${servicio.idInmueble}',
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
      return result.first.fields['id'] as int;
    });
  }

  Future<bool> eliminarAsignacionProveedor(int id) async {
    return _ejecutarConReintentos('eliminar asignación proveedor', () async {
      _logger.info('Eliminando asignación de proveedor ID: $id');
      final db = await dbHelper.connection;

      await db.query('CALL EliminarServicioProveedor(?)', [id]);
      return true;
    });
  }

  // Métodos auxiliares

  Future<bool> verificarExistenciaImagenFisica(String rutaImagen) async {
    return _ejecutarConReintentos(
      'verificar existencia imagen física',
      () async {
        try {
          final file = File(rutaImagen);
          final existe = await file.exists();
          final tamanoValido = existe ? await file.length() > 100 : false;
          return existe && tamanoValido;
        } catch (e) {
          _logger.warning('Error al verificar existencia física de imagen: $e');
          return false;
        }
      },
    );
  }

  Future<int> limpiarImagenesHuerfanas() async {
    return _ejecutarConReintentos('limpiar imágenes huérfanas', () async {
      _logger.info('Iniciando limpieza de imágenes huérfanas');
      final db = await dbHelper.connection;

      final results = await db.query(
        'SELECT id_imagen, ruta_imagen FROM inmuebles_imagenes',
      );

      int eliminadas = 0;

      for (var row in results) {
        try {
          final int idImagen = row.fields['id_imagen'] as int;
          final String rutaImagen = row.fields['ruta_imagen']?.toString() ?? '';

          if (rutaImagen.isEmpty) {
            await db.query(
              'DELETE FROM inmuebles_imagenes WHERE id_imagen = ?',
              [idImagen],
            );
            eliminadas++;
            continue;
          }

          final existe = await verificarExistenciaImagenFisica(rutaImagen);

          if (!existe) {
            await db.query(
              'DELETE FROM inmuebles_imagenes WHERE id_imagen = ?',
              [idImagen],
            );
            eliminadas++;
            _logger.info(
              'Eliminada imagen huérfana: $idImagen, ruta: $rutaImagen',
            );
          }
        } catch (e) {
          _logger.warning('Error al procesar imagen huérfana: $e');
        }
      }

      _logger.info(
        'Limpieza completada. Imágenes huérfanas eliminadas: $eliminadas',
      );
      return eliminadas;
    });
  }
}

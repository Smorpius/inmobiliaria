import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import '../utils/applogger.dart';
import '../models/venta_model.dart';
import '../models/inmueble_model.dart';
import '../services/mysql_helper.dart';
import '../models/inmueble_imagen.dart';
import '../models/inmueble_proveedor_servicio.dart';
import 'package:inmobiliaria/utils/error_handler.dart';

class InmuebleController {
  final DatabaseService dbHelper;

  // Bandera para evitar logs duplicados
  bool _procesandoError = false;

  InmuebleController({DatabaseService? dbService})
    : dbHelper = dbService ?? DatabaseService();

  // Reemplazar este método:
  Future<T> _ejecutarConReintentos<T>(
    String operacion,
    Future<T> Function() funcion,
  ) async {
    return ErrorHandler.ejecutarConReintentos(
      operacion: funcion,
      descripcion: operacion,
      reintentarSiErrorConexion: true,
    );
  }

  Future<bool> recalcularFinanzas() async {
    return _ejecutarConReintentos('recalcular finanzas inmuebles', () async {
      AppLogger.info(
        'Iniciando recálculo de finanzas para todos los inmuebles',
      );

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL RecalcularFinanzasInmuebles()');
          await conn.query('COMMIT');

          AppLogger.info('Recálculo de finanzas completado exitosamente');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al recalcular finanzas: $e');
        }
      });
    });
  }

  Future<List<Inmueble>> getInmuebles() async {
    return _ejecutarConReintentos('obtener inmuebles', () async {
      AppLogger.info('Iniciando consulta de inmuebles...');

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerInmuebles()');

        if (results.isEmpty) return [];

        final List<Inmueble> inmuebles = [];
        for (var row in results) {
          try {
            final inmueble = Inmueble.fromMap(row.fields);
            inmuebles.add(inmueble);
          } catch (e) {
            if (!_procesandoError) {
              _procesandoError = true;
              AppLogger.warning('Error procesando inmueble: $e');
              _procesandoError = false;
            }
          }
        }

        AppLogger.info('Se obtuvieron ${inmuebles.length} inmuebles');
        return inmuebles;
      });
    });
  }

  /// Ordena inmuebles por margen de utilidad de mayor a menor sin modificar la lista original
  List<Inmueble> ordenarPorMargenUtilidad(List<Inmueble> inmuebles) {
    final inmueblesOrdenados = List<Inmueble>.from(inmuebles);
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
      AppLogger.info('Insertando inmueble: ${inmueble.nombre}');

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          final estadoInmueble = inmueble.idEstado ?? 3;

          await conn.query(
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

          final idResult = await conn.query('SELECT @id_inmueble_out as id');
          if (idResult.isEmpty || idResult.first['id'] == null) {
            await conn.query('ROLLBACK');
            throw Exception('No se pudo obtener el ID del inmueble creado');
          }

          final inmuebleId = idResult.first['id'] as int;
          await conn.query('COMMIT');

          AppLogger.info('Inmueble creado con ID: $inmuebleId');
          return inmuebleId;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al insertar inmueble: $e');
        }
      });
    });
  }

  Future<int> updateInmueble(Inmueble inmueble) async {
    return _ejecutarConReintentos('actualizar inmueble', () async {
      if (inmueble.id == null) {
        throw Exception('No se puede actualizar un inmueble sin ID');
      }
      AppLogger.info('Actualizando inmueble: ${inmueble.nombre}');

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          final result = await conn.query(
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

          await conn.query('COMMIT');
          AppLogger.info('Inmueble actualizado ID: ${inmueble.id}');
          return result.affectedRows ?? 0;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al actualizar inmueble: $e');
        }
      });
    });
  }

  Future<bool> actualizarUtilidadVenta(
    int idVenta,
    double gastosAdicionales,
    int usuarioModificacion,
  ) async {
    return _ejecutarConReintentos('actualizar utilidad venta', () async {
      AppLogger.info(
        'Actualizando utilidad de venta ID: $idVenta con gastos adicionales: $gastosAdicionales',
      );

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL ActualizarUtilidadVenta(?, ?, ?)', [
            idVenta,
            gastosAdicionales,
            usuarioModificacion,
          ]);

          await conn.query('COMMIT');
          AppLogger.info('Utilidad de venta actualizada correctamente');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al actualizar utilidad de venta: $e');
        }
      });
    });
  }

  Future<bool> inactivarInmueble(int id) async {
    return _ejecutarConReintentos('inactivar inmueble', () async {
      AppLogger.info('Inactivando inmueble con ID: $id');

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL InactivarInmueble(?)', [id]);
          await conn.query('COMMIT');

          AppLogger.info('Inmueble inactivado: ID=$id');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al inactivar inmueble: $e');
        }
      });
    });
  }

  Future<bool> reactivarInmueble(int id) async {
    return _ejecutarConReintentos('reactivar inmueble', () async {
      AppLogger.info('Reactivando inmueble con ID: $id');

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL ReactivarInmueble(?)', [id]);
          await conn.query('COMMIT');

          AppLogger.info('Inmueble reactivado: ID=$id');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al reactivar inmueble: $e');
        }
      });
    });
  }

  Future<bool> verificarExistenciaInmueble(int id) async {
    return _ejecutarConReintentos('verificar existencia inmueble', () async {
      AppLogger.info('Verificando existencia del inmueble con ID: $id');

      return await dbHelper.withConnection((conn) async {
        await conn.query('CALL VerificarExistenciaInmueble(?, @existe)', [id]);
        final existeResult = await conn.query('SELECT @existe as existe');

        final int existe = existeResult.first.fields['existe'] as int;
        AppLogger.info('¿Inmueble $id existe? ${existe > 0}');
        return existe > 0;
      });
    });
  }

  Future<List<Inmueble>> buscarInmuebles({
    String? tipo,
    String? operacion,
    double? precioMin,
    double? precioMax,
    String? ciudad,
    int? idEstado,
    double? margenMin,
  }) async {
    return _ejecutarConReintentos('buscar inmuebles', () async {
      AppLogger.info('Buscando inmuebles con criterios específicos');

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query(
          'CALL BuscarInmuebles(?, ?, ?, ?, ?, ?, ?)',
          [tipo, operacion, precioMin, precioMax, ciudad, idEstado, margenMin],
        );

        final List<Inmueble> inmuebles = [];
        for (var row in results) {
          try {
            inmuebles.add(Inmueble.fromMap(row.fields));
          } catch (e) {
            if (!_procesandoError) {
              _procesandoError = true;
              AppLogger.warning('Error procesando inmueble en búsqueda: $e');
              _procesandoError = false;
            }
          }
        }

        AppLogger.info(
          'Búsqueda completada: ${inmuebles.length} inmuebles encontrados',
        );
        return inmuebles;
      });
    });
  }

  Future<List<Map<String, dynamic>>> getClientesInteresados(
    int idInmueble,
  ) async {
    return _ejecutarConReintentos('obtener clientes interesados', () async {
      AppLogger.info(
        'Obteniendo clientes interesados en inmueble: $idInmueble',
      );

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerClientesInteresados(?)', [
          idInmueble,
        ]);

        AppLogger.info('Clientes interesados obtenidos: ${results.length}');
        return results.map((row) => row.fields).toList();
      });
    });
  }

  Future<int> registrarClienteInteresado(
    int idInmueble,
    int idCliente,
    String? comentarios,
  ) async {
    return _ejecutarConReintentos('registrar cliente interesado', () async {
      AppLogger.info(
        'Registrando cliente $idCliente interesado en inmueble $idInmueble',
      );

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query(
            'CALL RegistrarClienteInteresado(?, ?, ?, @id_registro)',
            [idInmueble, idCliente, comentarios],
          );

          final result = await conn.query('SELECT @id_registro as id');
          if (result.isEmpty || result.first['id'] == null) {
            await conn.query('ROLLBACK');
            throw Exception('No se pudo obtener el ID del registro de interés');
          }

          final idRegistro = result.first['id'] as int;
          await conn.query('COMMIT');

          AppLogger.info('Cliente interesado registrado con ID: $idRegistro');
          return idRegistro;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al registrar cliente interesado: $e');
        }
      });
    });
  }

  Future<int> registrarVenta(Venta venta) async {
    return _ejecutarConReintentos('registrar venta', () async {
      AppLogger.info('Registrando venta para inmueble: ${venta.idInmueble}');

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL CrearVenta(?, ?, ?, ?, ?, ?, @id_venta_out)', [
            venta.idCliente,
            venta.idInmueble,
            venta.fechaVenta.toIso8601String().split('T')[0],
            venta.ingreso,
            venta.comisionProveedores,
            venta.utilidadNeta,
          ]);

          final result = await conn.query('SELECT @id_venta_out as id');
          if (result.isEmpty || result.first['id'] == null) {
            await conn.query('ROLLBACK');
            throw Exception('No se pudo obtener el ID de la venta registrada');
          }

          final idVenta = result.first['id'] as int;
          await conn.query('COMMIT');

          AppLogger.info('Venta registrada con ID: $idVenta');
          return idVenta;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al registrar venta: $e');
        }
      });
    });
  }

  Future<List<Venta>> getVentas() async {
    return _ejecutarConReintentos('obtener ventas', () async {
      AppLogger.info('Obteniendo lista de ventas');

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerVentas()');
        if (results.isEmpty) return [];

        final ventas = results.map((row) => Venta.fromMap(row.fields)).toList();
        AppLogger.info('Ventas obtenidas: ${ventas.length}');
        return ventas;
      });
    });
  }

  Future<List<InmuebleImagen>> getImagenesInmueble(int idInmueble) async {
    return _ejecutarConReintentos('obtener imágenes inmueble', () async {
      AppLogger.info('Obteniendo imágenes del inmueble: $idInmueble');

      return await dbHelper.withConnection((conn) async {
        // Usar procedimiento almacenado ObtenerImagenesInmueble
        final results = await conn.query('CALL ObtenerImagenesInmueble(?)', [
          idInmueble,
        ]);

        List<InmuebleImagen> imagenes = [];
        for (var row in results) {
          try {
            if (row.fields['id_imagen'] == null ||
                row.fields['id_inmueble'] == null ||
                row.fields['ruta_imagen'] == null) {
              continue;
            }

            imagenes.add(InmuebleImagen.fromMap(row.fields));
          } catch (e) {
            if (!_procesandoError) {
              _procesandoError = true;
              AppLogger.warning('Error al procesar imagen: $e');
              _procesandoError = false;
            }
          }
        }

        AppLogger.info(
          'Se obtuvieron ${imagenes.length} imágenes para el inmueble $idInmueble',
        );
        return imagenes;
      });
    });
  }

  Future<InmuebleImagen?> getImagenPrincipal(int idInmueble) async {
    return _ejecutarConReintentos('obtener imagen principal', () async {
      AppLogger.info('Obteniendo imagen principal para inmueble: $idInmueble');

      return await dbHelper.withConnection((conn) async {
        try {
          final results = await conn.query('CALL ObtenerImagenPrincipal(?)', [
            idInmueble,
          ]);

          if (results.isEmpty ||
              results.first.fields.isEmpty ||
              results.first.fields['id_imagen'] == null) {
            AppLogger.info(
              'No se encontró imagen principal para inmueble: $idInmueble',
            );
            return null;
          }

          AppLogger.info('Imagen principal obtenida para inmueble $idInmueble');
          return InmuebleImagen.fromMap(results.first.fields);
        } catch (e) {
          if (!_procesandoError) {
            _procesandoError = true;
            AppLogger.error(
              'Error al procesar datos de imagen principal',
              e,
              StackTrace.current,
            );
            _procesandoError = false;
          }
          return null;
        }
      });
    });
  }

  Future<int> agregarImagenInmueble(InmuebleImagen imagen) async {
    return _ejecutarConReintentos('agregar imagen inmueble', () async {
      AppLogger.info('Agregando imagen al inmueble: ${imagen.idInmueble}');

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Este procedimiento está bien definido en SQL con una variable de salida @id_imagen_out
          await conn.query(
            'CALL AgregarImagenInmueble(?, ?, ?, ?, @id_imagen_out)',
            [
              imagen.idInmueble,
              imagen.rutaImagen,
              imagen.descripcion ?? '', // Asegurar valor no nulo
              imagen.esPrincipal ? 1 : 0,
            ],
          );

          // Obtención correcta del ID
          final result = await conn.query('SELECT @id_imagen_out as id');
          if (result.isEmpty || result.first['id'] == null) {
            await conn.query('ROLLBACK');
            throw Exception('No se pudo obtener el ID de la imagen agregada');
          }

          final idImagen = result.first['id'] as int;
          await conn.query('COMMIT');

          AppLogger.info('Imagen agregada con ID: $idImagen');
          return idImagen;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al agregar imagen: $e');
        }
      });
    });
  }

  Future<bool> marcarImagenComoPrincipal(int idImagen, int idInmueble) async {
    return _ejecutarConReintentos('marcar imagen como principal', () async {
      AppLogger.info(
        'Marcando imagen $idImagen como principal para inmueble $idInmueble',
      );

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL MarcarImagenComoPrincipal(?, ?)', [
            idImagen,
            idInmueble,
          ]);

          await conn.query('COMMIT');
          AppLogger.info(
            'Imagen $idImagen marcada como principal exitosamente',
          );
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al marcar imagen como principal: $e');
        }
      });
    });
  }

  Future<bool> eliminarImagenInmueble(int idImagen) async {
    return _ejecutarConReintentos('eliminar imagen inmueble', () async {
      AppLogger.info('Eliminando imagen con ID: $idImagen');

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL EliminarImagenInmueble(?)', [idImagen]);
          await conn.query('COMMIT');

          AppLogger.info('Imagen eliminada ID: $idImagen');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          if (!_procesandoError) {
            _procesandoError = true;
            AppLogger.error(
              'Error al eliminar imagen de la base de datos',
              e,
              StackTrace.current,
            );
            _procesandoError = false;
          }
          throw Exception('Error al eliminar imagen: $e');
        }
      });
    });
  }

  Future<bool> actualizarDescripcionImagen(
    int idImagen,
    String nuevaDescripcion,
  ) async {
    return _ejecutarConReintentos('actualizar descripción imagen', () async {
      AppLogger.info('Actualizando descripción de imagen: $idImagen');

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL ActualizarDescripcionImagen(?, ?)', [
            idImagen,
            nuevaDescripcion,
          ]);

          await conn.query('COMMIT');
          AppLogger.info('Descripción de imagen $idImagen actualizada');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al actualizar descripción de imagen: $e');
        }
      });
    });
  }

  Future<List<InmuebleProveedorServicio>> getServiciosProveedores(
    int idInmueble,
  ) async {
    return _ejecutarConReintentos('obtener servicios proveedores', () async {
      AppLogger.info(
        'Obteniendo servicios de proveedores para inmueble: $idInmueble',
      );

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query(
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
            if (!_procesandoError) {
              _procesandoError = true;
              AppLogger.warning('Error procesando servicio: $e');
              _procesandoError = false;
            }
          }
        }

        AppLogger.info('Servicios obtenidos: ${servicios.length}');
        return servicios;
      });
    });
  }

  Future<int> asignarProveedorAInmueble(
    InmuebleProveedorServicio servicio,
  ) async {
    return _ejecutarConReintentos('asignar proveedor a inmueble', () async {
      AppLogger.info(
        'Asignando proveedor ${servicio.idProveedor} a inmueble ${servicio.idInmueble}',
      );

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query(
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

          final result = await conn.query('SELECT @id_servicio_out as id');
          if (result.isEmpty || result.first['id'] == null) {
            await conn.query('ROLLBACK');
            throw Exception('No se pudo obtener el ID del servicio asignado');
          }

          final idServicio = result.first['id'] as int;
          await conn.query('COMMIT');

          AppLogger.info('Proveedor asignado con ID de servicio: $idServicio');
          return idServicio;
        } catch (e) {
          await conn.query('ROLLBACK');
          if (!_procesandoError) {
            _procesandoError = true;
            AppLogger.error(
              'Error al asignar proveedor a inmueble',
              e,
              StackTrace.current,
            );
            _procesandoError = false;
          }
          throw Exception('Error al asignar proveedor: $e');
        }
      });
    });
  }

  Future<bool> eliminarAsignacionProveedor(int id) async {
    return _ejecutarConReintentos('eliminar asignación proveedor', () async {
      AppLogger.info('Eliminando asignación de proveedor ID: $id');

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL EliminarServicioProveedor(?)', [id]);
          await conn.query('COMMIT');

          AppLogger.info('Asignación de proveedor eliminada ID: $id');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al eliminar asignación de proveedor: $e');
        }
      });
    });
  }

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
          if (!_procesandoError) {
            _procesandoError = true;
            AppLogger.warning(
              'Error al verificar existencia física de imagen: $e',
            );
            _procesandoError = false;
          }
          return false;
        }
      },
    );
  }

  Future<int> limpiarImagenesHuerfanas() async {
    return _ejecutarConReintentos('limpiar imágenes huérfanas', () async {
      AppLogger.info('Iniciando limpieza de imágenes huérfanas');

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query(
            'CALL LimpiarImagenesHuerfanas(@imagenes_eliminadas)',
          );

          final result = await conn.query(
            'SELECT @imagenes_eliminadas as eliminadas',
          );

          if (result.isEmpty || result.first.fields['eliminadas'] == null) {
            await conn.query('ROLLBACK');
            throw Exception(
              'No se pudo obtener el número de imágenes eliminadas',
            );
          }

          final int eliminadas = result.first.fields['eliminadas'] as int;
          await conn.query('COMMIT');

          AppLogger.info(
            'Limpieza completada. Imágenes huérfanas eliminadas: $eliminadas',
          );
          return eliminadas;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al limpiar imágenes huérfanas: $e');
        }
      });
    });
  }

  void dispose() {
    AppLogger.info('Liberando recursos de InmuebleController');
    // No hay StreamControllers que cerrar en este caso
  }
}

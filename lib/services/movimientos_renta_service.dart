import '../utils/applogger.dart';
import '../services/mysql_helper.dart';
import '../models/resumen_renta_model.dart';
import '../models/movimiento_renta_model.dart';
import '../models/comprobante_movimiento_model.dart';

class MovimientosRentaService {
  final DatabaseService _db;
  bool _procesandoError = false; // Control para evitar logs duplicados

  MovimientosRentaService(this._db);

  /// Registra un nuevo movimiento de renta usando el procedimiento almacenado
  Future<int> registrarMovimiento(MovimientoRenta movimiento) async {
    return await _db.withConnection((conn) async {
      await conn.query('START TRANSACTION');
      try {
        AppLogger.info(
          'Registrando movimiento para inmueble: ${movimiento.idInmueble}',
        );

        await conn.query(
          'CALL RegistrarMovimientoRenta(?, ?, ?, ?, ?, ?, ?, @id_movimiento_out)',
          [
            movimiento.idInmueble,
            movimiento.idCliente,
            movimiento.tipoMovimiento,
            movimiento.concepto,
            movimiento.monto,
            movimiento.fechaMovimiento.toIso8601String().split('T')[0],
            movimiento.comentarios,
          ],
        );

        final result = await conn.query('SELECT @id_movimiento_out as id');
        if (result.isEmpty || result.first['id'] == null) {
          await conn.query('ROLLBACK');
          throw Exception('No se pudo obtener el ID del movimiento registrado');
        }

        final idMovimiento = result.first['id'] as int;
        await conn.query('COMMIT');
        AppLogger.info('Movimiento registrado con ID: $idMovimiento');
        return idMovimiento;
      } catch (e, stackTrace) {
        await conn.query('ROLLBACK');
        if (!_procesandoError) {
          _procesandoError = true;
          AppLogger.error(
            'Error al registrar movimiento de renta',
            e,
            stackTrace,
          );
          _procesandoError = false;
        }
        throw Exception('Error al registrar movimiento de renta: $e');
      }
    });
  }

  /// Agrega un comprobante a un movimiento
  Future<int> agregarComprobante(ComprobanteMovimiento comprobante) async {
    return await _db.withConnection((conn) async {
      await conn.query('START TRANSACTION');
      try {
        AppLogger.info(
          'Agregando comprobante para movimiento: ${comprobante.idMovimiento}',
        );

        await conn.query(
          'CALL AgregarComprobanteMovimiento(?, ?, ?, ?, @id_comprobante_out)',
          [
            comprobante.idMovimiento,
            comprobante.rutaImagen,
            comprobante.descripcion,
            comprobante.esPrincipal ? 1 : 0,
          ],
        );

        final result = await conn.query('SELECT @id_comprobante_out as id');
        if (result.isEmpty || result.first['id'] == null) {
          await conn.query('ROLLBACK');
          throw Exception(
            'No se pudo obtener el ID del comprobante registrado',
          );
        }

        final idComprobante = result.first['id'] as int;
        await conn.query('COMMIT');
        AppLogger.info('Comprobante registrado con ID: $idComprobante');
        return idComprobante;
      } catch (e, stackTrace) {
        await conn.query('ROLLBACK');
        if (!_procesandoError) {
          _procesandoError = true;
          AppLogger.error('Error al registrar comprobante', e, stackTrace);
          _procesandoError = false;
        }
        throw Exception('Error al registrar comprobante: $e');
      }
    });
  }

  /// Obtiene los movimientos de un inmueble
  Future<List<MovimientoRenta>> obtenerMovimientosPorInmueble(
    int idInmueble,
  ) async {
    return await _db.withConnection((conn) async {
      try {
        AppLogger.info('Obteniendo movimientos para inmueble: $idInmueble');

        final results = await conn.query(
          'CALL ObtenerMovimientosPorInmueble(?)',
          [idInmueble],
        );

        if (results.isEmpty) return [];

        final movimientos =
            results.map((row) {
              return MovimientoRenta.fromMap(row.fields);
            }).toList();

        AppLogger.info('Movimientos obtenidos: ${movimientos.length}');
        return movimientos;
      } catch (e, stackTrace) {
        if (!_procesandoError) {
          _procesandoError = true;
          AppLogger.error('Error al obtener movimientos', e, stackTrace);
          _procesandoError = false;
        }
        throw Exception('Error al obtener movimientos: $e');
      }
    });
  }

  /// Obtiene los comprobantes de un movimiento
  Future<List<ComprobanteMovimiento>> obtenerComprobantes(
    int idMovimiento,
  ) async {
    return await _db.withConnection((conn) async {
      try {
        AppLogger.info(
          'Obteniendo comprobantes para movimiento: $idMovimiento',
        );

        final results = await conn.query(
          'CALL ObtenerComprobantesPorMovimiento(?)',
          [idMovimiento],
        );

        if (results.isEmpty) return [];

        final comprobantes =
            results.map((row) {
              return ComprobanteMovimiento.fromMap(row.fields);
            }).toList();

        AppLogger.info('Comprobantes obtenidos: ${comprobantes.length}');
        return comprobantes;
      } catch (e, stackTrace) {
        if (!_procesandoError) {
          _procesandoError = true;
          AppLogger.error('Error al obtener comprobantes', e, stackTrace);
          _procesandoError = false;
        }
        throw Exception('Error al obtener comprobantes: $e');
      }
    });
  }

  /// Obtiene resumen de movimientos por mes
  Future<ResumenRenta> obtenerResumenMovimientos(
    int idInmueble,
    int anio,
    int mes,
  ) async {
    return await _db.withConnection((conn) async {
      try {
        AppLogger.info(
          'Obteniendo resumen para inmueble: $idInmueble, $mes/$anio',
        );

        final resultados = await conn.query(
          'CALL ObtenerResumenMovimientosRenta(?, ?, ?)',
          [idInmueble, anio, mes],
        );

        // Procesamos los tres conjuntos de resultados
        double totalIngresos = 0;
        double totalEgresos = 0;
        List<MovimientoRenta> movimientos = [];

        if (resultados.isNotEmpty) {
          final ingresos = resultados.first;
          if (ingresos.isNotEmpty) {
            for (var row in ingresos) {
              totalIngresos += double.parse(row['monto'].toString());
            }
          }
        }

        if (resultados.length > 1) {
          final egresos = resultados.elementAt(1);
          if (egresos.isNotEmpty) {
            for (var row in egresos) {
              totalEgresos += double.parse(row['monto'].toString());
            }
          }
        }

        if (resultados.length > 2) {
          final movimientosData = resultados.elementAt(2);
          movimientos =
              movimientosData.map((row) {
                return MovimientoRenta.fromMap(row.fields);
              }).toList();
        }

        return ResumenRenta(
          totalIngresos: totalIngresos,
          totalEgresos: totalEgresos,
          movimientos: movimientos,
        );
      } catch (e, stackTrace) {
        if (!_procesandoError) {
          _procesandoError = true;
          AppLogger.error('Error al obtener resumen', e, stackTrace);
          _procesandoError = false;
        }
        throw Exception('Error al obtener resumen: $e');
      }
    });
  }

  /// Obtiene movimientos de todos los inmuebles en un periodo específico
  Future<List<MovimientoRenta>> obtenerMovimientosPorPeriodo(
    String periodoStr,
  ) async {
    return await _db.withConnection((conn) async {
      try {
        AppLogger.info('Obteniendo movimientos para el periodo: $periodoStr');

        final results = await conn.query(
          'SELECT mr.*, c.nombre AS nombre_cliente, c.apellido_paterno AS apellido_cliente, '
          'i.nombre_inmueble, e.nombre_estado '
          'FROM movimientos_renta mr '
          'JOIN clientes c ON mr.id_cliente = c.id_cliente '
          'JOIN inmuebles i ON mr.id_inmueble = i.id_inmueble '
          'JOIN estados e ON mr.id_estado = e.id_estado '
          'WHERE mr.mes_correspondiente = ? '
          'ORDER BY mr.fecha_movimiento DESC',
          [periodoStr],
        );

        if (results.isEmpty) return [];

        final movimientos =
            results.map((row) {
              return MovimientoRenta.fromMap(row.fields);
            }).toList();

        AppLogger.info(
          'Movimientos obtenidos para el periodo $periodoStr: ${movimientos.length}',
        );
        return movimientos;
      } catch (e, stackTrace) {
        if (!_procesandoError) {
          _procesandoError = true;
          AppLogger.error(
            'Error al obtener movimientos por periodo',
            e,
            stackTrace,
          );
          _procesandoError = false;
        }
        throw Exception('Error al obtener movimientos por periodo: $e');
      }
    });
  }

  /// Elimina un movimiento
  Future<bool> eliminarMovimiento(int idMovimiento) async {
    return await _db.withConnection((conn) async {
      await conn.query('START TRANSACTION');
      try {
        AppLogger.info('Eliminando movimiento: $idMovimiento');

        await conn.query('CALL EliminarMovimientoRenta(?)', [idMovimiento]);

        await conn.query('COMMIT');
        AppLogger.info('Movimiento eliminado correctamente');
        return true;
      } catch (e, stackTrace) {
        await conn.query('ROLLBACK');
        if (!_procesandoError) {
          _procesandoError = true;
          AppLogger.error('Error al eliminar movimiento', e, stackTrace);
          _procesandoError = false;
        }
        throw Exception('Error al eliminar movimiento: $e');
      }
    });
  }
}

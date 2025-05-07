import 'package:intl/intl.dart';
import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../services/mysql_helper.dart';

class RentaService {
  final DatabaseService _db;
  bool _procesandoError = false;
  static const Duration _tiempoMinEntreLogs = Duration(seconds: 10);
  DateTime? _ultimoErrorLog;

  RentaService(this._db);

  /// Obtiene los detalles de la renta para un inmueble específico
  Future<Map<String, dynamic>> obtenerDetalleRenta(int idInmueble) async {
    return await _db.withConnection((conn) async {
      try {
        if (idInmueble <= 0) {
          throw Exception('ID de inmueble inválido');
        }

        AppLogger.info(
          'Obteniendo detalle de renta para inmueble ID: $idInmueble',
        );

        // Obtener información básica de la renta usando procedimiento almacenado
        final results = await conn.query('CALL ObtenerDetalleRenta(?)', [
          idInmueble,
        ]);

        if (results.isEmpty) {
          return {
            'tiene_contrato': false,
            'mensaje': 'No hay contrato de renta activo para este inmueble',
          };
        }

        // Procesar resultados
        final detalle = results.first.fields;

        // Formatear fechas para UI
        final fechaInicio =
            detalle['fecha_inicio'] is DateTime
                ? detalle['fecha_inicio'] as DateTime
                : DateTime.parse(detalle['fecha_inicio'].toString());

        final fechaFin =
            detalle['fecha_fin'] is DateTime
                ? detalle['fecha_fin'] as DateTime
                : DateTime.parse(detalle['fecha_fin'].toString());

        final formatoFecha = DateFormat('dd/MM/yyyy');

        return {
          'tiene_contrato': true,
          'id_contrato': detalle['id_contrato'],
          'id_cliente': detalle['id_cliente'],
          'nombre_cliente':
              '${detalle['nombre_cliente'] ?? ''} ${detalle['apellido_cliente'] ?? ''}'
                  .trim(),
          'fecha_inicio': formatoFecha.format(fechaInicio),
          'fecha_fin': formatoFecha.format(fechaFin),
          'monto_mensual': detalle['monto_mensual'],
          'monto_mensual_formateado': NumberFormat.currency(
            symbol: '\$',
            locale: 'es_MX',
          ).format(double.parse(detalle['monto_mensual'].toString())),
          'condiciones_adicionales': detalle['condiciones_adicionales'],
          'estado_renta': detalle['estado_renta'],
          'fecha_inicio_raw': fechaInicio,
          'fecha_fin_raw': fechaFin,
        };
      } catch (e, stackTrace) {
        _registrarError('Error al obtener detalle de renta', e, stackTrace);
        throw Exception(
          'Error al obtener detalle de renta: ${_formatearMensajeError(e)}',
        );
      }
    });
  }

  /// Registra un nuevo contrato de renta
  Future<int> registrarContratoRenta(
    int idInmueble,
    int idCliente,
    DateTime fechaInicio,
    DateTime fechaFin,
    double montoMensual,
    String? condicionesAdicionales,
  ) async {
    int idContratoFinal = 0;

    return await _db
        .withConnection((conn) async {
          await conn.query('START TRANSACTION');
          try {
            // Validaciones previas
            if (idInmueble <= 0) throw Exception('ID de inmueble inválido');
            if (idCliente <= 0) throw Exception('ID de cliente inválido');
            if (montoMensual <= 0) {
              throw Exception('El monto mensual debe ser mayor a cero');
            }
            if (fechaInicio.isAfter(fechaFin)) {
              throw Exception(
                'La fecha de inicio no puede ser posterior a la fecha de fin',
              );
            }

            AppLogger.info(
              'Registrando contrato de renta para inmueble ID: $idInmueble, '
              'cliente ID: $idCliente, monto: $montoMensual',
            );

            final fechaInicioStr = fechaInicio.toIso8601String().split('T')[0];
            final fechaFinStr = fechaFin.toIso8601String().split('T')[0];

            // Verificar si ya existe un contrato activo
            final checkResult = await conn.query(
              'SELECT COUNT(*) AS count FROM contratos_renta WHERE id_inmueble = ? AND id_estado = 1',
              [idInmueble],
            );

            // Verificar que tengamos resultados antes de acceder a first
            if (checkResult.isNotEmpty) {
              final count = checkResult.first.fields['count'] as int? ?? 0;
              if (count > 0) {
                await conn.query('ROLLBACK');
                throw Exception(
                  'Ya existe un contrato activo para este inmueble',
                );
              }
            }

            // Verificar el estado del inmueble
            final inmuebleResult = await conn.query(
              'SELECT id_estado FROM inmuebles WHERE id_inmueble = ?',
              [idInmueble],
            );

            if (inmuebleResult.isEmpty) {
              await conn.query('ROLLBACK');
              throw Exception('No se encontró el inmueble con ID: $idInmueble');
            }

            final idEstadoInmueble =
                inmuebleResult.first.fields['id_estado'] as int? ?? 0;
            if (idEstadoInmueble == 4) {
              // Vendido
              await conn.query('ROLLBACK');
              throw Exception(
                'No se puede rentar un inmueble que ya ha sido vendido',
              );
            } else if (idEstadoInmueble == 5) {
              // Rentado
              await conn.query('ROLLBACK');
              throw Exception('El inmueble ya está rentado');
            }

            // Insertar el contrato con procedimiento almacenado más seguro
            try {
              // Reiniciar variable de salida para evitar problemas
              await conn.query('SET @id_contrato_out = 0');

              await conn.query(
                'CALL RegistrarContratoRenta(?, ?, ?, ?, ?, ?, @id_contrato_out)',
                [
                  idInmueble,
                  idCliente,
                  fechaInicioStr,
                  fechaFinStr,
                  montoMensual,
                  condicionesAdicionales ?? '',
                ],
              );

              final outResult = await conn.query(
                'SELECT @id_contrato_out AS id',
              );

              if (outResult.isEmpty || outResult.first['id'] == null) {
                throw Exception(
                  'No se pudo obtener el ID del contrato registrado',
                );
              }

              idContratoFinal = outResult.first['id'] as int;
            } catch (e) {
              // Si falla el procedimiento almacenado, intentar inserción directa como respaldo
              final insertResult = await conn.query(
                'INSERT INTO contratos_renta (id_inmueble, id_cliente, fecha_inicio, fecha_fin, monto_mensual, condiciones_adicionales) '
                'VALUES (?, ?, ?, ?, ?, ?)',
                [
                  idInmueble,
                  idCliente,
                  fechaInicioStr,
                  fechaFinStr,
                  montoMensual,
                  condicionesAdicionales ?? '',
                ],
              );

              final insertId = insertResult.insertId;
              if (insertId != null) {
                idContratoFinal = insertId;
              } else {
                throw Exception(
                  'No se pudo obtener el ID del contrato insertado',
                );
              }
            }

            // Validación final del ID del contrato
            if (idContratoFinal <= 0) {
              await conn.query('ROLLBACK');
              throw Exception(
                'No se pudo obtener un ID válido para el contrato registrado',
              );
            }

            // Actualizar el estado del inmueble a rentado (5)
            await conn.query(
              'UPDATE inmuebles SET id_estado = 5 WHERE id_inmueble = ?',
              [idInmueble],
            );

            await conn.query('COMMIT');

            AppLogger.info(
              'Contrato de renta registrado con ID: $idContratoFinal para inmueble ID: $idInmueble',
            );

            return idContratoFinal;
          } catch (e, stackTrace) {
            try {
              // Intentar hacer rollback
              await conn.query('ROLLBACK');
            } catch (rollbackError) {
              // Si falla el rollback, solo registrar el error pero continuar el flujo
              AppLogger.warning(
                'Error al realizar ROLLBACK: ${rollbackError.toString()}',
              );
            }

            _registrarError(
              'Error al registrar contrato de renta',
              e,
              stackTrace,
            );

            // Proporcionar mensajes de error específicos
            final mensajeOriginal = e.toString().toLowerCase();
            if (mensajeOriginal.contains('ya existe un contrato activo')) {
              throw Exception(
                'Ya existe un contrato de renta activo para este inmueble',
              );
            } else if (mensajeOriginal.contains('foreign key')) {
              throw Exception('El inmueble o cliente especificado no existe');
            } else if (mensajeOriginal.contains('no element')) {
              throw Exception(
                'Error en la consulta de verificación de contratos',
              );
            }

            throw Exception(
              'Error al registrar contrato de renta: ${_formatearMensajeError(e)}',
            );
          }
        })
        .catchError((e) {
          // Capa final de seguridad para garantizar que nunca devolvamos un Future incompleto
          AppLogger.error(
            'Error capturado en nivel superior de registrarContratoRenta',
            e,
          );
          throw Exception(
            'No se pudo completar el registro del contrato de renta: ${_formatearMensajeError(e)}',
          );
        });
  }

  /// Actualiza el estado de un contrato de renta
  Future<bool> actualizarEstadoContrato(int idContrato, int nuevoEstado) async {
    return await _db.withConnection((conn) async {
      await conn.query('START TRANSACTION');
      try {
        // Validaciones
        if (idContrato <= 0) throw Exception('ID de contrato inválido');
        if (nuevoEstado <= 0) throw Exception('Estado inválido');

        AppLogger.info(
          'Actualizando estado de contrato ID: $idContrato a estado: $nuevoEstado',
        );

        // Llamar al procedimiento almacenado
        await conn.query('CALL ActualizarEstadoContratoRenta(?, ?)', [
          idContrato,
          nuevoEstado,
        ]);

        await conn.query('COMMIT');
        AppLogger.info(
          'Estado de contrato ID: $idContrato actualizado correctamente',
        );
        return true;
      } catch (e, stackTrace) {
        await conn.query('ROLLBACK');
        _registrarError(
          'Error al actualizar estado de contrato',
          e,
          stackTrace,
        );
        throw Exception(
          'Error al actualizar estado de contrato: ${_formatearMensajeError(e)}',
        );
      }
    });
  }

  /// Obtiene los contratos de renta por estado
  Future<List<Map<String, dynamic>>> obtenerContratosPorEstado(
    int idEstado,
  ) async {
    return await _db.withConnection((conn) async {
      try {
        if (idEstado <= 0) throw Exception('ID de estado inválido');

        AppLogger.info('Obteniendo contratos con estado ID: $idEstado');

        final results = await conn.query(
          'SELECT cr.*, c.nombre, c.apellido_paterno, i.nombre_inmueble, e.nombre_estado '
          'FROM contratos_renta cr '
          'JOIN clientes c ON cr.id_cliente = c.id_cliente '
          'JOIN inmuebles i ON cr.id_inmueble = i.id_inmueble '
          'JOIN estados e ON cr.id_estado = e.id_estado '
          'WHERE cr.id_estado = ?',
          [idEstado],
        );

        if (results.isEmpty) return [];

        final List<Map<String, dynamic>> contratos = [];
        for (var row in results) {
          final contrato = {
            'id_contrato': row['id_contrato'],
            'id_inmueble': row['id_inmueble'],
            'id_cliente': row['id_cliente'],
            'nombre_cliente':
                '${row['nombre'] ?? ''} ${row['apellido_paterno'] ?? ''}'
                    .trim(),
            'nombre_inmueble': row['nombre_inmueble'],
            'fecha_inicio': row['fecha_inicio'],
            'fecha_fin': row['fecha_fin'],
            'monto_mensual': row['monto_mensual'],
            'estado': row['nombre_estado'],
          };
          contratos.add(contrato);
        }

        return contratos;
      } catch (e, stackTrace) {
        _registrarError('Error al obtener contratos de renta', e, stackTrace);
        throw Exception(
          'Error al obtener contratos de renta: ${_formatearMensajeError(e)}',
        );
      }
    });
  }

  /// Formatea un mensaje de error para presentación al usuario
  String _formatearMensajeError(dynamic error) {
    final mensajeOriginal = error.toString();

    // Extraer solo la primera línea del error
    final primeraLinea = mensajeOriginal.split('\n').first;

    // Eliminar prefijos técnicos comunes
    if (primeraLinea.contains('Exception:')) {
      return primeraLinea.split('Exception:').last.trim();
    }

    return primeraLinea;
  }

  /// Registra errores evitando duplicados en intervalos cortos
  void _registrarError(String mensaje, dynamic error, StackTrace stackTrace) {
    final ahora = DateTime.now();

    if (_procesandoError ||
        (_ultimoErrorLog != null &&
            ahora.difference(_ultimoErrorLog!) < _tiempoMinEntreLogs)) {
      return; // Evitar logs duplicados en intervalos cortos
    }

    _procesandoError = true;
    _ultimoErrorLog = ahora;

    AppLogger.error(mensaje, error, stackTrace);

    _procesandoError = false;
  }

  Future<Map<String, dynamic>> obtenerEstadisticasRentas(
    DateTimeRange periodo,
  ) async {
    AppLogger.info(
      'Obteniendo estadísticas de rentas para el periodo: ${periodo.start} - ${periodo.end}',
    );
    return await _db.withConnection((conn) async {
      try {
        final fechaInicioStr = DateFormat('yyyy-MM-dd').format(periodo.start);
        final fechaFinStr = DateFormat('yyyy-MM-dd').format(periodo.end);

        // Usar queryMulti para obtener todos los conjuntos de resultados
        final queryMultiResult = conn.queryMulti(
          'CALL ObtenerEstadisticasRentas(?, ?)',
          [
            [fechaInicioStr, fechaFinStr],
          ], // queryMulti espera una Iterable<List<Object?>>
        );

        // Primero obtenemos el Stream.
        final resultsStream = await queryMultiResult;
        // Luego convertimos el Stream a una Lista.
        // Según el error, resultsStream.toList() aquí devuelve List<Results> directamente.
        final allResults = resultsStream.toList();

        // Procesar primer result set (estadísticas de contratos)
        Map<String, dynamic> estadisticasContratos = {};
        if (allResults.isNotEmpty && allResults[0].isNotEmpty) {
          final resultsContratos = allResults[0];
          final rowContratos = resultsContratos.first.fields;
          estadisticasContratos = {
            'totalContratos': rowContratos['total_contratos'] ?? 0,
            'ingresosMensuales': rowContratos['ingresos_mensuales'] ?? 0.0,
            'contratosActivos': rowContratos['contratos_activos'] ?? 0,
          };
        } else {
          estadisticasContratos = {
            'totalContratos': 0,
            'ingresosMensuales': 0.0,
            'contratosActivos': 0,
          };
        }

        // Procesar segundo result set (estadísticas de movimientos)
        Map<String, dynamic> estadisticasMovimientos = {};
        if (allResults.length > 1 && allResults[1].isNotEmpty) {
          final resultsMovimientos = allResults[1];
          final rowMovimientos = resultsMovimientos.first.fields;
          estadisticasMovimientos = {
            'totalIngresos': rowMovimientos['total_ingresos'] ?? 0.0,
            'totalEgresos': rowMovimientos['total_egresos'] ?? 0.0,
            'balanceGeneral': rowMovimientos['balance'] ?? 0.0,
          };
        } else {
          // Si no hay segundo result set o está vacío
          estadisticasMovimientos = {
            'totalIngresos': 0.0,
            'totalEgresos': 0.0,
            'balanceGeneral': 0.0,
          };
        }

        // Combinar resultados y calcular rentabilidad
        final double totalIngresosMov =
            estadisticasMovimientos['totalIngresos'];
        final double totalEgresosMov = estadisticasMovimientos['totalEgresos'];
        double rentabilidad = 0.0;
        if (totalIngresosMov > 0) {
          rentabilidad =
              ((totalIngresosMov - totalEgresosMov) / totalIngresosMov) * 100;
        }

        return {
          ...estadisticasContratos,
          // Mapeo para las claves esperadas por la UI
          'ingresosMensuales':
              estadisticasContratos['ingresosMensuales'], // Suma de montos de contrato
          'egresosMensuales': totalEgresosMov, // Egresos reales del periodo
          'balanceMensual':
              totalIngresosMov - totalEgresosMov, // Balance real del periodo
          'rentabilidad': rentabilidad,
          'datosInmuebles': [], // No disponible en este SP
          'evolucionMensual': [], // No disponible en este SP
        };
      } catch (e, stackTrace) {
        _registrarError(
          'Error al obtener estadísticas de rentas',
          e,
          stackTrace,
        );
        throw Exception(
          'Error al obtener estadísticas de rentas: ${_formatearMensajeError(e)}',
        );
      }
    });
  }
}

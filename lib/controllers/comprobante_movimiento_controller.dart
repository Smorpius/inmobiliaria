import '../utils/applogger.dart';
import '../services/mysql_helper.dart';
import '../models/comprobante_movimiento_model.dart';

/// Controlador para gestionar los comprobantes de movimientos de renta en la base de datos
class ComprobanteMovimientoController {
  final DatabaseService dbHelper;
  bool _procesandoError = false;

  ComprobanteMovimientoController({DatabaseService? dbService})
    : dbHelper = dbService ?? DatabaseService();

  /// Método auxiliar para ejecutar operaciones con manejo de errores consistente
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
      if (!_procesandoError) {
        _procesandoError = true;

        // Categorizar el error para mejor manejo
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('connection') ||
            errorStr.contains('socket') ||
            errorStr.contains('timeout') ||
            errorStr.contains('closed')) {
          AppLogger.error(
            'Error de conexión en operación "$descripcion"',
            e,
            stackTrace,
          );
          _procesandoError = false;
          throw Exception(
            'Error de conexión con la base de datos. Intente nuevamente más tarde.',
          );
        }

        if (errorStr.contains('denied') ||
            errorStr.contains('access') ||
            errorStr.contains('permission')) {
          AppLogger.error(
            'Error de permisos en operación "$descripcion"',
            e,
            stackTrace,
          );
          _procesandoError = false;
          throw Exception('No tiene permisos para realizar esta operación.');
        }

        AppLogger.error('Error en operación "$descripcion"', e, stackTrace);
        _procesandoError = false;
      }
      throw Exception('Error en $descripcion: $e');
    }
  }

  /// Ejecuta ROLLBACK de forma segura, capturando errores
  Future<void> _ejecutarRollbackSeguro(dynamic conn) async {
    try {
      await conn.query('ROLLBACK');
    } catch (rollbackError) {
      AppLogger.warning('Error al ejecutar ROLLBACK: $rollbackError');
    }
  }

  /// Obtiene los comprobantes asociados a un movimiento usando el procedimiento almacenado
  Future<List<ComprobanteMovimiento>> obtenerComprobantesPorMovimiento(
    int idMovimiento,
  ) async {
    return _ejecutarOperacion('obtener comprobantes por movimiento', () async {
      if (idMovimiento <= 0) {
        throw Exception('ID de movimiento inválido');
      }

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query(
          'CALL ObtenerComprobantesPorMovimiento(?)',
          [idMovimiento],
        );

        if (results.isEmpty) {
          return [];
        }

        return results.map((row) {
          // Asegúrate de que el modelo ComprobanteMovimiento maneje correctamente
          // la propiedad rutaArchivo en lugar de rutaImagen
          final Map<String, dynamic> fields = Map.from(row.fields);

          // Si existe ruta_imagen pero no existe ruta_archivo, renombrar el campo
          if (fields.containsKey('ruta_imagen') &&
              !fields.containsKey('ruta_archivo')) {
            fields['ruta_archivo'] = fields['ruta_imagen'];
          }

          return ComprobanteMovimiento.fromMap(fields);
        }).toList();
      });
    });
  }

  /// Agrega un nuevo comprobante a un movimiento usando el procedimiento almacenado
  Future<int> agregarComprobante(ComprobanteMovimiento comprobante) async {
    return _ejecutarOperacion('agregar comprobante de movimiento', () async {
      if (comprobante.idMovimiento <= 0) {
        throw Exception('ID de movimiento inválido');
      }

      if (comprobante.rutaArchivo.isEmpty) {
        throw Exception('La ruta del archivo no puede estar vacía');
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // El procedimiento devuelve el ID del comprobante en una variable OUT
          await conn.query(
            'CALL AgregarComprobanteMovimiento(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @id_comprobante_out)',
            [
              comprobante.idMovimiento,
              comprobante.rutaArchivo,
              comprobante.tipoArchivo,
              comprobante.descripcion as Object?, // Convertir String? a Object?
              comprobante.esPrincipal ? 1 : 0,
              comprobante.tipoComprobante,
              comprobante.numeroReferencia
                  as Object?, // Convertir String? a Object?
              comprobante.emisor as Object?, // Convertir String? a Object?
              comprobante.receptor as Object?, // Convertir String? a Object?
              comprobante.metodoPago as Object?, // Convertir String? a Object?
              comprobante.fechaEmision?.toIso8601String().split('T')[0]
                  as Object?, // Convertir String? a Object?
              comprobante.notasAdicionales
                  as Object?, // Convertir String? a Object?
            ],
          );

          // Recuperar el ID generado
          final result = await conn.query('SELECT @id_comprobante_out as id');
          final idComprobante = result.first.fields['id'] as int;

          await conn.query('COMMIT');
          AppLogger.info(
            'Comprobante de movimiento registrado con ID: $idComprobante',
          );
          return idComprobante;
        } catch (e) {
          await _ejecutarRollbackSeguro(conn);
          AppLogger.error(
            'Error al agregar comprobante de movimiento',
            e,
            StackTrace.current,
          );
          throw Exception('Error al agregar comprobante de movimiento: $e');
        }
      });
    });
  }

  /// Actualiza un comprobante de movimiento usando el procedimiento almacenado
  Future<bool> actualizarComprobante(ComprobanteMovimiento comprobante) async {
    return _ejecutarOperacion('actualizar comprobante de movimiento', () async {
      if (comprobante.id == null || comprobante.id! <= 0) {
        throw Exception('ID de comprobante inválido');
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Ejecutar el procedimiento de actualización
          await conn.query(
            'CALL ActualizarComprobanteMovimiento(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
              comprobante.id!,
              comprobante.descripcion ?? '',
              comprobante.esPrincipal ? 1 : 0,
              comprobante.tipoComprobante,
              comprobante.numeroReferencia,
              comprobante.emisor,
              comprobante.receptor,
              comprobante.metodoPago,
              comprobante.fechaEmision?.toIso8601String().split('T')[0],
              comprobante.notasAdicionales,
            ],
          );

          await conn.query('COMMIT');
          AppLogger.info(
            'Comprobante de movimiento actualizado: ${comprobante.id}',
          );
          return true;
        } catch (e) {
          await _ejecutarRollbackSeguro(conn);
          AppLogger.error(
            'Error al actualizar comprobante de movimiento',
            e,
            StackTrace.current,
          );
          throw Exception('Error al actualizar comprobante de movimiento: $e');
        }
      });
    });
  }

  /// Elimina un comprobante de movimiento usando el procedimiento almacenado
  Future<bool> eliminarComprobante(int idComprobante) async {
    return _ejecutarOperacion('eliminar comprobante de movimiento', () async {
      if (idComprobante <= 0) {
        throw Exception('ID de comprobante inválido');
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Ejecutar el procedimiento de eliminación
          await conn.query(
            'CALL EliminarComprobanteMovimiento(?, @afectados)',
            [idComprobante],
          );

          // Recuperar filas afectadas
          final result = await conn.query('SELECT @afectados as filas');
          final filasAfectadas = result.first.fields['filas'] as int? ?? 0;

          await conn.query('COMMIT');

          AppLogger.info(
            'Comprobante de movimiento eliminado: $idComprobante. Filas afectadas: $filasAfectadas',
          );
          return filasAfectadas > 0;
        } catch (e) {
          await _ejecutarRollbackSeguro(conn);
          AppLogger.error(
            'Error al eliminar comprobante de movimiento',
            e,
            StackTrace.current,
          );
          throw Exception('Error al eliminar comprobante de movimiento: $e');
        }
      });
    });
  }

  /// Obtiene comprobantes detallados con filtro por tipo usando el procedimiento almacenado
  Future<List<ComprobanteMovimiento>> obtenerComprobantesDetallados(
    int idMovimiento,
    String? tipoComprobante,
  ) async {
    return _ejecutarOperacion('obtener comprobantes detallados', () async {
      if (idMovimiento <= 0) {
        throw Exception('ID de movimiento inválido');
      }

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query(
          'CALL ObtenerComprobantesDetallados(?, ?)',
          [idMovimiento, tipoComprobante],
        );

        if (results.isEmpty) {
          return [];
        }

        return results
            .map((row) => ComprobanteMovimiento.fromMap(row.fields))
            .toList();
      });
    });
  }

  /// Busca comprobantes por tipo, fecha y otros criterios usando el procedimiento
  Future<List<ComprobanteMovimiento>> buscarComprobantes({
    required String tipoComprobante,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    return _ejecutarOperacion('buscar comprobantes por tipo', () async {
      final fechaInicioStr = fechaInicio?.toIso8601String().split('T')[0];
      final fechaFinStr = fechaFin?.toIso8601String().split('T')[0];

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query(
          'CALL BuscarComprobantesPorTipo(?, ?, ?)',
          [tipoComprobante, fechaInicioStr, fechaFinStr],
        );

        if (results.isEmpty) {
          return [];
        }

        return results
            .map((row) => ComprobanteMovimiento.fromMap(row.fields))
            .toList();
      });
    });
  }

  /// Valida un comprobante fiscal (factura o recibo) usando el procedimiento almacenado
  Future<bool> validarComprobanteFiscal({
    required int idComprobante,
    required String estadoValidacion,
    required int usuarioValidacion,
    required String comentarioValidacion,
  }) async {
    return _ejecutarOperacion('validar comprobante fiscal', () async {
      if (idComprobante <= 0) {
        throw Exception('ID de comprobante inválido');
      }

      if (estadoValidacion.isEmpty) {
        throw Exception('Estado de validación no puede estar vacío');
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Ejecutar el procedimiento de validación
          await conn
              .query('CALL ValidarComprobanteFiscal(?, ?, ?, ?, @afectados)', [
                idComprobante,
                estadoValidacion as Object,
                usuarioValidacion as Object,
                comentarioValidacion as Object,
              ]);

          await conn.query('COMMIT');
          AppLogger.info('Comprobante fiscal validado: $idComprobante');
          return true;
        } catch (e) {
          await _ejecutarRollbackSeguro(conn);
          AppLogger.error(
            'Error al validar comprobante fiscal',
            e,
            StackTrace.current,
          );
          throw Exception('Error al validar comprobante fiscal: $e');
        }
      });
    });
  }

  /// Clona un comprobante de un movimiento a otro usando el procedimiento almacenado
  Future<int> clonarComprobante(
    int idComprobanteOriginal,
    int idMovimientoDestino,
  ) async {
    return _ejecutarOperacion('clonar comprobante', () async {
      if (idComprobanteOriginal <= 0 || idMovimientoDestino <= 0) {
        throw Exception('IDs inválidos para clonar comprobante');
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // El procedimiento devuelve el ID del nuevo comprobante en una variable OUT
          await conn.query(
            'CALL ClonarComprobante(?, ?, @nuevo_id_comprobante)',
            [idComprobanteOriginal, idMovimientoDestino],
          );

          // Recuperar el ID generado
          final result = await conn.query('SELECT @nuevo_id_comprobante as id');
          final idNuevoComprobante = result.first.fields['id'] as int;

          await conn.query('COMMIT');
          AppLogger.info(
            'Comprobante $idComprobanteOriginal clonado exitosamente con nuevo ID: $idNuevoComprobante',
          );
          return idNuevoComprobante;
        } catch (e) {
          await _ejecutarRollbackSeguro(conn);
          AppLogger.error('Error al clonar comprobante', e, StackTrace.current);
          throw Exception('Error al clonar comprobante: $e');
        }
      });
    });
  }

  /// Obtiene resumen de comprobantes por período usando el procedimiento almacenado
  Future<Map<String, dynamic>> obtenerResumenComprobantes({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    return _ejecutarOperacion('obtener resumen de comprobantes', () async {
      final fechaInicioStr = fechaInicio?.toIso8601String().split('T')[0];
      final fechaFinStr = fechaFin?.toIso8601String().split('T')[0];

      return await dbHelper.withConnection((conn) async {
        // Crear una lista de listas para el parámetro (Iterable<List<Object?>>)
        final params = [
          [fechaInicioStr, fechaFinStr],
        ];

        // El procedimiento devuelve múltiples conjuntos de resultados
        final multiResults = await conn.queryMulti(
          'CALL ObtenerResumenComprobantes(?, ?)',
          params,
        );

        if (multiResults.isEmpty) {
          return {};
        }

        // Resumen por tipo
        final porTipo =
            multiResults[0]
                .map(
                  (row) => {
                    'tipo': row.fields['tipo_comprobante'],
                    'cantidad': row.fields['cantidad'],
                    'movimientos_asociados':
                        row.fields['movimientos_asociados'],
                  },
                )
                .toList();

        // Resumen por mes
        final porMes =
            multiResults.length > 1
                ? multiResults[1]
                    .map(
                      (row) => {
                        'anio': row.fields['anio'],
                        'mes': row.fields['mes'],
                        'cantidad': row.fields['cantidad'],
                        'movimientos_asociados':
                            row.fields['movimientos_asociados'],
                      },
                    )
                    .toList()
                : [];

        // Resumen por método de pago
        final porMetodoPago =
            multiResults.length > 2
                ? multiResults[2]
                    .map(
                      (row) => {
                        'metodo_pago': row.fields['metodo_pago'],
                        'cantidad': row.fields['cantidad'],
                      },
                    )
                    .toList()
                : [];

        return {
          'por_tipo': porTipo,
          'por_mes': porMes,
          'por_metodo_pago': porMetodoPago,
        };
      });
    });
  }

  /// Genera reporte de comprobantes por período e inmueble
  Future<Map<String, dynamic>> generarReporteComprobantes({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    int? idInmueble,
  }) async {
    return _ejecutarOperacion('generar reporte de comprobantes', () async {
      final fechaInicioStr = fechaInicio.toIso8601String().split('T')[0];
      final fechaFinStr = fechaFin.toIso8601String().split('T')[0];

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query(
          'CALL GenerarReporteComprobantes(?, ?, ?)',
          [fechaInicioStr, fechaFinStr, idInmueble],
        );

        if (results.isEmpty) {
          return {
            'total_egresos': 0.0,
            'total_ingresos': 0.0,
            'total_comprobantes': 0,
            'comprobantes_facturas': 0,
            'comprobantes_recibos': 0,
            'comprobantes_fiscales': 0,
            'porcentaje_cumplimiento': 0.0,
          };
        }

        // Obtener resultados del reporte desde la primera fila
        final row = results.first.fields;
        final totalEgresos = (row['total_egresos'] as num? ?? 0).toDouble();
        final totalIngresos = (row['total_ingresos'] as num? ?? 0).toDouble();
        final totalComprobantes = row['total_comprobantes'] as int? ?? 0;
        final comprobantesFacturas = row['comprobantes_facturas'] as int? ?? 0;
        final comprobantesRecibos = row['comprobantes_recibos'] as int? ?? 0;
        final comprobantesFiscales = row['comprobantes_fiscales'] as int? ?? 0;
        final porcentajeCumplimiento =
            (row['porcentaje_cumplimiento'] as num? ?? 0).toDouble();

        return {
          'total_egresos': totalEgresos,
          'total_ingresos': totalIngresos,
          'total_comprobantes': totalComprobantes,
          'comprobantes_facturas': comprobantesFacturas,
          'comprobantes_recibos': comprobantesRecibos,
          'comprobantes_fiscales': comprobantesFiscales,
          'porcentaje_cumplimiento': porcentajeCumplimiento,
          'periodo': {
            'inicio': fechaInicioStr,
            'fin': fechaFinStr,
            'inmueble_id': idInmueble,
          },
        };
      });
    });
  }

  /// Obtiene comprobantes vencidos o con antigüedad superior a un límite usando el procedimiento
  Future<List<ComprobanteMovimiento>> obtenerComprobantesVencidos({
    int? diasAntiguedad,
  }) async {
    return _ejecutarOperacion('obtener comprobantes vencidos', () async {
      return await dbHelper.withConnection((conn) async {
        final results = await conn.query(
          'CALL ObtenerComprobantesVencidos(?)',
          [diasAntiguedad ?? 90], // Por defecto, 90 días
        );

        if (results.isEmpty) {
          return [];
        }

        return results
            .map((row) => ComprobanteMovimiento.fromMap(row.fields))
            .toList();
      });
    });
  }

  /// Obtiene estadísticas de cumplimiento fiscal usando el procedimiento
  Future<Map<String, dynamic>> obtenerCumplimientoFiscal(int idInmueble) async {
    return _ejecutarOperacion('obtener cumplimiento fiscal', () async {
      if (idInmueble <= 0) {
        throw Exception('ID de inmueble inválido');
      }

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerCumplimientoFiscal(?)', [
          idInmueble,
        ]);

        if (results.isEmpty) {
          return {
            'total_movimientos': 0,
            'con_comprobante': 0,
            'sin_comprobante': 0,
            'con_factura': 0,
            'con_recibo': 0,
            'otro_comprobante': 0,
            'porcentaje_cumplimiento': 0.0,
            'porcentaje_facturas': 0.0,
          };
        }

        final row = results.first.fields;
        return {
          'total_movimientos': row['total_movimientos'],
          'con_comprobante': row['con_comprobante'],
          'sin_comprobante': row['sin_comprobante'],
          'con_factura': row['con_factura'],
          'con_recibo': row['con_recibo'],
          'otro_comprobante': row['otro_comprobante'],
          'porcentaje_cumplimiento': row['porcentaje_cumplimiento'],
          'porcentaje_facturas': row['porcentaje_facturas'],
        };
      });
    });
  }

  /// Libera recursos cuando el controlador ya no se necesita
  void dispose() {
    AppLogger.info('Liberando recursos de ComprobanteMovimientoController');
  }
}

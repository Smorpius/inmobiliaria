import '../utils/applogger.dart';
import '../services/mysql_helper.dart';
import '../utils/operation_handler.dart';
import '../models/historial_transaccion_model.dart';

/// Controlador para gestionar el historial de cambios en transacciones
class HistorialTransaccionController {
  final DatabaseService dbHelper;

  HistorialTransaccionController({DatabaseService? dbService})
    : dbHelper = dbService ?? DatabaseService();

  /// Método base para registrar cambios en el historial de transacciones
  /// Este método unifica la lógica de registrarCambio y registrarCambiosMultiples
  Future<List<int>> _registrarCambiosBase(
    List<HistorialTransaccion> cambios,
  ) async {
    return OperationHandler.execute(
      operationName: 'registro_base_cambios_historial',
      operation: () async {
        if (cambios.isEmpty) {
          throw Exception('La lista de cambios no puede estar vacía');
        }

        // Validar cada registro antes de intentar guardar
        for (final historial in cambios) {
          if (historial.idEntidad <= 0) {
            throw Exception('ID de entidad inválido');
          }

          if (historial.campoModificado.isEmpty) {
            throw Exception('El campo modificado no puede estar vacío');
          }
        }

        return await dbHelper.withTransaction((conn) async {
          final idsRegistrados = <int>[];

          for (final historial in cambios) {
            // Ejecutar el procedimiento para cada registro
            await conn.query(
              'CALL RegistrarHistorialTransaccion(?, ?, ?, ?, ?, ?, @id_historial_out)',
              [
                historial.tipoEntidad.valor, // Ahora usando el valor del enum
                historial.idEntidad,
                historial.campoModificado,
                historial.valorAnterior as Object?,
                historial.valorNuevo as Object?,
                historial.idUsuarioModificacion as Object?,
              ],
            );

            // Recuperar el ID generado y agregarlo a la lista
            final result = await conn.query('SELECT @id_historial_out as id');
            if (result.isEmpty ||
                !result.first.fields.containsKey('id') ||
                result.first.fields['id'] == null) {
              throw Exception(
                'No se pudo obtener el ID de uno de los registros de historial',
              );
            }

            final idHistorial = result.first.fields['id'] as int;
            if (idHistorial <= 0) {
              throw Exception('ID de historial generado no es válido');
            }

            idsRegistrados.add(idHistorial);
          }

          AppLogger.info(
            'Registrados ${idsRegistrados.length} cambios en historial: ${idsRegistrados.join(", ")}',
          );
          return idsRegistrados;
        });
      },
    );
  }

  /// Registra un cambio en el historial de transacciones
  Future<int> registrarCambio(HistorialTransaccion historial) async {
    final resultados = await _registrarCambiosBase([historial]);
    return resultados.isNotEmpty ? resultados[0] : -1;
  }

  /// Registra múltiples cambios en una sola transacción (útil para cambios relacionados)
  Future<List<int>> registrarCambiosMultiples(
    List<HistorialTransaccion> cambios,
  ) async {
    return await _registrarCambiosBase(cambios);
  }

  /// Obtiene el historial de cambios para una entidad específica
  Future<List<HistorialTransaccion>> obtenerHistorialPorEntidad({
    required String tipoEntidad,
    required int idEntidad,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    return OperationHandler.execute(
      operationName: 'obtener_historial_por_entidad',
      operation: () async {
        if (idEntidad <= 0) {
          throw Exception('ID de entidad inválido');
        }

        final tipoEntidadValido = [
          'venta',
          'movimiento_renta',
          'contrato_renta',
        ].contains(tipoEntidad.toLowerCase());
        if (!tipoEntidadValido) {
          throw Exception('Tipo de entidad inválido');
        }

        final fechaDesdeStr = fechaDesde?.toIso8601String().split('T')[0];
        final fechaHastaStr = fechaHasta?.toIso8601String().split('T')[0];

        return await dbHelper.withConnection((conn) async {
          final results = await conn.query(
            'CALL ObtenerHistorialTransaccion(?, ?, ?, ?)',
            [
              tipoEntidad.toLowerCase(),
              idEntidad,
              fechaDesdeStr,
              fechaHastaStr,
            ],
          );

          if (results.isEmpty) {
            return [];
          }

          final historial = <HistorialTransaccion>[];
          for (var row in results) {
            try {
              historial.add(HistorialTransaccion.fromMap(row.fields));
            } catch (parseError) {
              AppLogger.warning(
                'Error al procesar registro de historial: $parseError',
              );
              // Continuar con el siguiente registro
            }
          }

          return historial;
        });
      },
    );
  }

  /// Obtiene un resumen del historial de cambios para un período
  Future<Map<String, dynamic>> obtenerResumenHistorial({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? idUsuario,
  }) async {
    return OperationHandler.execute(
      operationName: 'obtener_resumen_historial',
      operation: () async {
        final fechaDesdeStr = fechaDesde?.toIso8601String().split('T')[0];
        final fechaHastaStr = fechaHasta?.toIso8601String().split('T')[0];

        return await dbHelper.withConnection((conn) async {
          // Crear una lista de listas para el parámetro (Iterable<List<Object?>>)
          final params = [
            [fechaDesdeStr, fechaHastaStr, idUsuario],
          ];

          // El procedimiento puede devolver múltiples conjuntos de resultados
          final multiResults = await conn.queryMulti(
            'CALL ObtenerResumenHistorialTransacciones(?, ?, ?)',
            params,
          );

          if (multiResults.isEmpty) {
            return {};
          }

          // Resumen por tipo de entidad
          final porTipoEntidad = _procesarConjuntoResultados(multiResults[0], [
            'tipo_entidad',
            'cantidad_cambios',
          ]);

          // Resumen por usuario
          final porUsuario =
              multiResults.length > 1
                  ? _procesarConjuntoResultados(multiResults[1], [
                    'id_usuario',
                    'nombre_usuario',
                    'apellido_usuario',
                    'cantidad_cambios',
                  ])
                  : [];

          // Resumen por campo modificado
          final porCampo =
              multiResults.length > 2
                  ? _procesarConjuntoResultados(multiResults[2], [
                    'tipo_entidad',
                    'campo_modificado',
                    'cantidad_cambios',
                  ])
                  : [];

          return {
            'por_tipo_entidad': porTipoEntidad,
            'por_usuario': porUsuario,
            'por_campo': porCampo,
            'parametros': {
              'fecha_desde': fechaDesdeStr,
              'fecha_hasta': fechaHastaStr,
              'id_usuario': idUsuario,
            },
          };
        });
      },
    );
  }

  /// Método auxiliar para procesar conjuntos de resultados de forma segura
  List<Map<String, dynamic>> _procesarConjuntoResultados(
    dynamic resultSet,
    List<String> camposRequeridos,
  ) {
    final resultados = <Map<String, dynamic>>[];
    int errores = 0;

    try {
      for (var row in resultSet) {
        try {
          final item = <String, dynamic>{};
          bool camposFaltantes = false;

          // Verificar que estén todos los campos requeridos
          for (var campo in camposRequeridos) {
            if (!row.fields.containsKey(campo)) {
              camposFaltantes = true;
              break;
            }
            item[campo] = row.fields[campo];
          }

          if (!camposFaltantes) {
            resultados.add(item);
          } else {
            errores++;
          }
        } catch (e) {
          errores++;
          AppLogger.warning('Error procesando fila de resultados: $e');
        }
      }

      if (errores > 0) {
        AppLogger.warning(
          'Se omitieron $errores filas por datos incompletos o inválidos',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error procesando conjunto de resultados',
        e,
        StackTrace.current,
      );
    }

    return resultados;
  }

  /// Obtiene estadísticas de actividad de usuarios en transacciones
  Future<List<Map<String, dynamic>>> obtenerEstadisticasActividad({
    int? dias,
  }) async {
    return OperationHandler.execute(
      operationName: 'obtener_estadisticas_actividad',
      operation: () async {
        return await dbHelper.withConnection((conn) async {
          final results = await conn.query(
            'CALL ObtenerEstadisticasActividad(?)',
            [dias ?? 30], // Por defecto, últimos 30 días
          );

          if (results.isEmpty) {
            return [];
          }

          return results.map((row) => row.fields).toList();
        });
      },
    );
  }

  /// Eliminar registros de historial antiguos para limpieza de datos
  Future<int> eliminarHistorialAntiguo({
    required int diasAntiguedad,
    String? tipoEntidad,
  }) async {
    return OperationHandler.execute(
      operationName: 'eliminar_historial_antiguo',
      operation: () async {
        if (diasAntiguedad <= 0) {
          throw Exception('La antigüedad en días debe ser mayor a cero');
        }

        return await dbHelper.withTransaction((conn) async {
          // Ejecutar procedimiento de limpieza
          await conn.query(
            'CALL LimpiarHistorialTransacciones(?, ?, @registros_eliminados)',
            [diasAntiguedad, tipoEntidad],
          );

          // Recuperar cantidad de registros eliminados
          final result = await conn.query(
            'SELECT @registros_eliminados as cantidad',
          );
          if (result.isEmpty || !result.first.fields.containsKey('cantidad')) {
            throw Exception(
              'No se pudo obtener el número de registros eliminados',
            );
          }

          final eliminados = result.first.fields['cantidad'] as int;
          AppLogger.info('Historial antiguo eliminado: $eliminados registros');
          return eliminados;
        });
      },
    );
  }

  /// Libera recursos cuando el controlador ya no se necesita
  void dispose() {
    AppLogger.info('Liberando recursos de HistorialTransaccionController');
  }
}

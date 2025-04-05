import '../utils/applogger.dart';
import '../services/mysql_helper.dart';
import '../models/historial_transaccion_model.dart';

/// Controlador para gestionar el historial de cambios en transacciones
class HistorialTransaccionController {
  final DatabaseService dbHelper;
  bool _procesandoError = false;

  HistorialTransaccionController({DatabaseService? dbService})
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

  /// Registra un cambio en el historial de transacciones
  Future<int> registrarCambio(HistorialTransaccion historial) async {
    return _ejecutarOperacion('registrar cambio en historial', () async {
      if (historial.idEntidad <= 0) {
        throw Exception('ID de entidad inválido');
      }

      if (historial.campoModificado.isEmpty) {
        throw Exception('El campo modificado no puede estar vacío');
      }

      final tipoEntidadValido = [
        'venta',
        'movimiento_renta',
        'contrato_renta',
      ].contains(historial.tipoEntidad.toLowerCase());
      if (!tipoEntidadValido) {
        throw Exception('Tipo de entidad inválido');
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // El procedimiento devuelve el ID del registro en una variable OUT
          await conn.query(
            'CALL RegistrarHistorialTransaccion(?, ?, ?, ?, ?, ?, @id_historial_out)',
            [
              historial.tipoEntidad,
              historial.idEntidad,
              historial.campoModificado,
              historial.valorAnterior as Object?, // Convertir String? a Object?
              historial.valorNuevo as Object?, // Convertir String? a Object?
              historial.idUsuarioModificacion
                  as Object?, // Convertir int? a Object?
            ],
          );

          // Recuperar el ID generado
          final result = await conn.query('SELECT @id_historial_out as id');

          // Validar que el resultado tenga datos y un ID válido
          if (result.isEmpty ||
              !result.first.fields.containsKey('id') ||
              result.first.fields['id'] == null) {
            await _ejecutarRollbackSeguro(conn);
            throw Exception(
              'No se pudo obtener el ID del historial registrado',
            );
          }

          final idHistorial = result.first.fields['id'] as int;
          if (idHistorial <= 0) {
            await _ejecutarRollbackSeguro(conn);
            throw Exception('El ID del historial generado no es válido');
          }

          await conn.query('COMMIT');
          AppLogger.info('Cambio registrado en historial con ID: $idHistorial');
          return idHistorial;
        } catch (e) {
          await _ejecutarRollbackSeguro(conn);
          AppLogger.error(
            'Error al registrar cambio en historial',
            e,
            StackTrace.current,
          );
          throw Exception('Error al registrar cambio en historial: $e');
        }
      });
    });
  }

  /// Obtiene el historial de cambios para una entidad específica
  Future<List<HistorialTransaccion>> obtenerHistorialPorEntidad({
    required String tipoEntidad,
    required int idEntidad,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    return _ejecutarOperacion('obtener historial por entidad', () async {
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
        try {
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
        } catch (e) {
          AppLogger.error(
            'Error al consultar historial por entidad',
            e,
            StackTrace.current,
          );
          throw Exception('Error al obtener historial de transacción: $e');
        }
      });
    });
  }

  /// Obtiene un resumen del historial de cambios para un período
  Future<Map<String, dynamic>> obtenerResumenHistorial({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? idUsuario,
  }) async {
    return _ejecutarOperacion('obtener resumen de historial', () async {
      final fechaDesdeStr = fechaDesde?.toIso8601String().split('T')[0];
      final fechaHastaStr = fechaHasta?.toIso8601String().split('T')[0];

      return await dbHelper.withConnection((conn) async {
        try {
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
        } catch (e) {
          AppLogger.error(
            'Error al obtener resumen de historial',
            e,
            StackTrace.current,
          );
          throw Exception('Error al obtener resumen de historial: $e');
        }
      });
    });
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
    return _ejecutarOperacion('obtener estadísticas de actividad', () async {
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
    });
  }

  /// Eliminar registros de historial antiguos para limpieza de datos
  Future<int> eliminarHistorialAntiguo({
    required int diasAntiguedad,
    String? tipoEntidad,
  }) async {
    return _ejecutarOperacion('eliminar historial antiguo', () async {
      if (diasAntiguedad <= 0) {
        throw Exception('La antigüedad en días debe ser mayor a cero');
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
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
            await _ejecutarRollbackSeguro(conn);
            throw Exception(
              'No se pudo obtener el número de registros eliminados',
            );
          }

          final eliminados = result.first.fields['cantidad'] as int;

          await conn.query('COMMIT');
          AppLogger.info('Historial antiguo eliminado: $eliminados registros');
          return eliminados;
        } catch (e) {
          await _ejecutarRollbackSeguro(conn);
          AppLogger.error(
            'Error al eliminar historial antiguo',
            e,
            StackTrace.current,
          );
          throw Exception('Error al eliminar historial antiguo: $e');
        }
      });
    });
  }

  /// Registra múltiples cambios en una sola transacción (útil para cambios relacionados)
  Future<List<int>> registrarCambiosMultiples(
    List<HistorialTransaccion> cambios,
  ) async {
    return _ejecutarOperacion('registrar múltiples cambios en historial', () async {
      if (cambios.isEmpty) {
        throw Exception('La lista de cambios no puede estar vacía');
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          final idsRegistrados = <int>[];

          for (final historial in cambios) {
            // Validar cada registro
            if (historial.idEntidad <= 0) {
              throw Exception('ID de entidad inválido');
            }

            if (historial.campoModificado.isEmpty) {
              throw Exception('El campo modificado no puede estar vacío');
            }

            // Ejecutar el procedimiento para cada registro
            await conn.query(
              'CALL RegistrarHistorialTransaccion(?, ?, ?, ?, ?, ?, @id_historial_out)',
              [
                historial.tipoEntidad.toLowerCase(),
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
              await _ejecutarRollbackSeguro(conn);
              throw Exception(
                'No se pudo obtener el ID de uno de los registros de historial',
              );
            }

            final idHistorial = result.first.fields['id'] as int;
            if (idHistorial <= 0) {
              await _ejecutarRollbackSeguro(conn);
              throw Exception('ID de historial generado no es válido');
            }

            idsRegistrados.add(idHistorial);
          }

          await conn.query('COMMIT');
          AppLogger.info(
            'Registrados ${idsRegistrados.length} cambios en historial: ${idsRegistrados.join(", ")}',
          );
          return idsRegistrados;
        } catch (e) {
          await _ejecutarRollbackSeguro(conn);
          AppLogger.error(
            'Error al registrar múltiples cambios en historial',
            e,
            StackTrace.current,
          );
          throw Exception(
            'Error al registrar múltiples cambios en historial: $e',
          );
        }
      });
    });
  }

  /// Libera recursos cuando el controlador ya no se necesita
  void dispose() {
    AppLogger.info('Liberando recursos de HistorialTransaccionController');
  }
}

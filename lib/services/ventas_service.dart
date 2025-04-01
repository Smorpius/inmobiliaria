import 'dart:async';
import '../utils/applogger.dart';
import 'package:mysql1/mysql1.dart';
import '../models/venta_model.dart';
import '../services/mysql_helper.dart';
import '../models/venta_reporte_model.dart';
import 'package:synchronized/synchronized.dart';

class VentasService {
  final DatabaseService _db;
  // Control para evitar duplicación de logs
  bool _procesandoError = false;

  // Para operaciones concurrentes
  final _lock = Lock();

  // Control de reintentos
  static const int _maxReintentos = 2;
  static const Duration _tiempoEntreReintentos = Duration(milliseconds: 800);

  VentasService(this._db);

  /// Obtiene todas las ventas usando un procedimiento almacenado con manejo robusto
  Future<List<Venta>> obtenerVentas() async {
    return await _ejecutarConManejoDeFallos('obtener_ventas', () async {
      MySqlConnection? conn;
      try {
        conn = await _obtenerConexion();
        await conn.query('START TRANSACTION');

        AppLogger.info('Obteniendo lista completa de ventas');
        final result = await conn.query('CALL ObtenerVentas()');

        final ventas = <Venta>[];
        for (var row in result) {
          try {
            final map = <String, dynamic>{};
            for (var field in row.fields.keys) {
              map[field] = row[field];
            }
            ventas.add(Venta.fromMap(map));
          } catch (e) {
            _logErrorControlado(
              'Error al procesar venta',
              e,
              StackTrace.current,
            );
          }
        }

        await conn.query('COMMIT');
        AppLogger.info('Ventas recuperadas exitosamente: ${ventas.length}');
        await _liberarConexion(conn);
        return ventas;
      } catch (e, stackTrace) {
        if (conn != null) {
          await _ejecutarRollbackSeguro(conn);
          await _liberarConexion(conn);
        }

        // Si es error de conexión, intentar reconectar
        await _manejarErrorDeConexion(e);
        AppLogger.error('Error al obtener ventas', e, stackTrace);

        // Propagar error con mensaje amigable
        throw Exception(
          'Error al obtener ventas: ${_formatearMensajeError(e)}',
        );
      }
    });
  }

  /// Obtiene una venta por su ID usando procedimiento almacenado con manejo robusto
  Future<Venta?> obtenerVentaPorId(int idVenta) async {
    return await _ejecutarConManejoDeFallos('obtener_venta_por_id', () async {
      MySqlConnection? conn;
      try {
        conn = await _obtenerConexion();
        await conn.query('START TRANSACTION');

        AppLogger.info('Consultando venta con ID: $idVenta');
        final result = await conn.query('CALL ObtenerVentaPorId(?)', [idVenta]);

        if (result.isEmpty || result.first.isEmpty) {
          AppLogger.info('No se encontró venta con ID: $idVenta');
          await conn.query('COMMIT');
          await _liberarConexion(conn);
          return null;
        }

        final map = <String, dynamic>{};
        for (var field in result.first.fields.keys) {
          map[field] = result.first[field];
        }

        await conn.query('COMMIT');
        AppLogger.info('Venta recuperada exitosamente: ID=$idVenta');

        await _liberarConexion(conn);
        return Venta.fromMap(map);
      } catch (e, stackTrace) {
        if (conn != null) {
          await _ejecutarRollbackSeguro(conn);
          await _liberarConexion(conn);
        }

        await _manejarErrorDeConexion(e);
        AppLogger.error(
          'Error al obtener venta por ID: $idVenta',
          e,
          stackTrace,
        );

        throw Exception(
          'Error al obtener venta #$idVenta: ${_formatearMensajeError(e)}',
        );
      }
    });
  }

  /// Crea una nueva venta usando procedimiento almacenado con manejo robusto
  Future<int> crearVenta(Venta venta) async {
    return await _ejecutarConManejoDeFallos('crear_venta', () async {
      MySqlConnection? conn;
      try {
        conn = await _obtenerConexion();
        await conn.query('START TRANSACTION');

        AppLogger.info('Creando nueva venta para inmueble ${venta.idInmueble}');

        // Reiniciar variable de salida para evitar problemas previos
        await conn.query('SET @id_venta_out = 0');

        await conn.query('CALL CrearVenta(?, ?, ?, ?, ?, ?, @id_venta_out)', [
          venta.idCliente,
          venta.idInmueble,
          venta.fechaVenta.toIso8601String().split('T')[0],
          venta.ingreso,
          venta.comisionProveedores,
          venta.utilidadNeta,
        ]);

        final result = await conn.query('SELECT @id_venta_out AS id');
        if (result.isEmpty || result.first['id'] == null) {
          await conn.query('ROLLBACK');
          await _liberarConexion(conn);
          throw Exception('No se pudo obtener el ID de la venta creada');
        }

        final idVenta = result.first['id'] as int;
        await conn.query('COMMIT');

        AppLogger.info('Venta creada exitosamente con ID: $idVenta');
        await _liberarConexion(conn);
        return idVenta;
      } catch (e, stackTrace) {
        if (conn != null) {
          await _ejecutarRollbackSeguro(conn);
          await _liberarConexion(conn);
        }

        await _manejarErrorDeConexion(e);
        AppLogger.error('Error al crear venta', e, stackTrace);

        throw Exception('Error al crear venta: ${_formatearMensajeError(e)}');
      }
    });
  }

  /// Actualiza la utilidad de una venta usando procedimiento almacenado
  Future<bool> actualizarUtilidadVenta(
    int idVenta,
    double gastosAdicionales,
    int usuarioModificacion,
  ) async {
    return await _ejecutarConManejoDeFallos('actualizar_utilidad_venta', () async {
      MySqlConnection? conn;
      try {
        conn = await _obtenerConexion();
        await conn.query('START TRANSACTION');

        AppLogger.info(
          'Actualizando utilidad de venta ID: $idVenta con gastos: $gastosAdicionales',
        );

        _validarParametrosUtilidadVenta(
          idVenta,
          gastosAdicionales,
          usuarioModificacion,
        );

        await conn.query('CALL ActualizarUtilidadVenta(?, ?, ?)', [
          idVenta,
          gastosAdicionales,
          usuarioModificacion,
        ]);

        await conn.query('COMMIT');
        AppLogger.info('Utilidad de venta $idVenta actualizada correctamente');

        await _liberarConexion(conn);
        return true;
      } catch (e, stackTrace) {
        if (conn != null) {
          await _ejecutarRollbackSeguro(conn);
          await _liberarConexion(conn);
        }

        await _manejarErrorDeConexion(e);
        AppLogger.error(
          'Error al actualizar utilidad de venta: $idVenta',
          e,
          stackTrace,
        );

        throw Exception(
          'Error al actualizar utilidad de venta #$idVenta: ${_formatearMensajeError(e)}',
        );
      }
    });
  }

  /// Cambia el estado de una venta usando procedimiento almacenado
  Future<bool> cambiarEstadoVenta(
    int idVenta,
    int nuevoEstado,
    int usuarioModificacion,
  ) async {
    return await _ejecutarConManejoDeFallos('cambiar_estado_venta', () async {
      MySqlConnection? conn;
      try {
        conn = await _obtenerConexion();
        await conn.query('START TRANSACTION');

        _validarEstadoVenta(nuevoEstado);

        AppLogger.info(
          'Cambiando estado de venta ID: $idVenta a estado: $nuevoEstado',
        );

        await conn.query('CALL CambiarEstadoVenta(?, ?, ?)', [
          idVenta,
          nuevoEstado,
          usuarioModificacion,
        ]);

        await conn.query('COMMIT');
        AppLogger.info('Estado de venta $idVenta actualizado correctamente');

        await _liberarConexion(conn);
        return true;
      } catch (e, stackTrace) {
        if (conn != null) {
          await _ejecutarRollbackSeguro(conn);
          await _liberarConexion(conn);
        }

        await _manejarErrorDeConexion(e);
        AppLogger.error(
          'Error al cambiar estado de la venta: $idVenta',
          e,
          stackTrace,
        );

        throw Exception(
          'Error al cambiar estado de venta #$idVenta: ${_formatearMensajeError(e)}',
        );
      }
    });
  }

  /// Obtiene estadísticas de ventas en un período usando procedimientos almacenados
  Future<VentaReporte> obtenerEstadisticasVentas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    return await _ejecutarConManejoDeFallos(
      'obtener_estadisticas_ventas',
      () async {
        MySqlConnection? conn;
        try {
          conn = await _obtenerConexion();
          await conn.query('START TRANSACTION');

          AppLogger.info('Obteniendo estadísticas de ventas');

          _validarRangoFechas(fechaInicio, fechaFin);

          final fechaInicioStr = fechaInicio?.toIso8601String().split('T')[0];
          final fechaFinStr = fechaFin?.toIso8601String().split('T')[0];

          // Obtener estadísticas generales
          final estadisticasResult = await conn.query(
            'CALL ObtenerEstadisticasVentas(?, ?)',
            [fechaInicioStr, fechaFinStr],
          );

          final estadisticas = _procesarEstadisticasGenerales(
            estadisticasResult,
            fechaInicioStr,
            fechaFinStr,
          );

          // Procesar rentabilidad por tipo de inmueble
          final ventasPorTipo = await _procesarVentasPorTipo(conn);

          // Procesar ventas mensuales
          final ventasMensuales = await _procesarVentasMensuales(
            conn,
            fechaInicio?.year ?? DateTime.now().year - 2,
          );

          final reporte = _crearVentaReporte(
            fechaInicio,
            fechaFin,
            estadisticas,
            ventasPorTipo,
            ventasMensuales,
          );

          await conn.query('COMMIT');
          AppLogger.info('Estadísticas de ventas obtenidas exitosamente');

          await _liberarConexion(conn);
          return reporte;
        } catch (e, stackTrace) {
          if (conn != null) {
            await _ejecutarRollbackSeguro(conn);
            await _liberarConexion(conn);
          }

          await _manejarErrorDeConexion(e);
          AppLogger.error(
            'Error al obtener estadísticas de ventas',
            e,
            stackTrace,
          );

          // En caso de error, devolvemos un reporte vacío
          return _crearReporteVacio(fechaInicio, fechaFin);
        }
      },
    );
  }

  // =================== MÉTODOS AUXILIARES ===================

  /// Obtiene una conexión verificada
  Future<MySqlConnection> _obtenerConexion() async {
    try {
      return await _db.connection;
    } catch (e) {
      AppLogger.error('Error al obtener conexión', e, StackTrace.current);
      await _db.reiniciarConexion();
      return await _db.connection;
    }
  }

  /// Libera una conexión de manera segura
  Future<void> _liberarConexion(MySqlConnection conn) async {
    try {
      await _db.releaseConnection(conn);
    } catch (e) {
      // Si falla al liberar, solo registramos el error
      AppLogger.warning('Error al liberar conexión: ${e.toString()}');
    }
  }

  /// Ejecuta un rollback de manera segura
  Future<void> _ejecutarRollbackSeguro(MySqlConnection conn) async {
    try {
      await conn
          .query('ROLLBACK')
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              AppLogger.warning('Timeout al ejecutar ROLLBACK');
              throw TimeoutException('Timeout al ejecutar ROLLBACK');
            },
          );
    } catch (e) {
      AppLogger.warning('Error al ejecutar ROLLBACK: ${e.toString()}');
    }
  }

  /// Ejecuta una operación con manejo de fallos y reintentos
  Future<T> _ejecutarConManejoDeFallos<T>(
    String operacion,
    Future<T> Function() funcion,
  ) async {
    return _lock.synchronized(() async {
      int intentos = 0;

      while (true) {
        try {
          return await funcion();
        } catch (e) {
          intentos++;

          if (intentos >= _maxReintentos || !_esErrorDeConexion(e)) {
            rethrow;
          }

          AppLogger.warning(
            'Reintentando operación [$operacion] tras error de conexión (intento $intentos/$_maxReintentos)',
          );

          await Future.delayed(_tiempoEntreReintentos);
        }
      }
    });
  }

  /// Registra un error evitando duplicados
  void _logErrorControlado(
    String mensaje,
    dynamic error,
    StackTrace stackTrace,
  ) {
    if (!_procesandoError) {
      _procesandoError = true;
      AppLogger.warning('$mensaje: ${error.toString().split('\n').first}');
      _procesandoError = false;
    }
  }

  /// Maneja un error de conexión
  Future<void> _manejarErrorDeConexion(dynamic error) async {
    if (_esErrorDeConexion(error)) {
      try {
        await _db.reiniciarConexion();
      } catch (e) {
        AppLogger.warning('Error al reiniciar conexión: ${e.toString()}');
      }
    }
  }

  /// Verifica si el error recibido es de conexión
  bool _esErrorDeConexion(Object error) {
    final mensaje = error.toString().toLowerCase();
    return mensaje.contains('socket') ||
        mensaje.contains('connection') ||
        mensaje.contains('closed') ||
        mensaje.contains('it is closed') ||
        mensaje.contains('connection refused') ||
        mensaje.contains('timeout');
  }

  /// Formatea un mensaje de error para hacerlo más amigable
  String _formatearMensajeError(dynamic error) {
    final errorStr = error.toString();

    // Manejar errores específicos de MySQL
    if (errorStr.contains("Cannot write to socket")) {
      return "Error de conexión con la base de datos. Intente nuevamente.";
    }

    if (errorStr.contains("transaction")) {
      return "Error en la transacción de base de datos. Intente nuevamente.";
    }

    // Extraer solo la primera línea del error
    final mensaje = errorStr.split('\n').first;

    // Limitar longitud del mensaje
    return mensaje.length > 100 ? '${mensaje.substring(0, 97)}...' : mensaje;
  }

  /// Valida los parámetros para actualizar la utilidad
  void _validarParametrosUtilidadVenta(
    int idVenta,
    double gastosAdicionales,
    int usuarioModificacion,
  ) {
    if (idVenta <= 0) {
      throw Exception('ID de venta inválido');
    }
    if (gastosAdicionales < 0) {
      throw Exception('Los gastos no pueden ser negativos');
    }
    if (usuarioModificacion <= 0) {
      throw Exception('ID de usuario inválido');
    }
  }

  /// Valida el estado de una venta
  void _validarEstadoVenta(int nuevoEstado) {
    if (![7, 8, 9].contains(nuevoEstado)) {
      throw Exception(
        'Estado no válido. Debe ser 7 (en proceso), 8 (completada) o 9 (cancelada)',
      );
    }
  }

  /// Valida el rango de fechas
  void _validarRangoFechas(DateTime? fechaInicio, DateTime? fechaFin) {
    if (fechaInicio != null &&
        fechaFin != null &&
        fechaInicio.isAfter(fechaFin)) {
      throw Exception(
        'La fecha inicial no puede ser posterior a la fecha final',
      );
    }
  }

  /// Procesa las estadísticas generales
  Map<String, dynamic> _procesarEstadisticasGenerales(
    Results estadisticasResult,
    String? fechaInicioStr,
    String? fechaFinStr,
  ) {
    return estadisticasResult.isNotEmpty && estadisticasResult.first.isNotEmpty
        ? estadisticasResult.first.fields
        : {
          'total_ventas': 0,
          'ingreso_total': 0.0,
          'utilidad_total': 0.0,
          'margen_promedio': 0.0,
          'fecha_inicio':
              fechaInicioStr ??
              DateTime(2000, 1, 1).toIso8601String().split('T')[0],
          'fecha_fin':
              fechaFinStr ?? DateTime.now().toIso8601String().split('T')[0],
        };
  }

  /// Procesa las ventas por tipo
  Future<Map<String, double>> _procesarVentasPorTipo(
    MySqlConnection conn,
  ) async {
    final ventasPorTipo = <String, double>{};

    try {
      final rentabilidadResult = await conn.query(
        'CALL AnalisisRentabilidadPorTipo()',
      );

      for (var row in rentabilidadResult) {
        try {
          if (row['tipo_inmueble'] != null && row['cantidad_ventas'] != null) {
            ventasPorTipo[row['tipo_inmueble'].toString()] = double.parse(
              row['cantidad_ventas'].toString(),
            );
          }
        } catch (e) {
          _logErrorControlado(
            'Error al procesar dato de rentabilidad',
            e,
            StackTrace.current,
          );
        }
      }
    } catch (e) {
      _logErrorControlado(
        'Error al obtener análisis de rentabilidad',
        e,
        StackTrace.current,
      );
    }

    return ventasPorTipo;
  }

  /// Procesa las ventas mensuales
  Future<List<Map<String, dynamic>>> _procesarVentasMensuales(
    MySqlConnection conn,
    int anioInicio,
  ) async {
    final ventasMensuales = <Map<String, dynamic>>[];

    try {
      final ventasMensualesResult = await conn.query(
        'CALL ObtenerVentasMensuales(?)',
        [anioInicio],
      );

      for (var row in ventasMensualesResult) {
        try {
          if (row['mes'] != null) {
            ventasMensuales.add({
              'anio': row['anio'] ?? DateTime.now().year,
              'mes': row['mes'],
              'total': row['cantidad_ventas'] ?? 0,
              'ingreso': _parseDoubleSafe(row['ingresos_totales'], 0.0),
              'utilidad': _parseDoubleSafe(row['utilidad_neta'], 0.0),
            });
          }
        } catch (e) {
          _logErrorControlado(
            'Error al procesar dato de ventas mensuales',
            e,
            StackTrace.current,
          );
        }
      }
    } catch (e) {
      _logErrorControlado(
        'Error al obtener ventas mensuales',
        e,
        StackTrace.current,
      );
    }

    return ventasMensuales;
  }

  /// Crea un reporte de ventas a partir de los datos procesados
  VentaReporte _crearVentaReporte(
    DateTime? fechaInicio,
    DateTime? fechaFin,
    Map<String, dynamic> estadisticas,
    Map<String, double> ventasPorTipo,
    List<Map<String, dynamic>> ventasMensuales,
  ) {
    return VentaReporte(
      fechaInicio: fechaInicio ?? DateTime(2000, 1, 1),
      fechaFin: fechaFin ?? DateTime.now(),
      totalVentas: _parseIntSafe(estadisticas['total_ventas'], 0),
      ingresoTotal: _parseDoubleSafe(estadisticas['ingreso_total'], 0.0),
      utilidadTotal: _parseDoubleSafe(estadisticas['utilidad_total'], 0.0),
      margenPromedio: _parseDoubleSafe(estadisticas['margen_promedio'], 0.0),
      ventasPorTipo: ventasPorTipo,
      ventasMensuales: ventasMensuales,
    );
  }

  /// Reinicia la conexión a la base de datos
  Future<void> reiniciarConexion() async {
    try {
      AppLogger.info('Reiniciando conexión desde VentasService');
      await _db.reiniciarConexion();
      AppLogger.info('Conexión reiniciada exitosamente');
    } catch (e) {
      AppLogger.error('Error al reiniciar conexión', e, StackTrace.current);
      throw Exception(
        'No se pudo reiniciar la conexión: ${_formatearMensajeError(e)}',
      );
    }
  }

  /// Método para buscar ventas por diferentes criterios
  Future<List<Venta>> buscarVentas({
    int? idCliente,
    int? idInmueble,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? idEstado,
  }) async {
    return await _ejecutarConManejoDeFallos('buscar_ventas', () async {
      MySqlConnection? conn;
      try {
        conn = await _obtenerConexion();
        await conn.query('START TRANSACTION');

        // Construir parámetros para procedimiento almacenado
        final fechaInicioStr = fechaInicio?.toIso8601String().split('T')[0];
        final fechaFinStr = fechaFin?.toIso8601String().split('T')[0];

        AppLogger.info('Buscando ventas con criterios específicos');

        // Llamada al procedimiento almacenado BuscarVentas
        final results = await conn.query('CALL BuscarVentas(?, ?, ?, ?, ?)', [
          idCliente,
          idInmueble,
          fechaInicioStr,
          fechaFinStr,
          idEstado,
        ]);

        final List<Venta> ventas = [];
        for (var row in results) {
          try {
            final map = <String, dynamic>{};
            for (var field in row.fields.keys) {
              map[field] = row[field];
            }
            ventas.add(Venta.fromMap(map));
          } catch (e) {
            _logErrorControlado(
              'Error al procesar venta en búsqueda',
              e,
              StackTrace.current,
            );
          }
        }

        await conn.query('COMMIT');
        AppLogger.info(
          'Búsqueda de ventas completada: ${ventas.length} resultados',
        );

        await _liberarConexion(conn);
        return ventas;
      } catch (e, stackTrace) {
        if (conn != null) {
          await _ejecutarRollbackSeguro(conn);
          await _liberarConexion(conn);
        }

        await _manejarErrorDeConexion(e);
        AppLogger.error('Error al buscar ventas', e, stackTrace);

        throw Exception('Error al buscar ventas: ${_formatearMensajeError(e)}');
      }
    });
  }

  /// Crea un reporte vacío en caso de error
  VentaReporte _crearReporteVacio(DateTime? fechaInicio, DateTime? fechaFin) {
    return VentaReporte(
      fechaInicio: fechaInicio ?? DateTime(2000, 1, 1),
      fechaFin: fechaFin ?? DateTime.now(),
      totalVentas: 0,
      ingresoTotal: 0,
      utilidadTotal: 0,
      margenPromedio: 0,
      ventasPorTipo: {},
      ventasMensuales: [],
    );
  }

  /// Conversión segura a entero
  int _parseIntSafe(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    try {
      return int.parse(value.toString());
    } catch (e) {
      AppLogger.warning('Error al convertir a int: $value');
      return defaultValue;
    }
  }

  /// Conversión segura a double
  double _parseDoubleSafe(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    try {
      return double.parse(value.toString());
    } catch (e) {
      AppLogger.warning('Error al convertir a double: $value');
      return defaultValue;
    }
  }
}

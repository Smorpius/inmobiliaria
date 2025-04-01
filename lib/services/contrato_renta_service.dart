import 'package:intl/intl.dart';
import '../utils/applogger.dart';
import '../services/mysql_helper.dart';
import '../models/contrato_renta_model.dart';

/// Servicio para gestionar contratos de renta en la base de datos
/// Utiliza procedimientos almacenados para todas las operaciones
class ContratoRentaService {
  final DatabaseService _db;
  bool _procesandoError = false;
  static const Duration _tiempoMinEntreLogs = Duration(seconds: 10);
  DateTime? _ultimoErrorLog;

  ContratoRentaService(this._db);

  /// Registra un nuevo contrato de renta usando el procedimiento almacenado
  /// RegistrarContratoRenta
  Future<int> registrarContrato(ContratoRenta contrato) async {
    return await _db.withConnection((conn) async {
      await conn.query('START TRANSACTION');
      try {
        AppLogger.info(
          'Registrando contrato de renta para inmueble: ${contrato.idInmueble}, '
          'cliente: ${contrato.idCliente}, monto: ${contrato.montoMensual}',
        );

        // Convertir fechas a formato ISO para el procedimiento
        final fechaInicioStr = DateFormat(
          'yyyy-MM-dd',
        ).format(contrato.fechaInicio);
        final fechaFinStr = DateFormat('yyyy-MM-dd').format(contrato.fechaFin);

        // Llamar al procedimiento almacenado
        await conn.query(
          'CALL RegistrarContratoRenta(?, ?, ?, ?, ?, ?, @id_contrato_out)',
          [
            contrato.idInmueble,
            contrato.idCliente,
            fechaInicioStr,
            fechaFinStr,
            contrato.montoMensual,
            contrato.condicionesAdicionales ?? '',
          ],
        );

        // Obtener el ID generado
        final result = await conn.query('SELECT @id_contrato_out as id');
        if (result.isEmpty || result.first['id'] == null) {
          await conn.query('ROLLBACK');
          throw Exception('No se pudo obtener el ID del contrato registrado');
        }

        final idContrato = result.first['id'] as int;
        await conn.query('COMMIT');

        AppLogger.info('Contrato registrado con ID: $idContrato');
        return idContrato;
      } catch (e, stackTrace) {
        await conn.query('ROLLBACK');
        _registrarError('Error al registrar contrato de renta', e, stackTrace);

        // Devolver un mensaje de error más específico según el tipo de excepción
        final mensajeOriginal = e.toString().toLowerCase();
        if (mensajeOriginal.contains('ya existe un contrato activo')) {
          throw Exception(
            'Ya existe un contrato de renta activo para este inmueble',
          );
        } else if (mensajeOriginal.contains('foreign key')) {
          throw Exception('El inmueble o cliente especificado no existe');
        }

        throw Exception(
          'Error al registrar contrato de renta: ${_formatearMensajeError(e)}',
        );
      }
    });
  }

  /// Cambia el estado de un contrato (activo=1 o finalizado=2)
  /// Utiliza el procedimiento ActualizarEstadoContratoRenta
  Future<bool> cambiarEstadoContrato(int idContrato, int nuevoEstado) async {
    return await _db.withConnection((conn) async {
      await conn.query('START TRANSACTION');
      try {
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

  /// Obtiene todos los contratos (activos e inactivos)
  Future<List<ContratoRenta>> obtenerContratos() async {
    return await _db.withConnection((conn) async {
      try {
        AppLogger.info('Obteniendo lista de contratos de renta');

        final results = await conn.query('CALL ObtenerContratos()');

        if (results.isEmpty) {
          return [];
        }

        final contratos = <ContratoRenta>[];
        for (var row in results.first) {
          try {
            contratos.add(ContratoRenta.fromMap(row.fields));
          } catch (e, stackTrace) {
            _registrarError(
              'Error al procesar contrato de renta',
              e,
              stackTrace,
            );
          }
        }

        AppLogger.info('Contratos obtenidos: ${contratos.length}');
        return contratos;
      } catch (e, stackTrace) {
        _registrarError('Error al obtener contratos de renta', e, stackTrace);
        throw Exception(
          'Error al obtener contratos de renta: ${_formatearMensajeError(e)}',
        );
      }
    });
  }

  /// Busca contratos por cliente, estado o rango de fechas
  Future<List<ContratoRenta>> buscarContratos({
    int? idCliente,
    int? idInmueble,
    int? idEstado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    return await _db.withConnection((conn) async {
      try {
        AppLogger.info('Buscando contratos con criterios específicos');

        // Formatear fechas para SQL si están presentes
        String? fechaInicioStr;
        if (fechaInicio != null) {
          fechaInicioStr = DateFormat('yyyy-MM-dd').format(fechaInicio);
        }

        String? fechaFinStr;
        if (fechaFin != null) {
          fechaFinStr = DateFormat('yyyy-MM-dd').format(fechaFin);
        }

        // Llamar al procedimiento almacenado
        final results = await conn.query(
          'CALL BuscarContratos(?, ?, ?, ?, ?)',
          [idCliente, idInmueble, idEstado, fechaInicioStr, fechaFinStr],
        );

        if (results.isEmpty) {
          return [];
        }

        final contratos = <ContratoRenta>[];
        for (var row in results.first) {
          contratos.add(ContratoRenta.fromMap(row.fields));
        }

        AppLogger.info('Contratos encontrados: ${contratos.length}');
        return contratos;
      } catch (e, stackTrace) {
        _registrarError('Error al buscar contratos', e, stackTrace);
        throw Exception(
          'Error al buscar contratos: ${_formatearMensajeError(e)}',
        );
      }
    });
  }

  /// Calcula el resumen de ingresos por rentas en un periodo determinado
  Future<Map<String, dynamic>> obtenerEstadisticasRentas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    return await _db.withConnection((conn) async {
      try {
        AppLogger.info('Obteniendo estadísticas de rentas');

        // Establecer fechas por defecto si no se proporcionan
        final fechaInicioReal =
            fechaInicio ?? DateTime.now().subtract(const Duration(days: 365));
        final fechaFinReal = fechaFin ?? DateTime.now();

        // Formatear fechas para el procedimiento almacenado
        final fechaInicioStr = DateFormat('yyyy-MM-dd').format(fechaInicioReal);
        final fechaFinStr = DateFormat('yyyy-MM-dd').format(fechaFinReal);

        // Llamar al procedimiento almacenado
        final resultados = await conn.query(
          'CALL ObtenerEstadisticasRentas(?, ?)',
          [fechaInicioStr, fechaFinStr],
        );

        if (resultados.isEmpty) {
          return {
            'total_contratos': 0,
            'ingresos_mensuales': 0.0,
            'contratos_activos': 0,
            'total_ingresos': 0.0,
            'total_egresos': 0.0,
            'balance': 0.0,
            'periodo': '$fechaInicioStr a $fechaFinStr',
          };
        }

        // Primera fila: estadísticas de contratos
        final contratoStats = resultados.first.first.fields;

        // Segunda fila: estadísticas de movimientos
        final movimientoStats = resultados.last.first.fields;

        // Construir el resultado
        final estadisticas = {
          'total_contratos': contratoStats['total_contratos'] ?? 0,
          'ingresos_mensuales': contratoStats['ingresos_mensuales'] ?? 0.0,
          'contratos_activos': contratoStats['contratos_activos'] ?? 0,
          'total_ingresos': movimientoStats['total_ingresos'] ?? 0.0,
          'total_egresos': movimientoStats['total_egresos'] ?? 0.0,
          'balance': movimientoStats['balance'] ?? 0.0,
          'periodo': '$fechaInicioStr a $fechaFinStr',
        };

        return estadisticas;
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
}

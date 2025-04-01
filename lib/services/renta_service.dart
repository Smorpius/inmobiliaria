import 'package:intl/intl.dart';
import '../utils/applogger.dart';
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
    return await _db.withConnection((conn) async {
      await conn.query('START TRANSACTION');
      try {
        // Validaciones previas (mantener las existentes)
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
            throw Exception('Ya existe un contrato activo para este inmueble');
          }
        }

        // Insertar el contrato directamente
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

        // Obtener el ID generado y asegurarnos de que no sea nulo
        final idContrato = insertResult.insertId;

        if (idContrato == null || idContrato <= 0) {
          await conn.query('ROLLBACK');
          throw Exception('No se pudo obtener el ID del contrato registrado');
        }

        // Actualizar el estado del inmueble a rentado (5)
        await conn.query(
          'UPDATE inmuebles SET id_estado = 5 WHERE id_inmueble = ?',
          [idInmueble],
        );

        await conn.query('COMMIT');

        AppLogger.info(
          'Contrato de renta registrado con ID: $idContrato para inmueble ID: $idInmueble',
        );

        return idContrato;
      } catch (e, stackTrace) {
        await conn.query('ROLLBACK');
        _registrarError('Error al registrar contrato de renta', e, stackTrace);

        // Proporcionar mensajes de error específicos
        final mensajeOriginal = e.toString().toLowerCase();
        if (mensajeOriginal.contains('ya existe un contrato activo')) {
          throw Exception(
            'Ya existe un contrato de renta activo para este inmueble',
          );
        } else if (mensajeOriginal.contains('foreign key')) {
          throw Exception('El inmueble o cliente especificado no existe');
        } else if (mensajeOriginal.contains('no element')) {
          throw Exception('Error en la consulta de verificación de contratos');
        }

        throw Exception(
          'Error al registrar contrato de renta: ${_formatearMensajeError(e)}',
        );
      }
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
}

import '../utils/applogger.dart';
import '../models/pago_renta_model.dart';
import '../services/pago_renta_service.dart';

class PagoRentaController {
  final PagoRentaService _service;

  PagoRentaController({required PagoRentaService service}) : _service = service;

  /// Registra un nuevo pago de renta
  Future<int> registrarPago(PagoRenta pago) async {
    try {
      AppLogger.info(
        'Registrando pago de renta para contrato: ${pago.idContrato}',
      );
      return await _service.registrarPago(pago);
    } catch (e, stackTrace) {
      AppLogger.error('Error al registrar pago de renta', e, stackTrace);
      rethrow;
    }
  }

  /// Verifica si un contrato tiene pagos pendientes del mes actual
  Future<bool> tienePagoMesActual(int idContrato) async {
    try {
      AppLogger.info(
        'Verificando pago del mes actual para contrato: $idContrato',
      );
      final pagos = await _service.obtenerPagosPorContrato(idContrato);

      final ahora = DateTime.now();
      final mesActual =
          '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';

      // Verificar si existe algún pago para el mes actual
      return pagos.any((pago) {
        // Extraer año y mes de la fecha de pago
        final mesPago =
            '${pago.fechaPago.year}-${pago.fechaPago.month.toString().padLeft(2, '0')}';
        return mesPago == mesActual;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error al verificar pago del mes actual', e, stackTrace);
      rethrow;
    }
  }

  /// Calcula los meses con pagos pendientes para un contrato
  Future<List<String>> calcularMesesPendientes(
    int idContrato,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      AppLogger.info('Calculando meses pendientes para contrato: $idContrato');
      final pagos = await _service.obtenerPagosPorContrato(idContrato);

      // Obtener todos los meses que abarca el contrato
      List<String> mesesContrato = [];
      DateTime mesActual = DateTime(fechaInicio.year, fechaInicio.month);
      final ahora = DateTime.now();
      final hasta = fechaFin.isAfter(ahora) ? ahora : fechaFin;

      while (!mesActual.isAfter(hasta)) {
        mesesContrato.add(
          '${mesActual.year}-${mesActual.month.toString().padLeft(2, '0')}',
        );
        mesActual = DateTime(
          mesActual.month < 12 ? mesActual.year : mesActual.year + 1,
          mesActual.month < 12 ? mesActual.month + 1 : 1,
        );
      }

      // Meses con pagos registrados
      final mesesPagados =
          pagos.map((pago) {
            return '${pago.fechaPago.year}-${pago.fechaPago.month.toString().padLeft(2, '0')}';
          }).toSet();

      // Retornar meses pendientes (diferencia entre todos los meses y los pagados)
      return mesesContrato.where((mes) => !mesesPagados.contains(mes)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error al calcular meses pendientes', e, stackTrace);
      rethrow;
    }
  }

  /// Genera reporte de pagos por período
  Future<Map<String, dynamic>> generarReportePagosPeriodo(
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      AppLogger.info(
        'Generando reporte de pagos para período: ${fechaInicio.toIso8601String()} - ${fechaFin.toIso8601String()}',
      );

      // Esta función necesitaría implementarse en el servicio
      // Aquí mostramos una versión simplificada
      throw UnimplementedError(
        'Función pendiente de implementación en el servicio',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al generar reporte de pagos', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene los pagos realizados para un contrato específico
  Future<List<PagoRenta>> obtenerPagosPorContrato(int idContrato) async {
    try {
      AppLogger.info('Obteniendo pagos para contrato: $idContrato');
      return await _service.obtenerPagosPorContrato(idContrato);
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener pagos de renta', e, stackTrace);
      rethrow;
    }
  }
}

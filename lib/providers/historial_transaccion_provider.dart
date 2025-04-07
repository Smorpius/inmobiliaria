import '../models/historial_transaccion_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/historial_transaccion_service.dart';

/// Provider para el servicio de historial de transacciones
final historialTransaccionServiceProvider =
    Provider<HistorialTransaccionService>((ref) {
      final service = HistorialTransaccionService();
      ref.onDispose(service.dispose);
      return service;
    });

/// Provider para obtener el historial de una venta específica
final historialVentaProvider =
    FutureProvider.family<List<HistorialTransaccion>, int>((
      ref,
      idVenta,
    ) async {
      final service = ref.watch(historialTransaccionServiceProvider);
      return service.obtenerHistorialVenta(idVenta);
    });

/// Provider para obtener el historial de un movimiento específico
final historialMovimientoProvider =
    FutureProvider.family<List<HistorialTransaccion>, int>((
      ref,
      idMovimiento,
    ) async {
      final service = ref.watch(historialTransaccionServiceProvider);
      return service.obtenerHistorialMovimiento(idMovimiento);
    });

/// Provider para obtener el historial de un contrato de renta específico
final historialContratoProvider =
    FutureProvider.family<List<HistorialTransaccion>, int>((
      ref,
      idContrato,
    ) async {
      final service = ref.watch(historialTransaccionServiceProvider);
      return service.obtenerHistorialContratoRenta(idContrato);
    });

/// Provider para obtener el historial filtrado por entidad, fechas, etc
final historialFiltradoProvider = FutureProvider.family<
  List<HistorialTransaccion>,
  ({
    String tipoEntidad,
    int idEntidad,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  })
>((ref, params) async {
  final service = ref.watch(historialTransaccionServiceProvider);
  return service.obtenerHistorialDeEntidad(
    tipoEntidadStr: params.tipoEntidad,
    idEntidad: params.idEntidad,
    fechaDesde: params.fechaDesde,
    fechaHasta: params.fechaHasta,
  );
});

/// Provider para obtener resumen del historial por período
final resumenHistorialProvider = FutureProvider.family<
  Map<String, dynamic>,
  ({DateTime? fechaDesde, DateTime? fechaHasta, int? idUsuario})
>((ref, params) async {
  final service = ref.watch(historialTransaccionServiceProvider);
  return service.obtenerResumenHistorial(
    fechaDesde: params.fechaDesde,
    fechaHasta: params.fechaHasta,
    idUsuario: params.idUsuario,
  );
});

/// Provider para obtener estadísticas de actividad de usuarios
final estadisticasActividadProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int?>((ref, dias) async {
      final service = ref.watch(historialTransaccionServiceProvider);
      return service.obtenerEstadisticasActividad(diasUltimos: dias);
    });

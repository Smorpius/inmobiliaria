import '../models/comprobante_venta_model.dart';
import '../services/comprobante_venta_service.dart';
import '../models/comprobante_movimiento_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/comprobante_movimiento_service.dart';

/// Provider para el servicio de comprobantes de venta
final comprobanteVentaServiceProvider = Provider<ComprobanteVentaService>((
  ref,
) {
  final service = ComprobanteVentaService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider para el servicio de comprobantes de movimientos
final comprobanteMovimientoServiceProvider =
    Provider<ComprobanteMovimientoService>((ref) {
      final service = ComprobanteMovimientoService();
      ref.onDispose(service.dispose);
      return service;
    });

/// Provider para los comprobantes de una venta específica
final comprobantesPorVentaProvider =
    FutureProvider.family<List<ComprobanteVenta>, int>((ref, idVenta) async {
      final service = ref.watch(comprobanteVentaServiceProvider);
      return service.obtenerComprobantesPorVenta(idVenta);
    });

/// Provider para los comprobantes de un movimiento específico
final comprobantesPorMovimientoProvider =
    FutureProvider.family<List<ComprobanteMovimiento>, int>((
      ref,
      idMovimiento,
    ) async {
      final service = ref.watch(comprobanteMovimientoServiceProvider);
      return service.obtenerComprobantesPorMovimiento(idMovimiento);
    });

/// Provider para obtener comprobantes detallados de un movimiento con filtro por tipo
final comprobantesDetalladosProvider = FutureProvider.family<
  List<ComprobanteMovimiento>,
  ({int idMovimiento, String? tipoComprobante})
>((ref, params) async {
  final service = ref.watch(comprobanteMovimientoServiceProvider);
  return service.obtenerComprobantesDetallados(
    params.idMovimiento,
    params.tipoComprobante,
  );
});

/// Provider para buscar comprobantes por tipo y rango de fechas
final buscarComprobantesProvider = FutureProvider.autoDispose.family<
  List<ComprobanteMovimiento>,
  ({String tipoComprobante, DateTime? fechaInicio, DateTime? fechaFin})
>((ref, params) async {
  final service = ref.watch(comprobanteMovimientoServiceProvider);
  return service.buscarComprobantes(
    tipoComprobante: params.tipoComprobante,
    fechaInicio: params.fechaInicio,
    fechaFin: params.fechaFin,
  );
});

/// Provider para obtener el cumplimiento fiscal de un inmueble
final cumplimientoFiscalProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, idInmueble) async {
      final service = ref.watch(comprobanteMovimientoServiceProvider);
      return service.obtenerCumplimientoFiscal(idInmueble);
    });

/// Provider para obtener comprobantes vencidos
final comprobantesVencidosProvider = FutureProvider.family<
  List<ComprobanteMovimiento>,
  int?
>((ref, diasAntiguedad) async {
  final service = ref.watch(comprobanteMovimientoServiceProvider);
  return service.obtenerComprobantesVencidos(diasAntiguedad: diasAntiguedad);
});

/// Provider para generar reporte de comprobantes
final reporteComprobantesProvider = FutureProvider.autoDispose.family<
  Map<String, dynamic>,
  ({DateTime fechaInicio, DateTime fechaFin, int? idInmueble})
>((ref, params) async {
  final service = ref.watch(comprobanteMovimientoServiceProvider);
  return service.generarReporteComprobantes(
    fechaInicio: params.fechaInicio,
    fechaFin: params.fechaFin,
    idInmueble: params.idInmueble,
  );
});

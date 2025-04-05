import '../models/contrato_generado_model.dart';
import '../services/contrato_generado_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para el servicio de contratos generados
final contratoGeneradoServiceProvider = Provider<ContratoGeneradoService>((
  ref,
) {
  final service = ContratoGeneradoService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider para obtener contratos generados de una venta específica
final contratosGeneradosVentaProvider =
    FutureProvider.family<List<ContratoGenerado>, int>((ref, idVenta) async {
      final service = ref.watch(contratoGeneradoServiceProvider);
      return service.obtenerContratosVenta(idVenta);
    });

/// Provider para obtener contratos generados de un contrato de renta específico
final contratosGeneradosRentaProvider =
    FutureProvider.family<List<ContratoGenerado>, int>((ref, idContrato) async {
      final service = ref.watch(contratoGeneradoServiceProvider);
      return service.obtenerContratosRenta(idContrato);
    });

/// Provider para obtener el contrato actual (última versión) de una entidad
final contratoActualProvider = FutureProvider.family<
  ContratoGenerado?,
  ({String tipoContrato, int idReferencia})
>((ref, params) async {
  final service = ref.watch(contratoGeneradoServiceProvider);
  return service.obtenerContratoActual(
    tipoContrato: params.tipoContrato,
    idReferencia: params.idReferencia,
  );
});

/// Provider para obtener datos para generar un contrato de venta
final datosContratoVentaProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, idVenta) async {
      final service = ref.watch(contratoGeneradoServiceProvider);
      return service.obtenerDatosContratoVenta(idVenta);
    });

/// Provider para obtener datos para generar un contrato de renta
final datosContratoRentaProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, idContrato) async {
      final service = ref.watch(contratoGeneradoServiceProvider);
      return service.obtenerDatosContratoRenta(idContrato);
    });

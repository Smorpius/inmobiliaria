import 'providers_global.dart';
import '../models/pago_renta_model.dart';
import '../services/pago_renta_service.dart';
import '../controllers/pago_renta_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Proveedor para el servicio de pagos de renta
final pagoRentaServiceProvider = Provider<PagoRentaService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return PagoRentaService(dbService);
});

/// Proveedor para el controlador de pagos de renta
final pagoRentaControllerProvider = Provider<PagoRentaController>((ref) {
  final service = ref.watch(pagoRentaServiceProvider);
  return PagoRentaController(service: service);
});

/// Proveedor Future para obtener pagos de un contrato específico
final pagosPorContratoProvider =
    FutureProvider.family<List<PagoRenta>, int>((ref, idContrato) async {
  final controller = ref.watch(pagoRentaControllerProvider);
  return controller.obtenerPagosPorContrato(idContrato);
});
import 'providers_global.dart';
import '../models/contrato_renta_model.dart';
import '../controllers/contrato_renta_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Proveedor para el controlador de contratos de renta
final contratoRentaControllerProvider = Provider<ContratoRentaController>((
  ref,
) {
  final dbService = ref.watch(databaseServiceProvider);
  return ContratoRentaController(dbService: dbService);
});

/// Proveedor de detalle de contrato de renta por ID
final contratoRentaDetalleProvider = FutureProvider.family<ContratoRenta, int>((
  ref,
  idContrato,
) async {
  final controller = ref.watch(contratoRentaControllerProvider);
  final contrato = await controller.obtenerContratoPorId(idContrato);
  if (contrato == null) {
    throw Exception('Contrato no encontrado');
  }
  return contrato;
});

/// Proveedor de listado de contratos
final contratosRentaProvider = FutureProvider<List<ContratoRenta>>((ref) async {
  final controller = ref.watch(contratoRentaControllerProvider);
  return controller.obtenerContratos();
});

/// Proveedor para contratos próximos a vencer
final contratosProximosVencerProvider = FutureProvider<List<ContratoRenta>>((
  ref,
) async {
  final controller = ref.watch(contratoRentaControllerProvider);
  return controller.obtenerContratosProximosAVencer();
});

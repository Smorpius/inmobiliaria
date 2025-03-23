import '../controllers/inmueble_controller.dart';
import '../models/inmueble_proveedor_servicio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers_global.dart'; // Ajusta según tu estructura

final inmuebleProveedoresProvider = FutureProvider.family<List<InmuebleProveedorServicio>, int>(
  (ref, idInmueble) async {
    final controller = ref.watch(inmuebleControllerProvider);
    return await controller.getServiciosProveedores(idInmueble);
  },
);

class InmuebleProveedoresNotifier extends StateNotifier<AsyncValue<List<InmuebleProveedorServicio>>> {
  final InmuebleController _controller;
  final int inmuebleId;

  InmuebleProveedoresNotifier(this._controller, this.inmuebleId)
      : super(const AsyncValue.loading()) {
    cargarServicios();
  }

  Future<void> cargarServicios() async {
    try {
      state = const AsyncValue.loading();
      final servicios = await _controller.getServiciosProveedores(inmuebleId);
      state = AsyncValue.data(servicios);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> asignarProveedor(InmuebleProveedorServicio servicio) async {
    try {
      await _controller.asignarProveedorAInmueble(servicio);
      await cargarServicios();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> eliminarAsignacion(int id) async {
    try {
      final result = await _controller.eliminarAsignacionProveedor(id);
      await cargarServicios();
      return result;
    } catch (e) {
      return false;
    }
  }
}

final inmuebleProveedoresNotifierProvider = StateNotifierProvider.family<
    InmuebleProveedoresNotifier,
    AsyncValue<List<InmuebleProveedorServicio>>,
    int>((ref, inmuebleId) {
  final controller = ref.watch(inmuebleControllerProvider);
  return InmuebleProveedoresNotifier(controller, inmuebleId);
});
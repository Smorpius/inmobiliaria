import '../../../models/inmueble_model.dart';
import '../../../providers/providers_global.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier para manejar el estado de los detalles de un inmueble
class InmuebleDetalleNotifier extends StateNotifier<AsyncValue<Inmueble>> {
  final Ref _ref;
  final int inmuebleId;

  InmuebleDetalleNotifier(this._ref, this.inmuebleId)
    : super(const AsyncValue.loading()) {
    cargarInmueble();
  }

  /// Carga los datos del inmueble desde el controlador
  Future<void> cargarInmueble() async {
    try {
      state = const AsyncValue.loading();
      final inmuebleController = _ref.read(inmuebleControllerProvider);
      final inmuebles = await inmuebleController.getInmuebles();

      final inmueble = inmuebles.firstWhere(
        (inmueble) => inmueble.id == inmuebleId,
        orElse: () => throw Exception('Inmueble no encontrado'),
      );

      state = AsyncValue.data(inmueble);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Actualiza el estado del inmueble (Disponible, Vendido, Rentado, etc)
  Future<void> actualizarEstado(int nuevoEstado) async {
    try {
      final inmuebleController = _ref.read(inmuebleControllerProvider);

      if (state is AsyncData<Inmueble>) {
        final inmuebleActual = (state as AsyncData<Inmueble>).value;
        final inmuebleActualizado = Inmueble(
          id: inmuebleActual.id,
          nombre: inmuebleActual.nombre,
          idDireccion: inmuebleActual.idDireccion,
          montoTotal: inmuebleActual.montoTotal,
          idEstado: nuevoEstado,
          idCliente: inmuebleActual.idCliente,
          idEmpleado: inmuebleActual.idEmpleado,
          tipoInmueble: inmuebleActual.tipoInmueble,
          tipoOperacion: inmuebleActual.tipoOperacion,
          precioVenta: inmuebleActual.precioVenta,
          precioRenta: inmuebleActual.precioRenta,
          caracteristicas: inmuebleActual.caracteristicas,
          calle: inmuebleActual.calle,
          numero: inmuebleActual.numero,
          colonia: inmuebleActual.colonia,
          ciudad: inmuebleActual.ciudad,
          estadoGeografico: inmuebleActual.estadoGeografico,
          codigoPostal: inmuebleActual.codigoPostal,
          referencias: inmuebleActual.referencias,
          fechaRegistro: inmuebleActual.fechaRegistro,
        );

        await inmuebleController.updateInmueble(inmuebleActualizado);
        state = AsyncValue.data(inmuebleActualizado);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Recarga los datos del inmueble
  Future<void> refrescarInmueble() async {
    await cargarInmueble();
  }
}

/// Provider para acceder a los detalles de un inmueble por su ID
final inmuebleDetalleProvider = StateNotifierProvider.family<
  InmuebleDetalleNotifier,
  AsyncValue<Inmueble>,
  int
>((ref, inmuebleId) => InmuebleDetalleNotifier(ref, inmuebleId));

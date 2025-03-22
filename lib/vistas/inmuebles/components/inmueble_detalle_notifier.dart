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
    // Guardar el estado actual en caso de error para poder revertir
    final estadoAnterior = state;

    try {
      // Actualización optimista: actualizar la interfaz antes de esperar la BD
      if (state is AsyncData<Inmueble>) {
        final inmuebleActual = (state as AsyncData<Inmueble>).value;
        final inmuebleActualizado = Inmueble(
          id: inmuebleActual.id,
          nombre: inmuebleActual.nombre,
          idDireccion: inmuebleActual.idDireccion,
          montoTotal: inmuebleActual.montoTotal,
          idEstado: nuevoEstado, // Actualizar el estado
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
          // No olvidar incluir el resto de propiedades que pudieran existir
          costoCliente: inmuebleActual.costoCliente,
          costoServicios: inmuebleActual.costoServicios,
        );

        // Actualizar la UI inmediatamente
        state = AsyncValue.data(inmuebleActualizado);

        // Luego actualizar en la base de datos
        final inmuebleController = _ref.read(inmuebleControllerProvider);
        await inmuebleController.updateInmueble(inmuebleActualizado);

        // Opcional: recargar después para asegurar consistencia
        await cargarInmueble();
      }
    } catch (e, stack) {
      // En caso de error, restaurar el estado anterior y propagar el error
      state = estadoAnterior;
      // Actualizar estado para mostrar el error
      state = AsyncValue.error(e, stack);
      // Re-lanzar el error para manejarlo en la UI
      rethrow;
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

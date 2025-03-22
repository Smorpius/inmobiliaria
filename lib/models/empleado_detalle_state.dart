import '../models/empleado.dart';
import '../providers/empleado_providers.dart';
import '../controllers/empleado_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmpleadoDetalleState {
  final bool isLoading;
  final Empleado? empleado;
  final String? errorMessage;

  EmpleadoDetalleState({
    this.isLoading = false,
    this.empleado,
    this.errorMessage,
  });

  EmpleadoDetalleState copyWith({
    bool? isLoading,
    Empleado? empleado,
    String? errorMessage,
  }) {
    return EmpleadoDetalleState(
      isLoading: isLoading ?? this.isLoading,
      empleado: empleado ?? this.empleado,
      errorMessage: errorMessage,
    );
  }
}

class EmpleadoDetalleNotifier extends StateNotifier<EmpleadoDetalleState> {
  final EmpleadoController _controller;
  final int empleadoId;

  EmpleadoDetalleNotifier(this._controller, this.empleadoId)
    : super(EmpleadoDetalleState(isLoading: true)) {
    cargarEmpleado();
  }

  Future<void> cargarEmpleado() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final usuarioEmpleado = await _controller.obtenerEmpleado(empleadoId);

      if (usuarioEmpleado != null) {
        state = state.copyWith(
          empleado: usuarioEmpleado.empleado,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No se encontró el empleado solicitado',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar empleado: $e',
      );
    }
  }
}

// Provider para el detalle de un empleado específico
final empleadoDetalleProvider = StateNotifierProvider.family<
  EmpleadoDetalleNotifier,
  EmpleadoDetalleState,
  int
>((ref, empleadoId) {
  final controller = ref.watch(empleadoControllerProvider);
  return EmpleadoDetalleNotifier(controller, empleadoId);
});

import '../models/empleado.dart';
import '../providers/empleado_providers.dart';
import '../controllers/empleado_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmpleadosState {
  final List<Empleado> empleados;
  final bool isLoading;
  final String? errorMessage;
  final bool mostrarInactivos;
  final String terminoBusqueda;

  EmpleadosState({
    required this.empleados,
    required this.isLoading,
    this.errorMessage,
    required this.mostrarInactivos,
    required this.terminoBusqueda,
  });

  // Constructor para estado inicial
  factory EmpleadosState.initial() => EmpleadosState(
    empleados: [],
    isLoading: true,
    mostrarInactivos: false,
    terminoBusqueda: '',
  );

  // Método para crear copia con cambios
  EmpleadosState copyWith({
    List<Empleado>? empleados,
    bool? isLoading,
    String? errorMessage,
    bool? mostrarInactivos,
    String? terminoBusqueda,
  }) {
    return EmpleadosState(
      empleados: empleados ?? this.empleados,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      mostrarInactivos: mostrarInactivos ?? this.mostrarInactivos,
      terminoBusqueda: terminoBusqueda ?? this.terminoBusqueda,
    );
  }

  // Filtrar empleados según término de búsqueda
  List<Empleado> get empleadosFiltrados {
    if (terminoBusqueda.isEmpty) return empleados;

    final termino = terminoBusqueda.toLowerCase();
    return empleados.where((empleado) {
      final nombre =
          '${empleado.nombre} ${empleado.apellidoPaterno}'.toLowerCase();
      return nombre.contains(termino);
    }).toList();
  }
}

// Notifier para gestionar el estado
class EmpleadosNotifier extends StateNotifier<EmpleadosState> {
  final EmpleadoController _controller;

  EmpleadosNotifier(this._controller) : super(EmpleadosState.initial()) {
    cargarEmpleados();
  }

  Future<void> cargarEmpleados() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final empleados = await _controller.obtenerEmpleados();
      state = state.copyWith(empleados: empleados, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar empleados: $e',
      );
    }
  }

  void actualizarBusqueda(String termino) {
    state = state.copyWith(terminoBusqueda: termino);
  }

  void cambiarFiltroInactivos(bool mostrarInactivos) {
    state = state.copyWith(mostrarInactivos: mostrarInactivos);
  }
}

// Provider para acceder al estado de empleados
final empleadosStateProvider =
    StateNotifierProvider<EmpleadosNotifier, EmpleadosState>((ref) {
      final controller = ref.watch(empleadoControllerProvider);
      return EmpleadosNotifier(controller);
    });

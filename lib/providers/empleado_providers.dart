import 'providers_global.dart';
import '../models/empleado.dart';
import '../controllers/empleado_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para el controlador de empleados
final empleadoControllerProvider = Provider<EmpleadoController>((ref) {
  final usuarioEmpleadoService = ref.watch(usuarioEmpleadoServiceProvider);
  final usuarioService = ref.watch(usuarioServiceProvider);
  return EmpleadoController(usuarioEmpleadoService, usuarioService);
});

// Provider para la inicialización del controlador de empleados
final empleadoInitProvider = FutureProvider<bool>((ref) async {
  final controller = ref.watch(empleadoControllerProvider);
  await controller.inicializar();
  return true;
});

// Provider para la lista de empleados
final empleadosProvider = FutureProvider<List<Empleado>>((ref) async {
  // Esperar a que el controlador esté inicializado antes de obtener los empleados
  await ref.watch(empleadoInitProvider.future);
  final controller = ref.watch(empleadoControllerProvider);
  return controller.obtenerEmpleados();
});

// Provider para controlar si mostrar empleados inactivos
final mostrarEmpleadosInactivosProvider = StateProvider<bool>((ref) => false);

// Provider para empleados filtrados
final empleadosFiltradosProvider = Provider<List<Empleado>>((ref) {
  final empleadosAsyncValue = ref.watch(empleadosProvider);
  final mostrarInactivos = ref.watch(mostrarEmpleadosInactivosProvider);

  return empleadosAsyncValue.when(
    data: (empleados) {
      if (mostrarInactivos) {
        return empleados.where((e) => e.idEstado != 1).toList();
      } else {
        return empleados.where((e) => e.idEstado == 1).toList();
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

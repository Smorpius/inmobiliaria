import 'providers_global.dart';
import '../models/empleado.dart';
import '../utils/applogger.dart';
import '../models/usuario_empleado.dart';
import '../controllers/empleado_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para el controlador de empleados
/// Inyecta las dependencias necesarias desde providers_global
final empleadoControllerProvider = Provider<EmpleadoController>((ref) {
  final usuarioEmpleadoService = ref.watch(usuarioEmpleadoServiceProvider);
  final usuarioService = ref.watch(usuarioServiceProvider);
  return EmpleadoController(usuarioEmpleadoService, usuarioService);
});

/// Provider para la inicialización del controlador de empleados
/// Incluye manejo de errores mejorado
final empleadoInitProvider = FutureProvider<bool>((ref) async {
  try {
    final controller = ref.read(empleadoControllerProvider);
    await controller.inicializar();
    AppLogger.info('Controlador de empleados inicializado exitosamente');
    return true;
  } catch (e, stackTrace) {
    AppLogger.error(
      'Error al inicializar controlador de empleados',
      e,
      stackTrace,
    );
    return false;
  }
});

/// Provider para la lista de empleados con manejo de errores mejorado
final empleadosProvider = FutureProvider<List<Empleado>>((ref) async {
  // Esperar a que el controlador esté inicializado antes de obtener los empleados
  final inicializado = await ref.watch(empleadoInitProvider.future);

  if (!inicializado) {
    AppLogger.warning(
      'No se pudo cargar empleados porque el controlador no está inicializado',
    );
    return [];
  }

  try {
    final controller = ref.read(empleadoControllerProvider);
    final empleados = await controller.obtenerEmpleados();
    AppLogger.info('Empleados cargados: ${empleados.length}');
    return empleados;
  } catch (e, stackTrace) {
    AppLogger.error('Error al cargar lista de empleados', e, stackTrace);
    rethrow; // Re-lanzamos para que Riverpod pueda manejar el estado de error
  }
});

/// Provider para controlar si mostrar empleados inactivos
final mostrarEmpleadosInactivosProvider = StateProvider<bool>((ref) => false);

/// Provider para empleados filtrados con mejor manejo de errores
final empleadosFiltradosProvider = Provider<List<Empleado>>((ref) {
  final empleadosAsyncValue = ref.watch(empleadosProvider);
  final mostrarInactivos = ref.watch(mostrarEmpleadosInactivosProvider);

  return empleadosAsyncValue.when(
    data: (empleados) {
      try {
        // Aplicar filtro basado en el estado (1 = activo)
        if (mostrarInactivos) {
          return empleados.where((e) => e.idEstado != 1).toList();
        } else {
          return empleados.where((e) => e.idEstado == 1).toList();
        }
      } catch (e) {
        // Evitar errores silenciosos en el filtrado
        AppLogger.error('Error al filtrar empleados', e, StackTrace.current);
        return [];
      }
    },
    loading: () => [],
    error: (error, stackTrace) {
      // Registrar el error pero devolver una lista vacía para evitar fallos en la UI
      AppLogger.error('Error en empleadosProvider', error, stackTrace);
      return [];
    },
  );
});

/// Provider para un empleado específico por ID con manejo de errores
final empleadoDetalleProvider = FutureProvider.family<UsuarioEmpleado?, int>((
  ref,
  id,
) async {
  try {
    final controller = ref.read(empleadoControllerProvider);
    return await controller.obtenerEmpleado(id);
  } catch (e, stackTrace) {
    AppLogger.error(
      'Error al obtener detalles del empleado ID: $id',
      e,
      stackTrace,
    );
    return null;
  }
});

/// Provider para verificar existencia de nombre de usuario
final nombreUsuarioExisteProvider = FutureProvider.family<bool, String>((
  ref,
  nombreUsuario,
) async {
  if (nombreUsuario.isEmpty) return false;

  try {
    final controller = ref.read(empleadoControllerProvider);
    return await controller.existeNombreUsuario(nombreUsuario);
  } catch (e, stackTrace) {
    AppLogger.error('Error al verificar nombre de usuario', e, stackTrace);
    return false;
  }
});

/// Provider para verificar nombre de usuario excluyendo ID actual
final nombreUsuarioExisteExcluyendoProvider =
    FutureProvider.family<bool, (String, int)>((ref, params) async {
      final (nombreUsuario, idUsuario) = params;
      if (nombreUsuario.isEmpty) return false;

      try {
        final controller = ref.read(empleadoControllerProvider);
        return await controller.existeNombreUsuario(
          nombreUsuario,
          idUsuarioActual: idUsuario,
        );
      } catch (e, stackTrace) {
        AppLogger.error(
          'Error al verificar nombre de usuario excluyendo ID: $idUsuario',
          e,
          stackTrace,
        );
        return false;
      }
    });

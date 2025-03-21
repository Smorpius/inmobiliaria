import 'dart:developer' as developer;
import '../models/cliente_model.dart';
import '../models/inmueble_model.dart';
import '../services/mysql_helper.dart';
import '../services/auth_service.dart';
import '../models/inmueble_imagen.dart';
import '../services/image_service.dart';
import '../services/usuario_service.dart';
import '../controllers/cliente_controller.dart';
import '../controllers/usuario_controller.dart';
import '../controllers/inmueble_controller.dart';
import '../controllers/empleado_controller.dart';
import '../services/usuario_empleado_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/usuario_empleado_controller.dart';

// MARK: - Providers de Servicios Base con inicialización segura

/// Provider para inicializar la base de datos de forma asíncrona
final databaseInitProvider = FutureProvider<DatabaseService>((ref) async {
  try {
    developer.log('Inicializando servicio de base de datos...');
    final dbService = DatabaseService();
    // Esperar explícitamente a la conexión
    await dbService.connection;
    developer.log('Servicio de base de datos inicializado correctamente');
    return dbService;
  } catch (e) {
    developer.log('Error al inicializar base de datos: $e', error: e);
    rethrow;
  }
});

/// Provider para acceder a la base de datos ya inicializada
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final dbState = ref.watch(databaseInitProvider);
  return dbState.when(
    data: (db) => db,
    loading: () => throw StateError('Base de datos aún no inicializada'),
    error: (e, stack) => throw StateError('Error en la conexión: $e'),
  );
});

/// Provider para inicializar el servicio de imágenes de forma asíncrona
final imageInitProvider = FutureProvider<ImageService>((ref) async {
  try {
    developer.log('Inicializando servicio de imágenes...');
    final imageService = ImageService();
    imageService.scheduleCacheCleanup();
    developer.log('Servicio de imágenes inicializado correctamente');
    return imageService;
  } catch (e) {
    developer.log('Error al inicializar servicio de imágenes: $e', error: e);
    rethrow;
  }
});

/// Provider para acceder al servicio de imágenes ya inicializado
final imageServiceProvider = Provider<ImageService>((ref) {
  final imageState = ref.watch(imageInitProvider);
  return imageState.when(
    data: (service) => service,
    loading: () => throw StateError('Servicio de imágenes aún no inicializado'),
    error: (e, stack) => throw StateError('Error en servicio de imágenes: $e'),
  );
});

// MARK: - Provider para la aplicación inicializada
/// Provider que agrupa todas las inicializaciones para facilitar la gestión
final appInitializationProvider = FutureProvider<bool>((ref) async {
  // Esperar a que todos los servicios críticos estén inicializados
  await ref.watch(databaseInitProvider.future);
  await ref.watch(imageInitProvider.future);

  // Inicializar el controlador de empleados
  final usuarioEmpleadoController = ref.read(usuarioEmpleadoControllerProvider);
  await usuarioEmpleadoController.inicializar();

  return true;
});

// MARK: - Providers de Servicios

/// Provider para el servicio de usuarios
final usuarioServiceProvider = Provider<UsuarioService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return UsuarioService(dbService);
});

/// Provider para el servicio de empleados
final usuarioEmpleadoServiceProvider = Provider<UsuarioEmpleadoService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return UsuarioEmpleadoService(dbService);
});

// MARK: - Providers de Controladores

/// Provider para el controlador de usuarios
final usuarioControllerProvider = Provider<UsuarioController>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return UsuarioController(dbService: dbService);
});

/// Provider para el servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) {
  final usuarioController = ref.watch(usuarioControllerProvider);
  return AuthService(usuarioController);
});

/// Provider para el controlador de empleados-usuarios
final usuarioEmpleadoControllerProvider = Provider<UsuarioEmpleadoController>((
  ref,
) {
  final service = ref.watch(usuarioEmpleadoServiceProvider);
  final controller = UsuarioEmpleadoController(service);

  // Gestión del ciclo de vida
  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

/// Provider para el controlador de empleados
final empleadoControllerProvider = Provider<EmpleadoController>((ref) {
  final usuarioEmpleadoService = ref.watch(usuarioEmpleadoServiceProvider);
  final usuarioService = ref.watch(usuarioServiceProvider);
  return EmpleadoController(usuarioEmpleadoService, usuarioService);
});

/// Provider para el controlador de clientes
final clienteControllerProvider = Provider<ClienteController>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ClienteController(dbService: dbService);
});

/// Provider para el controlador de inmuebles
final inmuebleControllerProvider = Provider<InmuebleController>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return InmuebleController(dbService: dbService);
});

// MARK: - Providers de Estado UI

/// Provider para controlar si se muestran inmuebles inactivos
final mostrarInactivosProvider = StateProvider<bool>((ref) => false);

// MARK: - Providers para imágenes de inmuebles

/// Notifier para gestionar imágenes principales de inmuebles
class ImagenesPrincipalesNotifier
    extends StateNotifier<Map<int, InmuebleImagen?>> {
  final Ref ref;

  ImagenesPrincipalesNotifier(this.ref) : super({});

  /// Carga las imágenes principales para una lista de inmuebles
  Future<void> cargarImagenesPrincipales(List<Inmueble> inmuebles) async {
    try {
      final inmuebleController = ref.read(inmuebleControllerProvider);
      final Map<int, InmuebleImagen?> imagenes = {};

      for (var inmueble in inmuebles) {
        if (inmueble.id != null) {
          imagenes[inmueble.id!] = await inmuebleController.getImagenPrincipal(
            inmueble.id!,
          );
        }
      }

      state = imagenes;
    } catch (e) {
      developer.log('Error al cargar imágenes principales: $e', error: e);
      // Mantener el estado anterior en caso de error
    }
  }

  /// Actualiza una imagen específica como principal
  void actualizarImagenPrincipal(int idInmueble, InmuebleImagen? imagen) {
    state = {...state, idInmueble: imagen};
  }
}

/// Notifier para gestionar rutas de imágenes
class RutasImagenesNotifier extends StateNotifier<Map<int, String?>> {
  final Ref ref;

  RutasImagenesNotifier(this.ref) : super({});

  /// Carga las rutas completas para las imágenes
  Future<void> cargarRutasImagenes(Map<int, InmuebleImagen?> imagenes) async {
    try {
      final imageService = ref.read(imageServiceProvider);
      final Map<int, String?> rutas = {};

      for (var entry in imagenes.entries) {
        if (entry.value != null) {
          rutas[entry.key] = await imageService.obtenerRutaCompletaImagen(
            entry.value!.rutaImagen,
          );
        }
      }

      state = rutas;
    } catch (e) {
      developer.log('Error al cargar rutas de imágenes: $e', error: e);
      // Mantener el estado anterior en caso de error
    }
  }

  /// Actualiza la ruta para una imagen específica
  void actualizarRutaImagen(int idInmueble, String? ruta) {
    state = {...state, idInmueble: ruta};
  }
}

/// Provider para las imágenes principales de inmuebles
final imagenesPrincipalesProvider = StateNotifierProvider<
  ImagenesPrincipalesNotifier,
  Map<int, InmuebleImagen?>
>((ref) {
  return ImagenesPrincipalesNotifier(ref);
});

/// Provider para las rutas de imágenes principales
final rutasImagenesPrincipalesProvider =
    StateNotifierProvider<RutasImagenesNotifier, Map<int, String?>>((ref) {
      return RutasImagenesNotifier(ref);
    });

// MARK: - Providers para manejo de errores globales

/// Clase para manejar errores globales de la aplicación
class ErrorGlobalNotifier extends StateNotifier<String?> {
  ErrorGlobalNotifier() : super(null);

  /// Establece un mensaje de error global
  void setError(String mensaje) {
    state = mensaje;
    // Auto-limpieza después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (state == mensaje) {
        state = null;
      }
    });
  }

  /// Limpia el error actual
  void clearError() {
    state = null;
  }
}

/// Provider para el manejo de errores globales
final errorGlobalProvider = StateNotifierProvider<ErrorGlobalNotifier, String?>(
  (ref) {
    return ErrorGlobalNotifier();
  },
);

// MARK: - Providers con autoDispose

/// Provider con autoDispose para cliente por ID
final clientePorIdProvider = FutureProvider.autoDispose.family<Cliente?, int>((
  ref,
  id,
) async {
  try {
    final controller = ref.watch(clienteControllerProvider);

    // Primero buscamos entre los clientes activos
    final clientes = await controller.getClientes();
    try {
      return clientes.firstWhere((c) => c.id == id);
    } catch (_) {
      // Si no encontramos, buscamos entre los inactivos
      final inactivos = await controller.getClientesInactivos();
      try {
        return inactivos.firstWhere((c) => c.id == id);
      } catch (_) {
        // Si no se encuentra, devolvemos null
        return null;
      }
    }
  } catch (e) {
    developer.log('Error al buscar cliente por ID: $e', error: e);
    rethrow;
  }
});

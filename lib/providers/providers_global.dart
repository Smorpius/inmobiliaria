import '../utils/applogger.dart';
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
import 'package:inmobiliaria/services/socket_error_handler.dart';

// MARK: - Providers de Servicios Base con inicialización segura

/// Provider para inicializar la base de datos de forma asíncrona
final databaseInitProvider = FutureProvider<DatabaseService>((ref) async {
  try {
    AppLogger.info('Inicializando servicio de base de datos...');
    final dbService = DatabaseService();

    // Esperar explícitamente a la primera conexión para validar
    await dbService.connection;

    // Inicializar monitoreo periódico de salud
    dbService.iniciarHealthCheckPeriodico();

    AppLogger.info('Servicio de base de datos inicializado correctamente');
    return dbService;
  } catch (e, stack) {
    AppLogger.error('Error al inicializar base de datos', e, stack);
    rethrow;
  }
});

/// Provider para acceder a la base de datos ya inicializada
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final dbState = ref.watch(databaseInitProvider);
  final db = dbState.when(
    data: (db) => db,
    loading: () => throw StateError('Base de datos aún no inicializada'),
    error: (e, stack) => throw StateError('Error en la conexión: $e'),
  );

  // Asegurar liberación de recursos al finalizar
  ref.onDispose(() {
    // No cerramos toda la base de datos pero sí liberamos las conexiones específicas
    // que puedan haber sido usadas por este provider
    db.releaseUnusedConnections();
  });

  return db;
});

// Provider para el manejador de errores de socket
final socketErrorHandlerProvider = Provider<SocketErrorHandler>((ref) {
  return SocketErrorHandler();
});

/// Provider para inicializar el servicio de imágenes de forma asíncrona
final imageInitProvider = FutureProvider<ImageService>((ref) async {
  try {
    AppLogger.info('Inicializando servicio de imágenes...');
    final imageService = ImageService();
    imageService.scheduleCacheCleanup();
    AppLogger.info('Servicio de imágenes inicializado correctamente');
    return imageService;
  } catch (e, stack) {
    AppLogger.error('Error al inicializar servicio de imágenes', e, stack);
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
  try {
    // Esperar a que todos los servicios críticos estén inicializados
    await ref.watch(databaseInitProvider.future);
    await ref.watch(imageInitProvider.future);

    // Inicializar el controlador de empleados
    final usuarioEmpleadoController = ref.read(
      usuarioEmpleadoControllerProvider,
    );
    await usuarioEmpleadoController.inicializar();

    return true;
  } catch (e, stack) {
    AppLogger.error('Error durante inicialización de la aplicación', e, stack);
    rethrow;
  }
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
  bool _procesandoOperacion =
      false; // Control para evitar operaciones duplicadas
  bool _procesandoError = false; // Control para evitar logs duplicados

  ImagenesPrincipalesNotifier(this.ref) : super({});

  /// Carga las imágenes principales para una lista de inmuebles
  Future<void> cargarImagenesPrincipales(List<Inmueble> inmuebles) async {
    // Evitar operaciones duplicadas concurrentes
    if (_procesandoOperacion) {
      AppLogger.info(
        'Carga de imágenes principales ya en progreso, operación ignorada',
      );
      return;
    }

    _procesandoOperacion = true;

    try {
      final inmuebleController = ref.read(inmuebleControllerProvider);
      final Map<int, InmuebleImagen?> imagenes = {};

      // Procesar en lotes pequeños para evitar congelamiento
      final batchSize = 8;
      for (var i = 0; i < inmuebles.length; i += batchSize) {
        final end =
            (i + batchSize < inmuebles.length)
                ? i + batchSize
                : inmuebles.length;
        final batch = inmuebles.sublist(i, end);

        // Procesar de forma paralela los lotes
        final futures = <Future<void>>[];
        for (var inmueble in batch) {
          if (inmueble.id != null) {
            futures.add(() async {
              try {
                imagenes[inmueble.id!] = await inmuebleController
                    .getImagenPrincipal(inmueble.id!);
              } catch (e) {
                // Manejo de error individual, sin afectar todo el lote
                if (!_procesandoError) {
                  _procesandoError = true;
                  AppLogger.warning(
                    'Error al cargar imagen principal para inmueble ID: ${inmueble.id}',
                  );
                  _procesandoError = false;
                }
              }
            }());
          }
        }

        await Future.wait(futures);

        // Permitir que la UI responda brevemente entre lotes
        await Future.delayed(const Duration(milliseconds: 5));
      }

      state = imagenes;
      AppLogger.info('Cargadas ${imagenes.length} imágenes principales');
    } catch (e, stack) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al cargar imágenes principales', e, stack);
        _procesandoError = false;
      }
      // Mantener el estado anterior en caso de error
    } finally {
      _procesandoOperacion = false;
    }
  }

  /// Actualiza una imagen específica como principal
  void actualizarImagenPrincipal(int idInmueble, InmuebleImagen? imagen) {
    if (state.containsKey(idInmueble) || imagen != null) {
      state = {...state, idInmueble: imagen};
    }
  }
}

/// Notifier para gestionar rutas de imágenes
class RutasImagenesNotifier extends StateNotifier<Map<int, String?>> {
  final Ref ref;
  bool _procesandoOperacion =
      false; // Control para evitar operaciones duplicadas
  bool _procesandoError = false; // Control para evitar logs duplicados

  RutasImagenesNotifier(this.ref) : super({});

  /// Carga las rutas completas para las imágenes
  Future<void> cargarRutasImagenes(Map<int, InmuebleImagen?> imagenes) async {
    // Evitar operaciones duplicadas concurrentes
    if (_procesandoOperacion) {
      AppLogger.info(
        'Carga de rutas de imágenes ya en progreso, operación ignorada',
      );
      return;
    }

    _procesandoOperacion = true;

    try {
      final imageService = ref.read(imageServiceProvider);
      final Map<int, String?> rutas = {};

      // Procesar en lotes pequeños para evitar congelamiento
      final entries = imagenes.entries.toList();
      final batchSize = 10;

      for (var i = 0; i < entries.length; i += batchSize) {
        final end =
            (i + batchSize < entries.length) ? i + batchSize : entries.length;
        final batch = entries.sublist(i, end);

        final futures = <Future<void>>[];
        for (var entry in batch) {
          if (entry.value != null) {
            futures.add(() async {
              try {
                rutas[entry.key] = await imageService.obtenerRutaCompletaImagen(
                  entry.value!.rutaImagen,
                );
              } catch (e) {
                if (!_procesandoError) {
                  _procesandoError = true;
                  AppLogger.warning(
                    'Error al cargar ruta para imagen del inmueble ID: ${entry.key}',
                  );
                  _procesandoError = false;
                }
              }
            }());
          }
        }

        await Future.wait(futures);

        // Permitir que la UI responda brevemente entre lotes
        await Future.delayed(const Duration(milliseconds: 5));
      }

      state = rutas;
      AppLogger.info('Cargadas ${rutas.length} rutas de imágenes');
    } catch (e, stack) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al cargar rutas de imágenes', e, stack);
        _procesandoError = false;
      }
      // Mantener el estado anterior en caso de error
    } finally {
      _procesandoOperacion = false;
    }
  }

  /// Actualiza la ruta para una imagen específica
  void actualizarRutaImagen(int idInmueble, String? ruta) {
    if (state.containsKey(idInmueble) || ruta != null) {
      state = {...state, idInmueble: ruta};
    }
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
  DateTime? _ultimoError; // Control para evitar errores repetitivos

  /// Establece un mensaje de error global con control anti-spam
  void setError(String mensaje) {
    final ahora = DateTime.now();

    // Prevenir mensajes duplicados en un corto período de tiempo
    if (_ultimoError != null &&
        ahora.difference(_ultimoError!) < const Duration(seconds: 3)) {
      if (state == mensaje) {
        return; // Mismo error reciente, ignorar
      }
    }

    _ultimoError = ahora;
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
/// Usa procedimientos almacenados a través de los controladores
final clientePorIdProvider = FutureProvider.autoDispose.family<Cliente?, int>((
  ref,
  id,
) async {
  try {
    // Usar el método específico para obtener cliente por ID implementado con procedimiento almacenado
    final controller = ref.watch(clienteControllerProvider);
    final cliente = await controller.getClientePorId(id);

    if (cliente != null) {
      return cliente;
    }

    // Si no encuentra, devuelve null - no es necesario buscar en todos los clientes
    return null;
  } catch (e, stack) {
    AppLogger.error('Error al buscar cliente por ID: $id', e, stack);
    return null; // Devolver null en lugar de propagar el error para mejor UX
  }
});

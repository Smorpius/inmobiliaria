import '../utils/applogger.dart';
import '../models/inmueble_model.dart';
import '../models/inmueble_imagen.dart';
import '../services/image_service.dart';
import '../controllers/inmueble_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers_global.dart'; // Importar los providers globales

// Provider para controlar el orden por margen de utilidad
final ordenarPorMargenProvider = StateProvider<bool>((ref) => false);

// Provider para el controlador de inmuebles con manejo apropiado del dbService
final inmuebleControllerProvider = Provider<InmuebleController>((ref) {
  try {
    final dbService = ref.watch(databaseServiceProvider);
    return InmuebleController(dbService: dbService);
  } catch (e, stackTrace) {
    AppLogger.error('Error al inicializar InmuebleController', e, stackTrace);
    rethrow;
  }
});

// Provider para la lista de inmuebles con manejo de errores
final inmueblesProvider = FutureProvider<List<Inmueble>>((ref) async {
  try {
    final controller = ref.watch(inmuebleControllerProvider);
    AppLogger.info('Solicitando lista de inmuebles desde inmueblesProvider');
    return await controller.getInmuebles();
  } catch (e, stackTrace) {
    AppLogger.error('Error al obtener lista de inmuebles', e, stackTrace);
    return []; // Devuelve lista vacía en caso de error para evitar nulos
  }
});

// Provider para controlar si mostrar inmuebles inactivos
final mostrarInactivosProvider = StateProvider<bool>((ref) => false);

// Provider para inmuebles filtrados (activos o inactivos)
final inmueblesFiltradosProvider = Provider<List<Inmueble>>((ref) {
  final inmueblesAsyncValue = ref.watch(inmueblesProvider);
  final mostrarInactivos = ref.watch(mostrarInactivosProvider);

  return inmueblesAsyncValue.when(
    data: (inmuebles) {
      if (mostrarInactivos) {
        return inmuebles.where((inmueble) => inmueble.idEstado == 2).toList();
      } else {
        return inmuebles.where((inmueble) => inmueble.idEstado != 2).toList();
      }
    },
    loading: () => [],
    error: (error, stackTrace) {
      AppLogger.error('Error en inmueblesFiltradosProvider', error, stackTrace);
      return [];
    },
  );
});

// Provider para imágenes principales de inmuebles
final imagenesPrincipalesProvider = StateNotifierProvider<
  ImagenesPrincipalesNotifier,
  Map<int, InmuebleImagen?>
>((ref) {
  final inmuebleController = ref.watch(inmuebleControllerProvider);
  return ImagenesPrincipalesNotifier(inmuebleController);
});

// Notifier para manejar las imágenes principales
class ImagenesPrincipalesNotifier
    extends StateNotifier<Map<int, InmuebleImagen?>> {
  final InmuebleController _inmuebleController;
  bool _procesandoOperacion = false;
  bool _procesandoError = false;

  ImagenesPrincipalesNotifier(this._inmuebleController) : super({});

  Future<void> cargarImagenesPrincipales(List<Inmueble> inmuebles) async {
    // Prevenir operaciones concurrentes
    if (_procesandoOperacion) return;
    _procesandoOperacion = true;

    try {
      final Map<int, InmuebleImagen?> nuevasImagenes = {};
      final List<Future<void>> futures = [];

      // Limitar la cantidad de operaciones asíncronas concurrentes
      final inmueblesBatch =
          inmuebles.take(20).toList(); // Procesar en lotes de 20

      for (var inmueble in inmueblesBatch) {
        if (inmueble.id != null) {
          futures.add(_cargarImagenPrincipal(inmueble.id!, nuevasImagenes));
        }
      }

      await Future.wait(futures);

      // Solo actualizar el estado si hay cambios para evitar re-renders innecesarios
      if (nuevasImagenes.isNotEmpty && mounted) {
        state = {...state, ...nuevasImagenes};
      }
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al cargar imágenes principales', e, stackTrace);
        _procesandoError = false;
      }
    } finally {
      _procesandoOperacion = false;
    }
  }

  Future<void> _cargarImagenPrincipal(
    int idInmueble,
    Map<int, InmuebleImagen?> imagenes,
  ) async {
    try {
      final imagen = await _inmuebleController.getImagenPrincipal(idInmueble);
      imagenes[idInmueble] = imagen;
    } catch (e) {
      // Error individual no detiene toda la operación
      AppLogger.warning(
        'Error al cargar imagen principal para inmueble $idInmueble: $e',
      );
      imagenes[idInmueble] = null;
    }
  }
}

// Provider para rutas de imágenes
final rutasImagenesPrincipalesProvider =
    StateNotifierProvider<RutasImagenesNotifier, Map<int, String?>>((ref) {
      final imageService = ref.watch(imageServiceProvider);
      return RutasImagenesNotifier(imageService);
    });

// Notifier para manejar las rutas de imágenes
class RutasImagenesNotifier extends StateNotifier<Map<int, String?>> {
  final ImageService _imageService;
  bool _procesandoOperacion = false;
  bool _procesandoError = false;

  RutasImagenesNotifier(this._imageService) : super({});

  Future<void> cargarRutasImagenes(Map<int, InmuebleImagen?> imagenes) async {
    // Prevenir operaciones concurrentes
    if (_procesandoOperacion) return;
    _procesandoOperacion = true;

    try {
      final Map<int, String?> nuevasRutas = {};
      final List<Future<void>> futures = [];

      // Limitar la cantidad de operaciones asíncronas concurrentes
      final entries = imagenes.entries.take(20).toList(); // Procesar en lotes

      for (var entry in entries) {
        if (entry.value != null) {
          futures.add(_cargarRutaImagen(entry.key, entry.value!, nuevasRutas));
        }
      }

      await Future.wait(futures);

      // Solo actualizar el estado si hay cambios para evitar re-renders innecesarios
      if (nuevasRutas.isNotEmpty && mounted) {
        state = {...state, ...nuevasRutas};
      }
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al cargar rutas de imágenes', e, stackTrace);
        _procesandoError = false;
      }
    } finally {
      _procesandoOperacion = false;
    }
  }

  Future<void> _cargarRutaImagen(
    int idInmueble,
    InmuebleImagen imagen,
    Map<int, String?> rutas,
  ) async {
    try {
      final ruta = await _imageService.obtenerRutaCompletaImagen(
        imagen.rutaImagen,
      );
      rutas[idInmueble] = ruta;
    } catch (e) {
      // Error individual no detiene toda la operación
      AppLogger.warning(
        'Error al cargar ruta de imagen para inmueble $idInmueble: $e',
      );
      rutas[idInmueble] = null;
    }
  }
}

// Provider para filtros de búsqueda
final filtrosInmuebleProvider =
    StateNotifierProvider<FiltrosInmuebleNotifier, FiltrosInmueble>((ref) {
      return FiltrosInmuebleNotifier();
    });

// Clase para representar los filtros de búsqueda
class FiltrosInmueble {
  final String? tipo;
  final String? operacion;
  final double? precioMin;
  final double? precioMax;
  final String? ciudad;
  final int? idEstado;
  final double? margenMin;

  FiltrosInmueble({
    this.tipo,
    this.operacion,
    this.precioMin,
    this.precioMax,
    this.ciudad,
    this.idEstado,
    this.margenMin,
  });

  // Método para verificar si hay filtros aplicados
  bool get hayFiltrosAplicados =>
      tipo != null ||
      operacion != null ||
      precioMin != null ||
      precioMax != null ||
      ciudad != null ||
      idEstado != null ||
      margenMin != null;

  FiltrosInmueble copyWith({
    String? tipo,
    String? operacion,
    double? precioMin,
    double? precioMax,
    String? ciudad,
    int? idEstado,
    double? margenMin,
  }) {
    return FiltrosInmueble(
      tipo: tipo ?? this.tipo,
      operacion: operacion ?? this.operacion,
      precioMin: precioMin ?? this.precioMin,
      precioMax: precioMax ?? this.precioMax,
      ciudad: ciudad ?? this.ciudad,
      idEstado: idEstado ?? this.idEstado,
      margenMin: margenMin ?? this.margenMin,
    );
  }
}

// Notifier para manejar los filtros
class FiltrosInmuebleNotifier extends StateNotifier<FiltrosInmueble> {
  FiltrosInmuebleNotifier() : super(FiltrosInmueble());

  void actualizarFiltro({
    String? tipo,
    String? operacion,
    double? precioMin,
    double? precioMax,
    String? ciudad,
    int? idEstado,
    double? margenMin,
  }) {
    state = state.copyWith(
      tipo: tipo,
      operacion: operacion,
      precioMin: precioMin,
      precioMax: precioMax,
      ciudad: ciudad,
      idEstado: idEstado,
      margenMin: margenMin,
    );
  }

  void limpiarFiltros() {
    state = FiltrosInmueble();
  }
}

// NUEVA IMPLEMENTACIÓN - Estado para búsqueda de inmuebles
class InmueblesBusquedaState {
  final List<Inmueble> inmuebles;
  final bool isLoading;
  final String? errorMessage;

  InmueblesBusquedaState({
    required this.inmuebles,
    required this.isLoading,
    this.errorMessage,
  });

  InmueblesBusquedaState copyWith({
    List<Inmueble>? inmuebles,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InmueblesBusquedaState(
      inmuebles: inmuebles ?? this.inmuebles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Notificador para manejar la búsqueda de inmuebles
class InmueblesBusquedaNotifier extends StateNotifier<InmueblesBusquedaState> {
  final InmuebleController _controller;
  final Ref _ref;

  InmueblesBusquedaNotifier(this._controller, this._ref)
    : super(InmueblesBusquedaState(inmuebles: [], isLoading: false));

  Future<void> buscarInmuebles(FiltrosInmueble filtros) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      List<Inmueble> resultados;
      final ordenarPorMargen = _ref.read(ordenarPorMargenProvider);
      final mostrarInactivos = _ref.read(mostrarInactivosProvider);

      // Si no hay filtros aplicados, usa el provider general de inmuebles
      if (!filtros.hayFiltrosAplicados) {
        resultados = await _controller.getInmuebles();
      } else {
        // Si hay filtros, realizar la búsqueda con los criterios
        AppLogger.info(
          'Buscando inmuebles con filtros: ${_filtrosToString(filtros)}',
        );
        resultados = await _controller.buscarInmuebles(
          tipo: filtros.tipo,
          operacion: filtros.operacion,
          precioMin: filtros.precioMin,
          precioMax: filtros.precioMax,
          ciudad: filtros.ciudad,
          idEstado: filtros.idEstado,
          margenMin: filtros.margenMin,
        );
      }

      // Aplicar el filtro de activos/inactivos
      if (mostrarInactivos) {
        resultados =
            resultados.where((inmueble) => inmueble.idEstado == 2).toList();
      } else {
        resultados =
            resultados.where((inmueble) => inmueble.idEstado != 2).toList();
      }

      // Aplicar ordenamiento por margen si está activado
      if (ordenarPorMargen && resultados.isNotEmpty) {
        resultados.sort(
          (a, b) => (b.margenUtilidad ?? 0).compareTo(a.margenUtilidad ?? 0),
        );
      }

      state = state.copyWith(inmuebles: resultados, isLoading: false);
    } catch (e, stackTrace) {
      // Manejar error
      AppLogger.error('Error al buscar inmuebles', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Error al buscar inmuebles: ${e.toString().split('\n').first}',
      );
    }
  }
}

// Provider principal para el estado de búsqueda
final inmueblesBusquedaStateProvider =
    StateNotifierProvider<InmueblesBusquedaNotifier, InmueblesBusquedaState>((
      ref,
    ) {
      final controller = ref.watch(inmuebleControllerProvider);
      final notifier = InmueblesBusquedaNotifier(controller, ref);

      // Inicializar el notifier y suscribirse a cambios en los filtros
      ref.listen(filtrosInmuebleProvider, (previous, next) {
        notifier.buscarInmuebles(next);
      });

      // También reaccionar a cambios en las configuraciones de visualización
      ref.listen(mostrarInactivosProvider, (_, __) {
        notifier.buscarInmuebles(ref.read(filtrosInmuebleProvider));
      });

      ref.listen(ordenarPorMargenProvider, (_, __) {
        notifier.buscarInmuebles(ref.read(filtrosInmuebleProvider));
      });

      // Realizar una búsqueda inicial
      notifier.buscarInmuebles(ref.read(filtrosInmuebleProvider));

      return notifier;
    });

// Provider simplificado para acceder a la lista de inmuebles buscados
final inmueblesBuscadosProvider = Provider<List<Inmueble>>((ref) {
  final state = ref.watch(inmueblesBusquedaStateProvider);
  return state.inmuebles;
});

// Provider para el estado de carga desde el notifier
final isLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(inmueblesBusquedaStateProvider);
  return state.isLoading;
});

// Provider para mensajes de error desde el notifier
final errorMessageProvider = Provider<String?>((ref) {
  final state = ref.watch(inmueblesBusquedaStateProvider);
  return state.errorMessage;
});

// Función auxiliar para convertir filtros a cadena para logs
String _filtrosToString(FiltrosInmueble filtros) {
  final params = <String>[];
  if (filtros.tipo != null) params.add('tipo: ${filtros.tipo}');
  if (filtros.operacion != null) params.add('operación: ${filtros.operacion}');
  if (filtros.precioMin != null) params.add('precioMin: ${filtros.precioMin}');
  if (filtros.precioMax != null) params.add('precioMax: ${filtros.precioMax}');
  if (filtros.ciudad != null) params.add('ciudad: ${filtros.ciudad}');
  if (filtros.idEstado != null) params.add('idEstado: ${filtros.idEstado}');
  if (filtros.margenMin != null) params.add('margenMin: ${filtros.margenMin}');
  return params.join(', ');
}

import '../models/inmueble_model.dart';
import '../models/inmueble_imagen.dart';
import '../services/image_service.dart';
import '../controllers/inmueble_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers_global.dart'; // Importar los providers globales

// Provider para controlar el orden por margen de utilidad
final ordenarPorMargenProvider = StateProvider<bool>((ref) => false);

// Provider para el controlador de inmuebles
final inmuebleControllerProvider = Provider<InmuebleController>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return InmuebleController(dbService: dbService);
});

// Provider para la lista de inmuebles
final inmueblesProvider = FutureProvider<List<Inmueble>>((ref) async {
  final controller = ref.watch(inmuebleControllerProvider);
  return controller.getInmuebles();
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
    error: (_, __) => [],
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

  ImagenesPrincipalesNotifier(this._inmuebleController) : super({});

  Future<void> cargarImagenesPrincipales(List<Inmueble> inmuebles) async {
    final Map<int, InmuebleImagen?> nuevasImagenes = {};

    for (var inmueble in inmuebles) {
      if (inmueble.id != null) {
        nuevasImagenes[inmueble.id!] = await _inmuebleController
            .getImagenPrincipal(inmueble.id!);
      }
    }

    state = nuevasImagenes;
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

  RutasImagenesNotifier(this._imageService) : super({});

  Future<void> cargarRutasImagenes(Map<int, InmuebleImagen?> imagenes) async {
    final Map<int, String?> nuevasRutas = {};

    for (var entry in imagenes.entries) {
      if (entry.value != null) {
        nuevasRutas[entry.key] = await _imageService.obtenerRutaCompletaImagen(
          entry.value!.rutaImagen,
        );
      }
    }

    state = nuevasRutas;
  }
}

// Provider para el estado de carga
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Provider para mensajes de error
final errorMessageProvider = StateProvider<String?>((ref) => null);

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
  final double? margenMin; // Añadido nuevo campo

  FiltrosInmueble({
    this.tipo,
    this.operacion,
    this.precioMin,
    this.precioMax,
    this.ciudad,
    this.idEstado,
    this.margenMin, // Inicializar nuevo campo
  });

  FiltrosInmueble copyWith({
    String? tipo,
    String? operacion,
    double? precioMin,
    double? precioMax,
    String? ciudad,
    int? idEstado,
    double? margenMin, // Incluir en copyWith
  }) {
    return FiltrosInmueble(
      tipo: tipo ?? this.tipo,
      operacion: operacion ?? this.operacion,
      precioMin: precioMin ?? this.precioMin,
      precioMax: precioMax ?? this.precioMax,
      ciudad: ciudad ?? this.ciudad,
      idEstado: idEstado ?? this.idEstado,
      margenMin: margenMin ?? this.margenMin, // Copiar el valor
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
    double? margenMin, // Añadir el nuevo parámetro
  }) {
    state = state.copyWith(
      tipo: tipo,
      operacion: operacion,
      precioMin: precioMin,
      precioMax: precioMax,
      ciudad: ciudad,
      idEstado: idEstado,
      margenMin: margenMin, // Incluir en la actualización
    );
  }

  void limpiarFiltros() {
    state = FiltrosInmueble();
  }
}

// Provider para inmuebles filtrados por criterios de búsqueda
final inmueblesBuscadosProvider = FutureProvider<List<Inmueble>>((ref) async {
  final controller = ref.watch(inmuebleControllerProvider);
  final filtros = ref.watch(filtrosInmuebleProvider);
  final ordenarPorMargen = ref.watch(ordenarPorMargenProvider);

  // Si no hay filtros aplicados, usa el provider general de inmuebles filtrados
  if (filtros.tipo == null &&
      filtros.operacion == null &&
      filtros.precioMin == null &&
      filtros.precioMax == null &&
      filtros.ciudad == null &&
      filtros.idEstado == null &&
      filtros.margenMin == null) {
    // Incluir el nuevo campo en la validación
    List<Inmueble> inmuebles = ref.watch(inmueblesFiltradosProvider);

    // Aplicar ordenamiento por margen si está activado
    if (ordenarPorMargen) {
      inmuebles = [...inmuebles]; // Copia para no modificar la lista original
      inmuebles.sort(
        (a, b) => (b.margenUtilidad ?? 0).compareTo(a.margenUtilidad ?? 0),
      );
    }

    return inmuebles;
  }

  // Si hay filtros, realiza la búsqueda con los criterios
  List<Inmueble> resultados = await controller.buscarInmuebles(
    tipo: filtros.tipo,
    operacion: filtros.operacion,
    precioMin: filtros.precioMin,
    precioMax: filtros.precioMax,
    ciudad: filtros.ciudad,
    idEstado: filtros.idEstado,
    margenMin: filtros.margenMin, // Incluir el nuevo parámetro
  );

  // Aplicar el filtro de activos/inactivos
  final mostrarInactivos = ref.watch(mostrarInactivosProvider);
  if (mostrarInactivos) {
    resultados =
        resultados.where((inmueble) => inmueble.idEstado == 2).toList();
  } else {
    resultados =
        resultados.where((inmueble) => inmueble.idEstado != 2).toList();
  }

  // Aplicar ordenamiento por margen si está activado
  if (ordenarPorMargen) {
    resultados.sort(
      (a, b) => (b.margenUtilidad ?? 0).compareTo(a.margenUtilidad ?? 0),
    );
  }

  return resultados;
});

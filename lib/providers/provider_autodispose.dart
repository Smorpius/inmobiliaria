import './providers_global.dart';
import '../models/inmueble_model.dart';
import '../models/inmueble_imagen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider con autoDispose para el listado filtrado de inmuebles
final inmueblesFiltradosProvider = FutureProvider.autoDispose<List<Inmueble>>((ref) async {
  // Mantenemos el resultado en caché por un corto tiempo
  ref.keepAlive();
  
  final inmuebleController = ref.watch(inmuebleControllerProvider);
  final mostrarInactivos = ref.watch(mostrarInactivosProvider);
  
  final inmuebles = await inmuebleController.getInmuebles();
  
  if (mostrarInactivos) {
    return inmuebles.where((inmueble) => inmueble.idEstado == 2).toList();
  } else {
    return inmuebles.where((inmueble) => inmueble.idEstado != 2).toList();
  }
});

// Provider con autoDispose para imágenes de un inmueble específico
final inmuebleImagenesAutoDisposeProvider = FutureProvider.autoDispose.family<List<InmuebleImagen>, int>(
  (ref, inmuebleId) async {
    // Mantener el resultado en caché brevemente
    ref.keepAlive();
    
    final controller = ref.watch(inmuebleControllerProvider);
    return controller.getImagenesInmueble(inmuebleId);
  },
);

// Provider temporal para búsqueda de clientes
final clienteBusquedaProvider = StateProvider.autoDispose<String>((ref) => '');
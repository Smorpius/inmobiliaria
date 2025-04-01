import './providers_global.dart';
import '../utils/applogger.dart';
import '../models/inmueble_model.dart';
import '../models/inmueble_imagen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Control para evitar logs duplicados de errores
bool _procesandoError = false;

// Provider con autoDispose para el listado filtrado de inmuebles
// Optimizado con manejo de errores y prevención de logs duplicados
final inmueblesFiltradosProvider = FutureProvider.autoDispose<List<Inmueble>>((ref) async {
  // Mantenemos el resultado en caché por un corto tiempo para evitar múltiples peticiones
  ref.keepAlive();
  
  try {
    final inmuebleController = ref.watch(inmuebleControllerProvider);
    final mostrarInactivos = ref.watch(mostrarInactivosProvider);
    
    // Obtener inmuebles usando el procedimiento almacenado a través del controlador
    final inmuebles = await inmuebleController.getInmuebles();
    
    AppLogger.info('Provider: Inmuebles filtrados obtenidos: ${inmuebles.length}');
    
    if (mostrarInactivos) {
      return inmuebles.where((inmueble) => inmueble.idEstado == 2).toList();
    } else {
      return inmuebles.where((inmueble) => inmueble.idEstado != 2).toList();
    }
  } catch (e, stackTrace) {
    if (!_procesandoError) {
      _procesandoError = true;
      AppLogger.error('Error en inmueblesFiltradosProvider', e, stackTrace);
      _procesandoError = false;
    }
    // Propagación del error para que la UI pueda manejarlo
    throw Exception('Error al cargar inmuebles: ${e.toString().split('\n').first}');
  }
});

// Provider con autoDispose para imágenes de un inmueble específico
// Mejorado con manejo de errores y control de reconexión
final inmuebleImagenesAutoDisposeProvider = FutureProvider.autoDispose.family<List<InmuebleImagen>, int>(
  (ref, inmuebleId) async {
    // Mantener el resultado en caché brevemente para optimizar rendimiento
    ref.keepAlive();
    
    try {
      final controller = ref.watch(inmuebleControllerProvider);
      
      // Verificar que inmuebleId sea válido
      if (inmuebleId <= 0) {
        AppLogger.warning('Provider: ID de inmueble inválido: $inmuebleId');
        return [];
      }
      
      // Obtener imágenes usando el procedimiento almacenado del controlador
      final imagenes = await controller.getImagenesInmueble(inmuebleId);
      // Filtrar imágenes inválidas (con rutas vacías)
      final imagenesValidas = imagenes.where((img) => 
        img.rutaImagen.isNotEmpty
      ).toList();
      
      AppLogger.info('Provider: ${imagenesValidas.length} imágenes válidas cargadas para inmueble $inmuebleId');
      return imagenesValidas;
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al cargar imágenes para inmueble $inmuebleId',
          e,
          stackTrace
        );
        _procesandoError = false;
      }
      
      // Verificar si es un error de conexión o MySQL para implementar reintentos
      final esErrorConexion = 
        e.toString().toLowerCase().contains('connection') ||
        e.toString().toLowerCase().contains('socket') ||
        e.toString().toLowerCase().contains('closed') ||
        e.toString().toLowerCase().contains('mysql');
      
      if (esErrorConexion) {
        // En caso de error de conexión, intentar reiniciar la conexión
        // usando databaseServiceProvider que existe en providers_global.dart
        ref.read(databaseServiceProvider).reiniciarConexion().catchError((_) {});
      }
      
      // Devolver lista vacía en caso de error para evitar excepciones en cascada
      return [];
    }
  },
);

// Provider temporal para búsqueda de clientes
// Simple StateProvider que no necesita optimizaciones adicionales
final clienteBusquedaProvider = StateProvider.autoDispose<String>((ref) => '');

// Provider para la imagen principal de un inmueble
// Optimizado para usar el procedimiento almacenado correspondiente
final imagenPrincipalProvider = FutureProvider.autoDispose.family<InmuebleImagen?, int>(
  (ref, inmuebleId) async {
    // Comprobar si el ID es válido
    if (inmuebleId <= 0) return null;
    
    try {
      final controller = ref.watch(inmuebleControllerProvider);
      final imagenes = await controller.getImagenesInmueble(inmuebleId);
      
      // Buscar imagen principal o tomar la primera disponible
      final imagenPrincipal = imagenes.firstWhere(
        (img) => img.esPrincipal == true,
        orElse: () => imagenes.isNotEmpty ? imagenes.first : throw Exception('No hay imágenes'),
      );
      
      return imagenPrincipal;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.warning('No se pudo cargar la imagen principal para el inmueble $inmuebleId: $e');
        _procesandoError = false;
      }
      return null;
    }
  }
);
import 'package:inmobiliaria/utils/applogger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/models/inmueble_model.dart';
import 'package:inmobiliaria/providers/inmueble_providers.dart';

/// Provider para inmuebles disponibles para venta o renta
///
/// Utiliza el procedimiento almacenado BuscarInmuebles del controlador para
/// obtener resultados filtrados directamente desde la base de datos,
/// mejorando la eficiencia y evitando filtrado excesivo en memoria.
final inmueblesDisponiblesProvider = FutureProvider<List<Inmueble>>((
  ref,
) async {
  try {
    final controller = ref.watch(inmuebleControllerProvider);

    // Utilizamos directamente la búsqueda filtrada del controlador
    // que ejecuta el procedimiento almacenado BuscarInmuebles
    AppLogger.info('Obteniendo inmuebles disponibles usando filtro optimizado');

    final inmuebles = await controller.buscarInmuebles(
      idEstado: 3, // Estado disponible (3)
      // No incluimos otros filtros para mantener la lógica original
    );

    // Filtro secundario para mantener los inmuebles en estado "disponible" o "en negociación"
    // y con precios adecuados según el tipo de operación
    final inmueblesFiltrados =
        inmuebles.where((i) {
          // Incluir también estados vendido (4) y rentado (5)
          final estadoOk =
              (i.idEstado == 3 ||
                  i.idEstado == 4 ||
                  i.idEstado == 5 ||
                  i.idEstado == 6);

          // Verificar que tenga precio según tipo de operación
          final precioOk =
              (i.tipoOperacion == 'venta' && i.precioVenta != null) ||
              (i.tipoOperacion == 'renta' && i.precioRenta != null) ||
              (i.tipoOperacion == 'ambos' &&
                  (i.precioVenta != null || i.precioRenta != null));

          return estadoOk && precioOk;
        }).toList();

    AppLogger.info(
      'Inmuebles disponibles encontrados: ${inmueblesFiltrados.length} de ${inmuebles.length} consultados',
    );

    return inmueblesFiltrados;
  } catch (e, stackTrace) {
    // Registro estructurado del error para facilitar depuración
    AppLogger.error('Error al obtener inmuebles disponibles', e, stackTrace);

    // Rethrow para que Riverpod pueda manejar el estado de error
    rethrow;
  }
});

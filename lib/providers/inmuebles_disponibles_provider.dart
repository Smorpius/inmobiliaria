import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/models/inmueble_model.dart';
import 'package:inmobiliaria/providers/inmueble_providers.dart';

// Provider para inmuebles disponibles para venta
final inmueblesDisponiblesProvider = FutureProvider<List<Inmueble>>((
  ref,
) async {
  try {
    final controller = ref.watch(inmuebleControllerProvider);
    final inmuebles = await controller.getInmuebles();

    // Log detallado de los inmuebles obtenidos
    developer.log('Total de inmuebles obtenidos: ${inmuebles.length}');

    // Para depuración, revisemos los estados y precios de los inmuebles
    for (var i = 0; i < inmuebles.length; i++) {
      developer.log(
        'Inmueble #${i + 1}: ID=${inmuebles[i].id}, Estado=${inmuebles[i].idEstado}, '
        'Tipo=${inmuebles[i].tipoInmueble}, Operación=${inmuebles[i].tipoOperacion}, '
        'PrecioVenta=${inmuebles[i].precioVenta}, PrecioRenta=${inmuebles[i].precioRenta}',
      );
    }

    // Filtro modificado temporalmente para diagnóstico - menos restrictivo
    final inmueblesFiltrados =
        inmuebles.where((i) {
          // Verificar solo estado por ahora
          final estadoOk = (i.idEstado == 3 || i.idEstado == 6);

          // Verificar precios por separado para detectar el problema
          final precioOk =
              (i.tipoOperacion == 'venta' && i.precioVenta != null) ||
              (i.tipoOperacion == 'renta' && i.precioRenta != null);

          // Log para cada inmueble que no pasa los filtros
          if (!estadoOk || !precioOk) {
            developer.log(
              'Inmueble ${i.id} filtrado: estadoOk=$estadoOk, precioOk=$precioOk',
            );
          }

          // Para encontrar el problema, puedes temporalmente relajar los filtros
          // Puedes probar con: return true; // Mostrar todos para diagnóstico

          // O puedes quitar la verificación de precio temporalmente
          // return estadoOk;

          // O mantener el filtro original
          return estadoOk && precioOk;
        }).toList();

    developer.log(
      'Inmuebles filtrados disponibles: ${inmueblesFiltrados.length}',
    );

    return inmueblesFiltrados;
  } catch (e) {
    developer.log('Error en inmueblesDisponiblesProvider: $e', error: e);
    rethrow;
  }
});

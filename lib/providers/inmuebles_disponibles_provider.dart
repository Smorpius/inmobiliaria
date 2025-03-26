import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/models/inmueble_model.dart';
import 'package:inmobiliaria/providers/inmueble_providers.dart';
// Provider para inmuebles disponibles para venta

final inmueblesDisponiblesProvider = FutureProvider<List<Inmueble>>((
  ref,
) async {
  final controller = ref.watch(inmuebleControllerProvider);
  final inmuebles = await controller.getInmuebles();
  return inmuebles
      .where(
        (i) =>
            // Inmuebles disponibles (3) o en negociación (6)
            (i.idEstado == 3 || i.idEstado == 6) &&
            // Que tengan precio definido
            ((i.tipoOperacion == 'venta' && i.precioVenta != null) ||
                (i.tipoOperacion == 'renta' && i.precioRenta != null)),
      )
      .toList();
});

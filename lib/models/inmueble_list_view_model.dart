import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';
import '../../../models/inmueble_imagen.dart';
import '../../../services/image_service.dart';
import '../../../controllers/inmueble_controller.dart';

class InmuebleListViewModel {
  final InmuebleController inmuebleController;
  final ImageService imageService;

  // Notificadores de estado
  final ValueNotifier<List<Inmueble>> inmueblesFiltradosNotifier =
      ValueNotifier<List<Inmueble>>([]);
  final ValueNotifier<Map<int, InmuebleImagen?>> imagenesPrincipalesNotifier =
      ValueNotifier<Map<int, InmuebleImagen?>>({});
  final ValueNotifier<Map<int, String?>> rutasImagenesPrincipalesNotifier =
      ValueNotifier<Map<int, String?>>({});
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isFilteringNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessageNotifier = ValueNotifier<String?>(
    null,
  );

  // Datos internos
  List<Inmueble> _inmuebles = [];

  InmuebleListViewModel({
    required this.inmuebleController,
    required this.imageService,
  });

  Future<void> cargarInmuebles() async {
    isLoadingNotifier.value = true;
    errorMessageNotifier.value = null;

    try {
      final inmuebles = await inmuebleController.getInmuebles();

      // Inicializar mapas para las imágenes
      final Map<int, InmuebleImagen?> nuevasImagenesPrincipales = {};
      final Map<int, String?> nuevasRutasImagenes = {};

      // Cargar imágenes principales para cada inmueble
      for (var inmueble in inmuebles) {
        if (inmueble.id != null) {
          nuevasImagenesPrincipales[inmueble.id!] = await inmuebleController
              .getImagenPrincipal(inmueble.id!);
        }
      }

      // Obtener rutas completas para las imágenes principales
      for (var entry in nuevasImagenesPrincipales.entries) {
        if (entry.value != null) {
          nuevasRutasImagenes[entry.key] = await imageService
              .obtenerRutaCompletaImagen(entry.value!.rutaImagen);
        }
      }

      _inmuebles = inmuebles;
      inmueblesFiltradosNotifier.value = inmuebles;
      imagenesPrincipalesNotifier.value = nuevasImagenesPrincipales;
      rutasImagenesPrincipalesNotifier.value = nuevasRutasImagenes;
      isFilteringNotifier.value = false;
      errorMessageNotifier.value = null;
    } catch (e) {
      errorMessageNotifier.value = e.toString();
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> filtrarInmuebles({
    String? tipo,
    String? operacion,
    double? precioMin,
    double? precioMax,
    String? ciudad,
    int? idEstado,
  }) async {
    isLoadingNotifier.value = true;
    errorMessageNotifier.value = null;

    try {
      // Si todos los parámetros son nulos, no aplicamos filtros
      if (tipo == null &&
          operacion == null &&
          precioMin == null &&
          precioMax == null &&
          ciudad == null &&
          idEstado == null) {
        inmueblesFiltradosNotifier.value = _inmuebles;
        isFilteringNotifier.value = false;
        return;
      }

      // Usamos el método de búsqueda del controlador
      final inmueblesFiltrados = await inmuebleController.buscarInmuebles(
        tipo: tipo,
        operacion: operacion,
        precioMin: precioMin,
        precioMax: precioMax,
        ciudad: ciudad,
        idEstado: idEstado,
      );

      inmueblesFiltradosNotifier.value = inmueblesFiltrados;
      isFilteringNotifier.value = true;
    } catch (e) {
      errorMessageNotifier.value = 'Error al filtrar: $e';
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  void limpiarFiltros() {
    inmueblesFiltradosNotifier.value = _inmuebles;
    isFilteringNotifier.value = false;
  }

  Future<bool> cambiarEstadoInmueble(
    Inmueble inmueble,
    BuildContext context,
  ) async {
    try {
      // Determinar el nuevo estado
      int nuevoEstado = (inmueble.idEstado == 3) ? 4 : 3;

      // Crear una copia actualizada del inmueble con el nuevo estado
      final inmuebleActualizado = Inmueble(
        id: inmueble.id,
        nombre: inmueble.nombre,
        idDireccion: inmueble.idDireccion,
        montoTotal: inmueble.montoTotal,
        idEstado: nuevoEstado,
        idCliente: inmueble.idCliente,
        idEmpleado: inmueble.idEmpleado,
        tipoInmueble: inmueble.tipoInmueble,
        tipoOperacion: inmueble.tipoOperacion,
        precioVenta: inmueble.precioVenta,
        precioRenta: inmueble.precioRenta,
        caracteristicas: inmueble.caracteristicas,
        calle: inmueble.calle,
        numero: inmueble.numero,
        colonia: inmueble.colonia,
        ciudad: inmueble.ciudad,
        estadoGeografico: inmueble.estadoGeografico,
        codigoPostal: inmueble.codigoPostal,
        referencias: inmueble.referencias,
        fechaRegistro: inmueble.fechaRegistro,
      );

      // Actualizar el inmueble
      await inmuebleController.updateInmueble(inmuebleActualizado);

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoEstado == 3
                  ? 'Inmueble marcado como Disponible'
                  : 'Inmueble marcado como No Disponible',
            ),
            backgroundColor: nuevoEstado == 3 ? Colors.green : Colors.red,
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}

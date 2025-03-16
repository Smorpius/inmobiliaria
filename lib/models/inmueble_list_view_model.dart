import 'package:flutter/material.dart';
import '../models/inmueble_model.dart';
import '../models/inmueble_imagen.dart';
import '../services/image_service.dart';
import '../controllers/inmueble_controller.dart';

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
  final ValueNotifier<bool> isFilteringNotifier = ValueNotifier<bool>(
    true,
  ); // Ahora siempre true por defecto
  final ValueNotifier<String?> errorMessageNotifier = ValueNotifier<String?>(
    null,
  );

  // Notificador para controlar mostrar inmuebles activos/inactivos
  final ValueNotifier<bool> mostrarInactivosNotifier = ValueNotifier<bool>(
    false,
  );

  // Datos internos
  List<Inmueble> _inmuebles = [];
  List<Inmueble> _inmueblesSinFiltrar = []; // Lista completa sin filtros

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

      _inmueblesSinFiltrar = inmuebles; // Guardar todos los inmuebles
      _aplicarFiltroActivos(); // Aplicar filtro por defecto según el estado

      imagenesPrincipalesNotifier.value = nuevasImagenesPrincipales;
      rutasImagenesPrincipalesNotifier.value = nuevasRutasImagenes;
      errorMessageNotifier.value = null;
    } catch (e) {
      errorMessageNotifier.value = e.toString();
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  // Método para alternar entre inmuebles activos e inactivos
  void toggleMostrarInactivos() {
    mostrarInactivosNotifier.value = !mostrarInactivosNotifier.value;
    _aplicarFiltroActivos();
  }

  // Método para aplicar filtro de activos/inactivos
  void _aplicarFiltroActivos() {
    if (mostrarInactivosNotifier.value) {
      // Mostrar solo inmuebles inactivos (idEstado == 2)
      _inmuebles =
          _inmueblesSinFiltrar
              .where((inmueble) => inmueble.idEstado == 2)
              .toList();
    } else {
      // Mostrar solo inmuebles activos (idEstado != 2)
      _inmuebles =
          _inmueblesSinFiltrar
              .where((inmueble) => inmueble.idEstado != 2)
              .toList();
    }

    inmueblesFiltradosNotifier.value = _inmuebles;
    // Siempre estamos filtrando ahora, ya sea activos o inactivos
    isFilteringNotifier.value = true;
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
      // Si todos los parámetros son nulos, no aplicamos filtros adicionales
      if (tipo == null &&
          operacion == null &&
          precioMin == null &&
          precioMax == null &&
          ciudad == null &&
          idEstado == null) {
        // Al limpiar filtros, aplicamos solo el filtro de activos/inactivos
        _aplicarFiltroActivos();
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

      // Aplicar filtro adicional según mostrarInactivos
      if (mostrarInactivosNotifier.value) {
        // Si estamos mostrando inactivos, filtrar a solo inactivos
        inmueblesFiltradosNotifier.value =
            inmueblesFiltrados
                .where((inmueble) => inmueble.idEstado == 2)
                .toList();
      } else {
        // Si estamos mostrando activos, filtrar a solo activos
        inmueblesFiltradosNotifier.value =
            inmueblesFiltrados
                .where((inmueble) => inmueble.idEstado != 2)
                .toList();
      }
    } catch (e) {
      errorMessageNotifier.value = 'Error al filtrar: $e';
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  void limpiarFiltros() {
    // Al limpiar filtros, seguimos aplicando el filtro de activos/inactivos
    _aplicarFiltroActivos();
  }

  // Método para cambiar el estado del inmueble
  Future<bool> cambiarEstadoInmueble(
    Inmueble inmueble,
    BuildContext context,
  ) async {
    try {
      // Determinar el nuevo estado basado en el estado actual
      int nuevoEstado;
      String mensaje;
      Color colorMensaje;

      if (inmueble.idEstado == 2) {
        // Si está inactivo
        nuevoEstado = 3; // Marcar como disponible
        mensaje = 'Inmueble marcado como Disponible';
        colorMensaje = Colors.green;
      } else {
        // Si está disponible u otro estado
        nuevoEstado = 2; // Marcar como no disponible
        mensaje = 'Inmueble marcado como No Disponible';
        colorMensaje = Colors.red;
      }

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
            content: Text(mensaje),
            backgroundColor: colorMensaje,
            duration: const Duration(seconds: 2),
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

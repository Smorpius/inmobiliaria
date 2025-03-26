import '../models/venta_model.dart';
import '../models/ventas_state.dart';
import 'package:flutter/material.dart';
import '../services/ventas_service.dart';
import '../models/venta_reporte_model.dart';
import '../controllers/venta_controller.dart';
import 'package:inmobiliaria/models/usuario.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers_global.dart'; // Importamos el modelo de usuario

// Provider para el usuario actual - Si no existe, lo definimos
final usuarioActualProvider = StateProvider<Usuario?>((ref) => null);

// Provider para el servicio de ventas
final ventasServiceProvider = Provider<VentasService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return VentasService(dbService);
});

// Provider para el controlador de ventas
final ventaControllerProvider = Provider<VentaController>((ref) {
  final ventasService = ref.watch(ventasServiceProvider);
  return VentaController(ventasService);
});

// Provider para obtener todas las ventas
final ventasProvider = FutureProvider<List<Venta>>((ref) async {
  final controller = ref.watch(ventaControllerProvider);
  return controller.obtenerVentas();
});

// Provider para una venta específica por ID
final ventaDetalleProvider = FutureProvider.family<Venta?, int>((
  ref,
  id,
) async {
  final controller = ref.watch(ventaControllerProvider);
  return controller.obtenerVentaPorId(id);
});

// Notifier para la gestión del estado de ventas
class VentasNotifier extends StateNotifier<VentasState> {
  final VentaController _controller;
  final Ref _ref; // Añadimos una referencia a Ref

  VentasNotifier(this._controller, this._ref) : super(VentasState.initial()) {
    cargarVentas();
  }

  Future<void> cargarVentas() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final ventas = await _controller.obtenerVentas();
      state = state.copyWith(ventas: ventas, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar ventas: $e',
      );
    }
  }

  void actualizarBusqueda(String termino) {
    state = state.copyWith(terminoBusqueda: termino);
  }

  // REEMPLAZAR este método por la versión que acepta null
  void aplicarFiltroFechas(DateTimeRange? fechas) {
    // Si el valor es null, elimina el filtro
    if (fechas == null) {
      state = state.copyWith(filtroFechas: null);
    } else {
      state = state.copyWith(filtroFechas: fechas);
    }
  }

  // REEMPLAZAR este método por la versión que acepta null
  void aplicarFiltroEstado(String? estado) {
    // Si el valor es null, elimina el filtro
    if (estado == null) {
      state = state.copyWith(filtroEstado: null);
    } else {
      state = state.copyWith(filtroEstado: estado);
    }
  }

  void limpiarFiltros() {
    state = state.copyWith(
      filtroFechas: null,
      filtroEstado: null,
      terminoBusqueda: '',
    );
  }

  // También puedes agregar estos métodos para mayor claridad
  void limpiarFiltroFechas() {
    state = state.copyWith(filtroFechas: null);
  }

  void limpiarFiltroEstado() {
    state = state.copyWith(filtroEstado: null);
  }

  Future<bool> registrarVenta(Venta venta) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _controller.crearVenta(venta);
      await cargarVentas();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al registrar venta: $e',
      );
      return false;
    }
  }

  Future<bool> actualizarGastosVenta(
    int idVenta,
    double gastosAdicionales,
  ) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      // Ahora usamos _ref en lugar de ref
      final usuarioActual = _ref.read(usuarioActualProvider)?.id ?? 1;
      await _controller.actualizarGastosVenta(
        idVenta,
        gastosAdicionales,
        usuarioActual,
      );
      await cargarVentas();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar gastos: $e',
      );
      return false;
    }
  }

  Future<bool> actualizarUtilidadNeta(
    int idVenta,
    double nuevaUtilidadNeta,
  ) async {
    try {
      // Primero necesitamos obtener la venta actual para conocer su utilidad bruta
      final ventaActual = await _controller.obtenerVentaPorId(idVenta);
      if (ventaActual == null) {
        throw Exception('Venta no encontrada');
      }

      // Calcular los gastos adicionales como la diferencia entre utilidad bruta y neta
      final gastosAdicionales = ventaActual.utilidadBruta - nuevaUtilidadNeta;

      // Validar que los gastos no sean negativos
      if (gastosAdicionales < 0) {
        throw Exception(
          'La utilidad neta no puede ser mayor que la utilidad bruta',
        );
      }

      // Usar el método existente actualizarGastosVenta
      return await actualizarGastosVenta(idVenta, gastosAdicionales);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar utilidad neta: $e',
      );
      return false;
    }
  }

  Future<bool> cambiarEstadoVenta(int idVenta, int nuevoEstado) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _controller.cambiarEstadoVenta(idVenta, nuevoEstado);
      await cargarVentas();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cambiar estado: $e',
      );
      return false;
    }
  }
}

// ELIMINAR estos métodos que están fuera de la clase VentasNotifier
// void aplicarFiltroFechas(DateTimeRange? fechas) { ... }
// void aplicarFiltroEstado(String? idEstado) { ... }

// Provider para el estado de ventas - Modificado para pasar ref
final ventasStateProvider = StateNotifierProvider<VentasNotifier, VentasState>((
  ref,
) {
  final controller = ref.watch(ventaControllerProvider);
  return VentasNotifier(controller, ref); // Pasamos ref como segundo parámetro
});

// Provider para estadísticas de ventas
final ventasEstadisticasProvider =
    FutureProvider.family<VentaReporte, DateTimeRange?>((ref, fechas) async {
      final controller = ref.watch(ventaControllerProvider);
      return controller.obtenerEstadisticasVentas(
        fechaInicio: fechas?.start,
        fechaFin: fechas?.end,
      );
    });

// Provider para estadísticas sin filtro de fechas
final ventasEstadisticasGeneralProvider = FutureProvider<VentaReporte>((
  ref,
) async {
  final controller = ref.watch(ventaControllerProvider);
  return controller.obtenerEstadisticasVentas();
});

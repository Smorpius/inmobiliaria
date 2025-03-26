import '../models/venta_model.dart';
import 'dart:developer' as developer;
import '../services/ventas_service.dart';
import '../models/venta_reporte_model.dart';

class VentaController {
  final VentasService _ventasService;

  VentaController(this._ventasService);

  /// Obtiene todas las ventas
  Future<List<Venta>> obtenerVentas() async {
    try {
      return await _ventasService.obtenerVentas();
    } catch (e) {
      developer.log('Error en controller al obtener ventas: $e', error: e);
      throw Exception('No se pudieron cargar las ventas: $e');
    }
  }

  /// Obtiene una venta por ID
  Future<Venta?> obtenerVentaPorId(int idVenta) async {
    try {
      return await _ventasService.obtenerVentaPorId(idVenta);
    } catch (e) {
      developer.log(
        'Error en controller al obtener venta por ID: $e',
        error: e,
      );
      throw Exception('No se pudo encontrar la venta: $e');
    }
  }

  /// Crea una nueva venta
  Future<int> crearVenta(Venta venta) async {
    try {
      // Validar datos básicos
      if (venta.idCliente <= 0) {
        throw Exception('El ID del cliente es inválido');
      }
      if (venta.idInmueble <= 0) {
        throw Exception('El ID del inmueble es inválido');
      }
      if (venta.ingreso <= 0) {
        throw Exception('El ingreso debe ser mayor a cero');
      }

      // Llamar al servicio para crear la venta
      return await _ventasService.crearVenta(venta);
    } catch (e) {
      developer.log('Error en controller al crear venta: $e', error: e);
      throw Exception('No se pudo crear la venta: $e');
    }
  }

  /// Actualiza gastos adicionales y recalcula utilidad neta
  Future<bool> actualizarGastosVenta(
    int idVenta,
    double gastosAdicionales,
    int usuarioModificacion,
  ) async {
    try {
      // Validar que los gastos no sean negativos
      if (gastosAdicionales < 0) {
        throw Exception('Los gastos adicionales no pueden ser negativos');
      }

      // Continuar con la actualización
      return await _ventasService.actualizarUtilidadVenta(
        idVenta,
        gastosAdicionales,
        usuarioModificacion,
      );
    } catch (e) {
      developer.log('Error al actualizar gastos de venta: $e', error: e);
      throw Exception('No se pudieron actualizar los gastos adicionales: $e');
    }
  }

  /// Cambia el estado de una venta
  Future<bool> cambiarEstadoVenta(int idVenta, int nuevoEstado) async {
    try {
      if (![7, 8, 9].contains(nuevoEstado)) {
        // 7: en proceso, 8: completada, 9: cancelada
        throw Exception('Estado de venta no válido');
      }

      // Suponemos un ID de usuario activo
      const idUsuario = 1;

      return await _ventasService.cambiarEstadoVenta(
        idVenta,
        nuevoEstado,
        idUsuario,
      );
    } catch (e) {
      developer.log('Error en controller al cambiar estado: $e', error: e);
      throw Exception('No se pudo cambiar el estado de la venta: $e');
    }
  }

  /// Obtiene estadísticas de ventas en un período
  Future<VentaReporte> obtenerEstadisticasVentas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      return await _ventasService.obtenerEstadisticasVentas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
    } catch (e) {
      developer.log(
        'Error en controller al obtener estadísticas: $e',
        error: e,
      );
      throw Exception('No se pudieron obtener las estadísticas: $e');
    }
  }
}

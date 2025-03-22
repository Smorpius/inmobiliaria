import 'providers_global.dart';
import '../models/venta_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para obtener todas las ventas
final ventasProvider = FutureProvider<List<Venta>>((ref) {
  final inmuebleController = ref.watch(inmuebleControllerProvider);
  return inmuebleController.getVentas();
});

// Provider para filtrar ventas por fecha
final ventasFiltradas = FutureProvider.family<List<Venta>, DateTimeRange?>((
  ref,
  dateRange,
) async {
  final ventas = await ref.watch(ventasProvider.future);

  if (dateRange == null) {
    return ventas;
  }

  return ventas.where((venta) {
    return venta.fechaVenta.isAfter(dateRange.start) &&
        venta.fechaVenta.isBefore(dateRange.end.add(const Duration(days: 1)));
  }).toList();
});

// Provider para estadísticas de ventas
final ventasEstadisticasProvider = Provider<VentasEstadisticas>((ref) {
  final ventasAsyncValue = ref.watch(ventasProvider);

  return ventasAsyncValue.when(
    data: (ventas) {
      final totalVentas = ventas.length;
      final double ingresoTotal = ventas.fold(
        0,
        (sum, venta) => sum + venta.ingreso,
      );
      final double utilidadTotal = ventas.fold(
        0,
        (sum, venta) => sum + venta.utilidadNeta,
      );

      return VentasEstadisticas(
        totalVentas: totalVentas,
        ingresoTotal: ingresoTotal,
        utilidadTotal: utilidadTotal,
      );
    },
    loading:
        () => VentasEstadisticas(
          totalVentas: 0,
          ingresoTotal: 0,
          utilidadTotal: 0,
        ),
    error:
        (_, __) => VentasEstadisticas(
          totalVentas: 0,
          ingresoTotal: 0,
          utilidadTotal: 0,
        ),
  );
});

// Modelo para estadísticas de ventas
class VentasEstadisticas {
  final int totalVentas;
  final double ingresoTotal;
  final double utilidadTotal;

  VentasEstadisticas({
    required this.totalVentas,
    required this.ingresoTotal,
    required this.utilidadTotal,
  });
}

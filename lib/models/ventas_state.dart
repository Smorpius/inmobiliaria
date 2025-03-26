import '../models/venta_model.dart';
import 'package:flutter/material.dart';

class VentasState {
  final List<Venta> ventas;
  final bool isLoading;
  final String? errorMessage;
  final DateTimeRange? filtroFechas;
  final String? filtroEstado;
  final String terminoBusqueda;

  const VentasState({
    required this.ventas,
    required this.isLoading,
    this.errorMessage,
    this.filtroFechas,
    this.filtroEstado,
    this.terminoBusqueda = '',
  });

  factory VentasState.initial() =>
      const VentasState(ventas: [], isLoading: true);

  // Asegúrate de que tu método copyWith maneje correctamente los valores nulos

  VentasState copyWith({
    List<Venta>? ventas,
    bool? isLoading,
    String? errorMessage,
    DateTimeRange? filtroFechas,
    String? filtroEstado,
    String? terminoBusqueda,
  }) {
    return VentasState(
      ventas: ventas ?? this.ventas,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Permite null para limpiar el error
      filtroFechas: filtroFechas, // Permite null para eliminar el filtro
      filtroEstado: filtroEstado, // Permite null para eliminar el filtro
      terminoBusqueda: terminoBusqueda ?? this.terminoBusqueda,
    );
  }

  List<Venta> get ventasFiltradas {
    if (terminoBusqueda.isEmpty &&
        filtroFechas == null &&
        filtroEstado == null) {
      return ventas;
    }

    return ventas.where((venta) {
      bool cumpleBusqueda = true;
      bool cumpleFecha = true;
      bool cumpleEstado = true;

      // Filtro por búsqueda
      if (terminoBusqueda.isNotEmpty) {
        final terminoLower = terminoBusqueda.toLowerCase();
        cumpleBusqueda =
            (venta.nombreCliente?.toLowerCase().contains(terminoLower) ??
                false) ||
            (venta.apellidoCliente?.toLowerCase().contains(terminoLower) ??
                false) ||
            (venta.nombreInmueble?.toLowerCase().contains(terminoLower) ??
                false);
      }

      // Filtro por fecha
      if (filtroFechas != null) {
        cumpleFecha =
            venta.fechaVenta.isAfter(filtroFechas!.start) &&
            venta.fechaVenta.isBefore(
              filtroFechas!.end.add(const Duration(days: 1)),
            );
      }

      // Filtro por estado
      if (filtroEstado != null) {
        cumpleEstado = venta.idEstado.toString() == filtroEstado;
      }

      return cumpleBusqueda && cumpleFecha && cumpleEstado;
    }).toList();
  }
}

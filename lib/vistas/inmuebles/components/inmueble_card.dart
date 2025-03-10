import 'package:flutter/material.dart';

/// Utilidades comunes para las vistas de inmuebles
class InmuebleUtils {
  /// Determina el icono según el tipo de inmueble
  static IconData getTipoInmuebleIcon(String tipoInmueble) {
    switch (tipoInmueble.toLowerCase()) {
      case 'casa':
        return Icons.home;
      case 'departamento':
        return Icons.apartment;
      case 'terreno':
        return Icons.landscape;
      case 'oficina':
        return Icons.business;
      case 'bodega':
        return Icons.warehouse;
      default:
        return Icons.real_estate_agent;
    }
  }

  /// Capitaliza la primera letra de un texto
  static String capitalizarPalabra(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  /// Formatea un monto a formato de moneda
  static String formatearMonto(double? monto) {
    if (monto == null) return 'No especificado';
    return '\$${monto.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}

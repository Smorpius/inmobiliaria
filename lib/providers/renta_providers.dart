import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para cargar datos de rentas
final rentaProvider = Provider<RentaService>((ref) {
  return RentaService();
});

/// Servicio para gestionar operaciones relacionadas con rentas
class RentaService {
  // Aquí se implementarían métodos para interactuar con la API/BD
  Future<Map<String, dynamic>> obtenerEstadisticasRentas(
    DateTimeRange periodo,
  ) async {
    // En un caso real, aquí se conectaría con el backend
    await Future.delayed(const Duration(seconds: 1));

    return {
      'totalContratos': 25,
      'contratosActivos': 18,
      'ingresosMensuales': 75000.0,
      'egresosMensuales': 25000.0,
      'balanceMensual': 50000.0,
      'rentabilidad': 66.67,
      'datosInmuebles': [
        {
          'nombre': 'Edificio Centro',
          'ingresos': 25000.0,
          'egresos': 8000.0,
          'balance': 17000.0,
        },
        {
          'nombre': 'Condominio Sur',
          'ingresos': 18000.0,
          'egresos': 6500.0,
          'balance': 11500.0,
        },
        {
          'nombre': 'Apartamentos Norte',
          'ingresos': 32000.0,
          'egresos': 10500.0,
          'balance': 21500.0,
        },
      ],
      'evolucionMensual': [
        {
          'mes': 'Enero',
          'ingresos': 70000.0,
          'egresos': 24000.0,
          'balance': 46000.0,
        },
        {
          'mes': 'Febrero',
          'ingresos': 72000.0,
          'egresos': 24500.0,
          'balance': 47500.0,
        },
        {
          'mes': 'Marzo',
          'ingresos': 75000.0,
          'egresos': 25000.0,
          'balance': 50000.0,
        },
        {
          'mes': 'Abril',
          'ingresos': 75000.0,
          'egresos': 25500.0,
          'balance': 49500.0,
        },
        {
          'mes': 'Mayo',
          'ingresos': 77000.0,
          'egresos': 26000.0,
          'balance': 51000.0,
        },
        {
          'mes': 'Junio',
          'ingresos': 78000.0,
          'egresos': 26500.0,
          'balance': 51500.0,
        },
      ],
    };
  }
}

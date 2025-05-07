import 'package:flutter_riverpod/flutter_riverpod.dart';
// Necesario para DateTimeRange si se usa aquí directamente // Eliminada importación de material.dart
import '../services/renta_service.dart' as services; // Usar alias para claridad
import '../services/mysql_helper.dart'; // Para DatabaseService

/// Provider para el servicio de Renta que interactúa con la base de datos
final rentaProvider = Provider<services.RentaService>((ref) {
  // Se instancia DatabaseService directamente.
  // Si DatabaseService tuviera su propio provider, se usaría ref.watch()
  final dbService = DatabaseService();
  return services.RentaService(dbService);
});

// La clase RentaService que estaba aquí con datos hardcodeados ha sido eliminada.
// El FutureProvider rentasEstadisticasProvider se define en
// lib/vistas/estadisticas/rentas/reporte_rentas_screen.dart
// y utilizará esta nueva implementación de rentaProvider.

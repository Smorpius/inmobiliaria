import 'dart:async';
import 'providers_global.dart';
import '../utils/applogger.dart';
import '../models/contrato_renta_model.dart';
import '../controllers/contrato_renta_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado para gestionar los contratos de renta
class ContratosRentaState {
  final List<ContratoRenta> contratos;
  final bool isLoading;
  final String? errorMessage;
  final String filterTerm;
  final bool mostrarSoloActivos;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;

  ContratosRentaState({
    this.contratos = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filterTerm = '',
    this.mostrarSoloActivos = true,
    this.filterStartDate,
    this.filterEndDate,
  });

  ContratosRentaState copyWith({
    List<ContratoRenta>? contratos,
    bool? isLoading,
    String? errorMessage,
    String? filterTerm,
    bool? mostrarSoloActivos,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    bool clearErrorMessage = false,
  }) {
    return ContratosRentaState(
      contratos: contratos ?? this.contratos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      filterTerm: filterTerm ?? this.filterTerm,
      mostrarSoloActivos: mostrarSoloActivos ?? this.mostrarSoloActivos,
      filterStartDate: filterStartDate ?? this.filterStartDate,
      filterEndDate: filterEndDate ?? this.filterEndDate,
    );
  }

  /// Lista de contratos filtrados según criterios actuales
  List<ContratoRenta> get contratosFiltrados {
    if (filterTerm.isEmpty &&
        mostrarSoloActivos == false &&
        filterStartDate == null &&
        filterEndDate == null) {
      return contratos;
    }

    return contratos.where((contrato) {
      // Filtro por texto (nombre del cliente, inmueble o ID)
      bool matchesText =
          filterTerm.isEmpty ||
          (contrato.clienteNombreCompleto?.toLowerCase().contains(
                filterTerm.toLowerCase(),
              ) ??
              false) ||
          contrato.id.toString().contains(filterTerm) ||
          contrato.idInmueble.toString().contains(filterTerm);

      // Filtro por estado (activo/todos)
      bool matchesStatus = !mostrarSoloActivos || contrato.idEstado == 1;

      // Filtro por fechas
      bool matchesStartDate =
          filterStartDate == null ||
          !contrato.fechaInicio.isBefore(filterStartDate!);
      bool matchesEndDate =
          filterEndDate == null || !contrato.fechaFin.isAfter(filterEndDate!);

      return matchesText && matchesStatus && matchesStartDate && matchesEndDate;
    }).toList();
  }

  /// Obtiene contratos por vencer en los próximos X días
  List<ContratoRenta> contratosProximosAVencer({int diasLimite = 30}) {
    final ahora = DateTime.now();
    final limite = ahora.add(Duration(days: diasLimite));

    return contratos
        .where(
          (c) =>
              c.idEstado == 1 && // Solo contratos activos
              c.fechaFin.isAfter(ahora) &&
              c.fechaFin.isBefore(limite),
        )
        .toList();
  }
}

/// Provider para el controlador de contratos
final contratoRentaControllerProvider = Provider<ContratoRentaController>((
  ref,
) {
  final dbService = ref.watch(databaseServiceProvider);
  return ContratoRentaController(dbService: dbService);
});

/// Provider para obtener todos los contratos de renta
final contratosRentaProvider = FutureProvider<List<ContratoRenta>>((ref) async {
  final controller = ref.watch(contratoRentaControllerProvider);
  try {
    return await controller.obtenerContratos();
  } catch (e, stack) {
    AppLogger.error('Error al cargar contratos de renta', e, stack);
    return [];
  }
});

/// Provider para obtener un contrato específico por ID
final contratoDetalleProvider = FutureProvider.family<ContratoRenta?, int>((
  ref,
  idContrato,
) async {
  final controller = ref.watch(contratoRentaControllerProvider);
  try {
    final contratos = await controller.obtenerContratos();
    return contratos.firstWhere((c) => c.id == idContrato);
  } catch (e, stack) {
    AppLogger.error('Error al cargar detalle de contrato', e, stack);
    return null;
  }
});

class ContratosRentaNotifier extends StateNotifier<ContratosRentaState> {
  final ContratoRentaController _controller;

  ContratosRentaNotifier(this._controller) : super(ContratosRentaState()) {
    cargarContratos();
  }

  /// Carga todos los contratos de renta
  Future<void> cargarContratos() async {
    try {
      state = state.copyWith(isLoading: true, clearErrorMessage: true);
      final contratos = await _controller.obtenerContratos();
      state = state.copyWith(contratos: contratos, isLoading: false);
    } catch (e, stackTrace) {
      AppLogger.error('Error al cargar contratos', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar contratos: ${e.toString()}',
      );
    }
  }

  /// Renueva un contrato existente
  Future<bool> renovarContrato(
    int idContrato,
    DateTime nuevaFechaFin,
    double? nuevoMonto,
  ) async {
    try {
      final contrato = state.contratos.firstWhere((c) => c.id == idContrato);
      final contratoRenovado = contrato.copyWith(
        fechaFin: nuevaFechaFin,
        montoMensual: nuevoMonto ?? contrato.montoMensual,
      );

      await _controller.registrarContrato(contratoRenovado);
      await cargarContratos();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error al renovar contrato', e, stackTrace);
      return false;
    }
  }
}

/// Provider para el estado de contratos de renta
/// Provider para el estado de contratos de renta
final contratosRentaStateProvider =
    StateNotifierProvider<ContratosRentaNotifier, ContratosRentaState>((ref) {
      final controller = ref.watch(contratoRentaControllerProvider);
      return ContratosRentaNotifier(controller);
    });

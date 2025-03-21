import 'providers_global.dart';
import 'dart:developer' as developer;
import '../models/inmueble_model.dart';
import '../controllers/cliente_controller.dart';
import '../controllers/inmueble_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado para la gestión del detalle de un cliente
class ClienteDetalleState {
  final bool isLoading;
  final List<Map<String, dynamic>> inmuebles;
  final String? errorMessage;

  const ClienteDetalleState({
    this.isLoading = false,
    this.inmuebles = const [],
    this.errorMessage,
  });

  /// Constructor para crear una copia con algunos cambios
  ClienteDetalleState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? inmuebles,
    String? errorMessage,
  }) {
    return ClienteDetalleState(
      isLoading: isLoading ?? this.isLoading,
      inmuebles: inmuebles ?? this.inmuebles,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier para gestionar el estado del detalle de un cliente
class ClienteDetalleNotifier extends StateNotifier<ClienteDetalleState> {
  final ClienteController _clienteController;
  final InmuebleController _inmuebleController;
  final int clienteId;

  ClienteDetalleNotifier(
    this._clienteController,
    this._inmuebleController,
    this.clienteId,
  ) : super(const ClienteDetalleState(isLoading: true)) {
    cargarInmuebles();
  }

  /// Carga los inmuebles asociados al cliente
  Future<void> cargarInmuebles() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      developer.log('Cargando inmuebles para cliente ID: $clienteId');

      final inmuebles = await _clienteController.getInmueblesPorCliente(
        clienteId,
      );
      developer.log('Inmuebles cargados: ${inmuebles.length}');

      state = state.copyWith(inmuebles: inmuebles, isLoading: false);
    } catch (e) {
      developer.log('Error al cargar inmuebles del cliente: $e', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar inmuebles: $e',
      );
    }
  }

  /// Desasocia un inmueble del cliente
  Future<bool> desasignarInmueble(int idInmueble) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      developer.log(
        'Desasignando inmueble ID: $idInmueble del cliente ID: $clienteId',
      );

      final resultado = await _clienteController.desasignarInmuebleDeCliente(
        idInmueble,
      );

      // Recargar la lista después de desasignar
      await cargarInmuebles();
      return resultado;
    } catch (e) {
      developer.log('Error al desasignar inmueble: $e', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al desasignar inmueble: $e',
      );
      return false;
    }
  }

  /// Asigna un inmueble al cliente
  Future<bool> asignarInmueble(
    int idInmueble, [
    DateTime? fechaAdquisicion,
  ]) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      developer.log(
        'Asignando inmueble ID: $idInmueble al cliente ID: $clienteId',
      );

      final resultado = await _clienteController.asignarInmuebleACliente(
        clienteId,
        idInmueble,
        fechaAdquisicion,
      );

      // Recargar la lista después de asignar
      await cargarInmuebles();
      return resultado;
    } catch (e) {
      developer.log('Error al asignar inmueble: $e', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al asignar inmueble: $e',
      );
      return false;
    }
  }

  /// Obtiene inmuebles disponibles para asignar
  Future<List<Inmueble>> getInmueblesDisponibles() async {
    try {
      state = state.copyWith(isLoading: true);
      developer.log('Obteniendo inmuebles disponibles para asignar');

      // Usar el InmuebleController inyectado
      final inmuebles = await _inmuebleController.getInmuebles();

      // Filtrar solo los inmuebles disponibles (sin cliente o con estado=3)
      final disponibles =
          inmuebles
              .where((i) => i.idCliente == null || i.idEstado == 3)
              .toList();

      state = state.copyWith(isLoading: false);
      return disponibles;
    } catch (e) {
      developer.log('Error al obtener inmuebles disponibles: $e', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al obtener inmuebles disponibles: $e',
      );
      return [];
    }
  }
}

/// Provider para el ClienteDetalleNotifier
final clienteDetalleProvider = StateNotifierProvider.family<
  ClienteDetalleNotifier,
  ClienteDetalleState,
  int
>((ref, clienteId) {
  final clienteController = ref.watch(clienteControllerProvider);
  final inmuebleController = ref.watch(inmuebleControllerProvider);
  return ClienteDetalleNotifier(
    clienteController,
    inmuebleController,
    clienteId,
  );
});

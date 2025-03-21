import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/providers/inmueble_providers.dart';

class ClientesInteresadosState {
  final List<Map<String, dynamic>> clientes;
  final bool isLoading;
  final String? errorMessage;
  final String terminoBusqueda;

  const ClientesInteresadosState({
    required this.clientes,
    required this.isLoading,
    this.errorMessage,
    this.terminoBusqueda = '',
  });

  // Constructor para estado inicial
  factory ClientesInteresadosState.initial() =>
      const ClientesInteresadosState(clientes: [], isLoading: true);

  // Constructor para crear una copia con algunos cambios
  ClientesInteresadosState copyWith({
    List<Map<String, dynamic>>? clientes,
    bool? isLoading,
    String? errorMessage,
    String? terminoBusqueda,
  }) {
    return ClientesInteresadosState(
      clientes: clientes ?? this.clientes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      terminoBusqueda: terminoBusqueda ?? this.terminoBusqueda,
    );
  }

  // Clientes filtrados según término de búsqueda
  List<Map<String, dynamic>> get clientesFiltrados {
    if (terminoBusqueda.isEmpty) return clientes;

    final termino = terminoBusqueda.toLowerCase();
    return clientes.where((cliente) {
      final nombre =
          '${cliente['nombre']} ${cliente['apellido_paterno']} ${cliente['apellido_materno'] ?? ''}'
              .toLowerCase();
      final telefono =
          (cliente['telefono_cliente'] ?? '').toString().toLowerCase();
      final correo = (cliente['correo_cliente'] ?? '').toString().toLowerCase();

      return nombre.contains(termino) ||
          telefono.contains(termino) ||
          correo.contains(termino);
    }).toList();
  }
}

class ClientesInteresadosNotifier
    extends StateNotifier<ClientesInteresadosState> {
  final Ref _ref;
  final int inmuebleId;

  ClientesInteresadosNotifier(this._ref, this.inmuebleId)
    : super(ClientesInteresadosState.initial()) {
    cargarClientesInteresados();
  }

  Future<void> cargarClientesInteresados() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final controller = _ref.read(inmuebleControllerProvider);
      final clientes = await controller.getClientesInteresados(inmuebleId);

      state = state.copyWith(clientes: clientes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void actualizarBusqueda(String termino) {
    state = state.copyWith(terminoBusqueda: termino);
  }

  Future<bool> registrarClienteInteresado(
    int idCliente,
    String? comentarios,
  ) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final controller = _ref.read(inmuebleControllerProvider);
      final idRegistro = await controller.registrarClienteInteresado(
        inmuebleId,
        idCliente,
        comentarios,
      );

      if (idRegistro <= 0) {
        throw Exception('Error al registrar cliente interesado');
      }

      await cargarClientesInteresados();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

// Provider para gestionar clientes interesados
final clientesInteresadosStateProvider = StateNotifierProvider.family<
  ClientesInteresadosNotifier,
  ClientesInteresadosState,
  int
>((ref, inmuebleId) => ClientesInteresadosNotifier(ref, inmuebleId));

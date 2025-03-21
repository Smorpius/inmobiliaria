import '../models/cliente_model.dart';
import '../controllers/cliente_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para el controlador de clientes - CORREGIDO
final clienteControllerProvider = Provider<ClienteController>((ref) {
  // ClienteController no acepta el parámetro dbService, así que creamos la instancia directamente
  return ClienteController();
});

// Provider para todos los clientes activos
final clientesProvider = FutureProvider<List<Cliente>>((ref) async {
  final controller = ref.watch(clienteControllerProvider);
  return controller.getClientes();
});

// Provider para clientes inactivos
final clientesInactivosProvider = FutureProvider<List<Cliente>>((ref) async {
  final controller = ref.watch(clienteControllerProvider);
  return controller.getClientesInactivos();
});

// Provider para controlar si mostrar clientes inactivos
final mostrarClientesInactivosProvider = StateProvider<bool>((ref) => false);

// Provider para todos los clientes (activos e inactivos)
final todosClientesProvider = FutureProvider<List<Cliente>>((ref) async {
  final controller = ref.watch(clienteControllerProvider);
  final activos = await controller.getClientes();
  final inactivos = await controller.getClientesInactivos();
  return [...activos, ...inactivos];
});

// Provider para clientes filtrados según el estado
final clientesFiltradosProvider = Provider<List<Cliente>>((ref) {
  final clientesAsyncValue = ref.watch(todosClientesProvider);
  final mostrarInactivos = ref.watch(mostrarClientesInactivosProvider);
  
  return clientesAsyncValue.when(
    data: (clientes) {
      if (mostrarInactivos) {
        return clientes;
      } else {
        return clientes.where((c) => c.idEstado == 1).toList();
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider para buscar un cliente por ID
final clientePorIdProvider = FutureProvider.family<Cliente?, int>((ref, id) async {
  final controller = ref.watch(clienteControllerProvider);
  
  try {
    final clientes = await controller.getClientes();
    return clientes.firstWhere((c) => c.id == id);
  } catch (_) {
    try {
      final inactivos = await controller.getClientesInactivos();
      return inactivos.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
});
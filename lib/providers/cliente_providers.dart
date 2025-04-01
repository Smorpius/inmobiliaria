import '../utils/applogger.dart';
import '../models/cliente_model.dart';
import '../controllers/cliente_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para el controlador de clientes
final clienteControllerProvider = Provider<ClienteController>((ref) {
  try {
    AppLogger.info('Inicializando ClienteController en providers');
    return ClienteController();
  } catch (e, stack) {
    AppLogger.error('Error al inicializar ClienteController', e, stack);
    rethrow; // Permitir que Riverpod maneje el error
  }
});

/// Provider para todos los clientes activos
final clientesProvider = FutureProvider<List<Cliente>>((ref) async {
  try {
    final controller = ref.watch(clienteControllerProvider);
    AppLogger.info('Solicitando lista de clientes activos');
    final clientes = await controller.getClientes();
    AppLogger.info('Obtenidos ${clientes.length} clientes activos');
    return clientes;
  } catch (e, stack) {
    AppLogger.error('Error al obtener clientes activos', e, stack);
    rethrow;
  }
});

/// Provider para clientes inactivos
final clientesInactivosProvider = FutureProvider<List<Cliente>>((ref) async {
  try {
    final controller = ref.watch(clienteControllerProvider);
    AppLogger.info('Solicitando lista de clientes inactivos');
    final clientes = await controller.getClientesInactivos();
    AppLogger.info('Obtenidos ${clientes.length} clientes inactivos');
    return clientes;
  } catch (e, stack) {
    AppLogger.error('Error al obtener clientes inactivos', e, stack);
    rethrow;
  }
});

/// Provider para controlar si mostrar clientes inactivos
final mostrarClientesInactivosProvider = StateProvider<bool>((ref) => false);

/// Provider para todos los clientes (activos e inactivos)
final todosClientesProvider = FutureProvider<List<Cliente>>((ref) async {
  try {
    final controller = ref.watch(clienteControllerProvider);
    AppLogger.info('Solicitando todas las listas de clientes');

    // Obtener ambas listas en paralelo para mejor rendimiento
    final results = await Future.wait([
      controller.getClientes(),
      controller.getClientesInactivos(),
    ]);

    final activos = results[0];
    final inactivos = results[1];

    AppLogger.info(
      'Combinando listas: ${activos.length} activos, ${inactivos.length} inactivos',
    );
    return [...activos, ...inactivos];
  } catch (e, stack) {
    AppLogger.error('Error al obtener todos los clientes', e, stack);
    rethrow;
  }
});

/// Provider para clientes filtrados según el estado
final clientesFiltradosProvider = Provider<List<Cliente>>((ref) {
  final clientesAsyncValue = ref.watch(todosClientesProvider);
  final mostrarInactivos = ref.watch(mostrarClientesInactivosProvider);

  return clientesAsyncValue.when(
    data: (clientes) {
      if (mostrarInactivos) {
        return clientes;
      } else {
        final filtrados = clientes.where((c) => c.idEstado == 1).toList();
        AppLogger.info(
          'Filtro aplicado: ${filtrados.length} clientes activos de ${clientes.length} totales',
        );
        return filtrados;
      }
    },
    loading: () => [],
    error: (error, stack) {
      AppLogger.error('Error al filtrar clientes', error, stack);
      return [];
    },
  );
});

/// Provider para buscar un cliente por ID - usando el método específico del controlador
final clientePorIdProvider = FutureProvider.family<Cliente?, int>((
  ref,
  id,
) async {
  try {
    final controller = ref.watch(clienteControllerProvider);
    AppLogger.info('Buscando cliente con ID: $id usando método directo');

    // Usar el método específico del controlador que utiliza CALL ObtenerClientePorId
    final cliente = await controller.getClientePorId(id);

    if (cliente != null) {
      AppLogger.info('Cliente encontrado con ID: $id');
    } else {
      AppLogger.info('No se encontró cliente con ID: $id');
    }

    return cliente;
  } catch (e, stack) {
    AppLogger.error('Error al buscar cliente por ID: $id', e, stack);
    // En caso de error en la búsqueda específica, intentar el método alternativo
    try {
      final controller = ref.watch(clienteControllerProvider);
      final clientes = await controller.getClientes();
      for (var cliente in clientes) {
        if (cliente.id == id) return cliente;
      }

      final inactivos = await controller.getClientesInactivos();
      for (var cliente in inactivos) {
        if (cliente.id == id) return cliente;
      }

      return null;
    } catch (fallbackError) {
      AppLogger.error(
        'Error en método alternativo de búsqueda',
        fallbackError,
        StackTrace.current,
      );
      return null;
    }
  }
});

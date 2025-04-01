import 'providers_global.dart';
import '../utils/applogger.dart';
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

  // Control para evitar operaciones duplicadas
  bool _procesandoOperacion = false;

  // Control para evitar logs duplicados
  bool _procesandoError = false;

  ClienteDetalleNotifier(
    this._clienteController,
    this._inmuebleController,
    this.clienteId,
  ) : super(const ClienteDetalleState(isLoading: true)) {
    cargarInmuebles();
  }

  /// Carga los inmuebles asociados al cliente
  Future<void> cargarInmuebles() async {
    // Evitar operaciones duplicadas
    if (_procesandoOperacion) {
      AppLogger.info(
        'Operación en progreso, evitando duplicación de cargarInmuebles()',
      );
      return;
    }

    try {
      _procesandoOperacion = true;
      state = state.copyWith(isLoading: true, errorMessage: null);
      AppLogger.info('Cargando inmuebles para cliente ID: $clienteId');

      // Validar ID del cliente
      if (clienteId <= 0) {
        throw Exception('ID de cliente inválido');
      }

      // Llamada al procedimiento almacenado a través del controller
      final inmuebles = await _clienteController.getInmueblesPorCliente(
        clienteId,
      );
      AppLogger.info('Inmuebles cargados: ${inmuebles.length}');

      state = state.copyWith(inmuebles: inmuebles, isLoading: false);
    } catch (e) {
      // Evitar logs duplicados del mismo error
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al cargar inmuebles del cliente',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Error al cargar inmuebles: ${e.toString().split('\n').first}',
      );
    } finally {
      _procesandoOperacion = false;
    }
  }

  /// Desasocia un inmueble del cliente
  Future<bool> desasignarInmueble(int idInmueble) async {
    // Evitar operaciones duplicadas
    if (_procesandoOperacion) {
      AppLogger.warning(
        'Operación en progreso, evitando duplicación de desasignarInmueble()',
      );
      return false;
    }

    try {
      _procesandoOperacion = true;
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Validar parámetros
      if (idInmueble <= 0 || clienteId <= 0) {
        throw Exception('ID de inmueble o cliente inválido');
      }

      AppLogger.info(
        'Desasignando inmueble ID: $idInmueble del cliente ID: $clienteId',
      );

      // Llamada al procedimiento almacenado a través del controller
      final resultado = await _clienteController.desasignarInmuebleDeCliente(
        idInmueble,
      );

      // Recargar la lista después de desasignar para mantener datos frescos
      await cargarInmuebles();

      return resultado;
    } catch (e) {
      // Evitar logs duplicados del mismo error
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al desasignar inmueble', e, StackTrace.current);
        _procesandoError = false;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Error al desasignar inmueble: ${e.toString().split('\n').first}',
      );
      return false;
    } finally {
      _procesandoOperacion = false;
    }
  }

  /// Asigna un inmueble al cliente
  Future<bool> asignarInmueble(
    int idInmueble, [
    DateTime? fechaAdquisicion,
  ]) async {
    // Evitar operaciones duplicadas
    if (_procesandoOperacion) {
      AppLogger.warning(
        'Operación en progreso, evitando duplicación de asignarInmueble()',
      );
      return false;
    }

    try {
      _procesandoOperacion = true;
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Validar parámetros
      if (idInmueble <= 0 || clienteId <= 0) {
        throw Exception('ID de inmueble o cliente inválido');
      }

      AppLogger.info(
        'Asignando inmueble ID: $idInmueble al cliente ID: $clienteId',
      );

      // Llamada al procedimiento almacenado a través del controller
      final resultado = await _clienteController.asignarInmuebleACliente(
        clienteId,
        idInmueble,
        fechaAdquisicion,
      );

      // Recargar la lista después de asignar para mantener datos frescos
      await cargarInmuebles();

      return resultado;
    } catch (e) {
      // Evitar logs duplicados del mismo error
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al asignar inmueble', e, StackTrace.current);
        _procesandoError = false;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Error al asignar inmueble: ${e.toString().split('\n').first}',
      );
      return false;
    } finally {
      _procesandoOperacion = false;
    }
  }

  /// Obtiene inmuebles disponibles para asignar
  Future<List<Inmueble>> getInmueblesDisponibles() async {
    // Evitar operaciones duplicadas
    if (_procesandoOperacion) {
      AppLogger.warning(
        'Operación en progreso, evitando duplicación de getInmueblesDisponibles()',
      );
      return [];
    }

    try {
      _procesandoOperacion = true;
      state = state.copyWith(isLoading: true, errorMessage: null);
      AppLogger.info('Obteniendo inmuebles disponibles para asignar');

      // Usar el InmuebleController inyectado para obtener todos los inmuebles
      final inmuebles = await _inmuebleController.getInmuebles();

      // Filtrar solo los inmuebles disponibles (sin cliente o con estado=3: disponible)
      final disponibles =
          inmuebles
              .where((i) => i.idCliente == null && i.idEstado == 3)
              .toList();

      AppLogger.info(
        'Inmuebles disponibles encontrados: ${disponibles.length}',
      );
      state = state.copyWith(isLoading: false);
      return disponibles;
    } catch (e) {
      // Evitar logs duplicados del mismo error
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al obtener inmuebles disponibles',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Error al obtener inmuebles disponibles: ${e.toString().split('\n').first}',
      );
      return [];
    } finally {
      _procesandoOperacion = false;
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

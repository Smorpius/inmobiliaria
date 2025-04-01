import 'providers_global.dart';
import '../utils/applogger.dart';
import '../controllers/inmueble_controller.dart';
import '../models/inmueble_proveedor_servicio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para obtener la lista de servicios de proveedores por inmueble
final inmuebleProveedoresProvider =
    FutureProvider.family<List<InmuebleProveedorServicio>, int>((
      ref,
      idInmueble,
    ) async {
      final controller = ref.watch(inmuebleControllerProvider);
      return await controller.getServiciosProveedores(idInmueble);
    });

/// Notifier para gestionar el estado de servicios de proveedores de un inmueble
class InmuebleProveedoresNotifier
    extends StateNotifier<AsyncValue<List<InmuebleProveedorServicio>>> {
  final InmuebleController _controller;
  final int inmuebleId;

  // Control para evitar logs duplicados
  bool _procesandoError = false;

  // Control para evitar operaciones concurrentes
  bool _cargandoServicios = false;
  bool _asignandoProveedor = false;
  bool _eliminandoAsignacion = false;

  // Control para verificar si el notifier está activo
  bool _disposed = false;

  InmuebleProveedoresNotifier(this._controller, this.inmuebleId)
    : super(const AsyncValue.loading()) {
    cargarServicios();
  }

  /// Carga los servicios asociados al inmueble con control para evitar operaciones duplicadas
  Future<void> cargarServicios() async {
    if (_cargandoServicios) {
      AppLogger.info(
        'Ya se está cargando servicios para inmueble $inmuebleId, evitando operación duplicada',
      );
      return;
    }

    _cargandoServicios = true;

    try {
      state = const AsyncValue.loading();
      AppLogger.info(
        'Cargando servicios de proveedores para inmueble: $inmuebleId',
      );

      final servicios = await _controller.getServiciosProveedores(inmuebleId);

      if (mounted) {
        AppLogger.info(
          'Servicios cargados: ${servicios.length} para inmueble: $inmuebleId',
        );
        state = AsyncValue.data(servicios);
      }
    } catch (e, stack) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al cargar servicios de proveedores', e, stack);
        _procesandoError = false;
      }

      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    } finally {
      _cargandoServicios = false;
    }
  }

  /// Asigna un proveedor a un inmueble con control de operaciones concurrentes
  Future<bool> asignarProveedor(InmuebleProveedorServicio servicio) async {
    if (_asignandoProveedor) {
      AppLogger.warning(
        'Ya hay una operación de asignación en progreso para inmueble $inmuebleId',
      );
      return false;
    }

    _asignandoProveedor = true;

    try {
      AppLogger.info(
        'Asignando proveedor ${servicio.idProveedor} a inmueble $inmuebleId',
      );

      final idServicio = await _controller.asignarProveedorAInmueble(servicio);

      // Esperar un poco para asegurar que la BD procese el cambio
      await Future.delayed(const Duration(milliseconds: 300));

      await cargarServicios();

      AppLogger.info('Proveedor asignado exitosamente con ID: $idServicio');
      return true;
    } catch (e, stack) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al asignar proveedor a inmueble', e, stack);
        _procesandoError = false;
      }
      return false;
    } finally {
      _asignandoProveedor = false;
    }
  }

  /// Elimina la asignación de un servicio con control para prevenir operaciones duplicadas
  Future<bool> eliminarAsignacion(int id) async {
    if (_eliminandoAsignacion) {
      AppLogger.warning(
        'Ya hay una operación de eliminación en progreso para inmueble $inmuebleId',
      );
      return false;
    }

    _eliminandoAsignacion = true;

    try {
      AppLogger.info(
        'Eliminando asignación con ID: $id del inmueble $inmuebleId',
      );

      final result = await _controller.eliminarAsignacionProveedor(id);

      // Esperar un poco para asegurar que la BD procese el cambio
      await Future.delayed(const Duration(milliseconds: 300));

      await cargarServicios();

      AppLogger.info(
        'Asignación con ID: $id eliminada ${result ? 'exitosamente' : 'con errores'}',
      );
      return result;
    } catch (e, stack) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al eliminar asignación de proveedor', e, stack);
        _procesandoError = false;
      }
      return false;
    } finally {
      _eliminandoAsignacion = false;
    }
  }

  /// Verifica si este notifier sigue activo
  @override
  bool get mounted => !_disposed;

  /// Dispone los recursos del notifier
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Provider para gestionar los servicios de proveedores por inmueble
final inmuebleProveedoresNotifierProvider = StateNotifierProvider.family<
  InmuebleProveedoresNotifier,
  AsyncValue<List<InmuebleProveedorServicio>>,
  int
>((ref, inmuebleId) {
  final controller = ref.watch(inmuebleControllerProvider);
  return InmuebleProveedoresNotifier(controller, inmuebleId);
});

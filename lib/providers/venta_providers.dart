import 'dart:async';
import 'providers_global.dart';
import '../utils/applogger.dart';
import '../models/venta_model.dart';
import '../models/ventas_state.dart';
import 'package:flutter/material.dart';
import '../services/ventas_service.dart';
import '../models/venta_reporte_model.dart';
import '../controllers/venta_controller.dart';
import 'package:inmobiliaria/models/usuario.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/services/socket_error_handler.dart'
    as socket_handler;

// Provider para el usuario actual
final usuarioActualProvider = StateProvider<Usuario?>((ref) => null);

// Provider para el servicio de ventas
final ventasServiceProvider = Provider<VentasService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return VentasService(dbService);
});

// Provider para el controlador de ventas
final ventaControllerProvider = Provider<VentaController>((ref) {
  final ventasService = ref.watch(ventasServiceProvider);
  return VentaController(ventasService: ventasService);
});

// Provider para obtener todas las ventas con reintentos automáticos
final ventasProvider = FutureProvider<List<Venta>>((ref) async {
  try {
    final controller = ref.watch(ventaControllerProvider);
    return await controller.obtenerVentas();
  } catch (e, stack) {
    // Intentar reconexión automática en caso de error de conexión
    if (socket_handler.SocketErrorHandler().isSocketError(e)) {
      AppLogger.warning(
        'Error de conexión en ventasProvider, intentando reconexión',
      );
      await ref
          .read(databaseServiceProvider)
          .reiniciarConexion()
          .catchError((_) {});
    }

    // Devolver lista vacía en caso de error para evitar excepciones en cascada
    AppLogger.error('Error en ventasProvider', e, stack);
    return [];
  }
});

// Provider para una venta específica por ID con mejor manejo de errores
final ventaDetalleProvider = FutureProvider.family<Venta?, int>((
  ref,
  id,
) async {
  try {
    final controller = ref.watch(ventaControllerProvider);
    return await controller.obtenerVentaPorId(id);
  } catch (e, stack) {
    // Manejo especializado para errores de socket
    if (socket_handler.SocketErrorHandler().isSocketError(e)) {
      AppLogger.warning(
        'Error de conexión en ventaDetalleProvider, intentando reconexión',
      );
      await ref
          .read(databaseServiceProvider)
          .reiniciarConexion()
          .catchError((_) {});

      // Intentar un segundo acceso después de la reconexión
      try {
        await Future.delayed(const Duration(milliseconds: 800));
        final controller = ref.watch(ventaControllerProvider);
        return await controller.obtenerVentaPorId(id);
      } catch (secondError) {
        AppLogger.error(
          'Error en segundo intento de ventaDetalleProvider',
          secondError,
          stack,
        );
        return null;
      }
    }

    AppLogger.error('Error en ventaDetalleProvider', e, stack);
    return null;
  }
});

// Notifier para la gestión del estado de ventas
class VentasNotifier extends StateNotifier<VentasState> {
  final VentaController _controller;
  final Ref _ref;

  // Control para evitar operaciones duplicadas
  bool _procesandoOperacion = false;

  // Control para evitar reconexiones simultáneas
  bool _intentandoReconectar = false;

  // Control de mounted para evitar actualizaciones después de dispose
  bool _disposed = false;

  VentasNotifier(this._controller, this._ref) : super(VentasState.initial()) {
    cargarVentas();
  }

  @override
  bool get mounted => !_disposed;

  // Método para reconectar en caso de error de conexión
  Future<bool> _reconectar() async {
    if (_intentandoReconectar) return false;

    try {
      _intentandoReconectar = true;
      AppLogger.info('Intentando reconectar desde VentasNotifier');

      await _ref.read(databaseServiceProvider).reiniciarConexion();

      AppLogger.info('Reconexión exitosa desde VentasNotifier');
      return true;
    } catch (e) {
      AppLogger.error(
        'Error al reconectar desde VentasNotifier',
        e,
        StackTrace.current,
      );
      return false;
    } finally {
      _intentandoReconectar = false;
    }
  }

  Future<void> cargarVentas() async {
    if (_procesandoOperacion || _disposed) return;

    try {
      _procesandoOperacion = true;
      if (!mounted) return;

      state = state.copyWith(isLoading: true, errorMessage: null);

      final ventas = await _controller.obtenerVentas();

      // Solo actualizar estado si el notifier sigue montado
      if (mounted) {
        state = state.copyWith(ventas: ventas, isLoading: false);
      }

      AppLogger.info('Ventas cargadas: ${ventas.length}');
    } catch (e, stackTrace) {
      // Manejar errores de conexión con reconexión automática
      bool esErrorDeConexion =
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('closed');

      if (esErrorDeConexion) {
        AppLogger.warning(
          'Error de conexión al cargar ventas, intentando reconectar',
        );
        bool reconectado = await _reconectar();

        // Si se reconectó exitosamente, intentar cargar ventas nuevamente
        if (reconectado && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          _procesandoOperacion = false;
          return cargarVentas();
        }
      }

      AppLogger.error('Error al cargar ventas', e, stackTrace);

      // Solo actualizar estado si el notifier sigue montado
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _formatearMensajeError(e),
        );
      }
    } finally {
      _procesandoOperacion = false;
    }
  }

  // Formatea un mensaje de error para hacerlo más amigable
  String _formatearMensajeError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socket') ||
        errorStr.contains('connection') ||
        errorStr.contains('closed')) {
      return 'Error de conexión a la base de datos. Verifique su conexión e intente nuevamente.';
    } else if (errorStr.contains('timeout')) {
      return 'La operación tardó demasiado tiempo. Intente nuevamente más tarde.';
    } else if (errorStr.contains('mysql')) {
      return 'Error en la comunicación con la base de datos. Intente nuevamente.';
    }

    // Limitar longitud del mensaje
    final mensaje = error.toString().split('\n').first;
    return mensaje.length > 100 ? '${mensaje.substring(0, 97)}...' : mensaje;
  }

  void actualizarBusqueda(String termino) {
    if (_disposed || state.terminoBusqueda == termino) return;
    state = state.copyWith(terminoBusqueda: termino);
  }

  void aplicarFiltroFechas(DateTimeRange? fechas) {
    if (_disposed) return;
    state = state.copyWith(filtroFechas: fechas);
  }

  void aplicarFiltroEstado(String? estado) {
    if (_disposed) return;
    state = state.copyWith(filtroEstado: estado);
  }

  void limpiarFiltros() {
    if (_disposed) return;
    state = state.copyWith(
      filtroFechas: null,
      filtroEstado: null,
      terminoBusqueda: '',
    );
  }

  void limpiarFiltroFechas() {
    if (_disposed) return;
    state = state.copyWith(filtroFechas: null);
  }

  void limpiarFiltroEstado() {
    if (_disposed) return;
    state = state.copyWith(filtroEstado: null);
  }

  Future<bool> registrarVenta(Venta venta) async {
    if (_procesandoOperacion || _disposed) return false;

    try {
      _procesandoOperacion = true;
      if (!mounted) return false;

      state = state.copyWith(isLoading: true, errorMessage: null);

      // Usar el procedimiento almacenado a través del controlador con timeout
      final idVenta = await _controller
          .crearVenta(venta)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('La operación tardó demasiado tiempo');
            },
          );

      AppLogger.info('Venta registrada exitosamente con ID: $idVenta');

      // Recargar ventas solo si todavía está montado
      if (mounted) await cargarVentas();
      return true;
    } catch (e, stackTrace) {
      bool esErrorDeConexion =
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('closed');

      if (esErrorDeConexion) {
        await _reconectar();
      }

      AppLogger.error('Error al registrar venta', e, stackTrace);

      // Solo actualizar estado si el notifier sigue montado
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _formatearMensajeError(e),
        );
      }
      return false;
    } finally {
      _procesandoOperacion = false;
    }
  }

  Future<bool> actualizarGastosVenta(
    int idVenta,
    double gastosAdicionales,
  ) async {
    if (_procesandoOperacion || _disposed) return false;

    try {
      _procesandoOperacion = true;
      if (!mounted) return false;

      state = state.copyWith(isLoading: true, errorMessage: null);

      // Obtener el ID del usuario actual o usar valor por defecto
      final usuarioActual = _ref.read(usuarioActualProvider)?.id ?? 1;

      // Llamar al controlador que usa el procedimiento almacenado con timeout
      await _controller
          .actualizarGastosVenta(idVenta, gastosAdicionales, usuarioActual)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('La operación tardó demasiado tiempo');
            },
          );

      AppLogger.info('Gastos de venta $idVenta actualizados con éxito');

      // Recargar ventas solo si todavía está montado
      if (mounted) await cargarVentas();
      return true;
    } catch (e, stackTrace) {
      bool esErrorDeConexion =
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('closed');

      if (esErrorDeConexion) {
        await _reconectar();
      }

      AppLogger.error('Error al actualizar gastos de venta', e, stackTrace);

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _formatearMensajeError(e),
        );
      }
      return false;
    } finally {
      _procesandoOperacion = false;
    }
  }

  Future<bool> actualizarUtilidadNeta(
    int idVenta,
    double nuevaUtilidadNeta,
  ) async {
    if (_procesandoOperacion || _disposed) return false;

    try {
      _procesandoOperacion = true;
      if (!mounted) return false;

      state = state.copyWith(isLoading: true, errorMessage: null);

      // Primero necesitamos obtener la venta actual para conocer su utilidad bruta
      final ventaActual = await _controller
          .obtenerVentaPorId(idVenta)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'Tiempo de espera agotado al obtener detalles de la venta',
              );
            },
          );

      if (ventaActual == null) {
        throw Exception('Venta no encontrada');
      }

      // Validar que la utilidad neta no sea negativa
      if (nuevaUtilidadNeta < 0) {
        throw Exception('La utilidad neta no puede ser negativa');
      }

      // Validar que la utilidad neta no exceda la utilidad bruta
      if (nuevaUtilidadNeta > ventaActual.utilidadBruta) {
        AppLogger.warning(
          'Intento de establecer utilidad neta ($nuevaUtilidadNeta) mayor que la utilidad bruta '
          '(${ventaActual.utilidadBruta}). Ajustando al máximo permitido.',
        );
        nuevaUtilidadNeta = ventaActual.utilidadBruta;
      }

      // Calcular los gastos adicionales como la diferencia entre utilidad bruta y neta
      final gastosAdicionales = ventaActual.utilidadBruta - nuevaUtilidadNeta;

      // Log para depuración y auditoría
      AppLogger.info(
        'Actualizando utilidad neta de venta $idVenta: '
        'Utilidad Bruta=${ventaActual.utilidadBruta}, '
        'Nueva Utilidad Neta=$nuevaUtilidadNeta, '
        'Gastos Adicionales=$gastosAdicionales',
      );

      // Usar el método existente actualizarGastosVenta
      final resultado = await actualizarGastosVenta(idVenta, gastosAdicionales);

      // Si la operación fue exitosa, invalidar los proveedores relacionados para forzar recarga
      if (resultado && mounted) {
        // Refrescar proveedores relacionados
        _ref.invalidate(ventaDetalleProvider(idVenta));
      }

      return resultado;
    } catch (e, stackTrace) {
      bool esErrorDeConexion =
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('closed');

      if (esErrorDeConexion) {
        await _reconectar();
      }

      AppLogger.error('Error al actualizar utilidad neta', e, stackTrace);

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _formatearMensajeError(e),
        );
      }
      return false;
    } finally {
      _procesandoOperacion = false;
    }
  }

  Future<bool> cambiarEstadoVenta(int idVenta, int nuevoEstado) async {
    if (_procesandoOperacion || _disposed) return false;

    try {
      _procesandoOperacion = true;
      if (!mounted) return false;

      state = state.copyWith(isLoading: true, errorMessage: null);

      // Validar que el estado sea uno permitido
      if (![7, 8, 9].contains(nuevoEstado)) {
        throw Exception(
          'Estado no válido. Debe ser 7 (en proceso), 8 (completada) o 9 (cancelada)',
        );
      }

      // Llamada al controlador que usa el procedimiento almacenado CambiarEstadoVenta
      await _controller
          .cambiarEstadoVenta(idVenta, nuevoEstado)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('La operación tardó demasiado tiempo');
            },
          );

      AppLogger.info('Estado de venta $idVenta cambiado a $nuevoEstado');

      // Recargar ventas solo si todavía está montado
      if (mounted) await cargarVentas();
      return true;
    } catch (e, stackTrace) {
      bool esErrorDeConexion =
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('closed');

      if (esErrorDeConexion) {
        await _reconectar();
      }

      AppLogger.error('Error al cambiar estado de venta', e, stackTrace);

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _formatearMensajeError(e),
        );
      }
      return false;
    } finally {
      _procesandoOperacion = false;
    }
  }

  // Método para forzar una reconexión manual (útil para botones "Reintentar")
  Future<bool> forzarReconexion() async {
    if (_intentandoReconectar || _disposed) return false;

    try {
      _intentandoReconectar = true;
      if (!mounted) return false;

      state = state.copyWith(isLoading: true);

      // Reconectar y luego recargar datos
      await _ref.read(databaseServiceProvider).reiniciarConexion();
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        await cargarVentas();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error al forzar reconexión', e, StackTrace.current);

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'No se pudo restablecer la conexión: ${_formatearMensajeError(e)}',
        );
      }
      return false;
    } finally {
      _intentandoReconectar = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

// Provider para el estado de ventas
final ventasStateProvider = StateNotifierProvider<VentasNotifier, VentasState>((
  ref,
) {
  final controller = ref.watch(ventaControllerProvider);
  return VentasNotifier(controller, ref);
});

// Provider para estadísticas de ventas con rango de fechas y manejo de errores mejorado
final ventasEstadisticasProvider = FutureProvider.family<
  VentaReporte,
  DateTimeRange?
>((ref, fechas) async {
  try {
    final controller = ref.watch(ventaControllerProvider);
    return await controller
        .obtenerEstadisticasVentas(
          fechaInicio: fechas?.start,
          fechaFin: fechas?.end,
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('La operación tardó demasiado tiempo');
          },
        );
  } catch (e, stack) {
    // En caso de error, reintentar una vez
    if (socket_handler.SocketErrorHandler().isSocketError(e)) {
      AppLogger.warning(
        'Error de conexión en estadísticas, intentando reconexión',
      );
      await ref
          .read(databaseServiceProvider)
          .reiniciarConexion()
          .catchError((_) {});

      // Esperar un momento y reintentar
      await Future.delayed(const Duration(seconds: 1));
      try {
        final controller = ref.watch(ventaControllerProvider);
        return await controller.obtenerEstadisticasVentas(
          fechaInicio: fechas?.start,
          fechaFin: fechas?.end,
        );
      } catch (secondError) {
        // En el segundo error, devolver un reporte vacío para evitar fallos en cascada
        AppLogger.error(
          'Error persistente en estadísticas',
          secondError,
          stack,
        );
        return VentaReporte(
          fechaInicio: fechas?.start ?? DateTime(DateTime.now().year - 1),
          fechaFin: fechas?.end ?? DateTime.now(),
          totalVentas: 0,
          ingresoTotal: 0,
          utilidadTotal: 0,
          margenPromedio: 0,
          ventasPorTipo: {},
          ventasMensuales: [],
        );
      }
    }

    // Si no es error de conexión, lanzar directamente
    AppLogger.error('Error en estadísticas de ventas', e, stack);
    rethrow;
  }
});

// Provider para estadísticas sin filtro de fechas con manejo de errores mejorado
final ventasEstadisticasGeneralProvider = FutureProvider<VentaReporte>((
  ref,
) async {
  try {
    final controller = ref.watch(ventaControllerProvider);
    return await controller.obtenerEstadisticasVentas().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('La operación tardó demasiado tiempo');
      },
    );
  } catch (e, stack) {
    // En caso de error, reintentar una vez si es error de conexión
    if (socket_handler.SocketErrorHandler().isSocketError(e)) {
      AppLogger.warning(
        'Error de conexión en estadísticas generales, intentando reconexión',
      );
      await ref
          .read(databaseServiceProvider)
          .reiniciarConexion()
          .catchError((_) {});

      // Esperar un momento y reintentar
      await Future.delayed(const Duration(seconds: 1));
      try {
        final controller = ref.watch(ventaControllerProvider);
        return await controller.obtenerEstadisticasVentas();
      } catch (secondError) {
        // Devolver reporte vacío en vez de propagar el error
        AppLogger.error(
          'Error persistente en estadísticas generales',
          secondError,
          stack,
        );
        return VentaReporte(
          fechaInicio: DateTime(DateTime.now().year - 1),
          fechaFin: DateTime.now(),
          totalVentas: 0,
          ingresoTotal: 0,
          utilidadTotal: 0,
          margenPromedio: 0,
          ventasPorTipo: {},
          ventasMensuales: [],
        );
      }
    }

    // Si no es error de conexión, lanzar error
    AppLogger.error('Error en estadísticas generales', e, stack);
    rethrow;
  }
});

// Provider de diagnóstico de conexión para la UI
final conexionVentasStatusProvider = StateProvider<ConnectionStatus>((ref) {
  return ConnectionStatus.unknown;
});

// Enum para estado de conexión
enum ConnectionStatus { connected, disconnected, reconnecting, unknown }

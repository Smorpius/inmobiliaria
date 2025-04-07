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
import '../controllers/contrato_renta_controller.dart';
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

// Implementación del StateNotifier para el estado de ventas
class VentasStateNotifier extends StateNotifier<VentasState> {
  VentasStateNotifier(this._ref) : super(VentasState.initial()) {
    service = _ref.read(ventasServiceProvider);
  }

  final Ref _ref;
  late final VentasService service;

  /// Carga todas las ventas del backend
  Future<void> cargarVentas() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Cargar ventas desde el servicio
      final ventas = await service.obtenerVentas();

      // Cargar inmuebles disponibles para tener acceso a sus nombres
      final inmuebleController = _ref.read(inmuebleControllerProvider);
      final inmuebles =
          await inmuebleController
              .buscarInmuebles(); // Obtener todos los inmuebles

      // Mapa para búsqueda rápida de inmuebles por ID
      final mapaInmuebles = {for (var i in inmuebles) i.id: i};

      // Cargar contratos de renta para incluirlos como "ventas"
      final contratoService = ContratoRentaController();
      try {
        final contratos = await contratoService.obtenerContratos();

        // Convertir contratos de renta a formato Venta para mostrarlos en la misma lista
        final ventasDeContratos =
            contratos.map((contrato) {
              // Crear un ID único para el contrato que no colisione con ventas
              // Usamos un formato especial: -ID (negativo) para distinguirlos de ventas
              final idContrato = -(contrato.id ?? 0);

              // Buscar el nombre real del inmueble
              String nombreInmueble = "Inmueble ${contrato.idInmueble}";
              if (mapaInmuebles.containsKey(contrato.idInmueble)) {
                final inmueble = mapaInmuebles[contrato.idInmueble]!;
                nombreInmueble =
                    inmueble.nombre.isNotEmpty
                        ? inmueble.nombre
                        : "Inmueble ${contrato.idInmueble}";
              }

              return Venta(
                id: idContrato, // ID negativo para distinguir de ventas y evitar colisiones
                idCliente: contrato.idCliente,
                idInmueble: contrato.idInmueble,
                fechaVenta: contrato.fechaInicio,
                ingreso: contrato.montoMensual,
                comisionProveedores: 0,
                utilidadBruta: contrato.montoMensual,
                utilidadNeta: contrato.montoMensual,
                idEstado:
                    contrato.idEstado == 1
                        ? 7
                        : 8, // Activo=7 (en proceso), Finalizado=8 (completada)
                nombreCliente: contrato.nombreCliente,
                apellidoCliente: contrato.apellidoCliente,
                nombreInmueble:
                    nombreInmueble, // Mostrar solo el nombre del inmueble sin prefijo
                tipoOperacion: 'renta',
                tipoInmueble: 'renta',
                contratoRentaId:
                    contrato.id, // Guardamos el ID original del contrato
              );
            }).toList();

        // Combinar ventas y contratos en una sola lista
        ventas.addAll(ventasDeContratos);
      } catch (e) {
        // Usar correctamente el método estático error de AppLogger
        AppLogger.error(
          'Error al cargar contratos de renta',
          e,
          StackTrace.current,
        );
        // Continuamos con las ventas aunque no se hayan podido cargar los contratos
      } finally {
        contratoService.dispose();
      }

      // Actualizar estado con todas las ventas+contratos ordenados por fecha (más recientes primero)
      ventas.sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));
      state = state.copyWith(ventas: ventas, isLoading: false);
    } catch (e, stackTrace) {
      // Usar correctamente el método estático error de AppLogger
      AppLogger.error('Error al cargar ventas', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar ventas: $e',
      );
    }
  }

  /// Actualiza la utilidad neta de una venta
  Future<bool> actualizarUtilidadNeta(
    int idVenta,
    double nuevaUtilidadNeta,
  ) async {
    try {
      // Primero buscamos la venta en nuestro estado actual
      final ventas = List<Venta>.from(state.ventas);
      final index = ventas.indexWhere((v) => v.id == idVenta);

      if (index < 0) {
        return false;
      }

      // Calcular los gastos adicionales = utilidad bruta - utilidad neta nueva
      final utilidadBruta = ventas[index].utilidadBruta;
      final gastosAdicionales = utilidadBruta - nuevaUtilidadNeta;

      // Actualizamos la utilidad neta en el servicio
      // Usar el usuario por defecto 1 o mejor aún, obtenerlo del estado de la aplicación
      final usuarioModificacion = 1; // Idealmente obtener del estado de la app
      final result = await service.actualizarUtilidadVenta(
        idVenta,
        gastosAdicionales,
        usuarioModificacion,
      );

      if (result) {
        // Actualizamos la venta en el estado local
        // Creamos una nueva venta con la utilidad neta actualizada
        final ventaActualizada = Venta(
          id: ventas[index].id,
          idCliente: ventas[index].idCliente,
          idInmueble: ventas[index].idInmueble,
          fechaVenta: ventas[index].fechaVenta,
          ingreso: ventas[index].ingreso,
          comisionProveedores: ventas[index].comisionProveedores,
          utilidadBruta: ventas[index].utilidadBruta,
          utilidadNeta: nuevaUtilidadNeta,
          idEstado: ventas[index].idEstado,
          nombreCliente: ventas[index].nombreCliente,
          apellidoCliente: ventas[index].apellidoCliente,
          nombreInmueble: ventas[index].nombreInmueble,
          tipoOperacion: ventas[index].tipoOperacion,
          precioOriginalInmueble: ventas[index].precioOriginalInmueble,
          margenGanancia: ventas[index].margenGanancia,
          tipoInmueble: ventas[index].tipoInmueble,
        );

        ventas[index] = ventaActualizada;
        state = state.copyWith(ventas: ventas);
      }
      return result;
    } catch (e, stackTrace) {
      // Usar correctamente el método estático error de AppLogger
      AppLogger.error('Error al actualizar utilidad neta', e, stackTrace);
      return false;
    }
  }

  /// Cambiar el estado de una venta
  Future<bool> cambiarEstadoVenta(int idVenta, int nuevoEstado) async {
    try {
      // Usar el usuario por defecto 1 o mejor aún, obtenerlo del estado de la aplicación
      final usuarioModificacion = 1; // Idealmente obtener del estado de la app

      // Actualizamos el estado en el servicio usando el método correcto
      final result = await service.cambiarEstadoVenta(
        idVenta,
        nuevoEstado,
        usuarioModificacion,
      );

      if (result) {
        // Actualizar la venta en el estado local
        final ventas = List<Venta>.from(state.ventas);
        final index = ventas.indexWhere((v) => v.id == idVenta);

        if (index >= 0) {
          // Crear una nueva venta con el estado actualizado
          final ventaActualizada = Venta(
            id: ventas[index].id,
            idCliente: ventas[index].idCliente,
            idInmueble: ventas[index].idInmueble,
            fechaVenta: ventas[index].fechaVenta,
            ingreso: ventas[index].ingreso,
            comisionProveedores: ventas[index].comisionProveedores,
            utilidadBruta: ventas[index].utilidadBruta,
            utilidadNeta: ventas[index].utilidadNeta,
            idEstado: nuevoEstado,
            nombreCliente: ventas[index].nombreCliente,
            apellidoCliente: ventas[index].apellidoCliente,
            nombreInmueble: ventas[index].nombreInmueble,
            tipoOperacion: ventas[index].tipoOperacion,
            precioOriginalInmueble: ventas[index].precioOriginalInmueble,
            margenGanancia: ventas[index].margenGanancia,
            tipoInmueble: ventas[index].tipoInmueble,
          );

          ventas[index] = ventaActualizada;
          state = state.copyWith(ventas: ventas);
        }
      }
      return result;
    } catch (e, stackTrace) {
      // Usar correctamente el método estático error de AppLogger
      AppLogger.error('Error al cambiar estado de venta', e, stackTrace);
      return false;
    }
  }

  /// Registrar una nueva venta
  Future<bool> registrarVenta(Venta venta) async {
    try {
      final idVenta = await service.crearVenta(venta);
      if (idVenta > 0) {
        // Actualizar el estado con la nueva venta
        await cargarVentas(); // Recargar para obtener todos los datos actualizados
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      // Usar correctamente el método estático error de AppLogger
      AppLogger.error('Error al registrar venta', e, stackTrace);
      return false;
    }
  }

  /// Actualizar búsqueda
  void actualizarBusqueda(String query) {
    state = state.copyWith(terminoBusqueda: query);
  }

  /// Aplicar filtro de fechas
  void aplicarFiltroFechas(DateTimeRange? fechas) {
    state = state.copyWith(filtroFechas: fechas);
  }

  /// Aplicar filtro de estado
  void aplicarFiltroEstado(String? estado) {
    state = state.copyWith(filtroEstado: estado);
  }

  /// Limpiar todos los filtros aplicados
  void limpiarFiltros() {
    state = state.copyWith(
      terminoBusqueda: '',
      filtroFechas: null,
      filtroEstado: null,
    );
  }
}

// Provider para el estado de ventas
final ventasStateProvider =
    StateNotifierProvider<VentasStateNotifier, VentasState>((ref) {
      return VentasStateNotifier(ref);
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

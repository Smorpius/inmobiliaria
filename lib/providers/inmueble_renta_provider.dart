import '../utils/applogger.dart';
import '../models/resumen_renta_model.dart';
import '../models/movimiento_renta_model.dart';
import '../services/movimientos_renta_service.dart';
import '../models/comprobante_movimiento_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/models/inmueble_model.dart';
import '../controllers/movimiento_renta_controller.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:inmobiliaria/providers/providers_global.dart';
import 'package:inmobiliaria/providers/contrato_renta_providers.dart';

/// Proveedor para el servicio de movimientos de renta,
/// que internamente llama a los procedimientos almacenados
/// (RegistrarMovimientoRenta, ObtenerMovimientosPorInmueble, etc.)
final movimientosRentaServiceProvider = Provider<MovimientosRentaService>((
  ref,
) {
  final dbService = ref.watch(databaseServiceProvider);
  return MovimientosRentaService(dbService);
});

/// Proveedor para el controlador de movimientos de renta,
/// que encapsula la lógica de validación y llama al servicio.
final movimientoRentaControllerProvider = Provider<MovimientoRentaController>((
  ref,
) {
  final service = ref.watch(movimientosRentaServiceProvider);
  return MovimientoRentaController(rentaService: service);
});

/// Proveedor Future para obtener todos los movimientos de un inmueble
/// usando el procedimiento almacenado ObtenerMovimientosPorInmueble.
final movimientosPorInmuebleProvider =
    FutureProvider.family<List<MovimientoRenta>, int>((ref, idInmueble) async {
      final controller = ref.watch(movimientoRentaControllerProvider);
      return controller.obtenerMovimientosPorInmueble(idInmueble);
    });

/// Proveedor Future para obtener todos los comprobantes de un movimiento
/// usando el procedimiento almacenado ObtenerComprobantesPorMovimiento.
final comprobantesPorMovimientoProvider =
    FutureProvider.family<List<ComprobanteMovimiento>, int>((
      ref,
      idMovimiento,
    ) async {
      final controller = ref.watch(movimientoRentaControllerProvider);
      return controller.obtenerComprobantes(idMovimiento);
    });

/// Proveedor Future para obtener el resumen de un inmueble
/// en un mes y año específicos, usando ObtenerResumenMovimientosRenta.
final resumenRentaPorMesProvider =
    FutureProvider.family<ResumenRenta, ResumenRentaParams>((
      ref,
      params,
    ) async {
      final controller = ref.watch(movimientoRentaControllerProvider);
      return controller.obtenerResumenMovimientos(
        params.idInmueble,
        params.anio,
        params.mes,
      );
    });

/// Parámetros para solicitar el resumen de renta de un inmueble.
class ResumenRentaParams {
  final int idInmueble;
  final int anio;
  final int mes;

  ResumenRentaParams({
    required this.idInmueble,
    required this.anio,
    required this.mes,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResumenRentaParams) return false;
    return idInmueble == other.idInmueble &&
        anio == other.anio &&
        mes == other.mes;
  }

  @override
  int get hashCode => Object.hash(idInmueble, anio, mes);
}

/// Estado de los movimientos de renta para manejar en formularios o vistas.
class MovimientosRentaState {
  final List<MovimientoRenta> movimientos;
  final bool cargando;
  final String? error;
  final int? ultimoIdRegistrado;
  final DateTime? ultimaActualizacion;

  MovimientosRentaState({
    required this.movimientos,
    required this.cargando,
    this.error,
    this.ultimoIdRegistrado,
    this.ultimaActualizacion,
  });

  /// Obtiene los movimientos filtrados por tipo
  List<MovimientoRenta> get ingresos =>
      movimientos.where((m) => m.tipoMovimiento == 'ingreso').toList();

  /// Obtiene los movimientos filtrados por tipo
  List<MovimientoRenta> get egresos =>
      movimientos.where((m) => m.tipoMovimiento == 'egreso').toList();

  /// Obtiene el saldo actual calculado
  double get saldoActual {
    final totalIngresos = ingresos.fold(0.0, (sum, m) => sum + m.monto);
    final totalEgresos = egresos.fold(0.0, (sum, m) => sum + m.monto);
    return totalIngresos - totalEgresos;
  }

  MovimientosRentaState copyWith({
    List<MovimientoRenta>? movimientos,
    bool? cargando,
    String? error,
    int? ultimoIdRegistrado,
    DateTime? ultimaActualizacion,
    bool clearError = false,
  }) {
    return MovimientosRentaState(
      movimientos: movimientos ?? this.movimientos,
      cargando: cargando ?? this.cargando,
      error: clearError ? null : error ?? this.error,
      ultimoIdRegistrado: ultimoIdRegistrado ?? this.ultimoIdRegistrado,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }
}

/// Notifier para manejar el estado de los movimientos de renta,
/// permitiendo registrar o eliminar movimientos y reflejarlos en la UI.
class MovimientosRentaNotifier extends StateNotifier<MovimientosRentaState> {
  final MovimientoRentaController _controller;
  bool _disposed = false;

  MovimientosRentaNotifier(this._controller)
    : super(MovimientosRentaState(movimientos: [], cargando: false));

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Carga los movimientos de un inmueble y actualiza el estado.
  Future<void> cargarMovimientos(int idInmueble) async {
    if (_disposed) return;

    state = state.copyWith(cargando: true, clearError: true);
    try {
      AppLogger.info('Cargando movimientos para inmueble: $idInmueble');
      final lista = await _controller.obtenerMovimientosPorInmueble(idInmueble);

      if (_disposed) return;

      state = state.copyWith(
        movimientos: lista,
        cargando: false,
        ultimaActualizacion: DateTime.now(),
      );
      AppLogger.info('${lista.length} movimientos cargados correctamente');
    } catch (e, stackTrace) {
      AppLogger.error('Error al cargar movimientos', e, stackTrace);

      if (_disposed) return;

      state = state.copyWith(
        cargando: false,
        error: 'Error al cargar movimientos: ${e.toString()}',
      );
    }
  }

  /// Registra un nuevo movimiento de renta y recarga la lista.
  Future<bool> registrarMovimiento(MovimientoRenta movimiento) async {
    if (_disposed) return false;

    state = state.copyWith(cargando: true, clearError: true);
    try {
      AppLogger.info(
        'Registrando nuevo movimiento para inmueble: ${movimiento.idInmueble}',
      );
      final idMovimiento = await _controller.registrarMovimiento(movimiento);
      final lista = await _controller.obtenerMovimientosPorInmueble(
        movimiento.idInmueble,
      );

      if (_disposed) return false;

      state = state.copyWith(
        movimientos: lista,
        ultimoIdRegistrado: idMovimiento,
        cargando: false,
        ultimaActualizacion: DateTime.now(),
      );

      AppLogger.info(
        'Movimiento registrado correctamente con ID: $idMovimiento',
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error al registrar movimiento', e, stackTrace);

      if (_disposed) return false;

      state = state.copyWith(
        cargando: false,
        error: 'Error al registrar movimiento: ${e.toString()}',
      );
      return false;
    }
  }

  /// Agrega un comprobante a un movimiento y actualiza el estado.
  Future<bool> agregarComprobante(ComprobanteMovimiento comprobante) async {
    if (_disposed) return false;

    state = state.copyWith(cargando: true, clearError: true);
    try {
      AppLogger.info(
        'Agregando comprobante para movimiento: ${comprobante.idMovimiento}',
      );
      final idComprobante = await _controller.agregarComprobante(comprobante);

      // Actualizar la lista de comprobantes invalidando el provider correspondiente
      // para que la siguiente vez que se solicite, se recargue desde la base de datos
      // (esto se hace a nivel de UI con ref.invalidate())

      // También actualizamos la marca de tiempo para indicar que hubo una actualización
      if (!_disposed) {
        state = state.copyWith(
          cargando: false,
          ultimaActualizacion: DateTime.now(),
          clearError: true,
        );
      }

      AppLogger.info(
        'Comprobante registrado correctamente con ID: $idComprobante',
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error al agregar comprobante', e, stackTrace);

      if (!_disposed) {
        state = state.copyWith(
          cargando: false,
          error: 'Error al agregar comprobante: ${e.toString()}',
        );
      }
      return false;
    }
  }

  /// Elimina un movimiento y recarga la lista.
  Future<bool> eliminarMovimiento(int idMovimiento, int idInmueble) async {
    if (_disposed) return false;

    state = state.copyWith(cargando: true, clearError: true);
    try {
      AppLogger.info('Eliminando movimiento: $idMovimiento');
      await _controller.eliminarMovimiento(idMovimiento);
      final lista = await _controller.obtenerMovimientosPorInmueble(idInmueble);

      if (_disposed) return false;

      state = state.copyWith(
        movimientos: lista,
        cargando: false,
        ultimaActualizacion: DateTime.now(),
      );

      AppLogger.info('Movimiento eliminado correctamente');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error al eliminar movimiento', e, stackTrace);

      if (_disposed) return false;

      state = state.copyWith(
        cargando: false,
        error: 'Error al eliminar movimiento: ${e.toString()}',
      );
      return false;
    }
  }

  /// Filtra los movimientos por mes y año
  List<MovimientoRenta> filtrarPorMesAnio(int mes, int anio) {
    final mesStr = mes.toString().padLeft(2, '0');
    final mesCorrespondiente = '$anio-$mesStr';

    return state.movimientos
        .where((m) => m.mesCorrespondiente == mesCorrespondiente)
        .toList();
  }
}

/// Proveedor StateNotifier para manejar movimientos en un inmueble específico.
final movimientosRentaStateProvider = StateNotifierProvider.family<
  MovimientosRentaNotifier,
  MovimientosRentaState,
  int
>((ref, idInmueble) {
  final controller = ref.watch(movimientoRentaControllerProvider);
  return MovimientosRentaNotifier(controller);
});

/// Provider para obtener inmuebles que están actualmente rentados
final inmueblesRentadosProvider = FutureProvider<List<Inmueble>>((ref) async {
  try {
    final controller = ref.watch(inmuebleControllerProvider);
    return await controller.buscarInmuebles(idEstado: 5); // Estado rentado = 5
  } catch (e, stack) {
    AppLogger.error('Error al obtener inmuebles rentados', e, stack);
    return [];
  }
});

/// Provider que expone el resumen de todos los contratos de renta activos
final resumenContratosRentaProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  try {
    final contratos = await ref.watch(contratosRentaProvider.future);

    // Filtrar solo contratos activos
    final contratosActivos = contratos.where((c) => c.idEstado == 1).toList();

    // Calcular métricas
    final totalContratos = contratosActivos.length;
    final ingresoMensualEstimado = contratosActivos.fold<double>(
      0.0,
      (total, contrato) => total + contrato.montoMensual,
    );

    final contratosProximosAVencer =
        contratosActivos.where((c) {
          final diasRestantes = c.fechaFin.difference(DateTime.now()).inDays;
          return diasRestantes >= 0 && diasRestantes <= 30;
        }).toList();

    return {
      'total_contratos': totalContratos,
      'ingreso_mensual_estimado': ingresoMensualEstimado,
      'contratos_por_vencer': contratosProximosAVencer.length,
      'fecha_actualizacion': DateTime.now(),
    };
  } catch (e, stack) {
    AppLogger.error('Error al obtener resumen de contratos', e, stack);
    return {
      'total_contratos': 0,
      'ingreso_mensual_estimado': 0.0,
      'contratos_por_vencer': 0,
      'error': e.toString(),
    };
  }
});

/// Provider para filtrar movimientos por el período seleccionado
final movimientosFiltradosPorPeriodoProvider = Provider.family<
  List<MovimientoRenta>,
  ({int idInmueble, DateTimeRange periodo})
>((ref, params) {
  final todosLosMovimientos = ref.watch(
    movimientosPorInmuebleProvider(params.idInmueble),
  );

  return todosLosMovimientos.when(
    data: (movimientos) {
      return movimientos.where((movimiento) {
        final fechaMovimiento = movimiento.fechaMovimiento;

        // Normalizar las fechas para comparación (sin hora, minutos, etc.)
        final fechaInicio = DateTime(
          params.periodo.start.year,
          params.periodo.start.month,
          params.periodo.start.day,
        );

        final fechaFin = DateTime(
          params.periodo.end.year,
          params.periodo.end.month,
          params.periodo.end.day,
          23,
          59,
          59, // Incluir todo el día final
        );

        final fechaMovimientoNormalizada = DateTime(
          fechaMovimiento.year,
          fechaMovimiento.month,
          fechaMovimiento.day,
        );

        // Incluir fechas que están dentro del rango, incluyendo los límites
        return (fechaMovimientoNormalizada.isAtSameMomentAs(fechaInicio) ||
                fechaMovimientoNormalizada.isAfter(fechaInicio)) &&
            (fechaMovimientoNormalizada.isAtSameMomentAs(fechaFin) ||
                fechaMovimientoNormalizada.isBefore(fechaFin));
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider para calcular el balance de un período específico
final balancePeriodoProvider =
    Provider.family<Map<String, double>, List<MovimientoRenta>>((
      ref,
      movimientos,
    ) {
      double totalIngresos = 0;
      double totalEgresos = 0;

      for (final movimiento in movimientos) {
        if (movimiento.tipoMovimiento == 'ingreso') {
          totalIngresos += movimiento.monto;
        } else {
          totalEgresos += movimiento.monto;
        }
      }

      return {
        'ingresos': totalIngresos,
        'egresos': totalEgresos,
        'balance': totalIngresos - totalEgresos,
      };
    });

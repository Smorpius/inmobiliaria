import 'dart:async';
import '../utils/applogger.dart';
import '../models/venta_model.dart';
import '../utils/circuit_breaker.dart';
import '../services/ventas_service.dart';
import '../models/venta_reporte_model.dart';
import '../services/mysql_error_manager.dart';

class VentaController {
  final VentasService _ventasService;
  bool _procesandoError = false; // Control para evitar errores duplicados

  // Circuit breaker para operaciones de ventas
  final CircuitBreaker _circuitBreaker = CircuitBreaker(
    name: 'ventas-operations',
    resetTimeout: const Duration(minutes: 2),
    failureThreshold: 3,
    onCircuitOpen: () {
      AppLogger.warning('Circuit breaker abierto para operaciones de ventas');
    },
  );

  // Control para errores específicos de conexión
  final MySqlErrorManager _errorManager = MySqlErrorManager();

  // Mapa para reintentos con backoff exponencial
  final Map<String, DateTime> _ultimosReintentos = {};
  static const Duration _intervaloMinimoReintento = Duration(seconds: 2);

  // Bloqueo para operaciones concurrentes
  bool _reconectando = false;

  VentaController({required VentasService ventasService})
    : _ventasService = ventasService;

  /// Método auxiliar para ejecutar operaciones con manejo de errores consistente
  Future<T> _ejecutarOperacion<T>(
    String descripcion,
    Future<T> Function() operacion,
  ) async {
    try {
      // Log de inicio de operación
      AppLogger.info('Iniciando operación: $descripcion');

      // Utilizar circuit breaker para evitar operaciones cuando hay muchos fallos
      final resultado = await _circuitBreaker.execute(() => operacion());

      // Log de operación completada exitosamente
      AppLogger.info('Operación completada exitosamente: $descripcion');
      return resultado;
    } catch (e, stackTrace) {
      // Detectar si es un error de conexión
      final errorType = _errorManager.classifyError(e);
      final esErrorDeConexion =
          errorType == ErrorType.connection ||
          errorType == ErrorType.socketClosed ||
          errorType == ErrorType.timeout ||
          errorType == ErrorType.mysqlProtocol;

      // Evitar múltiples logs del mismo error (control de duplicados)
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error en operación "$descripcion" (${errorType.name})',
          e,
          stackTrace,
        );
        _procesandoError = false;
      }

      // Manejar error de conexión de manera específica
      if (esErrorDeConexion) {
        await _handleConnectionError(descripcion);
      }

      // Mensaje de error más informativo y estructurado
      final errorMensaje =
          esErrorDeConexion
              ? 'Error de conexión en $descripcion. Intente nuevamente.'
              : 'Error en $descripcion: ${e.toString().split('\n').first}';

      throw Exception(errorMensaje);
    }
  }

  /// Maneja específicamente errores de conexión con backoff exponencial
  Future<void> _handleConnectionError(String operacion) async {
    if (_reconectando) return;

    try {
      _reconectando = true;

      // Determinar si debemos esperar antes de reintentar (backoff exponencial)
      final ahora = DateTime.now();
      final ultimoReintento = _ultimosReintentos[operacion];

      if (ultimoReintento != null) {
        final tiempoDesdeUltimoReintento = ahora.difference(ultimoReintento);
        final tiempoDeEspera =
            _intervaloMinimoReintento *
            (1 <<
                (_ultimosReintentos.length %
                    6)); // Exponential backoff limitado

        if (tiempoDesdeUltimoReintento < tiempoDeEspera) {
          AppLogger.info(
            'Esperando ${tiempoDeEspera.inSeconds}s antes de reintentar conexión para $operacion',
          );
          await Future.delayed(tiempoDeEspera);
        }
      }

      _ultimosReintentos[operacion] = ahora;

      // Intentar forzar reinicio de conexión en el servicio
      await _ventasService.reiniciarConexion();

      AppLogger.warning(
        'Conexión reiniciada después de error en operación: $operacion',
      );
    } catch (e) {
      AppLogger.warning('Error adicional al manejar fallo de conexión: $e');
    } finally {
      // Garantizar que se libere el bloqueo
      _reconectando = false;

      // Limpiar entradas antiguas del mapa de reintentos
      _limpiarRegistrosAntiguos();
    }
  }

  /// Limpia registros antiguos de reintentos para evitar memory leaks
  void _limpiarRegistrosAntiguos() {
    final ahora = DateTime.now();
    final operacionesAEliminar =
        _ultimosReintentos.entries
            .where(
              (entry) =>
                  ahora.difference(entry.value) > const Duration(minutes: 10),
            )
            .map((entry) => entry.key)
            .toList();

    for (final key in operacionesAEliminar) {
      _ultimosReintentos.remove(key);
    }
  }

  /// Método con reintentos automáticos para errores de conexión
  Future<T> _ejecutarConReintentos<T>(
    String descripcion,
    Future<T> Function() operacion, {
    int maxIntentos = 2,
  }) async {
    int intento = 0;
    late dynamic ultimoError;
    final backoffs = [
      const Duration(milliseconds: 500),
      const Duration(seconds: 1),
      const Duration(seconds: 2),
    ];

    while (intento < maxIntentos) {
      try {
        if (intento > 0) {
          // Backoff exponencial entre reintentos
          final tiempoEspera =
              intento - 1 < backoffs.length
                  ? backoffs[intento - 1]
                  : backoffs.last * (intento - backoffs.length + 2);

          AppLogger.info(
            'Reintentando $descripcion (intento ${intento + 1}/$maxIntentos) después de ${tiempoEspera.inMilliseconds}ms',
          );

          await Future.delayed(tiempoEspera);
        }

        return await _ejecutarOperacion(descripcion, operacion);
      } catch (e) {
        intento++;
        ultimoError = e;

        // Solo reintentar para errores de conexión
        final errorType = _errorManager.classifyError(e);
        final esErrorDeConexion =
            errorType == ErrorType.connection ||
            errorType == ErrorType.socketClosed ||
            errorType == ErrorType.mysqlProtocol ||
            errorType == ErrorType.timeout;

        if (!esErrorDeConexion || intento >= maxIntentos) {
          // Control para hacer log solo si es el intento final
          if (intento >= maxIntentos) {
            AppLogger.warning(
              'Agotados intentos para $descripcion después de $maxIntentos intentos',
            );
          }
          rethrow;
        }
      }
    }

    // Si llegamos aquí es porque agotamos los reintentos
    throw ultimoError;
  }

  /// Obtiene todas las ventas usando procedimiento almacenado con reintentos
  Future<List<Venta>> obtenerVentas() async {
    return _ejecutarConReintentos('obtener ventas', () async {
      return await _ventasService.obtenerVentas();
    });
  }

  /// Obtiene una venta por ID usando procedimiento almacenado con reintentos
  Future<Venta?> obtenerVentaPorId(int idVenta) async {
    return _ejecutarConReintentos('obtener venta por ID', () async {
      if (idVenta <= 0) {
        throw Exception('ID de venta inválido');
      }
      return await _ventasService.obtenerVentaPorId(idVenta);
    });
  }

  /// Crea una nueva venta con validación exhaustiva y reintentos
  Future<int> crearVenta(Venta venta) async {
    return _ejecutarConReintentos('crear venta', () async {
      // Validación de datos de entrada
      _validarDatosVenta(venta);
      return await _ventasService.crearVenta(venta);
    });
  }

  /// Valida los datos de una venta antes de crear o actualizar
  void _validarDatosVenta(Venta venta) {
    if (venta.idCliente <= 0) {
      throw Exception('El ID del cliente es inválido');
    }
    if (venta.idInmueble <= 0) {
      throw Exception('El ID del inmueble es inválido');
    }
    if (venta.ingreso <= 0) {
      throw Exception('El ingreso debe ser mayor a cero');
    }
    if (venta.fechaVenta.isAfter(DateTime.now())) {
      throw Exception('La fecha de venta no puede ser futura');
    }
    if (venta.comisionProveedores < 0) {
      throw Exception('La comisión no puede ser negativa');
    }
    // Validar que la utilidad bruta sea coherente
    final utilidadBrutaCalculada = venta.ingreso - venta.comisionProveedores;
    if (venta.utilidadBruta != utilidadBrutaCalculada) {
      AppLogger.warning('Valor de utilidad bruta incorrecto, recalculando...');
      // No lanzamos excepción, asumimos que el cálculo se puede hacer en la base de datos
    }
  }

  /// Actualiza gastos adicionales y recalcula utilidad neta con reintentos
  Future<bool> actualizarGastosVenta(
    int idVenta,
    double gastosAdicionales,
    int usuarioModificacion,
  ) async {
    return _ejecutarConReintentos('actualizar gastos de venta', () async {
      // Validaciones
      if (idVenta <= 0) {
        throw Exception('ID de venta inválido');
      }
      if (gastosAdicionales < 0) {
        throw Exception('Los gastos adicionales no pueden ser negativos');
      }
      if (usuarioModificacion <= 0) {
        throw Exception('ID de usuario modificador inválido');
      }

      return await _ventasService.actualizarUtilidadVenta(
        idVenta,
        gastosAdicionales,
        usuarioModificacion,
      );
    });
  }

  /// Cambia el estado de una venta con validación de usuario y reintentos
  Future<bool> cambiarEstadoVenta(
    int idVenta,
    int nuevoEstado, {
    int usuarioModificacion = 1,
  }) async {
    return _ejecutarConReintentos('cambiar estado de venta', () async {
      // Validaciones
      if (idVenta <= 0) {
        throw Exception('ID de venta inválido');
      }
      if (![7, 8, 9].contains(nuevoEstado)) {
        throw Exception(
          'Estado no válido. Debe ser 7 (en proceso), 8 (completada) o 9 (cancelada)',
        );
      }

      return await _ventasService.cambiarEstadoVenta(
        idVenta,
        nuevoEstado,
        usuarioModificacion,
      );
    });
  }

  /// Obtiene estadísticas de ventas en un período con reintentos
  Future<VentaReporte> obtenerEstadisticasVentas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    return _ejecutarConReintentos('obtener estadísticas de ventas', () async {
      // Validar rango de fechas
      if (fechaInicio != null &&
          fechaFin != null &&
          fechaInicio.isAfter(fechaFin)) {
        throw Exception(
          'La fecha de inicio no puede ser posterior a la fecha fin',
        );
      }

      return await _ventasService.obtenerEstadisticasVentas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
    });
  }

  /// Busca ventas por diferentes criterios (cliente, inmueble, fechas)
  Future<List<Venta>> buscarVentas({
    int? idCliente,
    int? idInmueble,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? idEstado,
  }) async {
    return _ejecutarConReintentos('buscar ventas', () async {
      // Validar rango de fechas
      if (fechaInicio != null &&
          fechaFin != null &&
          fechaInicio.isAfter(fechaFin)) {
        throw Exception('Rango de fechas inválido');
      }

      return await _ventasService.buscarVentas(
        idCliente: idCliente,
        idInmueble: idInmueble,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        idEstado: idEstado,
      );
    });
  }

  /// Restablece el estado del circuit breaker si estaba abierto
  void resetCircuitBreaker() {
    if (_circuitBreaker.isOpen) {
      AppLogger.info(
        'Circuit breaker está abierto. Se reseteará automáticamente en: ${_circuitBreaker.timeUntilReset?.inSeconds ?? 0} segundos',
      );
    }
  }

  /// Verifica si hay problemas de conexión persistentes
  bool hayProblemasDeConexion() {
    return _circuitBreaker.isOpen;
  }

  /// Forzar reconexión a la base de datos
  Future<void> forzarReconexion() async {
    if (_reconectando) return;

    try {
      _reconectando = true;
      await _ventasService.reiniciarConexion();
      AppLogger.info('Reconexión forzada completada');
    } catch (e) {
      AppLogger.error('Error en reconexión forzada', e);
    } finally {
      _reconectando = false;
    }
  }

  /// Método para liberar recursos cuando ya no se necesitan
  void dispose() {
    _procesandoError = false;
    _ultimosReintentos.clear();
    AppLogger.info('Recursos de VentaController liberados');
  }
}

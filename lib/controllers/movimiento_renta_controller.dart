import 'package:intl/intl.dart';
import '../utils/applogger.dart';
import '../models/resumen_renta_model.dart';
import '../models/movimiento_renta_model.dart';
import '../services/movimientos_renta_service.dart';
import '../models/comprobante_movimiento_model.dart';

/// Controlador para la gestión de movimientos financieros asociados a rentas
///
/// Este controlador maneja la lógica de negocio para:
/// - Registrar ingresos (pagos de renta)
/// - Registrar egresos (gastos de mantenimiento, servicios, etc.)
/// - Obtener resúmenes financieros por inmueble/periodo
/// - Asociar comprobantes a los movimientos
class MovimientoRentaController {
  final MovimientosRentaService _service;
  bool _procesandoError = false;

  // Control para evitar operaciones concurrentes
  final Map<String, bool> _operacionesEnProgreso = {};

  // Constructor con inyección de dependencias para facilitar pruebas
  MovimientoRentaController({required MovimientosRentaService rentaService})
    : _service = rentaService;

  /// Método auxiliar para ejecutar operaciones con manejo de errores consistente
  Future<T> _ejecutarOperacion<T>(
    String descripcion,
    Future<T> Function() operacion, {
    bool permitirConcurrencia = false,
  }) async {
    // Evitar operaciones concurrentes del mismo tipo
    if (!permitirConcurrencia && _operacionesEnProgreso[descripcion] == true) {
      AppLogger.warning(
        'Operación "$descripcion" en progreso. Evitando operación duplicada.',
      );
      throw Exception('Operación en progreso, por favor espere');
    }

    try {
      _operacionesEnProgreso[descripcion] = true;
      AppLogger.info('Iniciando operación: $descripcion');

      final resultado = await operacion();

      AppLogger.info('Operación completada exitosamente: $descripcion');
      return resultado;
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;

        // Tratamiento especial para nuestras excepciones personalizadas
        if (e is MovimientoRentaException) {
          // Añadir información de la operación que se intentaba realizar
          final mensajeDetallado =
              'Error controlado en operación "$descripcion": ${e.mensaje}';
          final detalleOperacion =
              'Categoría: ${e.categoria}, Código: ${e.codigoError ?? "N/A"}';

          AppLogger.error(
            '$mensajeDetallado ($detalleOperacion)',
            e,
            stackTrace,
          );
        } else {
          // Para otras excepciones, registrar normalmente
          AppLogger.error('Error en operación "$descripcion"', e, stackTrace);
        }
        _procesandoError = false;
      }

      // Propagar el error con un mensaje amigable, preservando el tipo para las excepciones personalizadas
      if (e is MovimientoRentaException) {
        rethrow; // Propagar directamente la excepción personalizada
      } else {
        throw Exception('Error en $descripcion: ${_obtenerMensajeAmigable(e)}');
      }
    } finally {
      _operacionesEnProgreso[descripcion] = false;
    }
  }

  /// Registra un nuevo movimiento de renta con validaciones completas
  Future<int> registrarMovimiento(MovimientoRenta movimiento) {
    return _ejecutarOperacion('registrar movimiento de renta', () async {
      // Las validaciones ahora se manejan en el servicio
      return await _service.registrarMovimiento(movimiento);
    });
  }

  /// Agrega un comprobante a un movimiento con validaciones
  Future<int> agregarComprobante(ComprobanteMovimiento comprobante) {
    return _ejecutarOperacion('agregar comprobante', () async {
      // Las validaciones ahora se manejan en el servicio
      return await _service.agregarComprobante(comprobante);
    });
  }

  /// Obtiene los movimientos de un inmueble
  Future<List<MovimientoRenta>> obtenerMovimientosPorInmueble(int idInmueble) {
    return _ejecutarOperacion(
      'obtener movimientos',
      () async {
        return await _service.obtenerMovimientosPorInmueble(idInmueble);
      },
      permitirConcurrencia: true, // Permitir múltiples consultas de lectura
    );
  }

  /// Obtiene los comprobantes de un movimiento
  Future<List<ComprobanteMovimiento>> obtenerComprobantes(int idMovimiento) {
    return _ejecutarOperacion(
      'obtener comprobantes',
      () async {
        return await _service.obtenerComprobantes(idMovimiento);
      },
      permitirConcurrencia: true, // Permitir múltiples consultas de lectura
    );
  }

  /// Obtiene resumen de movimientos por mes con validaciones
  Future<ResumenRenta> obtenerResumenMovimientos(
    int idInmueble,
    int anio,
    int mes,
  ) {
    return _ejecutarOperacion(
      'obtener resumen de movimientos',
      () async {
        return await _service.obtenerResumenMovimientos(idInmueble, anio, mes);
      },
      permitirConcurrencia: true, // Permitir múltiples consultas de lectura
    );
  }

  /// Genera un balance mensual para todos los inmuebles
  Future<Map<String, dynamic>> generarBalanceMensual(int anio, int mes) {
    return _ejecutarOperacion('generar balance mensual', () async {
      // Obtener el periodo en formato YYYY-MM
      final periodoStr = '$anio-${mes.toString().padLeft(2, '0')}';

      // Obtener todos los movimientos del mes para todos los inmuebles
      final movimientos = await _service.obtenerMovimientosPorPeriodo(
        periodoStr,
      );

      // Calcular ingresos y egresos totales
      double ingresos = 0.0;
      double egresos = 0.0;

      for (var mov in movimientos) {
        if (mov.esIngreso) {
          ingresos += mov.monto;
        } else {
          egresos += mov.monto;
        }
      }

      // Agrupar por inmueble
      Map<int, Map<String, dynamic>> balancePorInmueble = {};

      for (var mov in movimientos) {
        if (!balancePorInmueble.containsKey(mov.idInmueble)) {
          balancePorInmueble[mov.idInmueble] = {
            'id_inmueble': mov.idInmueble,
            'nombre_inmueble': mov.nombreInmueble ?? 'Sin nombre',
            'ingresos': 0.0,
            'egresos': 0.0,
            'balance': 0.0,
          };
        }

        if (mov.esIngreso) {
          balancePorInmueble[mov.idInmueble]!['ingresos'] += mov.monto;
        } else {
          balancePorInmueble[mov.idInmueble]!['egresos'] += mov.monto;
        }

        // Actualizar balance
        balancePorInmueble[mov.idInmueble]!['balance'] =
            balancePorInmueble[mov.idInmueble]!['ingresos'] -
            balancePorInmueble[mov.idInmueble]!['egresos'];
      }

      return {
        'periodo': '$mes/$anio',
        'ingresos_totales': ingresos,
        'egresos_totales': egresos,
        'balance_total': ingresos - egresos,
        'rentabilidad':
            ingresos > 0 ? ((ingresos - egresos) / ingresos) * 100 : 0.0,
        'inmuebles': balancePorInmueble.values.toList(),
        'total_inmuebles': balancePorInmueble.length,
      };
    }, permitirConcurrencia: true);
  }

  /// Categoriza los movimientos por concepto para análisis estadístico
  Future<Map<String, dynamic>> categorizarMovimientos(
    int idInmueble,
    int anio,
    int mes,
  ) {
    return _ejecutarOperacion('categorizar movimientos', () async {
      // Obtener los movimientos del inmueble en el período
      final resumen = await _service.obtenerResumenMovimientos(
        idInmueble,
        anio,
        mes,
      );

      // Inicializar categorías
      final categorias = {
        'ingresos': <String, double>{
          'renta': 0.0,
          'depositos': 0.0,
          'otros_ingresos': 0.0,
        },
        'egresos': <String, double>{
          'mantenimiento': 0.0,
          'servicios': 0.0,
          'impuestos': 0.0,
          'administrativos': 0.0,
          'otros_gastos': 0.0,
        },
      };

      // Clasificar los movimientos según su concepto
      for (final movimiento in resumen.movimientos) {
        final concepto = movimiento.concepto.toLowerCase();

        if (movimiento.esIngreso) {
          if (concepto.contains('renta') || concepto.contains('alquiler')) {
            categorias['ingresos']!['renta'] =
                (categorias['ingresos']!['renta']!) + movimiento.monto;
          } else if (concepto.contains('depósito') ||
              concepto.contains('deposito') ||
              concepto.contains('garantía')) {
            categorias['ingresos']!['depositos'] =
                (categorias['ingresos']!['depositos']!) + movimiento.monto;
          } else {
            categorias['ingresos']!['otros_ingresos'] =
                (categorias['ingresos']!['otros_ingresos']!) + movimiento.monto;
          }
        } else {
          if (concepto.contains('manteni') || concepto.contains('reparac')) {
            categorias['egresos']!['mantenimiento'] =
                (categorias['egresos']!['mantenimiento']!) + movimiento.monto;
          } else if (concepto.contains('agua') ||
              concepto.contains('luz') ||
              concepto.contains('gas') ||
              concepto.contains('internet')) {
            categorias['egresos']!['servicios'] =
                (categorias['egresos']!['servicios']!) + movimiento.monto;
          } else if (concepto.contains('impuesto') ||
              concepto.contains('predial')) {
            categorias['egresos']!['impuestos'] =
                (categorias['egresos']!['impuestos']!) + movimiento.monto;
          } else if (concepto.contains('administra') ||
              concepto.contains('gestion')) {
            categorias['egresos']!['administrativos'] =
                (categorias['egresos']!['administrativos']!) + movimiento.monto;
          } else {
            categorias['egresos']!['otros_gastos'] =
                (categorias['egresos']!['otros_gastos']!) + movimiento.monto;
          }
        }
      }

      return {
        'inmueble_id': idInmueble,
        'periodo': '$anio-${mes.toString().padLeft(2, '0')}',
        'resumen': {
          'total_ingresos': resumen.totalIngresos,
          'total_egresos': resumen.totalEgresos,
          'balance': resumen.balance,
        },
        'categorias': categorias,
      };
    }, permitirConcurrencia: true);
  }

  /// Analiza la rentabilidad de un inmueble a lo largo del tiempo
  Future<Map<String, dynamic>> analizarRentabilidadInmueble(
    int idInmueble,
    int periodoMeses,
  ) {
    return _ejecutarOperacion('analizar rentabilidad histórica', () async {
      // Obtener fecha límite (hacia atrás)
      final ahora = DateTime.now();
      final fechaInicio = DateTime(ahora.year, ahora.month - periodoMeses, 1);

      // Obtener todos los movimientos del inmueble
      final movimientos = await _service.obtenerMovimientosPorInmueble(
        idInmueble,
      );

      // Filtrar por periodo
      final movimientosPeriodo =
          movimientos
              .where((m) => m.fechaMovimiento.isAfter(fechaInicio))
              .toList();

      // Agrupar por mes
      final Map<String, Map<String, dynamic>> datosPorMes = {};

      for (final mov in movimientosPeriodo) {
        final mesKey = DateFormat('yyyy-MM').format(mov.fechaMovimiento);

        if (!datosPorMes.containsKey(mesKey)) {
          datosPorMes[mesKey] = {
            'ingresos': 0.0,
            'egresos': 0.0,
            'balance': 0.0,
            'fecha': DateTime(
              mov.fechaMovimiento.year,
              mov.fechaMovimiento.month,
              1,
            ),
          };
        }

        if (mov.esIngreso) {
          datosPorMes[mesKey]!['ingresos'] += mov.monto;
        } else {
          datosPorMes[mesKey]!['egresos'] += mov.monto;
        }

        datosPorMes[mesKey]!['balance'] =
            datosPorMes[mesKey]!['ingresos'] - datosPorMes[mesKey]!['egresos'];
      }

      // Convertir a lista para ordenar cronológicamente
      final datosMensuales =
          datosPorMes.entries
              .map((e) => e.value)
              .toList()
              .cast<Map<String, dynamic>>();

      // Ordenar por fecha
      datosMensuales.sort(
        (a, b) => (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime),
      );

      // Calcular métricas clave
      final rentabilidadPromedio =
          datosMensuales.isEmpty
              ? 0.0
              : datosMensuales.fold(
                    0.0,
                    (sum, item) => sum + (item['balance'] as double),
                  ) /
                  datosMensuales.length;

      final tendencia = _calcularTendencia(datosMensuales);

      return {
        'inmueble_id': idInmueble,
        'periodo_meses': periodoMeses,
        'fecha_inicio': fechaInicio,
        'fecha_fin': ahora,
        'datos_mensuales': datosMensuales,
        'rentabilidad_promedio_mensual': rentabilidadPromedio,
        'tendencia': tendencia,
        'meses_rentables': datosMensuales.where((m) => m['balance'] > 0).length,
        'meses_con_perdida':
            datosMensuales.where((m) => m['balance'] < 0).length,
      };
    }, permitirConcurrencia: true);
  }

  /// Calcula la tendencia de rentabilidad (creciente, decreciente o estable)
  String _calcularTendencia(List<Map<String, dynamic>> datosMensuales) {
    if (datosMensuales.length < 3) return 'insuficientes_datos';

    // Tomar los últimos tres meses para ver la tendencia reciente
    final ultimos3Meses = datosMensuales.sublist(
      datosMensuales.length - 3,
      datosMensuales.length,
    );

    final primero = ultimos3Meses.first['balance'] as double;
    final ultimo = ultimos3Meses.last['balance'] as double;

    if ((ultimo - primero).abs() < (primero * 0.05)) {
      return 'estable'; // Si la diferencia es menor al 5% del valor inicial
    }

    return ultimo > primero ? 'creciente' : 'decreciente';
  }

  /// Compara rentabilidad entre varios inmuebles
  Future<List<Map<String, dynamic>>> compararRentabilidadInmuebles(
    List<int> idsInmuebles,
    int periodoMeses,
  ) {
    return _ejecutarOperacion('comparar rentabilidad', () async {
      final resultados = <Map<String, dynamic>>[];

      for (final idInmueble in idsInmuebles) {
        final analisis = await analizarRentabilidadInmueble(
          idInmueble,
          periodoMeses,
        );

        resultados.add({
          'inmueble_id': idInmueble,
          'rentabilidad_mensual': analisis['rentabilidad_promedio_mensual'],
          'tendencia': analisis['tendencia'],
          'meses_rentables': analisis['meses_rentables'],
          'roi_estimado':
              analisis['rentabilidad_promedio_mensual'] * 12, // ROI anual
        });
      }

      // Ordenar de mayor a menor rentabilidad
      resultados.sort(
        (a, b) => (b['rentabilidad_mensual'] as double).compareTo(
          a['rentabilidad_mensual'] as double,
        ),
      );

      return resultados;
    }, permitirConcurrencia: true);
  }

  /// Elimina un movimiento con confirmación
  Future<bool> eliminarMovimiento(int idMovimiento) {
    return _ejecutarOperacion('eliminar movimiento', () async {
      return await _service.eliminarMovimiento(idMovimiento);
    });
  }

  /// Procesa movimientos en lote (útil para importaciones)
  Future<Map<String, dynamic>> procesarMovimientosEnLote(
    List<MovimientoRenta> movimientos,
  ) {
    return _ejecutarOperacion('procesar movimientos en lote', () async {
      final resultados = <String, dynamic>{
        'exitos': 0,
        'errores': 0,
        'detalles': <Map<String, dynamic>>[],
      };

      for (final movimiento in movimientos) {
        try {
          final idMovimiento = await _service.registrarMovimiento(movimiento);
          resultados['exitos']++;
          resultados['detalles'].add({
            'exitoso': true,
            'id': idMovimiento,
            'concepto': movimiento.concepto,
          });
        } catch (e) {
          resultados['errores']++;

          // Extraer mensaje amigable para el usuario
          String mensajeError;
          if (e is MovimientoRentaException) {
            mensajeError = e.mensaje;
          } else {
            mensajeError = _obtenerMensajeAmigable(e);
          }

          resultados['detalles'].add({
            'exitoso': false,
            'concepto': movimiento.concepto,
            'error': mensajeError,
          });
        }
      }

      return resultados;
    });
  }

  /// Genera reporte mensual de rendimientos por propiedad
  Future<Map<String, dynamic>> generarReporteRendimientoPropiedades(
    int anio,
    int mes,
  ) {
    return _ejecutarOperacion('generar reporte rendimiento', () async {
      // Obtener el periodo en formato YYYY-MM
      final periodo = '$anio-${mes.toString().padLeft(2, '0')}';

      // Obtener todos los movimientos del periodo
      final movimientos = await _service.obtenerMovimientosPorPeriodo(periodo);

      // Agrupar por inmueble para análisis de rendimiento
      final Map<int, Map<String, dynamic>> rendimientoPorInmueble = {};

      // Procesar movimientos por inmueble
      for (final mov in movimientos) {
        if (!rendimientoPorInmueble.containsKey(mov.idInmueble)) {
          rendimientoPorInmueble[mov.idInmueble] = {
            'id_inmueble': mov.idInmueble,
            'nombre_inmueble': mov.nombreInmueble ?? 'Sin nombre',
            'ingresos': 0.0,
            'egresos': 0.0,
            'balance': 0.0,
            'roi': 0.0,
            'detalle_ingresos': <String, double>{},
            'detalle_egresos': <String, double>{},
          };
        }

        // Acumular montos
        if (mov.esIngreso) {
          rendimientoPorInmueble[mov.idInmueble]!['ingresos'] += mov.monto;

          // Agrupar ingresos por concepto
          final concepto = _normalizarConcepto(mov.concepto);
          rendimientoPorInmueble[mov
                  .idInmueble]!['detalle_ingresos'][concepto] =
              (rendimientoPorInmueble[mov
                      .idInmueble]!['detalle_ingresos'][concepto] ??
                  0.0) +
              mov.monto;
        } else {
          rendimientoPorInmueble[mov.idInmueble]!['egresos'] += mov.monto;

          // Agrupar egresos por concepto
          final concepto = _normalizarConcepto(mov.concepto);
          rendimientoPorInmueble[mov.idInmueble]!['detalle_egresos'][concepto] =
              (rendimientoPorInmueble[mov
                      .idInmueble]!['detalle_egresos'][concepto] ??
                  0.0) +
              mov.monto;
        }
      }

      // Calcular balance y ROI para cada inmueble
      for (final idInmueble in rendimientoPorInmueble.keys) {
        final datos = rendimientoPorInmueble[idInmueble]!;

        // Calcular balance (ingresos - egresos)
        datos['balance'] = datos['ingresos'] - datos['egresos'];

        // Calcular ROI (Return On Investment): balance / egresos
        // Si no hay egresos, el ROI es 0 para evitar división por cero
        if (datos['egresos'] > 0) {
          datos['roi'] = datos['balance'] / datos['egresos'] * 100;
        }
      }

      // Preparar resultado agrupando por inmueble con métricas agregadas
      final resultado = {
        'periodo': '$mes/$anio',
        'fecha_reporte': DateTime.now().toIso8601String(),
        'inmuebles': rendimientoPorInmueble.values.toList(),
        'total_inmuebles': rendimientoPorInmueble.length,
        'total_ingresos': rendimientoPorInmueble.values.fold(
          0.0,
          (sum, item) => sum + (item['ingresos'] as double),
        ),
        'total_egresos': rendimientoPorInmueble.values.fold(
          0.0,
          (sum, item) => sum + (item['egresos'] as double),
        ),
        'balance_global': rendimientoPorInmueble.values.fold(
          0.0,
          (sum, item) => sum + (item['balance'] as double),
        ),
        'roi_promedio':
            rendimientoPorInmueble.isEmpty
                ? 0.0
                : rendimientoPorInmueble.values.fold(
                      0.0,
                      (sum, item) => sum + (item['roi'] as double),
                    ) /
                    rendimientoPorInmueble.length,
      };

      return resultado;
    }, permitirConcurrencia: true);
  }

  /// Normaliza un concepto para agrupación en reportes
  String _normalizarConcepto(String concepto) {
    final conceptoLower = concepto.toLowerCase();

    if (conceptoLower.contains('renta') || conceptoLower.contains('alquiler')) {
      return 'renta';
    } else if (conceptoLower.contains('manten') ||
        conceptoLower.contains('repar')) {
      return 'mantenimiento';
    } else if (conceptoLower.contains('servicio') ||
        conceptoLower.contains('agua') ||
        conceptoLower.contains('luz') ||
        conceptoLower.contains('gas')) {
      return 'servicios';
    } else if (conceptoLower.contains('impuesto') ||
        conceptoLower.contains('predial')) {
      return 'impuestos';
    } else if (conceptoLower.contains('depósito') ||
        conceptoLower.contains('deposito')) {
      return 'deposito';
    } else {
      return 'otros';
    }
  }

  /// Obtiene un mensaje de error más amigable para el usuario
  String _obtenerMensajeAmigable(dynamic error) {
    final mensaje = error.toString();

    // Si ya tenemos una excepción personalizada, usar su mensaje directamente
    if (error is MovimientoRentaException) {
      return error.mensaje;
    }

    // Errores comunes de MySQL
    if (mensaje.contains('Duplicate entry')) {
      return 'Ya existe un registro con esos datos';
    }

    if (mensaje.contains('foreign key constraint fails')) {
      return 'Operación no permitida: el registro está relacionado con otros datos';
    }

    if (mensaje.contains('estado_inmueble')) {
      return 'El inmueble no está disponible para esta operación';
    }

    if (mensaje.contains('SQLSTATE')) {
      // Extraer el mensaje amigable de errores SQL
      final regex = RegExp(r"MESSAGE_TEXT = '(.*?)'");
      final match = regex.firstMatch(mensaje);
      if (match != null) {
        return match.group(1) ?? mensaje;
      }
    }

    // Si no es un error conocido, devolver solo la primera línea
    final primeraLinea = mensaje.split('\n').first;
    if (primeraLinea.length > 100) {
      return '${primeraLinea.substring(0, 100)}...';
    }

    return primeraLinea;
  }
}

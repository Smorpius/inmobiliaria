import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:inmobiliaria/models/movimiento_renta_model.dart';

class ResumenRenta {
  static final Logger _logger = Logger('ResumenRentaModel');

  final double totalIngresos;
  final double totalEgresos;
  final List<MovimientoRenta> movimientos;
  final DateTime? fechaResumen;
  final int? idInmueble;
  final String? nombreInmueble;

  ResumenRenta({
    required this.totalIngresos,
    required this.totalEgresos,
    required this.movimientos,
    this.fechaResumen,
    this.idInmueble,
    this.nombreInmueble,
  });

  /// Factory para crear una instancia de ResumenRenta desde un Map
  /// con manejo seguro de tipos
  factory ResumenRenta.fromMap(Map<String, dynamic> map) {
    try {
      // Conversión segura a double
      double parseDoubleSafe(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        try {
          return double.parse(value.toString());
        } catch (e) {
          _logger.warning('Error al convertir "$value" a double: $e');
          return 0.0;
        }
      }

      // Conversión de movimientos con manejo de errores individuales
      List<MovimientoRenta> parseMovimientos(List<dynamic>? listaMovimientos) {
        if (listaMovimientos == null) return [];

        final resultado = <MovimientoRenta>[];

        for (final item in listaMovimientos) {
          try {
            if (item is Map<String, dynamic>) {
              resultado.add(MovimientoRenta.fromMap(item));
            } else {
              _logger.warning('Formato inesperado de movimiento: $item');
            }
          } catch (e) {
            _logger.warning('Error al procesar movimiento: $e');
            // Continuar con el siguiente movimiento
          }
        }

        return resultado;
      }

      // Parseo de fecha con manejo de errores
      DateTime? parseFechaSafe(dynamic value) {
        if (value == null) return null;
        if (value is DateTime) return value;
        try {
          return DateTime.parse(value.toString());
        } catch (e) {
          _logger.warning('Error al parsear fecha: $e');
          return null;
        }
      }

      return ResumenRenta(
        totalIngresos: parseDoubleSafe(map['total_ingresos']),
        totalEgresos: parseDoubleSafe(map['total_egresos']),
        movimientos: parseMovimientos(map['movimientos'] as List?),
        fechaResumen: parseFechaSafe(map['fecha_resumen']),
        idInmueble: map['id_inmueble'] is int ? map['id_inmueble'] : null,
        nombreInmueble: map['nombre_inmueble']?.toString(),
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Error al crear ResumenRenta desde Map: $e',
        e,
        stackTrace,
      );
      // Retornar un objeto con valores predeterminados en caso de error
      return ResumenRenta(
        totalIngresos: 0.0,
        totalEgresos: 0.0,
        movimientos: [],
      );
    }
  }

  double get balance => totalIngresos - totalEgresos;

  bool get esPositivo => balance >= 0;

  String get balanceFormateado {
    final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
    return formatCurrency.format(balance);
  }

  String get ingresosFormateados {
    final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
    return formatCurrency.format(totalIngresos);
  }

  String get egresosFormateados {
    final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
    return formatCurrency.format(totalEgresos);
  }

  /// Calcula el rendimiento neto (porcentaje de beneficio sobre ingresos)
  double get rendimientoNeto {
    if (totalIngresos <= 0) return 0.0;
    return (balance / totalIngresos) * 100;
  }

  /// Obtiene las categorías de gastos ordenadas por monto
  List<Map<String, dynamic>> get categoriasGastosOrdenadas {
    final categorias = <Map<String, dynamic>>[];
    final egresosMap = <String, double>{};

    // Agrupar egresos por concepto
    for (final mov in movimientos.where((m) => !m.esIngreso)) {
      final concepto = _normalizarConcepto(mov.concepto);
      egresosMap[concepto] = (egresosMap[concepto] ?? 0) + mov.monto;
    }

    // Convertir a lista para ordenar
    egresosMap.forEach((concepto, monto) {
      categorias.add({
        'concepto': concepto,
        'monto': monto,
        'porcentaje': totalEgresos > 0 ? (monto / totalEgresos) * 100 : 0,
      });
    });

    // Ordenar de mayor a menor
    categorias.sort((a, b) => b['monto'].compareTo(a['monto']));
    return categorias;
  }

  /// Genera un informe mensual completo
  Map<String, dynamic> generarInformeMensual(String mes, String anio) {
    try {
      final movimientosMes =
          movimientos.where((m) {
            try {
              final fechaMes = DateFormat('yyyy-MM').format(m.fechaMovimiento);
              return fechaMes == '$anio-$mes';
            } catch (e) {
              _logger.warning('Error al formatear fecha de movimiento: $e');
              return false;
            }
          }).toList();

      final ingresosTotal = movimientosMes
          .where((m) => m.esIngreso)
          .fold(0.0, (sum, m) => sum + m.monto);

      final egresosTotal = movimientosMes
          .where((m) => !m.esIngreso)
          .fold(0.0, (sum, m) => sum + m.monto);

      return {
        'periodo': '$mes/$anio',
        'ingresos_total': ingresosTotal,
        'egresos_total': egresosTotal,
        'balance_periodo': ingresosTotal - egresosTotal,
        'rendimiento':
            ingresosTotal > 0
                ? ((ingresosTotal - egresosTotal) / ingresosTotal) * 100
                : 0,
        'movimientos': movimientosMes.length,
        'detalle_movimientos': movimientosMes,
      };
    } catch (e, stackTrace) {
      _logger.severe('Error en generarInformeMensual: $e', e, stackTrace);
      return {
        'periodo': '$mes/$anio',
        'ingresos_total': 0.0,
        'egresos_total': 0.0,
        'balance_periodo': 0.0,
        'rendimiento': 0.0,
        'movimientos': 0,
        'detalle_movimientos': <MovimientoRenta>[],
        'error': 'Error al generar informe: ${e.toString()}',
      };
    }
  }

  /// Obtiene información resumida para presentar en paneles de control
  Map<String, dynamic> obtenerDatosDashboard() {
    try {
      final numMovimientos = movimientos.length;
      final numIngresos = movimientos.where((m) => m.esIngreso).length;
      final numEgresos = numMovimientos - numIngresos;

      // Agrupar por tipo de concepto para gráficos
      final conceptosIngresos = <String, double>{};
      final conceptosEgresos = <String, double>{};

      for (final mov in movimientos) {
        final concepto = _normalizarConcepto(mov.concepto);
        if (mov.esIngreso) {
          conceptosIngresos[concepto] =
              (conceptosIngresos[concepto] ?? 0) + mov.monto;
        } else {
          conceptosEgresos[concepto] =
              (conceptosEgresos[concepto] ?? 0) + mov.monto;
        }
      }

      return {
        'balance': balance,
        'total_ingresos': totalIngresos,
        'total_egresos': totalEgresos,
        'num_movimientos': numMovimientos,
        'num_ingresos': numIngresos,
        'num_egresos': numEgresos,
        'rendimiento_porcentaje': rendimientoNeto,
        'categorias_ingresos': conceptosIngresos,
        'categorias_egresos': conceptosEgresos,
        'id_inmueble': idInmueble,
        'nombre_inmueble': nombreInmueble ?? 'Sin nombre',
        'fecha_generacion': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.warning('Error al generar datos de dashboard: $e');
      return {
        'error': 'Error al procesar datos',
        'balance': balance,
        'total_ingresos': totalIngresos,
        'total_egresos': totalEgresos,
      };
    }
  }

  /// Método auxiliar para normalizar conceptos para categorización
  String _normalizarConcepto(String concepto) {
    try {
      concepto = concepto.toLowerCase();

      if (concepto.contains('renta') || concepto.contains('alquiler')) {
        return 'Renta';
      }

      if (concepto.contains('manteni') || concepto.contains('reparac')) {
        return 'Mantenimiento';
      }

      if (concepto.contains('servi') ||
          concepto.contains('agua') ||
          concepto.contains('luz') ||
          concepto.contains('gas')) {
        return 'Servicios';
      }

      if (concepto.contains('impues') || concepto.contains('predial')) {
        return 'Impuestos';
      }

      if (concepto.contains('seguro')) {
        return 'Seguros';
      }

      if (concepto.contains('depósito') ||
          concepto.contains('deposito') ||
          concepto.contains('garantía')) {
        return 'Depósitos';
      }

      return 'Otros';
    } catch (e) {
      _logger.warning('Error al normalizar concepto "$concepto": $e');
      return 'Otros';
    }
  }
}

import 'package:intl/intl.dart';
import 'package:inmobiliaria/models/movimiento_renta_model.dart';

class ResumenRenta {
  final double totalIngresos;
  final double totalEgresos;
  final List<MovimientoRenta> movimientos;

  ResumenRenta({
    required this.totalIngresos,
    required this.totalEgresos,
    required this.movimientos,
  });

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
    final movimientosMes =
        movimientos.where((m) {
          final fechaMes = DateFormat('yyyy-MM').format(m.fechaMovimiento);
          return fechaMes == '$anio-$mes';
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
  }

  /// Método auxiliar para normalizar conceptos para categorización
  String _normalizarConcepto(String concepto) {
    concepto = concepto.toLowerCase();

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

    return 'Otros gastos';
  }
}

import 'package:intl/intl.dart';

/// Modelo para reportes y estadísticas de ventas
class VentaReporte {
  /// Fecha de inicio del periodo de reporte
  final DateTime fechaInicio;

  /// Fecha de fin del periodo de reporte
  final DateTime fechaFin;

  /// Total de ventas realizadas en el periodo
  final int totalVentas;

  /// Suma total de ingresos por ventas en el periodo
  final double ingresoTotal;

  /// Suma total de utilidades en el periodo
  final double utilidadTotal;

  /// Margen de ganancia promedio en porcentaje
  final double margenPromedio;

  /// Mapa de ventas por tipo de inmueble (clave: tipo, valor: monto)
  final Map<String, double> ventasPorTipo;

  /// Lista de datos mensuales para gráficas
  final List<Map<String, dynamic>> ventasMensuales;

  VentaReporte({
    required this.fechaInicio,
    required this.fechaFin,
    required this.totalVentas,
    required this.ingresoTotal,
    required this.utilidadTotal,
    required this.margenPromedio,
    required this.ventasPorTipo,
    required this.ventasMensuales,
  });

  /// Crea una instancia del reporte a partir de un mapa de datos
  factory VentaReporte.fromMap(Map<String, dynamic> map) {
    // Procesar fechas desde string si es necesario
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) {
        try {
          return DateFormat('yyyy-MM-dd').parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    // Procesar mapa de ventas por tipo
    Map<String, double> procesarVentasPorTipo(dynamic datos) {
      final resultado = <String, double>{};
      if (datos is List) {
        for (var item in datos) {
          if (item is Map<String, dynamic>) {
            final tipo = item['tipo_inmueble']?.toString() ?? 'Otro';
            final monto =
                (item['monto'] is num)
                    ? (item['monto'] as num).toDouble()
                    : 0.0;
            resultado[tipo] = monto;
          }
        }
      } else if (datos is Map) {
        datos.forEach((key, value) {
          if (value is num) {
            resultado[key.toString()] = value.toDouble();
          }
        });
      }
      return resultado;
    }

    // Procesar datos mensuales
    List<Map<String, dynamic>> procesarDatosMensuales(dynamic datos) {
      final resultado = <Map<String, dynamic>>[];
      if (datos is List) {
        for (var item in datos) {
          if (item is Map<String, dynamic>) {
            resultado.add(Map<String, dynamic>.from(item));
          }
        }
      }
      return resultado;
    }

    return VentaReporte(
      fechaInicio: parseDate(map['fecha_inicio']),
      fechaFin: parseDate(map['fecha_fin']),
      totalVentas: map['total_ventas'] is int ? map['total_ventas'] : 0,
      ingresoTotal:
          map['ingreso_total'] is num ? map['ingreso_total'].toDouble() : 0.0,
      utilidadTotal:
          map['utilidad_total'] is num ? map['utilidad_total'].toDouble() : 0.0,
      margenPromedio:
          map['margen_promedio'] is num
              ? map['margen_promedio'].toDouble()
              : 0.0,
      ventasPorTipo: procesarVentasPorTipo(map['ventas_por_tipo']),
      ventasMensuales: procesarDatosMensuales(map['ventas_mensuales']),
    );
  }

  /// Convierte este reporte a un mapa para serialización
  Map<String, dynamic> toMap() {
    return {
      'fecha_inicio': DateFormat('yyyy-MM-dd').format(fechaInicio),
      'fecha_fin': DateFormat('yyyy-MM-dd').format(fechaFin),
      'total_ventas': totalVentas,
      'ingreso_total': ingresoTotal,
      'utilidad_total': utilidadTotal,
      'margen_promedio': margenPromedio,
      'ventas_por_tipo': ventasPorTipo,
      'ventas_mensuales': ventasMensuales,
    };
  }

  /// Crea una copia de este reporte con los campos especificados modificados
  VentaReporte copyWith({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? totalVentas,
    double? ingresoTotal,
    double? utilidadTotal,
    double? margenPromedio,
    Map<String, double>? ventasPorTipo,
    List<Map<String, dynamic>>? ventasMensuales,
  }) {
    return VentaReporte(
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      totalVentas: totalVentas ?? this.totalVentas,
      ingresoTotal: ingresoTotal ?? this.ingresoTotal,
      utilidadTotal: utilidadTotal ?? this.utilidadTotal,
      margenPromedio: margenPromedio ?? this.margenPromedio,
      ventasPorTipo:
          ventasPorTipo ?? Map<String, double>.from(this.ventasPorTipo),
      ventasMensuales:
          ventasMensuales ??
          List<Map<String, dynamic>>.from(
            this.ventasMensuales.map((e) => Map<String, dynamic>.from(e)),
          ),
    );
  }
}

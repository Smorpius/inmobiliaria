class VentaReporte {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int totalVentas;
  final double ingresoTotal;
  final double utilidadTotal;
  final double margenPromedio;
  final Map<String, double> ventasPorTipo; // casa, departamento, etc.
  final List<Map<String, dynamic>> ventasMensuales; // para gráficos

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

  factory VentaReporte.fromMap(Map<String, dynamic> map) {
    return VentaReporte(
      fechaInicio: DateTime.parse(map['fecha_inicio']),
      fechaFin: DateTime.parse(map['fecha_fin']),
      totalVentas: map['total_ventas'],
      ingresoTotal: double.parse(map['ingreso_total'].toString()),
      utilidadTotal: double.parse(map['utilidad_total'].toString()),
      margenPromedio: double.parse(map['margen_promedio'].toString()),
      ventasPorTipo: Map<String, double>.from(map['ventas_por_tipo'] ?? {}),
      ventasMensuales: List<Map<String, dynamic>>.from(
        map['ventas_mensuales'] ?? [],
      ),
    );
  }
}

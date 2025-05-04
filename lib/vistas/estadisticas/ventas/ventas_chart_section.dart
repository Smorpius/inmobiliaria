import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class VentasChartSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> ventasMensuales;
  final NumberFormat formatCurrency;

  const VentasChartSection({
    super.key,
    required this.title,
    required this.ventasMensuales,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    if (ventasMensuales.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBarChart(context),
            const SizedBox(height: 20),
            _buildDataTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    // Encontrar el valor máximo para escalar correctamente las barras
    double maxIngreso = 0;
    for (var data in ventasMensuales) {
      // Convertir explícitamente a double
      final ingresoValue = data['ingreso'] ?? 0;
      final ingreso = ingresoValue is num ? ingresoValue.toDouble() : 0.0;
      if (ingreso > maxIngreso) maxIngreso = ingreso;
    }

    // Si no hay datos, mostrar un mensaje
    if (maxIngreso <= 0) {
      return const Center(
        child: Text(
          'No hay datos disponibles para mostrar',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.only(top: 20),
        width: max(
          MediaQuery.of(context).size.width - 40,
          ventasMensuales.length * 60.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:
              ventasMensuales.map((data) {
                final ingreso = (data['ingreso'] as num?)?.toDouble() ?? 0.0;
                final utilidad = (data['utilidad'] as num?)?.toDouble() ?? 0.0;
                final alturaIngreso =
                    maxIngreso > 0 ? (ingreso / maxIngreso * 180) : 0.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildTooltip(data, ingreso, utilidad),
                    Container(
                      width: 30,
                      height: alturaIngreso,
                      color: Theme.of(
                        context,
                      ).primaryColor.withAlpha((255 * 0.7).round()),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getMesCorto(data),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTooltip(
    Map<String, dynamic> data,
    double ingreso,
    double utilidad,
  ) {
    return Column(
      children: [
        Text(
          formatCurrency.format(ingreso),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        Text(
          'Utilidad: ${formatCurrency.format(utilidad)}',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Mes')),
          DataColumn(label: Text('Ventas'), numeric: true),
          DataColumn(label: Text('Ingreso'), numeric: true),
          DataColumn(label: Text('Utilidad'), numeric: true),
          DataColumn(label: Text('Margen'), numeric: true),
        ],
        rows:
            ventasMensuales.map((data) {
              final ingreso = (data['ingreso'] as num?)?.toDouble() ?? 0.0;
              final utilidad = (data['utilidad'] as num?)?.toDouble() ?? 0.0;
              final ventas = (data['cantidad'] as num?)?.toInt() ?? 0;
              final margen = ingreso > 0 ? (utilidad / ingreso * 100) : 0.0;

              return DataRow(
                cells: [
                  DataCell(Text(_getMesLabel(data))),
                  DataCell(Text(ventas.toString())),
                  DataCell(Text(formatCurrency.format(ingreso))),
                  DataCell(Text(formatCurrency.format(utilidad))),
                  DataCell(Text('${margen.toStringAsFixed(1)}%')),
                ],
              );
            }).toList(),
      ),
    );
  }

  String _getMesLabel(Map<String, dynamic> data) {
    final mes = data['mes'] ?? 0;
    final anio = data['anio'] ?? data['año'] ?? DateTime.now().year;
    try {
      final fecha = DateTime(anio, mes);
      return DateFormat('MMMM yyyy', 'es_ES').format(fecha);
    } catch (e) {
      return 'Mes $mes/$anio';
    }
  }

  String _getMesCorto(Map<String, dynamic> data) {
    final mes = data['mes'] ?? 0;
    final anio = data['anio'] ?? data['año'] ?? DateTime.now().year;
    try {
      final fecha = DateTime(anio, mes);
      return DateFormat('MMM', 'es_ES').format(fecha);
    } catch (e) {
      return '$mes/$anio';
    }
  }

  double max(double a, double b) {
    return a > b ? a : b;
  }
}

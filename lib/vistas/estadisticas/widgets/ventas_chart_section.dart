import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/chart_colors.dart';

class VentasChartSection extends StatelessWidget {
  final List<Map<String, dynamic>> ventasPorTipo;
  final List<Map<String, dynamic>> datosMensuales;

  const VentasChartSection({
    super.key,
    required this.ventasPorTipo,
    required this.datosMensuales,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDistribucionPorTipoCard(context),
        const SizedBox(height: 20),
        _buildEvolucionVentasCard(context),
      ],
    );
  }

  Widget _buildDistribucionPorTipoCard(BuildContext context) {
    if (ventasPorTipo.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');

    // Calcular total para porcentajes
    final double total = ventasPorTipo.fold(
      0,
      (sum, item) => sum + (item['monto'] as num? ?? 0).toDouble(),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Distribución por Tipo de Inmueble',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(flex: 2, child: _buildPieChart(total)),
                  Expanded(
                    flex: 3,
                    child: _buildTipoInmuebleList(formatCurrency, total),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(double total) {
    if (total <= 0) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _getSections(total),
      ),
    );
  }

  List<PieChartSectionData> _getSections(double total) {
    if (ventasPorTipo.isEmpty || total <= 0) {
      return [];
    }

    return ventasPorTipo.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final double monto = (item['monto'] as num? ?? 0).toDouble();
      final double porcentaje = total > 0 ? (monto / total * 100) : 0;

      return PieChartSectionData(
        color: ChartColors.getColorForIndex(index),
        value: monto,
        title: '${porcentaje.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildTipoInmuebleList(NumberFormat formatCurrency, double total) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: ventasPorTipo.length,
      itemBuilder: (context, index) {
        final item = ventasPorTipo[index];
        final String tipo = item['tipo_inmueble']?.toString() ?? 'Otro';
        final double monto = (item['monto'] as num? ?? 0).toDouble();
        final double porcentaje = total > 0 ? (monto / total * 100) : 0;

        return ListTile(
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ChartColors.getColorForIndex(index),
            ),
          ),
          title: Text(tipo),
          subtitle: Text('${porcentaje.toStringAsFixed(1)}%'),
          trailing: Text(
            formatCurrency.format(monto),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildEvolucionVentasCard(BuildContext context) {
    if (datosMensuales.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Evolución de Ventas',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            SizedBox(height: 250, child: _buildBarChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = datosMensuales[groupIndex];
              final mesLabel = _getMesLabel(item);
              final monto = (item['monto'] as num? ?? 0).toDouble();
              final formatCurrency = NumberFormat.currency(
                symbol: '\$',
                locale: 'es_MX',
              );

              return BarTooltipItem(
                '$mesLabel\n${formatCurrency.format(monto)}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < datosMensuales.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _getMesCorto(datosMensuales[value.toInt()]),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getMaxY() / 5,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final formatCurrency = NumberFormat.compactCurrency(
                  symbol: '\$',
                  locale: 'es_MX',
                );
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    formatCurrency.format(value),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, horizontalInterval: _getMaxY() / 5),
        borderData: FlBorderData(show: false),
        barGroups: _getBarGroups(),
      ),
    );
  }

  double _getMaxY() {
    if (datosMensuales.isEmpty) {
      return 10000; // Valor por defecto para evitar errores
    }

    double max = 0;
    for (final data in datosMensuales) {
      final monto = (data['monto'] as num? ?? 0).toDouble();
      if (monto > max) {
        max = monto;
      }
    }

    // Añadir un 10% para que las barras no lleguen al borde superior
    return max > 0 ? max * 1.1 : 10000;
  }

  List<BarChartGroupData> _getBarGroups() {
    if (datosMensuales.isEmpty) return [];

    return datosMensuales.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final monto = (data['monto'] as num? ?? 0).toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: monto,
            color: ChartColors.balance,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
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
}

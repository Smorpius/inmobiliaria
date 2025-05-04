import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/chart_colors.dart';

class RentasChartSection extends StatelessWidget {
  final List<Map<String, dynamic>> datosInmuebles;
  final List<Map<String, dynamic>> evolucionMensual;

  const RentasChartSection({
    super.key,
    required this.datosInmuebles,
    required this.evolucionMensual,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInmueblesRendimientoCard(context),
        const SizedBox(height: 24),
        _buildEvolucionMensualCard(context),
      ],
    );
  }

  Widget _buildInmueblesRendimientoCard(BuildContext context) {
    if (datosInmuebles.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');

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
                Icon(Icons.bar_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Rendimiento por Inmueble',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInmueblesChart(context),
            const SizedBox(height: 16),
            _buildInmueblesTable(formatCurrency),
          ],
        ),
      ),
    );
  }

  Widget _buildInmueblesChart(BuildContext context) {
    // Encontrar el valor máximo para escala
    double maxIngreso = 0;
    double maxEgreso = 0;

    for (final inmueble in datosInmuebles) {
      final ingreso = (inmueble['ingresos'] as num?)?.toDouble() ?? 0.0;
      final egreso = (inmueble['egresos'] as num?)?.toDouble() ?? 0.0;

      if (ingreso > maxIngreso) maxIngreso = ingreso;
      if (egreso > maxEgreso) maxEgreso = egreso;
    }

    final maxY = (maxIngreso > maxEgreso ? maxIngreso : maxEgreso) * 1.1;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final inmueble = datosInmuebles[groupIndex];
                final nombre = inmueble['nombre'] as String? ?? 'Sin nombre';
                final valor =
                    rodIndex == 0
                        ? inmueble['ingresos'] as double? ?? 0.0
                        : inmueble['egresos'] as double? ?? 0.0;
                final tipo = rodIndex == 0 ? 'Ingresos' : 'Egresos';
                final formatCurrency = NumberFormat.currency(
                  symbol: '\$',
                  locale: 'es_MX',
                );

                return BarTooltipItem(
                  '$nombre\n$tipo: ${formatCurrency.format(valor)}',
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
                  if (value >= 0 && value < datosInmuebles.length) {
                    final nombre =
                        datosInmuebles[value.toInt()]['nombre'] as String? ??
                        '';
                    // Acortar nombre si es muy largo
                    final nombreCorto =
                        nombre.length > 15
                            ? '${nombre.substring(0, 12)}...'
                            : nombre;

                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        nombreCorto,
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
                interval: maxY / 5,
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
          gridData: FlGridData(show: true, horizontalInterval: maxY / 5),
          borderData: FlBorderData(show: false),
          barGroups: _getInmuebleBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getInmuebleBarGroups() {
    if (datosInmuebles.isEmpty) return [];

    return datosInmuebles.asMap().entries.map((entry) {
      final index = entry.key;
      final inmueble = entry.value;
      final ingresos = (inmueble['ingresos'] as num?)?.toDouble() ?? 0.0;
      final egresos = (inmueble['egresos'] as num?)?.toDouble() ?? 0.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: ingresos,
            color: ChartColors.ingresos,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: egresos,
            color: ChartColors.egresos,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();
  }

  Widget _buildInmueblesTable(NumberFormat formatCurrency) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Inmueble')),
          DataColumn(label: Text('Ingresos'), numeric: true),
          DataColumn(label: Text('Egresos'), numeric: true),
          DataColumn(label: Text('Balance'), numeric: true),
          DataColumn(label: Text('Rentabilidad'), numeric: true),
        ],
        rows:
            datosInmuebles.map((inmueble) {
              final nombre = inmueble['nombre'] as String? ?? 'Sin nombre';
              final ingresos =
                  (inmueble['ingresos'] as num?)?.toDouble() ?? 0.0;
              final egresos = (inmueble['egresos'] as num?)?.toDouble() ?? 0.0;
              final balance = (inmueble['balance'] as num?)?.toDouble() ?? 0.0;
              final rentabilidad =
                  egresos > 0 ? (balance / egresos) * 100 : 0.0;

              return DataRow(
                cells: [
                  DataCell(Text(nombre)),
                  DataCell(Text(formatCurrency.format(ingresos))),
                  DataCell(Text(formatCurrency.format(egresos))),
                  DataCell(Text(formatCurrency.format(balance))),
                  DataCell(Text('${rentabilidad.toStringAsFixed(1)}%')),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildEvolucionMensualCard(BuildContext context) {
    if (evolucionMensual.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');

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
                  'Evolución Mensual',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildEvolucionChart(context),
            const SizedBox(height: 16),
            _buildEvolucionTable(formatCurrency),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolucionChart(BuildContext context) {
    // Encontrar valores máximos para escala
    double maxValor = 0;
    for (final mes in evolucionMensual) {
      final ingresos = (mes['ingresos'] as num?)?.toDouble() ?? 0.0;
      final egresos = (mes['egresos'] as num?)?.toDouble() ?? 0.0;
      final balance = (mes['balance'] as num?)?.toDouble() ?? 0.0;

      final maxMensual = [
        ingresos,
        egresos,
        balance.abs(),
      ].reduce((curr, next) => curr > next ? curr : next);
      if (maxMensual > maxValor) maxValor = maxMensual;
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: evolucionMensual.length - 1.0,
          minY: -maxValor * 0.2,
          maxY: maxValor * 1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final valueInt = value.toInt();
                  if (valueInt >= 0 && valueInt < evolucionMensual.length) {
                    final mes = evolucionMensual[valueInt]['mes'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(mes, style: const TextStyle(fontSize: 10)),
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
                interval: maxValor / 5,
                reservedSize: 50,
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
          gridData: FlGridData(show: true, horizontalInterval: maxValor / 5),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          lineBarsData: [
            // Línea de ingresos
            LineChartBarData(
              isCurved: true,
              color: ChartColors.ingresos,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: ChartColors.ingresosBackground,
              ),
              spots: _getSpots('ingresos'),
            ),
            // Línea de egresos
            LineChartBarData(
              isCurved: true,
              color: ChartColors.egresos,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: ChartColors.egresosBackground,
              ),
              spots: _getSpots('egresos'),
            ),
            // Línea de balance
            LineChartBarData(
              isCurved: true,
              color: ChartColors.balance,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: ChartColors.balanceBackground,
              ),
              spots: _getSpots('balance'),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final index = touchedSpot.spotIndex;
                  final lineIndex = touchedSpot.barIndex;
                  final mes = evolucionMensual[index]['mes'] ?? '';

                  String tipo;
                  Color color;
                  switch (lineIndex) {
                    case 0:
                      tipo = 'Ingresos';
                      color = Colors.green;
                      break;
                    case 1:
                      tipo = 'Egresos';
                      color = Colors.red;
                      break;
                    case 2:
                      tipo = 'Balance';
                      color = Colors.blue;
                      break;
                    default:
                      tipo = 'Valor';
                      color = Colors.purple;
                  }

                  final formatCurrency = NumberFormat.currency(
                    symbol: '\$',
                    locale: 'es_MX',
                  );

                  return LineTooltipItem(
                    '$mes - $tipo\n${formatCurrency.format(touchedSpot.y)}',
                    TextStyle(color: color, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getSpots(String fieldName) {
    if (evolucionMensual.isEmpty) return [];

    return evolucionMensual.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final data = entry.value;
      final valor = (data[fieldName] as num?)?.toDouble() ?? 0.0;
      return FlSpot(index, valor);
    }).toList();
  }

  Widget _buildEvolucionTable(NumberFormat formatCurrency) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Mes')),
          DataColumn(label: Text('Ingresos'), numeric: true),
          DataColumn(label: Text('Egresos'), numeric: true),
          DataColumn(label: Text('Balance'), numeric: true),
        ],
        rows:
            evolucionMensual.map((mes) {
              final nombre = mes['mes'] as String? ?? '';
              final ingresos = (mes['ingresos'] as num?)?.toDouble() ?? 0.0;
              final egresos = (mes['egresos'] as num?)?.toDouble() ?? 0.0;
              final balance = (mes['balance'] as num?)?.toDouble() ?? 0.0;

              return DataRow(
                cells: [
                  DataCell(Text(nombre)),
                  DataCell(Text(formatCurrency.format(ingresos))),
                  DataCell(Text(formatCurrency.format(egresos))),
                  DataCell(Text(formatCurrency.format(balance))),
                ],
              );
            }).toList(),
      ),
    );
  }
}

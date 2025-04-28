import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/venta_providers.dart';
import '../../models/venta_reporte_model.dart';
import '../../widgets/filtro_periodo_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Constantes para colores usados en los gráficos y tarjetas
class ReporteColors {
  static const Color ingresos = Colors.blue;
  static const Color utilidades = Colors.green;
  static const Color ventas = Colors.blue;
  static const Color dinero = Colors.green;
  static const Color utilidad = Colors.purple;
  static const Color margen = Colors.orange;
  static const List<Color> tiposInmuebles = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
  ];
}

/// Pantalla que muestra reportes y estadísticas de ventas
/// con gráficos de ventas mensuales y por tipo de inmueble.
class ReportesVentasScreen extends ConsumerStatefulWidget {
  const ReportesVentasScreen({super.key});

  @override
  ConsumerState<ReportesVentasScreen> createState() =>
      _ReportesVentasScreenState();
}

class _ReportesVentasScreenState extends ConsumerState<ReportesVentasScreen> {
  DateTimeRange? _rangoFechas;
  TipoPeriodo _tipoPeriodoActual = TipoPeriodo.mes;

  void _actualizarPeriodo(TipoPeriodo tipo, DateTimeRange rango) {
    setState(() {
      _tipoPeriodoActual = tipo;
      _rangoFechas = rango;
      ref.invalidate(ventasEstadisticasProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final estadisticasAsyncValue = ref.watch(
      ventasEstadisticasProvider(_rangoFechas),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes de Ventas')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _construirHeader(),
              const SizedBox(height: 16),
              estadisticasAsyncValue.when(
                data: (estadisticas) => _construirEstadisticas(estadisticas),
                loading:
                    () => const Center(
                      heightFactor: 3,
                      child: CircularProgressIndicator(),
                    ),
                error:
                    (error, _) => Center(
                      heightFactor: 2,
                      child: Text('Error al cargar estadísticas: $error'),
                    ),
              ),
              const SizedBox(height: 24),
              estadisticasAsyncValue.when(
                data: (estadisticas) => _construirGraficos(estadisticas),
                loading:
                    () => _construirPlaceholderGrafico("Cargando gráficos..."),
                error:
                    (error, _) => _construirPlaceholderGrafico(
                      "Error al cargar gráficos: $error",
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reportes de Ventas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FiltroPeriodoWidget(
              initialPeriodo: _tipoPeriodoActual,
              onPeriodoChanged: _actualizarPeriodo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirEstadisticas(VentaReporte estadisticas) {
    final formatter = NumberFormat.currency(symbol: '\$', locale: 'es_MX');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Ventas',
                estadisticas.totalVentas.toString(),
                Icons.sell,
                ReporteColors.ventas,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Ingresos',
                formatter.format(estadisticas.ingresoTotal),
                Icons.attach_money,
                ReporteColors.dinero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Utilidad Total',
                formatter.format(estadisticas.utilidadTotal),
                Icons.trending_up,
                ReporteColors.utilidad,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Margen Promedio',
                '${estadisticas.margenPromedio.toStringAsFixed(2)}%',
                Icons.pie_chart,
                ReporteColors.margen,
              ),
            ),
          ],
        ),
        if (estadisticas.totalVentas == 0)
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay ventas registradas en este período',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registre ventas o modifique el rango de fechas',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _construirGraficos(VentaReporte estadisticas) {
    if (estadisticas.totalVentas == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No hay ventas registradas en este período',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Intenta seleccionar otro período o registra nuevas ventas.',
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (estadisticas.ventasMensuales.isNotEmpty)
          _construirGraficoVentasMensuales(estadisticas.ventasMensuales),
        const SizedBox(height: 24),
        if (estadisticas.ventasPorTipo.isNotEmpty)
          _construirGraficoVentasPorTipo(estadisticas.ventasPorTipo),
      ],
    );
  }

  Widget _construirGraficoVentasMensuales(
    List<Map<String, dynamic>> ventasMensuales,
  ) {
    final ingresos = <FlSpot>[];
    final utilidades = <FlSpot>[];
    final labels = <String>[];

    ventasMensuales.sort((a, b) {
      int compareAnio = a['anio'].compareTo(b['anio']);
      if (compareAnio != 0) return compareAnio;
      return a['mes'].compareTo(b['mes']);
    });

    for (int i = 0; i < ventasMensuales.length; i++) {
      final venta = ventasMensuales[i];
      final double ingreso = (venta['ingreso'] ?? 0.0).toDouble();
      final double utilidad = (venta['utilidad'] ?? 0.0).toDouble();

      ingresos.add(FlSpot(i.toDouble(), ingreso / 1000));
      utilidades.add(FlSpot(i.toDouble(), utilidad / 1000));

      try {
        final fecha = DateTime(venta['anio'], venta['mes']);
        labels.add(DateFormat('MMM yy', 'es_ES').format(fecha));
      } catch (e) {
        labels.add('${venta['mes']}/${venta['anio']}');
      }
    }

    if (ingresos.isEmpty && utilidades.isEmpty) {
      return _construirPlaceholderGrafico(
        'No hay datos mensuales para este período.',
      );
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolución de Ventas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresos y utilidades (en miles de \$)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 &&
                              index < labels.length &&
                              index % (labels.length > 12 ? 2 : 1) == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                labels[index],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 30,
                        interval: 1,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: ingresos,
                      isCurved: true,
                      color: ReporteColors.ingresos,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: ReporteColors.ingresos.withAlpha(
                          (0.1 * 255).round(),
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: utilidades,
                      isCurved: true,
                      color: ReporteColors.utilidades,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: ReporteColors.utilidades.withAlpha(
                          (0.1 * 255).round(),
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final barData = spot.bar;
                          final labelIndex = spot.spotIndex;
                          String label = '';
                          if (labelIndex >= 0 && labelIndex < labels.length) {
                            label = labels[labelIndex];
                          }
                          final value = spot.y * 1000;
                          final formatter = NumberFormat.currency(
                            symbol: '\$',
                            locale: 'es_MX',
                          );

                          return LineTooltipItem(
                            '${barData.color == ReporteColors.ingresos ? 'Ingreso' : 'Utilidad'}\n',
                            TextStyle(
                              color: barData.color,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '${formatter.format(value)}\n',
                                style: const TextStyle(color: Colors.black),
                              ),
                              TextSpan(
                                text: label,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem('Ingresos', ReporteColors.ingresos),
                const SizedBox(width: 24),
                _legendItem('Utilidades', ReporteColors.utilidades),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirGraficoVentasPorTipo(Map<String, double> ventasPorTipo) {
    final List<PieChartSectionData> sections = [];
    final colores = ReporteColors.tiposInmuebles;

    double total = ventasPorTipo.values.fold(0, (sum, item) => sum + item);
    int i = 0;

    if (total > 0) {
      ventasPorTipo.forEach((tipo, monto) {
        final porcentaje = (monto / total) * 100;
        sections.add(
          PieChartSectionData(
            color: colores[i % colores.length],
            value: monto,
            title: '${porcentaje.toStringAsFixed(1)}%',
            radius: 80,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        i++;
      });
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas por Tipo de Inmueble',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child:
                  total > 0
                      ? PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      )
                      : _construirPlaceholderGrafico(
                        "No hay datos suficientes para generar el gráfico",
                      ),
            ),
            const SizedBox(height: 16),
            _construirLeyendaPieChart(ventasPorTipo, colores),
          ],
        ),
      ),
    );
  }

  Widget _construirLeyendaPieChart(
    Map<String, double> data,
    List<Color> colores,
  ) {
    final listaKeys = data.keys.toList();

    return Column(
      children:
          data.entries.map((entry) {
            final index = listaKeys.indexOf(entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colores[index % colores.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_capitalizarPalabra(entry.key))),
                  Text(
                    NumberFormat.currency(
                      symbol: '\$',
                      locale: 'es_MX',
                    ).format(entry.value),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizarPalabra(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  Widget _construirPlaceholderGrafico(String mensaje) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

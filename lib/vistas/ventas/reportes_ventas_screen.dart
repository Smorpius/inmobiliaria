import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/venta_providers.dart';
import '../../models/venta_reporte_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    // Usando el provider de estadísticas con el rango de fechas como parámetro
    final estadisticasAsyncValue = ref.watch(
      ventasEstadisticasProvider(_rangoFechas),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Seleccionar rango de fechas',
            onPressed: () => _seleccionarRangoFechas(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con período y botones
              _construirHeader(),

              const SizedBox(height: 16),

              // Estadísticas principales
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

              // Gráficos de ventas
              estadisticasAsyncValue.when(
                data: (estadisticas) => _construirGraficos(estadisticas),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el encabezado con información del período seleccionado
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
            const SizedBox(height: 8),
            Text(
              _rangoFechas != null
                  ? 'Período: ${DateFormat('dd/MM/yyyy').format(_rangoFechas!.start)} - '
                      '${DateFormat('dd/MM/yyyy').format(_rangoFechas!.end)}'
                  : 'Mostrando estadísticas de todas las ventas',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _seleccionarRangoFechas(context),
                  icon: const Icon(Icons.date_range),
                  label: const Text('Cambiar período'),
                ),
                const SizedBox(width: 16),
                if (_rangoFechas != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _rangoFechas = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar filtro'),
                  ),
              ],
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
        // Tarjetas de estadísticas principales
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Ventas',
                estadisticas.totalVentas.toString(),
                Icons.sell,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Ingresos',
                formatter.format(estadisticas.ingresoTotal),
                Icons.attach_money,
                Colors.green,
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
                Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Margen Promedio',
                '${estadisticas.margenPromedio.toStringAsFixed(2)}%',
                Icons.pie_chart,
                Colors.orange,
              ),
            ),
          ],
        ),

        // Mostrar mensaje si no hay ventas
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

  /// Construye la sección de gráficos con los datos de ventas
  Widget _construirGraficos(VentaReporte estadisticas) {
    // No mostrar gráficos si no hay datos
    if (estadisticas.totalVentas == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gráfico de ventas por mes
        if (estadisticas.ventasMensuales.isNotEmpty)
          _construirGraficoVentasMensuales(estadisticas.ventasMensuales),

        const SizedBox(height: 24),

        // Gráfico de ventas por tipo de inmueble
        if (estadisticas.ventasPorTipo.isNotEmpty)
          _construirGraficoVentasPorTipo(estadisticas.ventasPorTipo),
      ],
    );
  }

  /// Construye un gráfico de líneas con las ventas mensuales
  Widget _construirGraficoVentasMensuales(
    List<Map<String, dynamic>> ventasMensuales,
  ) {
    // Preparar datos para el gráfico
    final ingresos = <FlSpot>[];
    final utilidades = <FlSpot>[];
    final labels = <String>[];

    for (int i = 0; i < ventasMensuales.length; i++) {
      final venta = ventasMensuales[i];
      ingresos.add(FlSpot(i.toDouble(), venta['ingreso'] / 1000)); // En miles
      utilidades.add(
        FlSpot(i.toDouble(), venta['utilidad'] / 1000),
      ); // En miles
      labels.add('${_getNombreMes(venta['mes'])} ${venta['anio']}');
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas Mensuales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresos y utilidades por mes (en miles de \$)',
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
                          if (value >= 0 &&
                              value < labels.length &&
                              value % 2 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                labels[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
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
                    // Línea de ingresos
                    LineChartBarData(
                      spots: ingresos,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withAlpha((0.1 * 255).round()),
                      ),
                    ),
                    // Línea de utilidades
                    LineChartBarData(
                      spots: utilidades,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withAlpha((0.1 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem('Ingresos', Colors.blue),
                const SizedBox(width: 24),
                _legendItem('Utilidades', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un gráfico circular con las ventas por tipo de inmueble
  Widget _construirGraficoVentasPorTipo(Map<String, double> ventasPorTipo) {
    // Preparar datos para el gráfico
    final List<PieChartSectionData> sections = [];
    final colores = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    double total = ventasPorTipo.values.fold(0, (sum, item) => sum + item);
    int i = 0;

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
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _construirLeyendaPieChart(ventasPorTipo, colores),
          ],
        ),
      ),
    );
  }

  /// Construye la leyenda para el gráfico circular
  Widget _construirLeyendaPieChart(
    Map<String, double> data,
    List<Color> colores,
  ) {
    return Column(
      children:
          data.entries.map((entry) {
            final index = data.keys.toList().indexOf(entry.key);
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

  /// Construye un elemento de leyenda para los gráficos
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

  /// Construye una tarjeta de estadística
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

  /// Muestra un selector de rango de fechas
  Future<void> _seleccionarRangoFechas(BuildContext context) async {
    final fechaActual = DateTime.now();
    final rangoInicial =
        _rangoFechas ??
        DateTimeRange(
          start: DateTime(fechaActual.year, fechaActual.month - 6, 1),
          end: fechaActual,
        );

    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: fechaActual,
      initialDateRange: rangoInicial,
      saveText: 'APLICAR',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
      helpText: 'SELECCIONAR PERÍODO',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal, // Color primario para fechas seleccionadas
              onPrimary: Colors.white, // Color del texto en días seleccionados
              surface: Colors.teal.shade50, // Color de fondo
              onSurface: Colors.black, // Color del texto
            ),
          ),
          child: child!,
        );
      },
    );

    if (rango != null) {
      setState(() {
        _rangoFechas = rango;
      });
    }
  }

  /// Obtiene el nombre abreviado del mes
  String _getNombreMes(int mes) {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return meses[mes - 1];
  }

  /// Capitaliza la primera letra de una palabra
  String _capitalizarPalabra(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }
}

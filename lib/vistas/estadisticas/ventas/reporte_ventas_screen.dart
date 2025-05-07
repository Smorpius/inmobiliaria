import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import 'package:open_file/open_file.dart';
import '../widgets/loading_indicator.dart';
import '../../../services/pdf_service.dart';
import '../widgets/filtro_periodo_widget.dart';
import '../../../providers/venta_providers.dart';
import '../../../models/venta_reporte_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../vistas/estadisticas/widgets/ventas_chart_section.dart';

class ReporteVentasScreen extends ConsumerStatefulWidget {
  final DateTimeRange periodoInicial;

  const ReporteVentasScreen({super.key, required this.periodoInicial});

  @override
  ConsumerState<ReporteVentasScreen> createState() =>
      _ReporteVentasScreenState();
}

class _ReporteVentasScreenState extends ConsumerState<ReporteVentasScreen> {
  late DateTimeRange _periodo;
  bool _isGeneratingPdf = false;
  final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
  DateTime? _ultimaGeneracionPDF;

  @override
  void initState() {
    super.initState();
    _periodo = widget.periodoInicial;
  }

  @override
  Widget build(BuildContext context) {
    final reporteVentasAsync = ref.watch(ventasEstadisticasProvider(_periodo));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Ventas'),
        actions: [
          IconButton(
            icon: Icon(
              _isGeneratingPdf ? Icons.hourglass_bottom : Icons.picture_as_pdf,
            ),
            tooltip: 'Exportar a PDF',
            onPressed:
                _isGeneratingPdf
                    ? null
                    : () => _generarReportePDF(reporteVentasAsync),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FiltroPeriodoWidget(
              periodo: _periodo,
              onPeriodChanged: (newPeriod) {
                // Validar que la fecha inicial sea anterior a la final
                if (newPeriod.start.isAfter(newPeriod.end)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'La fecha inicial debe ser anterior a la final',
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  _periodo = newPeriod;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildReporteContent(reporteVentasAsync)),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteContent(AsyncValue<VentaReporte> reporteAsync) {
    return reporteAsync.when(
      data: (data) => _buildReporte(data),
      loading:
          () => const LoadingIndicator(mensaje: 'Cargando datos de ventas...'),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildReporte(VentaReporte data) {
    // Extraer datos de estadísticas
    final totalVentas = data.totalVentas;
    final ingresoTotal = data.ingresoTotal;
    final utilidadTotal = data.utilidadTotal;
    final margenPromedio = data.margenPromedio;
    final ventasPorTipo = data.ventasPorTipo;
    final datosMensuales = data.ventasMensuales;

    // Convertir totalVentas a double si es necesario
    final promedioVenta =
        totalVentas > 0 ? ingresoTotal / totalVentas.toDouble() : 0.0;
    final utilidadPromedio =
        totalVentas > 0 ? utilidadTotal / totalVentas.toDouble() : 0.0;

    // Convertir el Map<String, double> a una List<Map<String, dynamic>>
    final List<Map<String, dynamic>> ventasPorTipoList =
        ventasPorTipo.entries
            .map((entry) => {'tipo_inmueble': entry.key, 'monto': entry.value})
            .toList();

    return RefreshIndicator(
      onRefresh: () async {
        final _ = ref.refresh(ventasEstadisticasProvider(_periodo));
        return Future<void>.value();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumenCard(
              totalVentas: totalVentas,
              ingresoTotal: ingresoTotal,
              utilidadTotal: utilidadTotal,
              margenPromedio: margenPromedio,
              promedioVenta: promedioVenta,
              utilidadPromedio: utilidadPromedio,
            ),
            const SizedBox(height: 24),
            VentasChartSection(
              ventasPorTipo: ventasPorTipoList, // Usar la lista convertida
              datosMensuales: datosMensuales,
            ),
            const SizedBox(height: 24),
            _buildDetalleMensualCard(datosMensuales),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard({
    required int totalVentas,
    required double ingresoTotal,
    required double utilidadTotal,
    required double margenPromedio,
    required double promedioVenta,
    required double utilidadPromedio,
  }) {
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
                Icon(Icons.insights, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Resumen de Ventas',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Total de Ventas',
                    totalVentas.toString(),
                    Icons.sell,
                    Colors.blue.shade700,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Ingresos Totales',
                    formatCurrency.format(ingresoTotal),
                    Icons.attach_money,
                    Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Utilidad Total',
                    formatCurrency.format(utilidadTotal),
                    Icons.trending_up,
                    Colors.purple.shade700,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Margen Promedio',
                    '${margenPromedio.toStringAsFixed(2)}%',
                    Icons.percent,
                    Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Promedio por Venta',
                    formatCurrency.format(promedioVenta),
                    Icons.calculate,
                    Colors.teal.shade700,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Utilidad Promedio',
                    formatCurrency.format(utilidadPromedio),
                    Icons.bar_chart,
                    Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleMensualCard(List<Map<String, dynamic>> datosMensuales) {
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
                Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Detalle Mensual',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            if (datosMensuales.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No hay datos disponibles para el periodo seleccionado',
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    return Theme.of(context).colorScheme.primary.withAlpha(25);
                  }),
                  columns: const [
                    DataColumn(label: Text('Mes')),
                    DataColumn(label: Text('Cantidad'), numeric: true),
                    DataColumn(label: Text('Monto'), numeric: true),
                    DataColumn(label: Text('Utilidad'), numeric: true),
                    DataColumn(label: Text('Promedio'), numeric: true),
                  ],
                  rows:
                      datosMensuales.map((mes) {
                        final mesNombre =
                            mes['mes'] as String? ?? 'Desconocido';
                        final cantidad = mes['cantidad'] as int? ?? 0;
                        final monto = (mes['monto'] as num?)?.toDouble() ?? 0.0;
                        final utilidad =
                            (mes['utilidad'] as num?)?.toDouble() ?? 0.0;
                        final promedio = cantidad > 0 ? monto / cantidad : 0.0;

                        return DataRow(
                          cells: [
                            DataCell(Text(mesNombre)),
                            DataCell(Text('$cantidad')),
                            DataCell(Text(formatCurrency.format(monto))),
                            DataCell(Text(formatCurrency.format(utilidad))),
                            DataCell(Text(formatCurrency.format(promedio))),
                          ],
                        );
                      }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Card(
        elevation: 2,
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error al cargar los datos: $errorMessage',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final _ = ref.refresh(ventasEstadisticasProvider(_periodo));
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generarReportePDF(AsyncValue<dynamic> reporteAsync) async {
    if (_isGeneratingPdf) return;

    // Añadir debounce
    final ahora = DateTime.now();
    if (_ultimaGeneracionPDF != null &&
        ahora.difference(_ultimaGeneracionPDF!).inSeconds < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Espere un momento antes de generar otro reporte'),
        ),
      );
      return;
    }
    _ultimaGeneracionPDF = ahora;

    if (reporteAsync is AsyncLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Espera a que se carguen los datos para generar el reporte',
          ),
        ),
      );
      return;
    }

    if (reporteAsync is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede generar el reporte debido a errores en los datos',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      // Castear explícitamente a VentaReporte para mejor tipado
      final VentaReporte data = reporteAsync.value as VentaReporte;
      final pdf = await PdfService.crearDocumento();

      // Agregar página de título
      await PdfService.agregarPaginaTitulo(
        pdf,
        'REPORTE DE VENTAS',
        'Periodo: ${DateFormat('dd/MM/yyyy').format(_periodo.start)} - ${DateFormat('dd/MM/yyyy').format(_periodo.end)}',
        imagePath: 'assets/logo.png',
      );

      // Agregar resumen general
      PdfService.agregarTabla(
        pdf,
        ['Métrica', 'Resultado'],
        [
          ['Total de Ventas', '${data.totalVentas}'],
          ['Ingresos Totales', formatCurrency.format(data.ingresoTotal)],
          ['Utilidad Total', formatCurrency.format(data.utilidadTotal)],
          ['Margen Promedio', '${data.margenPromedio.toStringAsFixed(2)}%'],
          [
            'Promedio por Venta',
            formatCurrency.format(
              data.totalVentas > 0 ? data.ingresoTotal / data.totalVentas : 0,
            ),
          ],
          [
            'Utilidad Promedio',
            formatCurrency.format(
              data.totalVentas > 0 ? data.utilidadTotal / data.totalVentas : 0,
            ),
          ],
        ],
        titulo: 'Resumen General',
      );

      // Agregar gráficos y tablas
      if (data.ventasPorTipo.isNotEmpty) {
        PdfService.agregarGraficoTorta(
          pdf,
          'Distribución por Tipo de Inmueble',
          data.ventasPorTipo,
        );
      }

      if (data.ventasMensuales.isNotEmpty) {
        PdfService.agregarGraficoBarras(
          pdf,
          'Evolución Mensual de Ventas',
          Map<String, double>.fromEntries(
            data.ventasMensuales.map((e) {
              // Validación más segura:
              final mes = e['mes'] as String? ?? 'Sin dato';
              final monto =
                  e['monto'] is num ? (e['monto'] as num).toDouble() : 0.0;
              return MapEntry(mes, monto);
            }),
          ),
          unidad: ' \$',
        );

        // Agregar tabla detallada
        final List<List<String>> rowsData = [];

        for (final mes in data.ventasMensuales) {
          final mesNombre = mes['mes'] as String? ?? 'Desconocido';
          final cantidad = mes['cantidad'] as int? ?? 0;
          final monto = (mes['monto'] as num?)?.toDouble() ?? 0.0;
          final utilidad = (mes['utilidad'] as num?)?.toDouble() ?? 0.0;
          final promedio = cantidad > 0 ? monto / cantidad : 0.0;

          rowsData.add([
            mesNombre,
            cantidad.toString(),
            formatCurrency.format(monto),
            formatCurrency.format(utilidad),
            formatCurrency.format(promedio),
          ]);
        }

        PdfService.agregarTabla(
          pdf,
          ['Mes', 'Cantidad', 'Monto', 'Utilidad', 'Promedio'],
          rowsData,
          titulo: 'Detalle Mensual de Ventas',
        );
      }

      // Guardar PDF
      final fechaStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'reporte_ventas_$fechaStr';
      final filePath = await PdfService.guardarDocumentoEnDirectorio(
        pdf,
        fileName,
        'estadisticas',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte generado con éxito'),
            action: SnackBarAction(
              label: 'ABRIR',
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.error('Error al generar reporte de ventas PDF', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al generar el reporte: ${e.toString().split('\n').first}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }
}

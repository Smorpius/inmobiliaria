import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import 'package:open_file/open_file.dart';
import '../widgets/loading_indicator.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../services/pdf_service.dart';
import '../widgets/rentas_chart_section.dart';
import '../widgets/filtro_periodo_widget.dart';
import '../../../providers/renta_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para obtener las estadísticas de rentas
final rentasEstadisticasProvider =
    FutureProvider.family<Map<String, dynamic>, DateTimeRange>((
      ref,
      periodo,
    ) async {
      // Obtenemos el servicio de rentas
      final rentaService = ref.watch(rentaProvider);
      // Llamamos al método para obtener estadísticas
      return await rentaService.obtenerEstadisticasRentas(periodo);
    });

class ReporteRentasScreen extends ConsumerStatefulWidget {
  final DateTimeRange periodoInicial;

  const ReporteRentasScreen({super.key, required this.periodoInicial});

  @override
  ConsumerState<ReporteRentasScreen> createState() =>
      _ReporteRentasScreenState();
}

class _ReporteRentasScreenState extends ConsumerState<ReporteRentasScreen> {
  late DateTimeRange _periodo;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _periodo = widget.periodoInicial;
  }

  @override
  Widget build(BuildContext context) {
    final reporteRentasAsync = ref.watch(rentasEstadisticasProvider(_periodo));

    return AppScaffold(
      title: 'Reporte de Rentas',
      currentRoute: '/estadisticas/rentas',
      actions: [
        IconButton(
          icon: Icon(
            _isGeneratingPdf ? Icons.hourglass_bottom : Icons.picture_as_pdf,
          ),
          tooltip: 'Exportar a PDF',
          onPressed:
              _isGeneratingPdf
                  ? null
                  : () => _generarReportePDF(reporteRentasAsync),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FiltroPeriodoWidget(
              periodo: _periodo,
              onPeriodChanged: (newPeriod) {
                setState(() {
                  _periodo = newPeriod;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildReporteContent(reporteRentasAsync)),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteContent(AsyncValue<Map<String, dynamic>> reporteAsync) {
    return reporteAsync.when(
      data: (data) => _buildReporte(data),
      loading:
          () => const LoadingIndicator(mensaje: 'Cargando datos de rentas...'),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildReporte(Map<String, dynamic> data) {
    // Extraer datos de estadísticas con valores por defecto para evitar nulos
    final totalContratos = data['totalContratos'] ?? 0;
    final contratosActivos = data['contratosActivos'] ?? 0;
    final ingresosMensuales = data['ingresosMensuales'] ?? 0.0;
    final egresosMensuales = data['egresosMensuales'] ?? 0.0;
    final balanceMensual = data['balanceMensual'] ?? 0.0;

    // Mejor cálculo de rentabilidad para evitar divisiones por cero
    final rentabilidad =
        data['rentabilidad'] ??
        (ingresosMensuales > 0
            ? (balanceMensual / ingresosMensuales) * 100
            : 0);

    final datosInmuebles = List<Map<String, dynamic>>.from(
      data['datosInmuebles'] ?? [],
    );
    final evolucionMensual = List<Map<String, dynamic>>.from(
      data['evolucionMensual'] ?? [],
    );

    return RefreshIndicator(
      onRefresh: () async {
        final _ = await ref.refresh(
          rentasEstadisticasProvider(_periodo).future,
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumenCard(
              totalContratos: totalContratos,
              contratosActivos: contratosActivos,
              ingresosMensuales: ingresosMensuales,
              egresosMensuales: egresosMensuales,
              balanceMensual: balanceMensual,
              rentabilidad: rentabilidad,
            ),
            const SizedBox(height: 24),
            RentasChartSection(
              datosInmuebles: datosInmuebles,
              evolucionMensual: evolucionMensual,
            ),
            const SizedBox(height: 24),
            _buildContratosList(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard({
    required int totalContratos,
    required int contratosActivos,
    required double ingresosMensuales,
    required double egresosMensuales,
    required double balanceMensual,
    required double rentabilidad,
  }) {
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
                Icon(Icons.insights, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Resumen de Rentas',
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
                    'Total de Contratos',
                    totalContratos.toString(),
                    Icons.description,
                    Colors.blue.shade700,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Contratos Activos',
                    contratosActivos.toString(),
                    Icons.fact_check,
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
                    'Ingresos Mensuales',
                    formatCurrency.format(ingresosMensuales),
                    Icons.arrow_upward,
                    Colors.green.shade700,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Egresos Mensuales',
                    formatCurrency.format(egresosMensuales),
                    Icons.arrow_downward,
                    Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Balance Mensual',
                    formatCurrency.format(balanceMensual),
                    Icons.account_balance,
                    Colors.purple.shade700,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Rentabilidad',
                    '${rentabilidad.toStringAsFixed(2)}%',
                    Icons.trending_up,
                    Colors.amber.shade700,
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
        Icon(icon, color: color, size: 32),
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
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildContratosList() {
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
                Icon(Icons.assignment, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Contratos Activos',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // Acción para ver todos los contratos
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ver todos los contratos')),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Ver Todos'),
                ),
              ],
            ),
            const Divider(height: 24),
            // Placeholder para lista de contratos
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Lista de contratos activos',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Aquí se mostrarán los contratos activos cuando se implemente la funcionalidad completa',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
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
                  final _ = ref.refresh(rentasEstadisticasProvider(_periodo));
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generarReportePDF(
    AsyncValue<Map<String, dynamic>> reporteAsync,
  ) async {
    if (_isGeneratingPdf) return;

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
      final data = reporteAsync.value;
      final pdf = await PdfService.crearDocumento();

      // Agregar página de título
      await PdfService.agregarPaginaTitulo(
        pdf,
        'REPORTE DE RENTAS',
        'Periodo: ${DateFormat('dd/MM/yyyy').format(_periodo.start)} - ${DateFormat('dd/MM/yyyy').format(_periodo.end)}',
        imagePath: 'assets/logo.png',
      );

      // Agregar resumen general
      PdfService.agregarTabla(
        pdf,
        ['Métrica', 'Resultado'],
        [
          ['Total de Contratos', '${data?['totalContratos'] ?? 0}'],
          ['Contratos Activos', '${data?['contratosActivos'] ?? 0}'],
          [
            'Ingresos Mensuales',
            NumberFormat.currency(
              symbol: '\$',
              locale: 'es_MX',
            ).format(data?['ingresosMensuales'] ?? 0.0),
          ],
          [
            'Egresos Mensuales',
            NumberFormat.currency(
              symbol: '\$',
              locale: 'es_MX',
            ).format(data?['egresosMensuales'] ?? 0.0),
          ],
          [
            'Balance Mensual',
            NumberFormat.currency(
              symbol: '\$',
              locale: 'es_MX',
            ).format(data?['balanceMensual'] ?? 0.0),
          ],
          [
            'Rentabilidad',
            '${(data?['rentabilidad'] ?? 0).toStringAsFixed(2)}%',
          ],
        ],
        titulo: 'Resumen General',
      );

      // Agregar tabla de inmuebles
      final List<List<String>> rowsInmuebles = [];
      final datosInmuebles = List<Map<String, dynamic>>.from(
        data?['datosInmuebles'] ?? [],
      );

      for (final inmueble in datosInmuebles) {
        rowsInmuebles.add([
          inmueble['nombre'] as String? ?? '',
          NumberFormat.currency(
            symbol: '\$',
            locale: 'es_MX',
          ).format(inmueble['ingresos'] ?? 0),
          NumberFormat.currency(
            symbol: '\$',
            locale: 'es_MX',
          ).format(inmueble['egresos'] ?? 0),
          NumberFormat.currency(
            symbol: '\$',
            locale: 'es_MX',
          ).format(inmueble['balance'] ?? 0),
        ]);
      }

      if (rowsInmuebles.isNotEmpty) {
        PdfService.agregarTabla(
          pdf,
          ['Inmueble', 'Ingresos', 'Egresos', 'Balance'],
          rowsInmuebles,
          titulo: 'Rendimiento por Inmueble',
        );
      }

      // Agregar datos de evolución mensual
      final evolucionMensual = List<Map<String, dynamic>>.from(
        data?['evolucionMensual'] ?? [],
      );

      if (evolucionMensual.isNotEmpty) {
        // Gráfico de líneas para evolución mensual
        PdfService.agregarGraficoLineas(pdf, 'Evolución Mensual', {
          for (var e in evolucionMensual)
            e['mes'] as String? ?? 'Sin fecha': [
              {
                'name': 'Ingresos',
                'value': (e['ingresos'] as num? ?? 0).toDouble(),
              },
              {
                'name': 'Egresos',
                'value': (e['egresos'] as num? ?? 0).toDouble(),
              },
              {
                'name': 'Balance',
                'value': (e['balance'] as num? ?? 0).toDouble(),
              },
            ],
        });

        // Tabla detallada de evolución mensual
        final List<List<String>> rowsMensuales = [];

        for (final mes in evolucionMensual) {
          rowsMensuales.add([
            mes['mes'] as String? ?? '',
            NumberFormat.currency(
              symbol: '\$',
              locale: 'es_MX',
            ).format(mes['ingresos'] ?? 0),
            NumberFormat.currency(
              symbol: '\$',
              locale: 'es_MX',
            ).format(mes['egresos'] ?? 0),
            NumberFormat.currency(
              symbol: '\$',
              locale: 'es_MX',
            ).format(mes['balance'] ?? 0),
          ]);
        }

        PdfService.agregarTabla(
          pdf,
          ['Mes', 'Ingresos', 'Egresos', 'Balance'],
          rowsMensuales,
          titulo: 'Detalle Mensual de Rentas',
        );
      }

      // Guardar PDF
      final fechaStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'reporte_rentas_$fechaStr';
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
      AppLogger.error('Error al generar reporte de rentas PDF', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar el reporte: ${e.toString()}'),
            backgroundColor: Colors.red,
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

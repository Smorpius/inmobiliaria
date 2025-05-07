import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import '../widgets/loading_indicator.dart';
import '../../../services/pdf_service.dart';
import '../widgets/filtro_periodo_widget.dart';
import '../../../providers/renta_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw; // <--- IMPORTACIÓN AGREGADA

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Rentas'),
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
      ),
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
            Card(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vista previa del reporte',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Periodo: ${DateFormat('dd/MM/yyyy').format(_periodo.start)} - ${DateFormat('dd/MM/yyyy').format(_periodo.end)}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: PdfPreview(
                maxPageWidth: 700,
                build: (format) async {
                  try {
                    final pdf = await PdfService.crearDocumento();

                    // Agregar página de título con datos reales
                    await PdfService.agregarPaginaTitulo(
                      pdf,
                      'REPORTE DE RENTAS', // Título real
                      'Periodo: ${DateFormat('dd/MM/yyyy').format(_periodo.start)} - ${DateFormat('dd/MM/yyyy').format(_periodo.end)}',
                      imagePath: 'assets/logo.png',
                    );

                    // --- UTILIZAR DATOS REALES CARGADOS (data) ---
                    // La variable 'data' proviene del snapshot del provider 'reporteAsync.when(data: (data) => _buildReporte(data))'

                    // Resumen General desde 'data'
                    final datosRealesResumen = [
                      ['Total de Contratos', '${data['totalContratos'] ?? 0}'],
                      ['Contratos Activos', '${data['contratosActivos'] ?? 0}'],
                      [
                        'Ingresos Mensuales',
                        NumberFormat.currency(
                          symbol: '\$',
                          locale: 'es_MX',
                        ).format(data['ingresosMensuales'] ?? 0.0),
                      ],
                      [
                        'Egresos Mensuales',
                        NumberFormat.currency(
                          symbol: '\$',
                          locale: 'es_MX',
                        ).format(data['egresosMensuales'] ?? 0.0),
                      ],
                      [
                        'Balance Mensual',
                        NumberFormat.currency(
                          symbol: '\$',
                          locale: 'es_MX',
                        ).format(data['balanceMensual'] ?? 0.0),
                      ],
                      [
                        'Rentabilidad',
                        '${(data['rentabilidad'] ?? 0.0).toStringAsFixed(2)}%',
                      ],
                    ];

                    if (data.isNotEmpty) {
                      // Verificar si hay datos antes de agregar la tabla
                      PdfService.agregarTabla(
                        pdf,
                        ['Métrica', 'Resultado'],
                        datosRealesResumen,
                        titulo: 'Resumen General',
                      );
                    } else {
                      pdf.addPage(
                        pw.Page(
                          // Asegurar que se usa el alias pw.
                          build: (pw.Context context) {
                            // Asegurar que se usa pw.Context
                            return pw.Center(
                              // Asegurar que se usa el alias pw.
                              child: pw.Text(
                                'Resumen General: No hay datos disponibles para el período seleccionado.',
                              ), // Asegurar que se usa el alias pw.
                            );
                          },
                        ),
                      );
                    }

                    // Rendimiento por Inmueble desde 'data'
                    final List<List<String>> datosRealesInmuebles = [];
                    final List<Map<String, dynamic>> datosInmueblesList =
                        List<Map<String, dynamic>>.from(
                          data['datosInmuebles'] ?? [],
                        );
                    for (final inmueble in datosInmueblesList) {
                      datosRealesInmuebles.add([
                        inmueble['nombre'] as String? ?? '',
                        NumberFormat.currency(
                          symbol: '\$',
                          locale: 'es_MX',
                        ).format(inmueble['ingresos'] ?? 0.0),
                        NumberFormat.currency(
                          symbol: '\$',
                          locale: 'es_MX',
                        ).format(inmueble['egresos'] ?? 0.0),
                        NumberFormat.currency(
                          symbol: '\$',
                          locale: 'es_MX',
                        ).format(inmueble['balance'] ?? 0.0),
                      ]);
                    }

                    if (datosRealesInmuebles.isNotEmpty) {
                      PdfService.agregarTabla(
                        pdf,
                        ['Inmueble', 'Ingresos', 'Egresos', 'Balance'],
                        datosRealesInmuebles,
                        titulo: 'Rendimiento por Inmueble',
                      );
                    } else {
                      pdf.addPage(
                        pw.Page(
                          // Asegurar que se usa el alias pw.
                          build: (pw.Context context) {
                            // Asegurar que se usa pw.Context
                            return pw.Center(
                              // Asegurar que se usa el alias pw.
                              child: pw.Text(
                                'Rendimiento por Inmueble: No hay datos disponibles para el período seleccionado.',
                              ), // Asegurar que se usa el alias pw.
                            );
                          },
                        ),
                      );
                    }

                    // Evolución Mensual (Gráfico y Tabla) desde 'data'
                    final List<Map<String, dynamic>> evolucionMensualList =
                        List<Map<String, dynamic>>.from(
                          data['evolucionMensual'] ?? [],
                        );

                    final Map<String, List<Map<String, dynamic>>>
                    datosRealesEvolucionGrafico = {};
                    final List<List<String>> datosRealesEvolucionTabla = [];

                    if (evolucionMensualList.isNotEmpty) {
                      for (var e in evolucionMensualList) {
                        final mes = e['mes'] as String? ?? 'Sin fecha';
                        datosRealesEvolucionGrafico[mes] = [
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
                        ];
                        datosRealesEvolucionTabla.add([
                          mes,
                          NumberFormat.currency(
                            symbol: '\$',
                            locale: 'es_MX',
                          ).format(e['ingresos'] ?? 0.0),
                          NumberFormat.currency(
                            symbol: '\$',
                            locale: 'es_MX',
                          ).format(e['egresos'] ?? 0.0),
                          NumberFormat.currency(
                            symbol: '\$',
                            locale: 'es_MX',
                          ).format(e['balance'] ?? 0.0),
                        ]);
                      }
                    }

                    if (datosRealesEvolucionGrafico.isNotEmpty) {
                      PdfService.agregarGraficoLineas(
                        pdf,
                        'Evolución Mensual',
                        datosRealesEvolucionGrafico,
                      );
                    } else {
                      pdf.addPage(
                        pw.Page(
                          // Asegurar que se usa el alias pw.
                          build: (pw.Context context) {
                            // Asegurar que se usa pw.Context
                            return pw.Center(
                              // Asegurar que se usa el alias pw.
                              child: pw.Text(
                                'Evolución Mensual (Gráfico): No hay datos disponibles para el período seleccionado.',
                              ), // Asegurar que se usa el alias pw.
                            );
                          },
                        ),
                      );
                    }

                    if (datosRealesEvolucionTabla.isNotEmpty) {
                      PdfService.agregarTabla(
                        pdf,
                        ['Mes', 'Ingresos', 'Egresos', 'Balance'],
                        datosRealesEvolucionTabla,
                        titulo: 'Detalle Mensual de Rentas',
                      );
                    } else {
                      pdf.addPage(
                        pw.Page(
                          // Asegurar que se usa el alias pw.
                          build: (pw.Context context) {
                            // Asegurar que se usa pw.Context
                            return pw.Center(
                              // Asegurar que se usa el alias pw.
                              child: pw.Text(
                                'Detalle Mensual de Rentas (Tabla): No hay datos disponibles para el período seleccionado.',
                              ), // Asegurar que se usa el alias pw.
                            );
                          },
                        ),
                      );
                    }

                    // Devolver el PDF generado
                    return pdf.save();
                  } catch (e) {
                    AppLogger.error(
                      'Error al generar vista previa del PDF',
                      e,
                      StackTrace.current,
                    );
                    throw Exception('Error al generar vista previa: $e');
                  }
                },
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                pdfFileName: 'reporte_rentas_preview.pdf',
                loadingWidget: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generando vista previa del reporte...'),
                    ],
                  ),
                ),
                onError: (context, error) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error al generar vista previa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          error.toString().split('\n').first,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
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
    } catch (e) {
      AppLogger.error(
        'Error al generar reporte de rentas PDF',
        e,
        StackTrace.current,
      );
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

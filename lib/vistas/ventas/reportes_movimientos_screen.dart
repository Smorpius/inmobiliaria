import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:inmobiliaria/utils/applogger.dart';
import 'package:inmobiliaria/services/pdf_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/utils/pdf_font_helper.dart';
import 'package:inmobiliaria/models/movimiento_renta_model.dart';
import 'package:inmobiliaria/providers/inmueble_renta_provider.dart';
import 'package:printing/printing.dart'; // Añadir esta importación para la vista previa

class ReportesMovimientosScreen extends ConsumerStatefulWidget {
  final int idInmueble;
  final String nombreInmueble;
  final DateTimeRange? periodoInicial;

  const ReportesMovimientosScreen({
    super.key,
    required this.idInmueble,
    required this.nombreInmueble,
    this.periodoInicial,
  });

  @override
  ConsumerState<ReportesMovimientosScreen> createState() =>
      _ReportesMovimientosScreenState();
}

class _ReportesMovimientosScreenState
    extends ConsumerState<ReportesMovimientosScreen> {
  late DateTimeRange _periodo;
  final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Usar el período proporcionado o uno predeterminado
    _periodo =
        widget.periodoInicial ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _periodo,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );

    if (picked != null && picked != _periodo) {
      setState(() {
        _periodo = picked;
      });
    }
  }

  // Método para generar el documento PDF
  Future<pw.Document> _generarDocumentoPDF(
    List<MovimientoRenta> movimientos,
  ) async {
    // Usar PdfService para garantizar soporte Unicode
    final pdf = await PdfService.crearDocumento();

    // Preparar estilos de texto con soporte Unicode
    final titleStyle = await PdfFontHelper.getTextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
    );
    final subtitleStyle = await PdfFontHelper.getTextStyle(fontSize: 14);
    final headerStyle = await PdfFontHelper.getTextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );
    final contentStyle = await PdfFontHelper.getTextStyle(fontSize: 10);
    final summaryTitleStyle = await PdfFontHelper.getTextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Reporte de Movimientos', style: titleStyle),
              pw.SizedBox(height: 10),
              pw.Text(
                'Inmueble: ${widget.nombreInmueble}',
                style: subtitleStyle,
              ),
              pw.Text(
                'Período: ${DateFormat('dd/MM/yyyy').format(_periodo.start)} - ${DateFormat('dd/MM/yyyy').format(_periodo.end)}',
                style: subtitleStyle,
              ),
              pw.SizedBox(height: 20),
              _buildMovimientosTable(movimientos, headerStyle, contentStyle),
              pw.SizedBox(height: 20),
              _buildResumenFinanciero(
                movimientos,
                summaryTitleStyle,
                contentStyle,
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _generarReporteMovimientos() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final movimientosAsync = await ref.read(
        movimientosPorInmuebleProvider(widget.idInmueble).future,
      );

      // Filtrar movimientos por fecha
      final movimientosFiltrados =
          movimientosAsync
              .where(
                (m) =>
                    m.fechaMovimiento.isAfter(_periodo.start) &&
                    m.fechaMovimiento.isBefore(
                      _periodo.end.add(const Duration(days: 1)),
                    ),
              )
              .toList();

      // Generar el documento PDF
      final pdf = await _generarDocumentoPDF(movimientosFiltrados);

      final fileName =
          'reporte_movimientos_${widget.idInmueble}_${DateFormat('yyyyMMdd').format(DateTime.now())}';
      final filePath = await PdfService.guardarDocumento(pdf, fileName);

      // Abrir el archivo generado
      if (mounted) {
        OpenFile.open(filePath);
      }
    } catch (e, stack) {
      AppLogger.error('Error al generar reporte de movimientos', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al generar el reporte')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  pw.Widget _buildMovimientosTable(
    List<MovimientoRenta> movimientos,
    pw.TextStyle headerStyle,
    pw.TextStyle contentStyle,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Encabezados con soporte para acentos
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Fecha', style: headerStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Concepto', style: headerStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Tipo', style: headerStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Monto', style: headerStyle),
            ),
          ],
        ),
        // Filas de datos
        ...movimientos.map(
          (m) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  DateFormat('dd/MM/yyyy').format(m.fechaMovimiento),
                  style: contentStyle,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(m.concepto, style: contentStyle),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  m.tipoMovimiento == 'ingreso' ? 'Ingreso' : 'Egreso',
                  style: contentStyle,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  formatCurrency.format(m.monto),
                  style: contentStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildResumenFinanciero(
    List<MovimientoRenta> movimientos,
    pw.TextStyle titleStyle,
    pw.TextStyle contentStyle,
  ) {
    final ingresos = movimientos
        .where((m) => m.tipoMovimiento == 'ingreso')
        .fold<double>(0, (sum, m) => sum + m.monto);
    final egresos = movimientos
        .where((m) => m.tipoMovimiento == 'egreso')
        .fold<double>(0, (sum, m) => sum + m.monto);
    final balance = ingresos - egresos;

    final balanceStyle = contentStyle.copyWith(
      color: balance >= 0 ? PdfColors.green : PdfColors.red,
      fontWeight: pw.FontWeight.bold,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Resumen Financiero', style: titleStyle),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Ingresos:', style: contentStyle),
              pw.Text(
                formatCurrency.format(ingresos),
                style: contentStyle.copyWith(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Egresos:', style: contentStyle),
              pw.Text(
                formatCurrency.format(egresos),
                style: contentStyle.copyWith(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Balance:', style: contentStyle),
              pw.Text(formatCurrency.format(balance), style: balanceStyle),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes de Movimientos'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.settings), text: 'Configuración'),
              Tab(icon: Icon(Icons.picture_as_pdf), text: 'Vista Previa'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildConfiguracionTab(), _buildVistaPreviaTab()],
        ),
      ),
    );
  }

  // Tab de configuración
  Widget _buildConfiguracionTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inmueble: ${widget.nombreInmueble}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Selector de rango de fechas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Período de reporte:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${DateFormat('dd/MM/yyyy').format(_periodo.start)} - ${DateFormat('dd/MM/yyyy').format(_periodo.end)}',
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Cambiar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botón para generar reporte
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generarReporteMovimientos,
              icon:
                  _isGenerating
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.picture_as_pdf),
              label: Text(
                _isGenerating ? 'Generando...' : 'Guardar Reporte PDF',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Nota sobre caracteres especiales
        ],
      ),
    );
  }

  // Tab de vista previa del PDF
  Widget _buildVistaPreviaTab() {
    return FutureBuilder<List<MovimientoRenta>>(
      future: _getMovimientosFiltrados(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error al cargar los datos: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}), // Recargar
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber, size: 60, color: Colors.amber),
                SizedBox(height: 16),
                Text('No hay movimientos para el período seleccionado'),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: PdfPreview(
            maxPageWidth: 700,
            build: (format) async {
              try {
                // Inicializar el sistema de fuentes (usará Helvetica incorporada)
                await PdfFontHelper.init();

                // Crear un documento PDF simple sin depender de fuentes externas
                final pdf = pw.Document();

                // Usar la fuente predeterminada (Helvetica)
                final font = await PdfFontHelper.getCachedFont();

                final titleStyle = pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                );
                final subtitleStyle = pw.TextStyle(font: font, fontSize: 14);
                final headerStyle = pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                );
                final contentStyle = pw.TextStyle(font: font, fontSize: 10);
                final summaryTitleStyle = pw.TextStyle(
                  font: font,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                );

                pdf.addPage(
                  pw.Page(
                    pageFormat: format,
                    build: (context) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Reporte de Movimientos', style: titleStyle),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'Inmueble: ${widget.nombreInmueble}',
                            style: subtitleStyle,
                          ),
                          pw.Text(
                            'Período: ${DateFormat('dd/MM/yyyy').format(_periodo.start)} - ${DateFormat('dd/MM/yyyy').format(_periodo.end)}',
                            style: subtitleStyle,
                          ),
                          pw.SizedBox(height: 20),
                          _buildMovimientosTable(
                            snapshot.data!,
                            headerStyle,
                            contentStyle,
                          ),
                          pw.SizedBox(height: 20),
                          _buildResumenFinanciero(
                            snapshot.data!,
                            summaryTitleStyle,
                            contentStyle,
                          ),
                        ],
                      );
                    },
                  ),
                );

                return pdf.save();
              } catch (e, stack) {
                AppLogger.error(
                  'Error al generar la vista previa del PDF',
                  e,
                  stack,
                );

                // En caso de error, generar un PDF simple con mensaje de error
                final pdf = pw.Document();
                pdf.addPage(
                  pw.Page(
                    build:
                        (context) => pw.Center(
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                'Error al generar la vista previa',
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  color: PdfColors.red,
                                ),
                              ),
                              pw.SizedBox(height: 20),
                              pw.Text(
                                'Detalles del error: $e',
                                style: pw.TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                  ),
                );
                return pdf.save();
              }
            },
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
            pdfFileName:
                'reporte_movimientos_${widget.idInmueble}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
            previewPageMargin: const EdgeInsets.all(10),
            loadingWidget: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando vista previa del PDF...'),
                ],
              ),
            ),
            actions: [
              PdfPreviewAction(
                icon: const Icon(Icons.description),
                onPressed: (context, pdfBytes, pages) {
                  // Personalizar la acción de compartir si es necesario
                },
              ),
            ],
            onError: (context, error) {
              // Mostramos un mensaje de error en la interfaz
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al generar PDF: ${error.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
              return const Center(
                child: Text('Error al generar la vista previa del documento'),
              );
            },
          ),
        );
      },
    );
  }

  // Obtener los movimientos filtrados para la vista previa
  Future<List<MovimientoRenta>> _getMovimientosFiltrados() async {
    final movimientosAsync = await ref.read(
      movimientosPorInmuebleProvider(widget.idInmueble).future,
    );

    // Filtrar movimientos por fecha
    final movimientosFiltrados =
        movimientosAsync
            .where(
              (m) =>
                  m.fechaMovimiento.isAfter(_periodo.start) &&
                  m.fechaMovimiento.isBefore(
                    _periodo.end.add(const Duration(days: 1)),
                  ),
            )
            .toList();

    return movimientosFiltrados;
  }
}

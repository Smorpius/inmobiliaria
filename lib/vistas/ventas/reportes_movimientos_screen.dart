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

class ReportesMovimientosScreen extends ConsumerStatefulWidget {
  final int idInmueble;
  final String nombreInmueble;

  const ReportesMovimientosScreen({
    super.key,
    required this.idInmueble,
    required this.nombreInmueble,
  });

  @override
  ConsumerState<ReportesMovimientosScreen> createState() =>
      _ReportesMovimientosScreenState();
}

class _ReportesMovimientosScreenState
    extends ConsumerState<ReportesMovimientosScreen> {
  DateTimeRange _periodo = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
  bool _isGenerating = false;

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
                _buildMovimientosTable(
                  movimientosFiltrados,
                  headerStyle,
                  contentStyle,
                ),
                pw.SizedBox(height: 20),
                _buildResumenFinanciero(
                  movimientosFiltrados,
                  summaryTitleStyle,
                  contentStyle,
                ),
              ],
            );
          },
        ),
      );

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
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes de Movimientos')),
      body: Padding(
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
                  _isGenerating ? 'Generando...' : 'Generar Reporte PDF',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Nota sobre caracteres especiales
            const Text(
              'Este reporte incluirá todos los caracteres acentuados y símbolos especiales correctamente.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

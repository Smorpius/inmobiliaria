import 'pdf_service.dart';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../utils/applogger.dart';
import '../models/cliente_model.dart';
import 'package:flutter/services.dart';
import '../models/inmueble_model.dart';
import '../utils/pdf_font_helper.dart';
import 'package:pdf/widgets.dart' as pw;

class ContratoPdfService {
  /// Genera un contrato de venta en formato PDF
  Future<String> generarContratoVentaPDF({
    required Inmueble inmueble,
    required Cliente cliente,
    required double montoVenta,
    DateTime? fechaContrato,
  }) async {
    try {
      // Usar PdfService en lugar de crear el documento directamente
      final pdf = await PdfService.crearDocumento();

      // Precargar la fuente para usarla en todo el documento
      final font = await PdfFontHelper.getCachedFont();

      // Cargar logo (opcional)
      Uint8List? logoData;
      pw.MemoryImage? logoImage;
      try {
        logoData = await rootBundle
            .load('assets/logo.png')
            .then((data) => data.buffer.asUint8List());
        if (logoData != null) {
          logoImage = pw.MemoryImage(logoData);
        }
      } catch (e) {
        AppLogger.warning('No se pudo cargar el logo: $e');
      }

      final contrato = fechaContrato ?? DateTime.now();

      pdf.addPage(
        pw.MultiPage(
          header: (context) {
            final titleStyle = pw.TextStyle(
              font: font,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            );
            final subtitleStyle = pw.TextStyle(font: font, fontSize: 10);

            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 1, color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  logoImage != null
                      ? pw.Image(logoImage, width: 60)
                      : pw.Container(
                        width: 60,
                        height: 60,
                        child: pw.Center(
                          child: pw.Text('LOGO', style: subtitleStyle),
                        ),
                      ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('CONTRATO', style: titleStyle),
                      pw.Text('INMOBILIARIA', style: subtitleStyle),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        style: subtitleStyle,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          footer: (context) {
            final footerStyle = pw.TextStyle(font: font, fontSize: 8);

            return pw.Container(
              padding: const pw.EdgeInsets.only(top: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(width: 1, color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Documento legal - Inmobiliaria', style: footerStyle),
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: footerStyle,
                  ),
                ],
              ),
            );
          },
          build: (context) {
            final titleStyle = pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            );
            final bodyStyle = pw.TextStyle(font: font);
            final clauseTitleStyle = pw.TextStyle(
              font: font,
              fontWeight: pw.FontWeight.bold,
            );
            final signatureStyle = pw.TextStyle(font: font, fontSize: 10);

            return [
              // Título
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'CONTRATO DE COMPRAVENTA',
                  style: titleStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 20),

              // Introducción
              pw.Paragraph(
                text:
                    'En la ciudad de ${inmueble.ciudad ?? "---"}, a los ${contrato.day} días del mes de ${_getNombreMes(contrato.month)} del año ${contrato.year}, celebran el presente contrato de compraventa:',
                style: bodyStyle,
              ),
              pw.SizedBox(height: 10),

              // Cláusulas
              _buildClause(
                'VENDEDOR',
                'La empresa INMOBILIARIA, representada en este acto por su representante legal, en adelante "EL VENDEDOR".',
                clauseTitleStyle,
                bodyStyle,
                font,
              ),
              _buildClause(
                'COMPRADOR',
                '${cliente.nombreCompleto}, con domicilio en ${cliente.direccionCompleta}, en adelante "EL COMPRADOR".',
                clauseTitleStyle,
                bodyStyle,
                font,
              ),
              _buildClause(
                'INMUEBLE OBJETO DE VENTA',
                '''
                El inmueble ubicado en ${inmueble.direccionCompleta ?? "---"}, con las siguientes características:
                - Tipo: ${inmueble.tipoInmueble}
                - Características: ${inmueble.caracteristicas ?? "No especificado"}
                ''',
                clauseTitleStyle,
                bodyStyle,
                font,
              ),
              _buildClause(
                'PRECIO Y FORMA DE PAGO',
                'El precio pactado por la venta es de ${NumberFormat.currency(locale: "es_MX", symbol: "\$").format(montoVenta)} (${_convertirNumeroALetras(montoVenta)} PESOS MXN), que EL COMPRADOR se compromete a pagar en los términos establecidos en este contrato.',
                clauseTitleStyle,
                bodyStyle,
                font,
              ),
              _buildClause(
                'ENTREGA DEL INMUEBLE',
                'EL VENDEDOR se compromete a entregar el inmueble libre de todo gravamen y al corriente en el pago de impuestos y servicios.',
                clauseTitleStyle,
                bodyStyle,
                font,
              ),

              // Firmas
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSignatureLine('EL VENDEDOR', signatureStyle, font),
                  _buildSignatureLine('EL COMPRADOR', signatureStyle, font),
                ],
              ),
            ];
          },
        ),
      );

      final fileName =
          'contrato_venta_${inmueble.id}_${DateFormat('yyyyMMdd').format(DateTime.now())}';
      final filePath = await PdfService.guardarDocumento(pdf, fileName);
      AppLogger.info('Contrato de venta generado: $filePath');
      return filePath;
    } catch (e, stackTrace) {
      AppLogger.error('Error al generar contrato de venta PDF', e, stackTrace);
      throw Exception('Error al generar PDF: $e');
    }
  }

  /// Genera un contrato de renta en formato PDF
  Future<String> generarContratoRentaPDF({
    required Inmueble inmueble,
    required Cliente cliente,
    required double montoRenta,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? condicionesAdicionales,
  }) async {
    try {
      // Usar PdfService en lugar de crear el documento directamente
      final pdf = await PdfService.crearDocumento();

      // Precargar la fuente para usarla en todo el documento
      final font = await PdfFontHelper.getCachedFont();

      // Cargar logo (opcional)
      Uint8List? logoData;
      pw.MemoryImage? logoImage;
      try {
        logoData = await rootBundle
            .load('assets/logo.png')
            .then((data) => data.buffer.asUint8List());
        if (logoData != null) {
          logoImage = pw.MemoryImage(logoData);
        }
      } catch (e) {
        AppLogger.warning('No se pudo cargar el logo: $e');
      }

      pdf.addPage(
        pw.MultiPage(
          header: (context) {
            final titleStyle = pw.TextStyle(
              font: font,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            );
            final subtitleStyle = pw.TextStyle(font: font, fontSize: 10);

            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 1, color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  logoImage != null
                      ? pw.Image(logoImage, width: 60)
                      : pw.Container(
                        width: 60,
                        height: 60,
                        child: pw.Center(
                          child: pw.Text('LOGO', style: subtitleStyle),
                        ),
                      ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('CONTRATO', style: titleStyle),
                      pw.Text('INMOBILIARIA', style: subtitleStyle),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        style: subtitleStyle,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          footer: (context) {
            final footerStyle = pw.TextStyle(font: font, fontSize: 8);

            return pw.Container(
              padding: const pw.EdgeInsets.only(top: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(width: 1, color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Documento legal - Inmobiliaria', style: footerStyle),
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: footerStyle,
                  ),
                ],
              ),
            );
          },
          build: (context) {
            final titleStyle = pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            );
            final bodyStyle = pw.TextStyle(font: font);
            final clauseTitleStyle = pw.TextStyle(
              font: font,
              fontWeight: pw.FontWeight.bold,
            );
            final signatureStyle = pw.TextStyle(font: font, fontSize: 10);

            return [
              // Título
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'CONTRATO DE ARRENDAMIENTO',
                  style: titleStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 20),

              // Introducción
              pw.Paragraph(
                text:
                    'En la ciudad de ${inmueble.ciudad ?? "---"}, a los ${fechaInicio.day} días del mes de ${_getNombreMes(fechaInicio.month)} del año ${fechaInicio.year}, celebran el presente contrato de arrendamiento:',
                style: bodyStyle,
              ),
              pw.SizedBox(height: 10),

              // Cláusulas
              _buildClause(
                'ARRENDADOR',
                'La empresa INMOBILIARIA, representada en este acto por su representante legal, en adelante "EL ARRENDADOR".',
                clauseTitleStyle,
                bodyStyle,
                font,
              ),
              _buildClause(
                'ARRENDATARIO',
                '${cliente.nombreCompleto}, con domicilio en ${cliente.direccionCompleta}, en adelante "EL ARRENDATARIO".',
                clauseTitleStyle,
                bodyStyle,
                font,
              ),
              _buildClause(
                'INMUEBLE OBJETO DEL ARRENDAMIENTO',
                '''
                El inmueble ubicado en ${inmueble.direccionCompleta ?? "---"}, con las siguientes características:
                - Tipo: ${inmueble.tipoInmueble}
                - Características: ${inmueble.caracteristicas ?? "No especificado"}
                ''',
                clauseTitleStyle,
                bodyStyle,
                font,
              ),
              _buildClause(
                'DURACIÓN DEL CONTRATO',
                'El presente contrato tendrá una vigencia de ${_calcularDuracionContrato(fechaInicio, fechaFin)} meses, iniciando el día ${DateFormat('dd/MM/yyyy').format(fechaInicio)} y concluyendo el día ${DateFormat('dd/MM/yyyy').format(fechaFin)}.',
                clauseTitleStyle,
                bodyStyle,
                font,
              ),
              _buildClause(
                'RENTA MENSUAL',
                'El precio pactado por la renta mensual es de ${NumberFormat.currency(locale: "es_MX", symbol: "\$").format(montoRenta)} (${_convertirNumeroALetras(montoRenta)} PESOS MXN), que EL ARRENDATARIO se compromete a pagar los primeros 5 días de cada mes.',
                clauseTitleStyle,
                bodyStyle,
                font,
              ),
              if (condicionesAdicionales != null &&
                  condicionesAdicionales.isNotEmpty)
                _buildClause(
                  'CONDICIONES ADICIONALES',
                  condicionesAdicionales,
                  clauseTitleStyle,
                  bodyStyle,
                  font,
                ),

              // Firmas
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSignatureLine('EL ARRENDADOR', signatureStyle, font),
                  _buildSignatureLine('EL ARRENDATARIO', signatureStyle, font),
                ],
              ),
            ];
          },
        ),
      );

      final fileName =
          'contrato_renta_${inmueble.id}_${DateFormat('yyyyMMdd').format(DateTime.now())}';
      final filePath = await PdfService.guardarDocumento(pdf, fileName);
      AppLogger.info('Contrato de renta generado: $filePath');
      return filePath;
    } catch (e, stackTrace) {
      AppLogger.error('Error al generar contrato de renta PDF', e, stackTrace);
      throw Exception('Error al generar PDF: $e');
    }
  }

  // Funciones auxiliares
  String _getNombreMes(int mes) {
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return meses[mes - 1];
  }

  String _convertirNumeroALetras(double numero) {
    // Implementación básica para convertir números a letras
    // Esta función puede ser expandida con una implementación completa
    final entero = numero.toInt();
    return entero.toString();
  }

  int _calcularDuracionContrato(DateTime inicio, DateTime fin) {
    return ((fin.difference(inicio).inDays) / 30).round();
  }

  pw.Widget _buildClause(
    String title,
    String content,
    pw.TextStyle titleStyle,
    pw.TextStyle contentStyle,
    pw.Font font,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: titleStyle),
          pw.SizedBox(height: 6), // Aumentar ligeramente el espaciado
          pw.Container(
            padding: const pw.EdgeInsets.all(10), // Aumentar el padding
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(content, style: contentStyle),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureLine(
    String title,
    pw.TextStyle textStyle,
    pw.Font font,
  ) {
    return pw.Container(
      width: 150,
      child: pw.Column(
        children: [
          pw.Container(
            width: 120,
            height: 1,
            margin: const pw.EdgeInsets.only(bottom: 5),
            color: PdfColors.black,
          ),
          pw.Text(title, style: textStyle),
        ],
      ),
    );
  }
}

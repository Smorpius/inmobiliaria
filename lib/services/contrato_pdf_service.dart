import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/inmueble_model.dart';
import '../models/cliente_model.dart';
import '../utils/applogger.dart';

class ContratoPdfService {
  /// Genera un contrato de venta en formato PDF
  Future<String> generarContratoVentaPDF({
    required Inmueble inmueble,
    required Cliente cliente,
    required double montoVenta,
    DateTime? fechaContrato,
  }) async {
    try {
      final pdf = pw.Document();
      final fechaActual = fechaContrato ?? DateTime.now();
      final formatoFecha = DateFormat('dd/MM/yyyy');
      final formatoMoneda = NumberFormat.currency(symbol: '\$', locale: 'es_MX');

      // Obtener el logo desde assets si existe
      pw.MemoryImage? logoImage;
      try {
        final logoData = await rootBundle.load('assets/logo.png');
        logoImage = pw.MemoryImage(
          logoData.buffer.asUint8List(),
        );
      } catch (e) {
        AppLogger.info('No se pudo cargar el logo: $e');
      }

      // Crear el PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          header: (context) => _buildHeader(logoImage),
          footer: (context) => _buildFooter(context.pageNumber, context.pagesCount),
          build: (context) => [
            _buildTitle('CONTRATO DE COMPRAVENTA DE BIEN INMUEBLE'),
            pw.SizedBox(height: 20),
            
            // Introducción/preámbulo
            pw.Paragraph(
              text: 'En ${inmueble.direccionCiudad ?? "la ciudad"}, a ${formatoFecha.format(fechaActual)}, comparecen:',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 10),
            
            // Datos del vendedor (la inmobiliaria)
            pw.Paragraph(
              text: 'Por una parte, LA EMPRESA INMOBILIARIA, representada legalmente por ___________________, en adelante denominado "EL VENDEDOR".',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 10),
            
            // Datos del cliente
            pw.Paragraph(
              text: 'Por otra parte, ${cliente.nombre} ${cliente.apellidoPaterno} ${cliente.apellidoMaterno ?? ""}, '
                  'con identificación ${cliente.documentoIdentidad ?? "___________"}, '
                  'con domicilio en ${cliente.direccion ?? "___________"}, '
                  'en adelante denominado "EL COMPRADOR".',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 10),
            
            // Declaración de capacidad
            pw.Paragraph(
              text: 'Ambas partes declaran tener la capacidad legal necesaria para contratar y obligarse, y libre y voluntariamente convienen celebrar el presente CONTRATO DE COMPRAVENTA al tenor de las siguientes cláusulas:',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 20),
            
            // Cláusula primera - Objeto de la compraventa
            _buildClause('PRIMERA - OBJETO DE LA COMPRAVENTA', 
              'EL VENDEDOR transfiere a título de venta real y efectiva a favor de EL COMPRADOR, el inmueble de su propiedad ubicado en: '
              '${inmueble.direccionCalle ?? ""} ${inmueble.direccionNumero ?? ""}, ${inmueble.direccionColonia ?? ""}, '
              '${inmueble.direccionCiudad ?? ""}, ${inmueble.direccionEstadoGeografico ?? ""}, '
              'C.P. ${inmueble.direccionCodigoPostal ?? ""}, con las siguientes características: '
              '${inmueble.caracteristicas ?? ""}.'
            ),
            
            // Cláusula segunda - Precio y forma de pago
            _buildClause('SEGUNDA - PRECIO Y FORMA DE PAGO', 
              'El precio pactado por las partes para la presente compraventa es de ${formatoMoneda.format(montoVenta)}, '
              'que EL COMPRADOR pagará a EL VENDEDOR de la siguiente manera: [DETALLAR FORMA DE PAGO].'
            ),
            
            // Cláusula tercera - Entrega del bien
            _buildClause('TERCERA - ENTREGA DEL BIEN', 
              'EL VENDEDOR se obliga a entregar el bien inmueble objeto de este contrato a EL COMPRADOR en un plazo máximo de '
              '30 días calendario contados a partir de la firma del presente contrato, libre de todo gravamen, carga, ocupante o cualquier '
              'restricción que pudiera limitar su uso y goce.'
            ),
            
            // Cláusula cuarta - Estado del inmueble
            _buildClause('CUARTA - ESTADO DEL INMUEBLE', 
              'EL COMPRADOR declara conocer el estado físico y jurídico del inmueble objeto del presente contrato y manifestando expresamente '
              'su conformidad respecto del mismo.'
            ),
            
            // Cláusula quinta - Gastos y honorarios
            _buildClause('QUINTA - GASTOS Y HONORARIOS', 
              'Los gastos, impuestos, honorarios notariales y registrales que generen la formalización de la presente compraventa '
              'serán asumidos por EL COMPRADOR.'
            ),
            
            // Cláusula sexta - Saneamiento
            _buildClause('SEXTA - SANEAMIENTO', 
              'EL VENDEDOR garantiza que el inmueble no tiene ningún gravamen ni restricción que pueda limitar su dominio, posesión, uso o goce, '
              'comprometiéndose al saneamiento en caso de evicción conforme a la ley.'
            ),
            
            // Cláusula séptima - Resolución de controversias
            _buildClause('SÉPTIMA - RESOLUCIÓN DE CONTROVERSIAS', 
              'Cualquier controversia derivada de la interpretación o ejecución del presente contrato será resuelta mediante negociación '
              'directa entre las partes. De no llegar a un acuerdo, las partes se someten a la jurisdicción y competencia de los tribunales de '
              '${inmueble.direccionCiudad ?? "la ciudad"}, renunciando expresamente a cualquier otra jurisdicción que pudiera corresponderles.'
            ),
            
            pw.SizedBox(height: 60),
            
            // Firmas
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildSignatureLine('EL VENDEDOR'),
                _buildSignatureLine('EL COMPRADOR'),
              ],
            ),
          ],
        ),
      );

      // Guardar el PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/contrato_venta_${inmueble.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e, stackTrace) {
      AppLogger.error('Error al generar contrato de venta PDF', e, stackTrace);
      rethrow;
    }
  }

  /// Genera un contrato de renta en formato PDF
  Future<String> generarContratoRentaPDF({
    required Inmueble inmueble,
    required Cliente cliente,
    required double montoMensual,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? condicionesAdicionales,
  }) async {
    try {
      final pdf = pw.Document();
      final formatoFecha = DateFormat('dd/MM/yyyy');
      final formatoMoneda = NumberFormat.currency(symbol: '\$', locale: 'es_MX');

      // Obtener el logo desde assets si existe
      pw.MemoryImage? logoImage;
      try {
        final logoData = await rootBundle.load('assets/logo.png');
        logoImage = pw.MemoryImage(
          logoData.buffer.asUint8List(),
        );
      } catch (e) {
        AppLogger.info('No se pudo cargar el logo: $e');
      }

      // Calcular duración del contrato en meses
      final meses = (fechaFin.year - fechaInicio.year) * 12 + fechaFin.month - fechaInicio.month;

      // Crear el PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          header: (context) => _buildHeader(logoImage),
          footer: (context) => _buildFooter(context.pageNumber, context.pagesCount),
          build: (context) => [
            _buildTitle('CONTRATO DE ARRENDAMIENTO DE BIEN INMUEBLE'),
            pw.SizedBox(height: 20),
            
            // Introducción/preámbulo
            pw.Paragraph(
              text: 'En ${inmueble.direccionCiudad ?? "la ciudad"}, a ${formatoFecha.format(DateTime.now())}, comparecen:',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 10),
            
            // Datos del arrendador (la inmobiliaria)
            pw.Paragraph(
              text: 'Por una parte, LA EMPRESA INMOBILIARIA, representada legalmente por ___________________, en adelante denominado "EL ARRENDADOR".',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 10),
            
            // Datos del cliente
            pw.Paragraph(
              text: 'Por otra parte, ${cliente.nombre} ${cliente.apellidoPaterno} ${cliente.apellidoMaterno ?? ""}, '
                  'con identificación ${cliente.documentoIdentidad ?? "___________"}, '
                  'con domicilio en ${cliente.direccion ?? "___________"}, '
                  'en adelante denominado "EL ARRENDATARIO".',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 10),
            
            // Declaración de capacidad
            pw.Paragraph(
              text: 'Ambas partes declaran tener la capacidad legal necesaria para contratar y obligarse, y libre y voluntariamente convienen celebrar el presente CONTRATO DE ARRENDAMIENTO al tenor de las siguientes cláusulas:',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 20),
            
            // Cláusula primera - Objeto del arrendamiento
            _buildClause('PRIMERA - OBJETO DEL ARRENDAMIENTO', 
              'EL ARRENDADOR da en arrendamiento a EL ARRENDATARIO, el inmueble ubicado en: '
              '${inmueble.direccionCalle ?? ""} ${inmueble.direccionNumero ?? ""}, ${inmueble.direccionColonia ?? ""}, '
              '${inmueble.direccionCiudad ?? ""}, ${inmueble.direccionEstadoGeografico ?? ""}, '
              'C.P. ${inmueble.direccionCodigoPostal ?? ""}, con las siguientes características: '
              '${inmueble.caracteristicas ?? ""}.'
            ),
            
            // Cláusula segunda - Duración del contrato
            _buildClause('SEGUNDA - DURACIÓN DEL CONTRATO', 
              'El presente contrato tendrá una vigencia de $meses meses, iniciando el ${formatoFecha.format(fechaInicio)} '
              'y finalizando el ${formatoFecha.format(fechaFin)}, sin necesidad de requerimiento previo.'
            ),
            
            // Cláusula tercera - Renta y forma de pago
            _buildClause('TERCERA - RENTA Y FORMA DE PAGO', 
              'EL ARRENDATARIO se obliga a pagar a EL ARRENDADOR por concepto de renta mensual la cantidad de '
              '${formatoMoneda.format(montoMensual)}, que deberá ser pagada dentro de los primeros 5 días de cada mes, '
              'mediante depósito o transferencia bancaria a la cuenta que designe EL ARRENDADOR.'
            ),
            
            // Cláusula cuarta - Garantía / Depósito
            _buildClause('CUARTA - GARANTÍA', 
              'EL ARRENDATARIO entrega a EL ARRENDADOR en este acto, por concepto de garantía, la cantidad equivalente a '
              'un mes de renta, es decir la suma de ${formatoMoneda.format(montoMensual)}, que será devuelta al finalizar el '
              'contrato, siempre y cuando EL ARRENDATARIO haya cumplido con todas sus obligaciones y el inmueble se encuentre '
              'en las mismas condiciones en que fue recibido, salvo el deterioro normal por el uso.'
            ),
            
            // Cláusula quinta - Servicios y mantenimiento
            _buildClause('QUINTA - SERVICIOS Y MANTENIMIENTO', 
              'EL ARRENDATARIO se obliga a pagar por su cuenta los servicios de agua, luz, gas, teléfono y cualquier otro servicio '
              'que utilice en el inmueble arrendado. Asimismo, se obliga a mantener el inmueble en buen estado de uso, conservación '
              'y limpieza.'
            ),
            
            // Cláusula sexta - Prohibiciones
            _buildClause('SEXTA - PROHIBICIONES', 
              'Queda expresamente prohibido a EL ARRENDATARIO subarrendar o ceder total o parcialmente los derechos derivados del '
              'presente contrato, así como destinar el inmueble a un uso distinto al habitacional, salvo autorización expresa y por '
              'escrito de EL ARRENDADOR.'
            ),
            
            // Condiciones adicionales (si existen)
            if (condicionesAdicionales != null && condicionesAdicionales.isNotEmpty)
              _buildClause('SÉPTIMA - CONDICIONES ADICIONALES', condicionesAdicionales),
            
            // Cláusula de resolución de controversias
            _buildClause(condicionesAdicionales != null && condicionesAdicionales.isNotEmpty ? 
              'OCTAVA - RESOLUCIÓN DE CONTROVERSIAS' : 'SÉPTIMA - RESOLUCIÓN DE CONTROVERSIAS', 
              'Cualquier controversia derivada de la interpretación o ejecución del presente contrato será resuelta mediante negociación '
              'directa entre las partes. De no llegar a un acuerdo, las partes se someten a la jurisdicción y competencia de los tribunales de '
              '${inmueble.direccionCiudad ?? "la ciudad"}, renunciando expresamente a cualquier otra jurisdicción que pudiera corresponderles.'
            ),
            
            pw.SizedBox(height: 60),
            
            // Firmas
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildSignatureLine('EL ARRENDADOR'),
                _buildSignatureLine('EL ARRENDATARIO'),
              ],
            ),
          ],
        ),
      );

      // Guardar el PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/contrato_renta_${inmueble.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e, stackTrace) {
      AppLogger.error('Error al generar contrato de renta PDF', e, stackTrace);
      rethrow;
    }
  }

  // Funciones auxiliares para construir el PDF
  pw.Widget _buildHeader(pw.MemoryImage? logoImage) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          if (logoImage != null)
            pw.Container(
              height: 60,
              width: 120,
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
          pw.SizedBox(height: 5),
          pw.Text(
            'INMOBILIARIA',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Dirección de la Inmobiliaria - Teléfono - Correo electrónico',
            style: const pw.TextStyle(
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(int pageNumber, int pageCount) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      alignment: pw.Alignment.centerRight,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Contrato generado el ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Página $pageNumber de $pageCount',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTitle(String title) {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildClause(String title, String content) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            content,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureLine(String title) {
    return pw.Container(
      width: 200,
      child: pw.Column(
        children: [
          pw.Container(
            width: 150,
            height: 1,
            color: PdfColors.black,
            margin: const pw.EdgeInsets.only(bottom: 5),
          ),
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
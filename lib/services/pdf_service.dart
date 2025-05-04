import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'directory_service.dart';
import '../utils/applogger.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
// import 'dart:typed_data'; - Eliminado el import no usado

/// Servicio para generar documentos PDF
class PdfService {
  /// Crea un documento PDF vacío con configuración estándar
  static Future<pw.Document> crearDocumento() async {
    final pdf = pw.Document(
      author: 'Sistema de Inmobiliaria',
      creator: 'Inmobiliaria App',
      subject: 'Reporte',
    );

    return pdf;
  }

  /// Guarda un documento PDF en el sistema de archivos en el directorio documentos
  static Future<String> guardarDocumento(
    pw.Document pdf,
    String nombreArchivo,
  ) async {
    try {
      // Obtener directorio de documentos
      final tempDir = await DirectoryService.getDirectoryPath('documentos');
      if (tempDir == null) {
        throw Exception('No se pudo obtener el directorio de documentos');
      }

      // Asegurar que el nombre del archivo tenga extensión .pdf
      String nombreFinal = nombreArchivo;
      if (!nombreFinal.toLowerCase().endsWith('.pdf')) {
        nombreFinal = '$nombreFinal.pdf';
      }

      final String rutaCompleta = path.join(tempDir, nombreFinal);
      final file = File(rutaCompleta);
      await file.writeAsBytes(await pdf.save());

      AppLogger.info('Documento guardado en: $rutaCompleta');
      return rutaCompleta;
    } catch (e, stackTrace) {
      AppLogger.error('Error al guardar documento PDF', e, stackTrace);
      throw Exception('Error al guardar el PDF: $e');
    }
  }

  /// Guarda un documento PDF en un directorio específico
  static Future<String> guardarDocumentoEnDirectorio(
    pw.Document pdf,
    String nombreArchivo,
    String directorio,
  ) async {
    try {
      // Asegurar que el directorio exista
      final dirPath = await DirectoryService.getDirectoryPath(directorio);
      if (dirPath == null) {
        throw Exception(
          'No se pudo obtener la ruta del directorio $directorio',
        );
      }

      // Agregar extensión .pdf si no está presente
      final nombre =
          nombreArchivo.endsWith('.pdf') ? nombreArchivo : '$nombreArchivo.pdf';

      final filePath = path.join(dirPath, nombre);
      final file = File(filePath);

      // Guardar el documento
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      AppLogger.info('Documento PDF guardado en: $filePath');
      return filePath;
    } catch (e, stackTrace) {
      AppLogger.error('Error al guardar documento PDF', e, stackTrace);
      rethrow;
    }
  }

  /// Método para guardar un contrato PDF en el directorio correspondiente según su tipo
  static Future<String> guardarContratoPDF(
    pw.Document pdf,
    String nombreArchivo,
    String tipoContrato,
  ) async {
    final directorio =
        tipoContrato.toLowerCase() == 'venta'
            ? 'contratos_venta'
            : 'contratos_renta';

    return await guardarDocumentoEnDirectorio(pdf, nombreArchivo, directorio);
  }

  /// Método para agregar una página de título al documento
  static Future<void> agregarPaginaTitulo(
    pw.Document pdf,
    String titulo,
    String subtitulo, {
    String? imagePath,
  }) async {
    try {
      pw.ImageProvider? logoProvider;

      // Intentar cargar el logo si existe
      if (imagePath != null) {
        try {
          final logoFile = File(imagePath);
          if (await logoFile.exists()) {
            final logoBytes = await logoFile.readAsBytes();
            logoProvider = pw.MemoryImage(logoBytes);
          } else {
            // Intentar cargar desde assets
            try {
              final assetLogoBytes = await rootBundle.load(imagePath);
              logoProvider = pw.MemoryImage(
                assetLogoBytes.buffer.asUint8List(),
              );
            } catch (e) {
              AppLogger.warning('No se pudo cargar el logo desde assets: $e');
            }
          }
        } catch (e) {
          AppLogger.warning('No se pudo cargar el logo: $e');
        }
      }

      // Crear página de título
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // Logo si existe
                  if (logoProvider != null)
                    pw.Container(
                      height: 100,
                      width: 200,
                      child: pw.Image(logoProvider),
                    ),

                  pw.SizedBox(height: 20),

                  // Título
                  pw.Text(
                    titulo,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // Subtítulo
                  pw.Text(
                    subtitulo,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),

                  pw.SizedBox(height: 30),

                  // Fecha de generación
                  pw.Text(
                    'Generado el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al agregar página de título', e, stackTrace);
      rethrow;
    }
  }

  /// Método para agregar una tabla al documento
  static void agregarTabla(
    pw.Document pdf,
    List<String> encabezados,
    List<List<String>> datos, {
    String? titulo,
  }) {
    try {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            // Crear tabla con encabezados
            final table = pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: Map<int, pw.TableColumnWidth>.fromIterable(
                List.generate(encabezados.length, (index) => index),
                value: (_) => const pw.FlexColumnWidth(),
              ),
              children: [
                // Fila de encabezados
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children:
                      encabezados
                          .map(
                            (encabezado) => pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                encabezado,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          )
                          .toList(),
                ),

                // Filas de datos
                ...datos.map(
                  (fila) => pw.TableRow(
                    children:
                        fila
                            .map(
                              (celda) => pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(celda),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            );

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Título de la tabla si existe
                if (titulo != null) ...[
                  pw.Text(
                    titulo,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],

                // Tabla
                table,
              ],
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al agregar tabla', e, stackTrace);
      rethrow;
    }
  }

  /// Método para agregar un gráfico sencillo de barras horizontal
  static void agregarGraficoBarras(
    pw.Document pdf,
    String titulo,
    Map<String, double> datos, {
    String unidad = '',
  }) {
    try {
      // Encontrar el valor máximo para dimensionar el gráfico
      final double maxValue =
          datos.values.isEmpty
              ? 0.0
              : datos.values.reduce((a, b) => a > b ? a : b);
      final double escala = maxValue > 0 ? 100 / maxValue : 1;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            // Convertir el mapa a una lista de entradas para facilitar el trabajo
            final entries = datos.entries.toList();

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Título del gráfico
                pw.Text(
                  titulo,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 20),

                // Gráfico de barras
                pw.Container(
                  height: 300,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: List.generate(entries.length, (index) {
                      final entry = entries[index];
                      final altura = (entry.value * escala) / 100 * 280;

                      return pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            '$unidad${entry.value.toStringAsFixed(0)}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Container(
                            width: 40,
                            height: altura,
                            color:
                                index % 2 == 0
                                    ? PdfColors.blue300
                                    : PdfColors.green300,
                          ),
                          pw.SizedBox(height: 5),
                          pw.Container(
                            width: 40,
                            child: pw.Text(
                              entry.key,
                              maxLines: 2,
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),

                // Tabla de datos
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Categoría',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Valor',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...entries.map(
                      (entry) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(entry.key),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              '$unidad${entry.value.toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al agregar gráfico de barras', e, stackTrace);
      rethrow;
    }
  }

  /// Método para agregar un gráfico de líneas al documento PDF
  static void agregarGraficoLineas(
    pw.Document pdf,
    String titulo,
    Map<String, List<Map<String, dynamic>>> series, {
    List<String>? ejeX,
    String? etiquetaY,
  }) {
    try {
      // Calculamos el valor máximo para la escala
      double maxValue = 0;
      int maxLength = 0;

      series.forEach((key, dataPoints) {
        for (var punto in dataPoints) {
          final value = punto['value'] as double;
          if (value > maxValue) maxValue = value;
        }
        if (dataPoints.length > maxLength) {
          maxLength = dataPoints.length;
        }
      });

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Título del gráfico
                pw.Text(
                  titulo,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 20),

                // Contenedor para el gráfico
                pw.Container(
                  height: 250,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Stack(
                    children: [
                      // Líneas horizontales de guía
                      pw.Positioned.fill(
                        child: pw.Column(
                          children: List.generate(
                            5,
                            (index) => pw.Expanded(
                              child: pw.Container(
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(
                                    bottom:
                                        index < 4
                                            ? const pw.BorderSide(
                                              color: PdfColors.grey300,
                                              width: 0.5,
                                            )
                                            : pw.BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Etiquetas de valores (eje Y)
                      pw.Positioned(
                        top: 5,
                        left: 5,
                        bottom: 0,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            5,
                            (index) => pw.Text(
                              (maxValue - (index * (maxValue / 4)))
                                  .toStringAsFixed(0),
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ),
                      ),

                      // Aquí iría el dibujo de las líneas del gráfico
                      // Nota: PDF no permite gráficos complejos como FL_Chart,
                      // así que hacemos una representación simplificada

                      // Tabla con la leyenda debajo de las líneas
                      pw.Positioned(
                        bottom: 10,
                        left: 50,
                        right: 10,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children:
                              series.entries.map((entry) {
                                return pw.Container(
                                  margin: const pw.EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: pw.Row(
                                    children: [
                                      pw.Container(
                                        width: 10,
                                        height: 10,
                                        color: _getColorForIndex(
                                          series.keys.toList().indexOf(
                                            entry.key,
                                          ),
                                        ),
                                        margin: const pw.EdgeInsets.only(
                                          right: 5,
                                        ),
                                      ),
                                      pw.Text(
                                        entry.key,
                                        style: const pw.TextStyle(fontSize: 8),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Tabla con valores
                _buildDataTable(series, ejeX),
              ],
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al agregar gráfico de líneas', e, stackTrace);
      rethrow;
    }
  }

  /// Método para agregar un gráfico circular (torta/pie)
  static void agregarGraficoTorta(
    pw.Document pdf,
    String titulo,
    Map<String, double> datos,
  ) {
    try {
      // Calcular el total para los porcentajes
      final total = datos.values.fold(0.0, (sum, value) => sum + value);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Título del gráfico
                pw.Text(
                  titulo,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 20),

                // Aquí iría la visualización del gráfico circular
                // Como no podemos hacer un gráfico circular directamente con pdf.widgets,
                // hacemos una representación simplificada
                pw.Container(
                  height: 200,
                  width: double.infinity,
                  child: pw.Center(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          "Distribución Porcentual",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 10),
                        // Información de valores proporcionales
                        ...datos.entries.map((entry) {
                          final porcentaje =
                              total > 0 ? (entry.value / total * 100) : 0;
                          return pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Container(
                                  width: 10,
                                  height: 10,
                                  color: _getColorForIndex(
                                    datos.keys.toList().indexOf(entry.key),
                                  ),
                                  margin: const pw.EdgeInsets.only(right: 5),
                                ),
                                pw.Text(
                                  "${entry.key}: ${porcentaje.toStringAsFixed(1)}%",
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(height: 20),

                // Tabla detallada
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Categoría',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Valor',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Porcentaje',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...datos.entries.map((entry) {
                      final porcentaje =
                          total > 0 ? (entry.value / total * 100) : 0;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(entry.key),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(entry.value.toStringAsFixed(2)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('${porcentaje.toStringAsFixed(1)}%'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al agregar gráfico de torta', e, stackTrace);
      rethrow;
    }
  }

  // Construye una tabla de datos para los gráficos
  static pw.Widget _buildDataTable(
    Map<String, List<Map<String, dynamic>>> series,
    List<String>? ejeX,
  ) {
    try {
      // Preparar encabezados
      final List<pw.Widget> headers = [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            'Periodo',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
      ];

      // Añadir una columna por serie - Reemplazado forEach por bucle for
      for (final serieKey in series.keys) {
        headers.add(
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(
              serieKey,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        );
      }

      // Determinar cuántas filas necesitamos
      final int maxRows = series.values.fold(
        0,
        (max, dataPoints) => dataPoints.length > max ? dataPoints.length : max,
      );

      // Crear filas
      final List<pw.TableRow> rows = [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers,
        ),
      ];

      // Llenar las filas con datos
      for (int i = 0; i < maxRows; i++) {
        final List<pw.Widget> cells = [];

        // Primera columna: etiqueta del eje X (periodo)
        cells.add(
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(
              ejeX != null && i < ejeX.length ? ejeX[i] : 'Periodo ${i + 1}',
            ),
          ),
        );

        // Una columna por cada serie - Reemplazado forEach por bucle for
        for (final entry in series.entries) {
          final dataPoints = entry.value;
          cells.add(
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                i < dataPoints.length
                    ? (dataPoints[i]['value'] as double).toStringAsFixed(2)
                    : '-',
              ),
            ),
          );
        }

        rows.add(pw.TableRow(children: cells));
      }

      return pw.Table(border: pw.TableBorder.all(), children: rows);
    } catch (e) {
      AppLogger.error('Error al construir tabla de datos', e);
      return pw.Container();
    }
  }

  // Obtener un color para un índice
  static PdfColor _getColorForIndex(int index) {
    final colors = [
      PdfColors.blue,
      PdfColors.green,
      PdfColors.red,
      PdfColors.amber,
      PdfColors.purple,
      PdfColors.teal,
      PdfColors.indigo,
      PdfColors.orange,
    ];

    return colors[index % colors.length];
  }
}

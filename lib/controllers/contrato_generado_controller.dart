import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../models/inmueble_model.dart';
import '../models/cliente_model.dart';
import '../utils/applogger.dart';
import '../services/contrato_pdf_service.dart';
import '../utils/applogger.dart';
import '../services/mysql_helper.dart';
import '../models/contrato_generado_model.dart';

final contratoGeneradoControllerProvider = Provider<ContratoGeneradoController>((ref) {
  return ContratoGeneradoController();
});

class ContratoGeneradoController {
  final ContratoPdfService _pdfService = ContratoPdfService();
  final DatabaseService dbHelper;
  bool _procesandoError = false;

  ContratoGeneradoController({DatabaseService? dbService})
    : dbHelper = dbService ?? DatabaseService();

  /// Método auxiliar para ejecutar operaciones con manejo de errores consistente
  Future<T> _ejecutarOperacion<T>(
    String descripcion,
    Future<T> Function() operacion,
  ) async {
    try {
      AppLogger.info('Iniciando operación: $descripcion');
      final resultado = await operacion();
      AppLogger.info('Operación completada: $descripcion');
      return resultado;
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error en operación "$descripcion"', e, stackTrace);
        _procesandoError = false;
      }
      throw Exception('Error en $descripcion: $e');
    }
  }

  /// Registra un nuevo contrato generado usando el procedimiento almacenado
  Future<int> registrarContrato({
    required String tipoContrato,
    required int idReferencia,
    required String rutaArchivo,
    required int idUsuario,
  }) async {
    return _ejecutarOperacion('registrar contrato generado', () async {
      if (idReferencia <= 0) {
        throw Exception('ID de referencia inválido');
      }

      if (rutaArchivo.isEmpty) {
        throw Exception('La ruta del archivo no puede estar vacía');
      }

      if (!['venta', 'renta'].contains(tipoContrato.toLowerCase())) {
        throw Exception(
          'Tipo de contrato inválido. Debe ser "venta" o "renta"',
        );
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // El procedimiento devuelve el ID del contrato generado en una variable OUT
          await conn.query(
            'CALL RegistrarContratoGenerado(?, ?, ?, ?, @id_contrato_generado_out)',
            [tipoContrato.toLowerCase(), idReferencia, rutaArchivo, idUsuario],
          );

          // Recuperar el ID generado
          final result = await conn.query(
            'SELECT @id_contrato_generado_out as id',
          );
          final idContratoGenerado = result.first.fields['id'] as int;

          await conn.query('COMMIT');
          AppLogger.info(
            'Contrato generado registrado con ID: $idContratoGenerado',
          );
          return idContratoGenerado;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error(
            'Error al registrar contrato generado',
            e,
            StackTrace.current,
          );
          throw Exception('Error al registrar contrato generado: $e');
        }
      });
    });
  }

  /// Obtiene los contratos generados de una venta o contrato de renta
  Future<List<ContratoGenerado>> obtenerPorReferencia({
    required String tipoContrato,
    required int idReferencia,
  }) async {
    return _ejecutarOperacion(
      'obtener contratos generados por referencia',
      () async {
        if (idReferencia <= 0) {
          throw Exception('ID de referencia inválido');
        }

        if (!['venta', 'renta'].contains(tipoContrato.toLowerCase())) {
          throw Exception(
            'Tipo de contrato inválido. Debe ser "venta" o "renta"',
          );
        }

        return await dbHelper.withConnection((conn) async {
          final results = await conn.query(
            'CALL ObtenerContratosGeneradosPorReferencia(?, ?)',
            [tipoContrato.toLowerCase(), idReferencia],
          );

          if (results.isEmpty) {
            return [];
          }

          return results
              .map((row) => ContratoGenerado.fromMap(row.fields))
              .toList();
        });
      },
    );
  }

  /// Elimina un contrato generado usando el procedimiento almacenado
  Future<bool> eliminarContrato(int idContratoGenerado) async {
    return _ejecutarOperacion('eliminar contrato generado', () async {
      if (idContratoGenerado <= 0) {
        throw Exception('ID de contrato generado inválido');
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Ejecutar el procedimiento de eliminación
          await conn.query('CALL EliminarContratoGenerado(?, @afectados)', [
            idContratoGenerado,
          ]);

          // Recuperar filas afectadas
          final result = await conn.query('SELECT @afectados as filas');
          final filasAfectadas = result.first.fields['filas'] as int? ?? 0;

          await conn.query('COMMIT');

          AppLogger.info(
            'Contrato generado eliminado: $idContratoGenerado. Filas afectadas: $filasAfectadas',
          );
          return filasAfectadas > 0;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error(
            'Error al eliminar contrato generado',
            e,
            StackTrace.current,
          );
          throw Exception('Error al eliminar contrato generado: $e');
        }
      });
    });
  }

  /// Obtiene datos para un contrato de venta usando el procedimiento almacenado
  Future<Map<String, dynamic>> obtenerDatosContratoVenta(int idVenta) async {
    return _ejecutarOperacion('obtener datos para contrato de venta', () async {
      if (idVenta <= 0) {
        throw Exception('ID de venta inválido');
      }

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerDatosContratoVenta(?)', [
          idVenta,
        ]);

        if (results.isEmpty) {
          throw Exception(
            'No se encontraron datos para la venta con ID $idVenta',
          );
        }

        // Convierte el resultado a un mapa de datos
        return results.first.fields;
      });
    });
  }

  /// Obtiene datos para un contrato de renta usando el procedimiento almacenado
  Future<Map<String, dynamic>> obtenerDatosContratoRenta(int idContrato) async {
    return _ejecutarOperacion('obtener datos para contrato de renta', () async {
      if (idContrato <= 0) {
        throw Exception('ID de contrato inválido');
      }

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerDatosContratoRenta(?)', [
          idContrato,
        ]);

        if (results.isEmpty) {
          throw Exception(
            'No se encontraron datos para el contrato con ID $idContrato',
          );
        }

        // Convierte el resultado a un mapa de datos
        return results.first.fields;
      });
    });
  }

  /// Genera un contrato de venta en PDF y lo muestra en un visor
  Future<void> generarMostrarContratoVenta({
    required BuildContext context,
    required Inmueble inmueble,
    required Cliente cliente,
    required double montoVenta,
    DateTime? fechaContrato,
  }) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generar el PDF
      final pdfPath = await _pdfService.generarContratoVentaPDF(
        inmueble: inmueble,
        cliente: cliente,
        montoVenta: montoVenta,
        fechaContrato: fechaContrato,
      );

      // Cerrar el diálogo de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar el PDF
      if (context.mounted) {
        await _mostrarPdfPreview(context, pdfPath, 'Contrato de Compraventa');
      }
    } catch (e, stack) {
      AppLogger.error('Error al generar contrato de venta', e, stack);
      
      // Cerrar diálogo de carga si está abierto
      if (context.mounted) {
        Navigator.maybeOf(context)?.pop();
      }
      
      // Mostrar mensaje de error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar contrato: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Genera un contrato de renta en PDF y lo muestra en un visor
  Future<void> generarMostrarContratoRenta({
    required BuildContext context,
    required Inmueble inmueble,
    required Cliente cliente,
    required double montoMensual,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? condicionesAdicionales,
  }) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generar el PDF
      final pdfPath = await _pdfService.generarContratoRentaPDF(
        inmueble: inmueble,
        cliente: cliente,
        montoMensual: montoMensual,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        condicionesAdicionales: condicionesAdicionales,
      );

      // Cerrar el diálogo de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar el PDF
      if (context.mounted) {
        await _mostrarPdfPreview(context, pdfPath, 'Contrato de Arrendamiento');
      }
    } catch (e, stack) {
      AppLogger.error('Error al generar contrato de renta', e, stack);
      
      // Cerrar diálogo de carga si está abierto
      if (context.mounted) {
        Navigator.maybeOf(context)?.pop();
      }
      
      // Mostrar mensaje de error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar contrato: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Muestra un PDF en un visor con opciones de impresión y compartir
  Future<void> _mostrarPdfPreview(BuildContext context, String filePath, String title) async {
    final file = File(filePath);
    if (await file.exists()) {
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => Scaffold(
              appBar: AppBar(
                title: Text(title),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () async {
                      try {
                        await Printing.sharePdf(
                          bytes: await file.readAsBytes(),
                          filename: file.path.split('/').last,
                        );
                      } catch (e) {
                        AppLogger.error('Error al compartir PDF', e);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al compartir: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    tooltip: 'Compartir',
                  ),
                ],
              ),
              body: PdfPreview(
                build: (format) => file.readAsBytes(),
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
              ),
            ),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el contrato: archivo no encontrado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Libera recursos cuando el controlador ya no se necesita
  void dispose() {
    AppLogger.info('Liberando recursos de ContratoGeneradoController');
  }
}

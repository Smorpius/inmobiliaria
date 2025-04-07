import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/comprobante_movimiento_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget para seleccionar un comprobante desde la galería o cámara
class ComprobanteSelector extends ConsumerWidget {
  final Function(ComprobanteMovimiento) onComprobanteSelected;

  const ComprobanteSelector({super.key, required this.onComprobanteSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.image),
          title: const Text('Seleccionar de la galería'),
          onTap: () => _seleccionarComprobante(context, ImageSource.gallery),
        ),
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text('Tomar una foto'),
          onTap: () => _seleccionarComprobante(context, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.file_copy),
          title: const Text('Seleccionar archivo PDF'),
          onTap: () => _seleccionarArchivo(context),
        ),
      ],
    );
  }

  Future<void> _seleccionarComprobante(
    BuildContext context,
    ImageSource source,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null && context.mounted) {
        final comprobante = await _mostrarDialogoDescripcion(
          context,
          image.path,
          'imagen',
        );

        if (comprobante != null) {
          onComprobanteSelected(comprobante);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seleccionarArchivo(BuildContext context) async {
    // En una implementación real, aquí se integraría un selector de archivos PDF
    // Por ahora solo mostraremos un mensaje
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Funcionalidad de selección de PDF pendiente de implementar',
          ),
        ),
      );
    }
  }

  Future<ComprobanteMovimiento?> _mostrarDialogoDescripcion(
    BuildContext context,
    String rutaArchivo,
    String tipo,
  ) async {
    final descripcionController = TextEditingController();
    final resultado = await showDialog<ComprobanteMovimiento?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Descripción del comprobante'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tipo == 'imagen')
                  Image.file(
                    File(rutaArchivo),
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej: Recibo bancario, Transferencia, etc.',
                  ),
                  maxLength: 100,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final comprobante = ComprobanteMovimiento(
                  rutaArchivo: rutaArchivo,
                  tipoArchivo: tipo,
                  descripcion:
                      descripcionController.text.isNotEmpty
                          ? descripcionController.text
                          : 'Comprobante de pago',
                  fechaCarga: DateTime.now(),
                  idMovimiento:
                      0, // Valor temporal, se actualizará al asociar con el pago
                  tipoComprobante:
                      'recibo', // Valor predeterminado para pagos de renta
                );
                Navigator.of(context).pop(comprobante);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    descripcionController.dispose();
    return resultado;
  }
}

/// Pantalla para seleccionar comprobantes
class ComprobanteSelectionScreen extends StatelessWidget {
  const ComprobanteSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Comprobante')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ComprobanteSelector(
          onComprobanteSelected: (comprobante) {
            Navigator.of(context).pop(comprobante);
          },
        ),
      ),
    );
  }
}

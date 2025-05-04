import 'dart:io';
import 'package:intl/intl.dart';
import '../../utils/applogger.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../utils/archivo_utils.dart';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import '../../models/documento_model.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/documento_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocumentoDetalleScreen extends ConsumerStatefulWidget {
  final Documento documento;

  const DocumentoDetalleScreen({super.key, required this.documento});

  @override
  ConsumerState<DocumentoDetalleScreen> createState() =>
      _DocumentoDetalleScreenState();
}

class _DocumentoDetalleScreenState
    extends ConsumerState<DocumentoDetalleScreen> {
  File? _archivoLocal;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarArchivo();
  }

  Future<void> _cargarArchivo() async {
    try {
      // Intentar obtener la ruta completa del archivo
      final rutaCompleta = await ArchivoUtils.obtenerRutaCompleta(
        widget.documento.rutaArchivo,
      );
      final archivo = File(rutaCompleta);

      // Verificar si el archivo existe en la ruta principal
      if (await archivo.exists()) {
        setState(() {
          _archivoLocal = archivo;
          _cargando = false;
        });
        return;
      }

      // Si no existe, buscar por nombre del archivo en múltiples ubicaciones
      final nombreArchivo = path.basename(widget.documento.rutaArchivo);
      final rutaAlternativa = await ArchivoUtils.buscarArchivoPorNombre(
        nombreArchivo,
      );

      if (rutaAlternativa != null) {
        final archivoAlternativo = File(rutaAlternativa);
        if (await archivoAlternativo.exists()) {
          setState(() {
            _archivoLocal = archivoAlternativo;
            _cargando = false;
          });
          AppLogger.info(
            'Archivo encontrado en ruta alternativa: $rutaAlternativa',
          );
          return;
        }
      }

      // Si no se encuentra el archivo en ninguna ubicación
      throw Exception('Archivo no encontrado: ${widget.documento.rutaArchivo}');
    } catch (e, stack) {
      AppLogger.error('Error al cargar archivo', e, stack);
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _compartirDocumento() async {
    if (_archivoLocal == null) return;

    try {
      final xFile = XFile(_archivoLocal!.path);
      await Share.shareXFiles([
        xFile,
      ], text: 'Compartiendo ${widget.documento.nombre}');
    } catch (e, stack) {
      AppLogger.error('Error al compartir documento', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _eliminarDocumento() async {
    // Guardar el BuildContext antes de la operación asíncrona
    final BuildContext currentContext = context;

    final confirmar = await showDialog<bool>(
      context: currentContext,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Estás seguro de que deseas eliminar "${widget.documento.nombre}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    // Verificar que el widget siga montado antes de continuar
    if (!mounted) return;

    if (confirmar == true) {
      try {
        final resultado = await ref
            .read(documentoServiceProvider)
            .eliminarDocumento(widget.documento);

        // Verificar nuevamente que el widget siga montado
        if (!mounted) return;

        if (resultado) {
          // Refrescar la lista de documentos y volver atrás
          // Asegurarse de que la actualización se propague correctamente
          await Future.microtask(() => ref.refresh(documentosProvider));

          // Verificar que el widget siga montado después de cada operación asíncrona
          if (!mounted) return;

          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documento eliminado correctamente')),
          );
        }
      } catch (e, stack) {
        AppLogger.error('Error al eliminar documento', e, stack);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documento.nombre),
        actions: [
          if (_archivoLocal != null && !_cargando) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _compartirDocumento,
              tooltip: 'Compartir',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _eliminarDocumento,
              tooltip: 'Eliminar',
            ),
          ],
        ],
      ),
      body:
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : _archivoLocal != null
              ? _buildVisualizador()
              : const Center(child: Text('No se pudo cargar el documento')),
    );
  }

  Widget _buildVisualizador() {
    if (_archivoLocal == null) {
      return const Center(child: Text('Documento no disponible'));
    }

    if (widget.documento.isPdf) {
      return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: PdfPreview(
                build: (format) => _archivoLocal!.readAsBytesSync(),
                canChangeOrientation: false,
                canChangePageFormat: false,
                allowPrinting: true,
                allowSharing: true,
                maxPageWidth: 700,
                pdfFileName: widget.documento.nombre,
              ),
            ),
          ),
          _buildInfoPanel(),
        ],
      );
    } else if (widget.documento.isImage) {
      return Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.file(
                  _archivoLocal!,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, e, __) => Center(
                        child: Text('Error al cargar imagen: ${e.toString()}'),
                      ),
                ),
              ),
            ),
          ),
          _buildInfoPanel(),
        ],
      );
    } else {
      // Para otros tipos de archivo, mostrar información y botón para abrir
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'Archivo ${widget.documento.extension.toUpperCase().substring(1)}',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir con visor predeterminado'),
            onPressed: () => OpenFile.open(_archivoLocal!.path),
          ),
          Expanded(child: Container()),
          _buildInfoPanel(),
        ],
      );
    }
  }

  Widget _buildInfoPanel() {
    final fileStats = _archivoLocal?.statSync();
    final fileSize =
        fileStats != null ? _formatFileSize(fileStats.size) : 'Desconocido';

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información del documento',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Tipo', widget.documento.tipoDocumento.capitalize()),
          _buildInfoRow('Categoría', widget.documento.categoria.capitalize()),
          _buildInfoRow(
            'Fecha',
            DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(widget.documento.fechaCreacion),
          ),
          _buildInfoRow('Tamaño', fileSize),
          if (widget.documento.descripcion != null &&
              widget.documento.descripcion!.isNotEmpty)
            _buildInfoRow('Descripción', widget.documento.descripcion!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

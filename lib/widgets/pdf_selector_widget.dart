import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/applogger.dart';

class PdfSelectorWidget extends StatefulWidget {
  final Function(File, String) onFileSelected;
  final String? initialFilePath;
  final bool isLoading;

  const PdfSelectorWidget({
    Key? key,
    required this.onFileSelected,
    this.initialFilePath,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<PdfSelectorWidget> createState() => _PdfSelectorWidgetState();
}

class _PdfSelectorWidgetState extends State<PdfSelectorWidget> {
  File? _pdfFile;
  String? _fileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading;
    _loadInitialFile();
  }

  @override
  void didUpdateWidget(PdfSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      setState(() {
        _isLoading = widget.isLoading;
      });
    }
  }

  Future<void> _loadInitialFile() async {
    if (widget.initialFilePath != null && widget.initialFilePath!.isNotEmpty) {
      final file = File(widget.initialFilePath!);
      if (await file.exists()) {
        setState(() {
          _pdfFile = file;
          _fileName = widget.initialFilePath!.split('/').last;
        });
      }
    }
  }

  Future<void> _selectPdfFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        setState(() {
          _pdfFile = file;
          _fileName = fileName;
        });

        widget.onFileSelected(file, fileName);
      }
    } catch (e, stack) {
      AppLogger.error('Error al seleccionar archivo PDF', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Documento PDF',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _selectPdfFile,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: const Text('Seleccionar PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_pdfFile != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blueGrey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName ?? 'Documento PDF',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FutureBuilder<int>(
                        future: _pdfFile!.length(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final kb = snapshot.data! / 1024;
                            return Text(
                              '${kb.toStringAsFixed(1)} KB',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            );
                          }
                          return const Text('Calculando tamaño...');
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _pdfFile = null;
                      _fileName = null;
                    });
                    // Notify that file was removed
                    widget.onFileSelected(File(''), '');
                  },
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, size: 36, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Ningún archivo seleccionado',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Haga clic en "Seleccionar PDF" para adjuntar un documento',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
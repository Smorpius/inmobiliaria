import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import 'package:image_picker/image_picker.dart';

/// Widget para seleccionar imágenes desde la galería o cámara
/// y mostrar la imagen seleccionada
class ImagePickerWidget extends StatefulWidget {
  final String? currentImagePath;
  final Function(String?) onImageSelected;
  final String category;
  final String prefix;
  final double size;
  final String placeholder;
  final Color backgroundColor;
  final bool circular;
  final bool showChangeButton;

  const ImagePickerWidget({
    super.key,
    this.currentImagePath,
    required this.onImageSelected,
    required this.category,
    required this.prefix,
    this.size = 120.0,
    this.placeholder = 'Seleccionar\nimagen',
    this.backgroundColor = Colors.teal,
    this.circular = true,
    this.showChangeButton = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImageService _imageService = ImageService();
  String? _imagePath;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.currentImagePath;
    _loadImage();
  }

  @override
  void didUpdateWidget(ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentImagePath != oldWidget.currentImagePath) {
      _imagePath = widget.currentImagePath;
      _loadImage();
    }
  }

  /// Carga la imagen desde el sistema de archivos
  Future<void> _loadImage() async {
    if (_imagePath == null || _imagePath!.isEmpty) {
      setState(() {
        _imageFile = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final file = File.fromUri(Uri.file(_imagePath!));
      if (await file.exists()) {
        setState(() {
          _imageFile = file;
          _isLoading = false;
        });
      } else {
        setState(() {
          _imageFile = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _imageFile = null;
        _isLoading = false;
      });
    }
  }

  /// Muestra un diálogo para seleccionar la fuente de la imagen
  Future<void> _showImageSourceDialog() async {
    if (_isLoading) return;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleccionar imagen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galería'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Cámara'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.camera);
                  },
                ),
                if (_imagePath != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Eliminar imagen',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _deleteImage();
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  /// Selecciona una imagen y la guarda
  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final imageFile = await _imageService.pickImage(source);
      if (imageFile != null) {
        // Eliminar imagen anterior si existe
        if (_imagePath != null && _imagePath!.isNotEmpty) {
          await _imageService.deleteImage(_imagePath);
        }

        final savedPath = await _imageService.saveImage(
          imageFile,
          widget.category,
          widget.prefix,
        );

        setState(() {
          _imagePath = savedPath;
          _imageFile = imageFile;
          _isLoading = false;
        });

        widget.onImageSelected(savedPath);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al seleccionar imagen')),
        );
      }
    }
  }

  /// Elimina la imagen actual
  Future<void> _deleteImage() async {
    setState(() {
      _isLoading = true;
    });

    if (_imagePath != null) {
      final success = await _imageService.deleteImage(_imagePath);
      if (success) {
        setState(() {
          _imagePath = null;
          _imageFile = null;
          _isLoading = false;
        });
        widget.onImageSelected(null);
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar imagen')),
          );
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shape = widget.circular ? BoxShape.circle : BoxShape.rectangle;
    final borderRadius = widget.circular ? null : BorderRadius.circular(12);

    return Column(
      children: [
        InkWell(
          onTap: _showImageSourceDialog,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                (widget.backgroundColor.r * 255).round(),
                (widget.backgroundColor.g * 255).round(),
                (widget.backgroundColor.b * 255).round(),
                0.1,
              ),
              border: Border.all(color: widget.backgroundColor, width: 2),
              shape: shape,
              borderRadius: borderRadius,
              image:
                  _imageFile != null
                      ? DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: widget.backgroundColor,
                      ),
                    )
                    : _imageFile == null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: widget.size * 0.4,
                            color: widget.backgroundColor,
                          ),
                          Text(
                            widget.placeholder,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: widget.size * 0.14,
                              color: widget.backgroundColor,
                            ),
                          ),
                        ],
                      ),
                    )
                    : null,
          ),
        ),
        if (widget.showChangeButton)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton(
              onPressed: _showImageSourceDialog,
              child: Text(
                _imagePath == null ? 'Seleccionar imagen' : 'Cambiar imagen',
              ),
            ),
          ),
      ],
    );
  }
}

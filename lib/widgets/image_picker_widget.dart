import 'dart:io';
import 'dart:async';
import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../services/image_service.dart';

/// Widget para seleccionar imágenes desde la galería y mostrar la imagen seleccionada
/// Version optimizada con manejo mejorado de errores y sin opción de cámara
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
  // Uso de final para prevenir reasignaciones accidentales
  final ImageService _imageService = ImageService();
  String? _imagePath;
  File? _imageFile;
  bool _isLoading = false;
  bool _isDisposed =
      false; // Bandera para evitar actualizar estado después de dispose

  @override
  void initState() {
    super.initState();
    _imagePath = widget.currentImagePath;
    // Cargar imagen con pequeño retraso para evitar bloqueo de UI durante inicialización
    Future.microtask(_loadImage);
  }

  @override
  void didUpdateWidget(ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentImagePath != oldWidget.currentImagePath) {
      _imagePath = widget.currentImagePath;
      _loadImage();
    }
  }

  /// Carga la imagen desde el sistema de archivos de manera optimizada
  Future<void> _loadImage() async {
    if (_isDisposed) return;
    if (_imagePath == null || _imagePath!.isEmpty) {
      if (mounted) {
        setState(() => _imageFile = null);
      }
      return;
    }

    // Solo mostrar carga si toma más de 100ms
    bool showLoading = false;
    final timer = Timer(const Duration(milliseconds: 100), () {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = true);
        showLoading = true;
      }
    });

    try {
      final file = File.fromUri(Uri.file(_imagePath!));

      if (await file.exists()) {
        if (mounted && !_isDisposed) {
          setState(() {
            _imageFile = file;
            _isLoading = false;
          });
        }
      } else {
        AppLogger.warning('Imagen no encontrada: $_imagePath');
        if (mounted && !_isDisposed) {
          setState(() {
            _imageFile = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error al cargar imagen: $_imagePath',
        e,
        StackTrace.current,
      );
      if (mounted && !_isDisposed) {
        setState(() {
          _imageFile = null;
          _isLoading = false;
        });
      }
    } finally {
      // Cancelar el timer si aún no se ha mostrado
      if (!showLoading) {
        timer.cancel();
      }
    }
  }

  /// Muestra un diálogo simplificado para seleccionar la imagen (solo galería)
  Future<void> _showImageSourceDialog() async {
    if (_isLoading || _isDisposed) return;

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
                    await _pickImage();
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

  /// Selecciona una imagen de la galería y la guarda optimizadamente
  Future<void> _pickImage() async {
    if (_isLoading || _isDisposed) return;

    _setLoading(true);

    try {
      // Utilizamos directamente pickImageFromGallery en lugar de pickImage con source
      final imageFile = await _imageService.pickImageFromGallery();

      if (imageFile != null) {
        // Eliminar imagen anterior si existe antes de guardar la nueva
        if (_imagePath != null && _imagePath!.isNotEmpty) {
          await _imageService.deleteImage(_imagePath);
        }

        // Guardar la nueva imagen
        final savedPath = await _imageService.saveImage(
          imageFile,
          widget.category,
          widget.prefix,
        );

        if (savedPath != null) {
          if (!_isDisposed && mounted) {
            setState(() {
              _imagePath = savedPath;
              _imageFile = imageFile;
            });
          }

          // Notificar al padre sobre la imagen seleccionada
          widget.onImageSelected(savedPath);

          AppLogger.info('Imagen guardada exitosamente en: $savedPath');
        } else {
          _mostrarError('No se pudo guardar la imagen seleccionada');
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error al seleccionar imagen de galería',
        e,
        StackTrace.current,
      );
      _mostrarError('Error al procesar imagen: ${e.toString().split('\n')[0]}');
    } finally {
      _setLoading(false);
    }
  }

  /// Elimina la imagen actual con manejo mejorado de errores
  Future<void> _deleteImage() async {
    if (_isLoading || _isDisposed || _imagePath == null) return;

    _setLoading(true);

    try {
      final success = await _imageService.deleteImage(_imagePath);

      if (success) {
        if (!_isDisposed && mounted) {
          setState(() {
            _imagePath = null;
            _imageFile = null;
          });
        }

        // Notificar al padre que la imagen ha sido eliminada
        widget.onImageSelected(null);

        AppLogger.info('Imagen eliminada correctamente: $_imagePath');
      } else {
        _mostrarError('No se pudo eliminar la imagen');
        AppLogger.warning('Fallo al eliminar imagen: $_imagePath');
      }
    } catch (e) {
      AppLogger.error('Error al eliminar imagen', e, StackTrace.current);
      _mostrarError('Error al eliminar imagen: ${e.toString().split('\n')[0]}');
    } finally {
      _setLoading(false);
    }
  }

  /// Muestra un mensaje de error al usuario
  void _mostrarError(String mensaje) {
    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Actualiza el estado de carga de manera segura
  void _setLoading(bool loading) {
    if (mounted && !_isDisposed) {
      setState(() => _isLoading = loading);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shape = widget.circular ? BoxShape.circle : BoxShape.rectangle;
    final borderRadius = widget.circular ? null : BorderRadius.circular(12);

    return Column(
      children: [
        InkWell(
          onTap: _isLoading ? null : _showImageSourceDialog,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                widget.backgroundColor.r.round(),
                widget.backgroundColor.g.round(),
                widget.backgroundColor.b.round(),
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
                        strokeWidth: 2.0, // Más delgado para mejor apariencia
                      ),
                    )
                    : _imageFile == null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate, // Icono solo de galería
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
              onPressed: _isLoading ? null : _showImageSourceDialog,
              child: Text(
                _imagePath == null ? 'Seleccionar imagen' : 'Cambiar imagen',
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    // Marcar como eliminado para evitar setState después de dispose
    _isDisposed = true;
    super.dispose();
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../models/inmueble_imagen.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/inmueble_controller.dart';

class ImagenSelectorWidget extends StatefulWidget {
  final int idInmueble;
  final Function() onImagenCargada;

  const ImagenSelectorWidget({
    super.key,
    required this.idInmueble,
    required this.onImagenCargada,
  });

  @override
  State<ImagenSelectorWidget> createState() => _ImagenSelectorWidgetState();
}

class _ImagenSelectorWidgetState extends State<ImagenSelectorWidget> {
  final ImageService _imageService = ImageService();
  final InmuebleController _inmuebleController = InmuebleController();
  final TextEditingController _descripcionController = TextEditingController();
  bool _cargando = false;
  File? _imagenSeleccionada;

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      setState(() => _cargando = true);
      final imagen = await _imageService.cargarImagenDesdeDispositivo(source);

      // Verificar si el widget sigue montado
      if (!mounted) return;

      if (imagen != null) {
        setState(() {
          _imagenSeleccionada = imagen;
        });
      }
    } finally {
      // Verificar si el widget sigue montado antes de actualizar el estado
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _guardarImagen() async {
    if (_imagenSeleccionada == null) return;

    try {
      setState(() => _cargando = true);

      // Guardar la imagen en el almacenamiento
      final rutaRelativa = await _imageService.guardarImagenInmueble(
        _imagenSeleccionada!,
        widget.idInmueble,
      );

      // Verificar si el widget sigue montado después de la operación asíncrona
      if (!mounted) return;

      if (rutaRelativa != null) {
        // Crear modelo de imagen
        final nuevaImagen = InmuebleImagen(
          idInmueble: widget.idInmueble,
          rutaImagen: rutaRelativa,
          descripcion: _descripcionController.text,
          esPrincipal: false, // Por defecto no es principal
          fechaCarga: DateTime.now(),
        );

        // Guardar información en la base de datos
        final idImagen = await _inmuebleController.agregarImagenInmueble(
          nuevaImagen,
        );

        // Verificar si el widget sigue montado después de la segunda operación asíncrona
        if (!mounted) return;

        if (idImagen > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagen cargada correctamente')),
          );
          widget.onImagenCargada(); // Notificar que se cargó una imagen
          _limpiarSeleccion();
        }
      }
    } catch (e) {
      // Verificar si el widget sigue montado antes de mostrar el mensaje de error
      if (!mounted) return;
      
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar la imagen: $e')));
    } finally {
      // Verificar si el widget sigue montado antes de actualizar el estado
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _limpiarSeleccion() {
    setState(() {
      _imagenSeleccionada = null;
      _descripcionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agregar nueva imagen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_imagenSeleccionada == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _cargando
                            ? null
                            : () => _seleccionarImagen(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        _cargando
                            ? null
                            : () => _seleccionarImagen(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Image.file(
                      _imagenSeleccionada!,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción de la imagen',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _limpiarSeleccion,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancelar'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _cargando ? null : _guardarImagen,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
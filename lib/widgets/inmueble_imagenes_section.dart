import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/inmueble_imagen.dart';
import '../../../services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/inmueble_controller.dart';
import '../../../widgets/inmueble_imagen_carousel.dart';

class InmuebleImagenesSection extends StatefulWidget {
  final int inmuebleId;
  final bool isInactivo;

  const InmuebleImagenesSection({
    super.key,
    required this.inmuebleId,
    this.isInactivo = false,
  });

  @override
  State<InmuebleImagenesSection> createState() =>
      _InmuebleImagenesSectionState();
}

class _InmuebleImagenesSectionState extends State<InmuebleImagenesSection> {
  final InmuebleController _controller = InmuebleController();
  final ImageService _imageService = ImageService();
  bool _isLoading = true;
  List<InmuebleImagen> _imagenes = [];

  @override
  void initState() {
    super.initState();
    _cargarImagenes();
  }

  Future<void> _cargarImagenes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final imagenes = await _controller.getImagenesInmueble(widget.inmuebleId);
      setState(() {
        _imagenes = imagenes;
        _isLoading = false;
      });
    } catch (e) {
      _mostrarSnackBar('Error al cargar imágenes: $e', Colors.red);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _agregarImagen(ImageSource source) async {
    try {
      final File? imagen = await _imageService.cargarImagenDesdeDispositivo(
        source,
      );
      if (imagen == null) return;

      final String? rutaRelativa = await _imageService.guardarImagenInmueble(
        imagen,
        widget.inmuebleId,
      );

      if (rutaRelativa == null) {
        _mostrarSnackBar('Error al guardar la imagen', Colors.red);
        return;
      }

      // Definir si será la imagen principal (si no hay otras imágenes)
      bool esPrincipal = _imagenes.isEmpty;

      // Crear objeto de imagen
      final nuevaImagen = InmuebleImagen(
        idInmueble: widget.inmuebleId,
        rutaImagen: rutaRelativa,
        esPrincipal: esPrincipal,
        fechaCarga: DateTime.now(),
      );

      // Guardar en BD
      final idImagen = await _controller.agregarImagenInmueble(nuevaImagen);

      if (idImagen > 0) {
        await _cargarImagenes(); // Recargar todas las imágenes
        _mostrarSnackBar('Imagen agregada con éxito', Colors.green);
      } else {
        _mostrarSnackBar('Error al agregar imagen', Colors.red);
      }
    } catch (e) {
      _mostrarSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _eliminarImagen(int index) async {
    try {
      final imagen = _imagenes[index];
      if (imagen.id == null) return;

      final confirmado = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Eliminar imagen'),
              content: const Text(
                '¿Está seguro que desea eliminar esta imagen?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
      );

      if (confirmado != true) return;

      final eliminado = await _controller.eliminarImagenInmueble(imagen.id!);

      if (eliminado) {
        // También eliminar archivo físico
        await _imageService.eliminarImagenInmueble(imagen.rutaImagen);
        await _cargarImagenes(); // Recargar imágenes
        _mostrarSnackBar('Imagen eliminada con éxito', Colors.green);
      } else {
        _mostrarSnackBar('Error al eliminar imagen', Colors.red);
      }
    } catch (e) {
      _mostrarSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _marcarComoPrincipal(int index) async {
    try {
      final imagen = _imagenes[index];
      if (imagen.id == null || imagen.esPrincipal) return;

      final marcado = await _controller.marcarImagenComoPrincipal(
        imagen.id!,
        widget.inmuebleId,
      );

      if (marcado) {
        await _cargarImagenes(); // Recargar imágenes
        _mostrarSnackBar('Imagen principal actualizada', Colors.green);
      } else {
        _mostrarSnackBar('Error al actualizar imagen principal', Colors.red);
      }
    } catch (e) {
      _mostrarSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _editarDescripcion(int index) async {
    final TextEditingController descripcionController = TextEditingController();
    descripcionController.text = _imagenes[index].descripcion ?? '';

    final nuevaDescripcion = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Descripción de la imagen'),
            content: TextField(
              controller: descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ingrese una descripción para la imagen',
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(context).pop(descripcionController.text),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (nuevaDescripcion != null && _imagenes[index].id != null) {
      try {
        final actualizado = await _controller.actualizarDescripcionImagen(
          _imagenes[index].id!,
          nuevaDescripcion,
        );

        if (actualizado) {
          await _cargarImagenes(); // Recargar imágenes
          _mostrarSnackBar('Descripción actualizada', Colors.green);
        }
      } catch (e) {
        _mostrarSnackBar('Error al actualizar descripción: $e', Colors.red);
      }
    }
  }

  void _mostrarMenuOpciones(int index) {
    if (widget.isInactivo) return; // No mostrar menú si está inactivo

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar descripción'),
                onTap: () {
                  Navigator.of(context).pop();
                  _editarDescripcion(index);
                },
              ),
              if (!_imagenes[index].esPrincipal)
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Marcar como principal'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _marcarComoPrincipal(index);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Eliminar imagen',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _eliminarImagen(index);
                },
              ),
            ],
          ),
    );
  }

  void _mostrarOpcionesAgregarImagen() {
    if (widget.isInactivo) return; // No mostrar opciones si está inactivo

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de la galería'),
                onTap: () {
                  Navigator.of(context).pop();
                  _agregarImagen(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar una foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _agregarImagen(ImageSource.camera);
                },
              ),
            ],
          ),
    );
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Imágenes del inmueble',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        InmuebleImagenCarousel(
          imagenes: _imagenes,
          onImagenTap: _mostrarMenuOpciones,
          onAddTap: widget.isInactivo ? null : _mostrarOpcionesAgregarImagen,
        ),
      ],
    );
  }
}

import 'inmueble_image_item.dart';
import 'package:flutter/material.dart';
import '../../../models/inmueble_imagen.dart';
import '../../../services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/inmueble_controller.dart';

class InmuebleImageGallery extends StatefulWidget {
  final int? inmuebleId;
  final List<InmuebleImagen> imagenes;
  final bool isLoading;
  final ImageService imageService;
  final InmuebleController inmuebleController;
  final Function(List<InmuebleImagen>) onImagenesUpdated;

  const InmuebleImageGallery({
    super.key,
    required this.inmuebleId,
    required this.imagenes,
    required this.isLoading,
    required this.imageService,
    required this.inmuebleController,
    required this.onImagenesUpdated,
  });

  @override
  State<InmuebleImageGallery> createState() => _InmuebleImageGalleryState();
}

class _InmuebleImageGalleryState extends State<InmuebleImageGallery> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Imágenes del Inmueble',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildImagenesList(),
            const SizedBox(height: 16),
            _buildImageButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenesList() {
    if (widget.imagenes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No hay imágenes para este inmueble',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: widget.imagenes.length,
      itemBuilder: (context, index) {
        final imagen = widget.imagenes[index];
        return InmuebleImageItem(
          imagen: imagen,
          imageService: widget.imageService,
          onTap: () => _showImagenOpciones(imagen),
          onDelete: () => _eliminarImagen(imagen),
        );
      },
    );
  }

  Widget _buildImageButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => _seleccionarImagen(ImageSource.camera),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Cámara'),
        ),
        ElevatedButton.icon(
          onPressed: () => _seleccionarImagen(ImageSource.gallery),
          icon: const Icon(Icons.photo_library),
          label: const Text('Galería'),
        ),
      ],
    );
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    if (widget.inmuebleId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guarde el inmueble antes de agregar imágenes'),
        ),
      );
      return;
    }

    try {
      final imagen = await widget.imageService.cargarImagenDesdeDispositivo(
        source,
      );
      if (imagen == null || !mounted) return;

      // Si es la primera imagen, se marca como principal
      final esPrincipal = widget.imagenes.isEmpty;

      // Guardar imagen en almacenamiento
      final rutaRelativa = await widget.imageService.guardarImagenInmueble(
        imagen,
        widget.inmuebleId!,
      );

      if (rutaRelativa == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la imagen')),
        );
        return;
      }

      // Crear objeto para base de datos
      final nuevaImagen = InmuebleImagen(
        idInmueble: widget.inmuebleId!,
        rutaImagen: rutaRelativa,
        descripcion: 'Imagen del inmueble',
        esPrincipal: esPrincipal,
      );

      // Guardar en base de datos
      final idImagen = await widget.inmuebleController.agregarImagenInmueble(
        nuevaImagen,
      );

      if (idImagen > 0) {
        // Recargar imágenes
        final imagenesFrescas = await widget.inmuebleController
            .getImagenesInmueble(widget.inmuebleId!);

        if (!mounted) return;
        widget.onImagenesUpdated(imagenesFrescas);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al agregar imagen: $e')));
    }
  }

  Future<void> _eliminarImagen(InmuebleImagen imagen) async {
    // Confirmar eliminación
    if (!mounted) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar imagen'),
            content: const Text('¿Está seguro que desea eliminar esta imagen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmar != true || !mounted) return;

    if (imagen.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede eliminar una imagen sin ID')),
      );
      return;
    }

    try {
      final eliminado = await widget.inmuebleController.eliminarImagenInmueble(
        imagen.id!,
      );

      if (eliminado) {
        // También eliminar el archivo físico
        await widget.imageService.eliminarImagenInmueble(imagen.rutaImagen);

        // Recargar imágenes
        if (widget.inmuebleId != null) {
          final imagenesFrescas = await widget.inmuebleController
              .getImagenesInmueble(widget.inmuebleId!);

          if (!mounted) return; // Verificación adicional antes de usar context
          widget.onImagenesUpdated(imagenesFrescas);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagen eliminada correctamente')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar imagen: $e')));
    }
  }

  Future<void> _showImagenOpciones(InmuebleImagen imagen) async {
    if (imagen.id == null || !mounted) return;

    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Establecer como imagen principal'),
                onTap: () {
                  Navigator.pop(ctx);
                  _marcarComoPrincipal(imagen);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar descripción'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editarDescripcion(imagen);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Eliminar imagen',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _eliminarImagen(imagen);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _marcarComoPrincipal(InmuebleImagen imagen) async {
    if (imagen.id == null || imagen.esPrincipal) return;

    try {
      final actualizado = await widget.inmuebleController
          .marcarImagenComoPrincipal(imagen.id!, imagen.idInmueble);

      if (actualizado && widget.inmuebleId != null) {
        final imagenesFrescas = await widget.inmuebleController
            .getImagenesInmueble(widget.inmuebleId!);

        if (!mounted) return; // Verificación adicional antes de usar context
        widget.onImagenesUpdated(imagenesFrescas);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen principal actualizada')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al establecer imagen principal: $e')),
      );
    }
  }

  Future<void> _editarDescripcion(InmuebleImagen imagen) async {
    if (!mounted) return;
    final controllerDescripcion = TextEditingController(
      text: imagen.descripcion,
    );

    final nuevaDescripcion = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Editar descripción'),
            content: TextField(
              controller: controllerDescripcion,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLength: 255,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(ctx).pop(controllerDescripcion.text),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (nuevaDescripcion == null ||
        nuevaDescripcion == imagen.descripcion ||
        imagen.id == null ||
        !mounted) {
      return;
    }

    try {
      final actualizado = await widget.inmuebleController
          .actualizarDescripcionImagen(imagen.id!, nuevaDescripcion);

      if (actualizado && widget.inmuebleId != null) {
        final imagenesFrescas = await widget.inmuebleController
            .getImagenesInmueble(widget.inmuebleId!);

        if (!mounted) return; // Verificación adicional antes de usar context
        widget.onImagenesUpdated(imagenesFrescas);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descripción actualizada')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar descripción: $e')),
      );
    }
  }
}

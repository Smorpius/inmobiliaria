import 'dart:io';
import 'package:flutter/material.dart';
import '../models/inmueble_imagen.dart';
import '../services/image_service.dart';
import '../controllers/inmueble_controller.dart';
import '../vistas/inmuebles/galeria_pantalla_completa.dart';

class GaleriaImagenesWidget extends StatefulWidget {
  final int idInmueble;
  final bool permitirEdicion;
  final Function()? onImagenesActualizadas;

  const GaleriaImagenesWidget({
    super.key,
    required this.idInmueble,
    this.permitirEdicion = true,
    this.onImagenesActualizadas,
  });

  @override
  State<GaleriaImagenesWidget> createState() => _GaleriaImagenesWidgetState();
}

class _GaleriaImagenesWidgetState extends State<GaleriaImagenesWidget> {
  final InmuebleController _inmuebleController = InmuebleController();
  final ImageService _imageService = ImageService();
  List<InmuebleImagen>? _imagenes;
  bool _cargando = true;
  int _imagenActual = 0;

  @override
  void initState() {
    super.initState();
    _cargarImagenes();
  }

  Future<void> _cargarImagenes() async {
    setState(() => _cargando = true);
    try {
      final imagenes = await _inmuebleController.getImagenesInmueble(
        widget.idInmueble,
      );
      // Verificar si el widget sigue montado antes de actualizar el estado
      if (!mounted) return;
      setState(() {
        _imagenes = imagenes;
        _cargando = false;
      });
    } catch (e) {
      // Verificar si el widget sigue montado antes de actualizar el estado
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar imágenes: $e')));
    }
  }

  Future<void> _marcarComoPrincipal(InmuebleImagen imagen) async {
    try {
      setState(() => _cargando = true);
      await _inmuebleController.marcarImagenComoPrincipal(
        imagen.id ?? 0,
        widget.idInmueble,
      );

      // Verificar si el widget sigue montado antes de mostrar mensajes
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen establecida como principal')),
      );

      if (widget.onImagenesActualizadas != null) {
        widget.onImagenesActualizadas!();
      }

      await _cargarImagenes();
    } catch (e) {
      // Verificar si el widget sigue montado
      if (!mounted) return;

      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al establecer imagen principal: $e')),
      );
    }
  }

  Future<void> _eliminarImagen(InmuebleImagen imagen) async {
    try {
      final confirmado = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Eliminar imagen'),
              content: const Text(
                '¿Estás seguro de que deseas eliminar esta imagen?',
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

      // Verificar si el widget sigue montado después del diálogo
      if (!mounted) return;

      if (confirmado == true && imagen.id != null) {
        setState(() => _cargando = true);
        await _inmuebleController.eliminarImagenInmueble(imagen.id!);

        // Verificar si el widget sigue montado después de eliminar
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen eliminada correctamente')),
        );

        if (widget.onImagenesActualizadas != null) {
          widget.onImagenesActualizadas!();
        }

        await _cargarImagenes();
      }
    } catch (e) {
      // Verificar si el widget sigue montado
      if (!mounted) return;

      setState(() => _cargando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar imagen: $e')));
    }
  }

  Future<void> _editarDescripcion(InmuebleImagen imagen) async {
    final TextEditingController controller = TextEditingController(
      text: imagen.descripcion,
    );

    final nuevaDescripcion = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar descripción'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    // Verificar si el widget sigue montado después del diálogo
    if (!mounted) return;

    if (nuevaDescripcion != null &&
        nuevaDescripcion != imagen.descripcion &&
        imagen.id != null) {
      try {
        setState(() => _cargando = true);
        await _inmuebleController.actualizarDescripcionImagen(
          imagen.id!,
          nuevaDescripcion,
        );

        // Verificar si el widget sigue montado después de actualizar
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Descripción actualizada correctamente'),
          ),
        );

        await _cargarImagenes();
      } catch (e) {
        // Verificar si el widget sigue montado
        if (!mounted) return;

        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar descripción: $e')),
        );
      }
    }
  }

  // Método auxiliar para verificar si una imagen es principal
  bool esPrincipal(InmuebleImagen imagen) {
    // La propiedad esPrincipal puede ser null, así que verificamos y devolvemos false en ese caso
    final esPrincipal = imagen.esPrincipal;
    return esPrincipal ==
        true; // Esta expresión maneja correctamente el caso null
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _imagenes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_imagenes == null || _imagenes!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No hay imágenes disponibles para este inmueble'),
        ),
      );
    }

    // Obtenemos la imagen actual
    final imagenActual = _imagenes![_imagenActual];

    return Column(
      children: [
        // Visor de imágenes principal
        AspectRatio(
          aspectRatio: 4 / 3,
          child: FutureBuilder<String?>(
            future: _imageService.obtenerRutaCompletaImagen(
              imagenActual.rutaImagen,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || snapshot.data == null) {
                return const Center(child: Icon(Icons.broken_image, size: 80));
              }

              return InteractiveViewer(
                child: Image.file(File(snapshot.data!), fit: BoxFit.contain),
              );
            },
          ),
        ),

        // Descripción de la imagen
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            imagenActual.descripcion ?? 'Sin descripción',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),

        // Botón para ver en pantalla completa (disponible para todos)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: () {
              abrirGaleriaPantallaCompleta(
                context,
                widget.idInmueble,
                initialIndex: _imagenActual,
              );
            },
            icon: const Icon(Icons.fullscreen),
            label: const Text('Ver pantalla completa'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ),

        // Controles para imágenes (marcar como principal, eliminar)
        if (widget.permitirEdicion)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!esPrincipal(imagenActual))
                  ElevatedButton.icon(
                    onPressed:
                        _cargando
                            ? null
                            : () => _marcarComoPrincipal(imagenActual),
                    icon: const Icon(Icons.star),
                    label: const Text('Marcar como principal'),
                  ),
                if (esPrincipal(imagenActual))
                  Chip(
                    avatar: const Icon(Icons.star, color: Colors.amber),
                    label: const Text('Imagen principal'),
                    backgroundColor: Colors.amber.withAlpha(51),
                  ),
                IconButton(
                  onPressed:
                      _cargando ? null : () => _editarDescripcion(imagenActual),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar descripción',
                ),
                IconButton(
                  onPressed:
                      _cargando ? null : () => _eliminarImagen(imagenActual),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  tooltip: 'Eliminar imagen',
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Miniaturas de imágenes
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imagenes!.length,
            itemBuilder: (context, index) {
              final imagen = _imagenes![index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _imagenActual = index;
                    });
                  },
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            _imagenActual == index
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                        width: _imagenActual == index ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FutureBuilder<String?>(
                          future: _imageService.obtenerRutaCompletaImagen(
                            imagen.rutaImagen,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError || snapshot.data == null) {
                              return const Center(
                                child: Icon(Icons.broken_image),
                              );
                            }

                            return Image.file(
                              File(snapshot.data!),
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                        if (esPrincipal(imagen))
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              color: Colors.amber.withAlpha(179),
                              child: const Icon(
                                Icons.star,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (_cargando)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

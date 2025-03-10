import 'dart:io';
import 'package:flutter/material.dart';
import '../models/inmueble_imagen.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class InmuebleImagenCarousel extends StatefulWidget {
  final List<InmuebleImagen> imagenes;
  final Function(int) onImagenTap;
  final VoidCallback? onAddTap;

  const InmuebleImagenCarousel({
    super.key,
    required this.imagenes,
    required this.onImagenTap,
    this.onAddTap,
  });

  @override
  State<InmuebleImagenCarousel> createState() => _InmuebleImagenCarouselState();
}

class _InmuebleImagenCarouselState extends State<InmuebleImagenCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay imágenes, mostrar un placeholder con botón para agregar
    if (widget.imagenes.isEmpty) {
      return GestureDetector(
        onTap: widget.onAddTap,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 64,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'Agregar imágenes',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Carrusel de imágenes
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                // Corrección: uso correcto de withAlpha
                color: Colors.grey.withAlpha((0.3 * 255).round()),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Carrusel
                PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  builder: (BuildContext context, int index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: FileImage(
                        File(widget.imagenes[index].rutaImagen),
                      ),
                      initialScale: PhotoViewComputedScale.contained,
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 2,
                    );
                  },
                  itemCount: widget.imagenes.length,
                  loadingBuilder:
                      (context, event) => Center(
                        child: CircularProgressIndicator(
                          value:
                              event == null
                                  ? 0
                                  : event.cumulativeBytesLoaded /
                                      event.expectedTotalBytes!,
                        ),
                      ),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  pageController: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),

                // Indicador de principal
                if (widget.imagenes[_currentIndex].esPrincipal)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        // Corrección: uso correcto de withAlpha
                        color: Colors.green.withAlpha((0.8 * 255).round()),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.star, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Principal',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Descripción de la imagen
                if (widget.imagenes[_currentIndex].descripcion?.isNotEmpty ??
                    false)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      // Corrección: uso correcto de withAlpha
                      color: Colors.black.withAlpha((0.5 * 255).round()),
                      child: Text(
                        widget.imagenes[_currentIndex].descripcion!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Botón de opciones
                Positioned(
                  top: 16,
                  left: 16,
                  child: Material(
                    // Corrección: uso correcto de withAlpha
                    color: Colors.black.withAlpha((0.5 * 255).round()),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => widget.onImagenTap(_currentIndex),
                    ),
                  ),
                ),

                // Botón para añadir
                // Corrección: reordenado para que child sea el último argumento
                if (widget.onAddTap != null)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: widget.onAddTap,
                      backgroundColor: Colors.teal,
                      child: const Icon(Icons.add_photo_alternate),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Indicador de página y miniaturas
        if (widget.imagenes.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                // Indicador de página
                SmoothPageIndicator(
                  controller: _pageController,
                  count: widget.imagenes.length,
                  effect: WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: Colors.teal,
                    dotColor: Colors.grey.shade300,
                  ),
                ),

                // Miniaturas
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.imagenes.length,
                    itemBuilder: (context, index) {
                      final imagen = widget.imagenes[index];
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  _currentIndex == index
                                      ? Colors.teal
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(imagen.rutaImagen),
                                  fit: BoxFit.cover,
                                  width: 60,
                                  height: 60,
                                ),
                              ),
                              if (imagen.esPrincipal)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(6),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

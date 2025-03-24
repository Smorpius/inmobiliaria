import 'dart:io';
import 'package:flutter/material.dart';
import '../models/inmueble_imagen.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class InmuebleImagenCarousel extends StatefulWidget {
  final List<InmuebleImagen> imagenes;
  final Function(int)? onImagenTap;
  final VoidCallback? onAddTap;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  // Corrigiendo el uso de super parameters
  const InmuebleImagenCarousel({
    super.key,
    required this.imagenes,
    this.onImagenTap,
    this.onAddTap,
    required this.errorBuilder,
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
    if (widget.imagenes.isEmpty) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay imágenes disponibles',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (widget.onAddTap != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: widget.onAddTap,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Agregar imagen'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
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
                // Carrusel con manejo de errores mejorado
                PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  builder: (BuildContext context, int index) {
                    // CAMBIO IMPORTANTE: Validar la ruta de imagen y prevenir errores
                    return PhotoViewGalleryPageOptions.customChild(
                      child: _buildSafeImage(widget.imagenes[index].rutaImagen),
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
                                      (event.expectedTotalBytes ?? 1),
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
                if (_currentIndex < widget.imagenes.length &&
                    widget.imagenes[_currentIndex].esPrincipal)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha((0.8 * 255).round()),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                if (_currentIndex < widget.imagenes.length &&
                    (widget.imagenes[_currentIndex].descripcion != null &&
                        widget.imagenes[_currentIndex].descripcion!.isNotEmpty))
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
                    elevation: 4,
                    color: Colors.black.withAlpha((0.5 * 255).round()),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => widget.onImagenTap?.call(_currentIndex),
                    ),
                  ),
                ),

                // Botón para añadir
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
                            borderRadius: BorderRadius.circular(6),
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
                                // CAMBIO IMPORTANTE: Usar el método seguro para las miniaturas también
                                child: _buildSafeThumbnail(imagen.rutaImagen),
                              ),
                              if (imagen.esPrincipal)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.only(
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

  // Método principal para mostrar imágenes de forma segura
  Widget _buildSafeImage(String rutaImagen) {
    try {
      final file = File(rutaImagen);

      // Verificación robusta de existencia del archivo
      if (!file.existsSync()) {
        return _buildImageErrorWidget('Imagen no encontrada');
      }

      // Verificar tamaño mínimo para asegurar que es una imagen válida
      if (file.lengthSync() < 100) {
        return _buildImageErrorWidget('Archivo de imagen dañado o incompleto');
      }

      // Verificar si el archivo tiene datos mínimos para ser una imagen
      try {
        final bytes = file.readAsBytesSync().take(16).toList();
        if (bytes.isEmpty) {
          return _buildImageErrorWidget('Archivo de imagen sin datos válidos');
        }
      } catch (headerError) {
        return _buildImageErrorWidget('Error al verificar formato de imagen');
      }

      // Cargar la imagen con manejo de errores específicos
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          if (error.toString().contains('byteOffset') ||
              error.toString().contains('index') ||
              error is RangeError) {
            return _buildImageErrorWidget(
              'Datos de imagen dañados',
              showRecover: true,
            );
          } else if (error.toString().contains('decode') ||
              error.toString().contains('PNG') ||
              error.toString().contains('codec')) {
            return _buildImageErrorWidget(
              'Formato de imagen incompatible',
              showRecover: true,
            );
          }
          return _buildImageErrorWidget('Error al mostrar la imagen');
        },
        gaplessPlayback: true,
        cacheWidth: 1000,
      );
    } catch (e) {
      return _buildImageErrorWidget(
        'Error inesperado al procesar imagen: ${e.toString().split('\n').first}',
      );
    }
  }

  // Widget para mostrar errores en las imágenes
  Widget _buildImageErrorWidget(String mensaje, {bool showRecover = false}) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (showRecover) ...[
              const SizedBox(height: 12),
              Text(
                "Intente eliminar esta imagen y cargar una nueva",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Método para miniaturas seguras
  Widget _buildSafeThumbnail(String rutaImagen) {
    try {
      final file = File(rutaImagen);

      // Verificar existencia y tamaño mínimo
      if (!file.existsSync() || file.lengthSync() < 100) {
        return Container(
          width: 60,
          height: 60,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 20),
        );
      }

      // Cargar miniatura con manejo de errores
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
        cacheWidth: 120,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 20,
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        width: 60,
        height: 60,
        color: Colors.grey.shade200,
        child: const Icon(Icons.error, color: Colors.grey, size: 20),
      );
    }
  }
}

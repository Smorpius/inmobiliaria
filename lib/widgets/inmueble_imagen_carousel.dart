import 'dart:io';
import 'dart:async';
import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../models/inmueble_imagen.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../utils/app_colors.dart'; // Importando AppColors
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class InmuebleImagenCarousel extends StatefulWidget {
  final List<InmuebleImagen> imagenes;
  final Function(int)? onImagenTap;
  final VoidCallback? onAddTap;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const InmuebleImagenCarousel({
    super.key,
    required this.imagenes,
    this.onImagenTap,
    this.onAddTap,
    this.errorBuilder,
  });

  @override
  State<InmuebleImagenCarousel> createState() => _InmuebleImagenCarouselState();
}

class _InmuebleImagenCarouselState extends State<InmuebleImagenCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isLoading = false; // Para gestionar estado de carga

  // Caché para optimizar la verificación de existencia de archivos
  final Map<String, bool> _fileExistsCache = {};
  final Map<String, int> _fileSizeCache = {};

  // Timer para limpiar caché periódicamente
  Timer? _cacheCleanupTimer;

  @override
  void initState() {
    super.initState();
    _setupCacheCleanup();
  }

  // Configurar limpieza periódica de caché para evitar fugas de memoria
  void _setupCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!mounted) return;
      _fileExistsCache.clear();
      _fileSizeCache.clear();
      AppLogger.debug('InmuebleImagenCarousel: Caché limpiado');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cacheCleanupTimer?.cancel();
    _fileExistsCache.clear();
    _fileSizeCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagenes.isEmpty) {
      return _buildEmptyState();
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
                    return PhotoViewGalleryPageOptions.customChild(
                      child: _buildSafeImage(widget.imagenes[index].rutaImagen),
                      initialScale: PhotoViewComputedScale.contained,
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 2,
                      heroAttributes: PhotoViewHeroAttributes(
                        tag: 'imagen_${widget.imagenes[index].id ?? index}',
                      ),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                // Botón de opciones
                if (widget.onImagenTap != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Material(
                      elevation: 4,
                      color: AppColors.withAlpha(
                        AppColors.oscuro,
                        128,
                      ), // ~0.5 opacidad
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.claro,
                        ),
                        onPressed:
                            () => widget.onImagenTap?.call(_currentIndex),
                        tooltip: 'Opciones de imagen',
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
                      onPressed: _isLoading ? null : widget.onAddTap,
                      backgroundColor: Colors.teal,
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.add_photo_alternate),
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

                // Miniaturas - Implementación optimizada
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

  // Widget para mostrar cuando no hay imágenes
  Widget _buildEmptyState() {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Método principal para mostrar imágenes de forma segura y eficiente
  Widget _buildSafeImage(String rutaImagen) {
    try {
      final cacheKey = 'exists_$rutaImagen';
      final sizeCacheKey = 'size_$rutaImagen';

      // Validación previa más detallada
      if (rutaImagen.isEmpty) {
        return _buildImageErrorWidget('Ruta de imagen vacía');
      }

      return FutureBuilder<bool>(
        future: _verificarImagenValida(rutaImagen, cacheKey, sizeCacheKey),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data != true) {
            String mensaje = 'Imagen no encontrada o inválida';
            if (snapshot.hasError) {
              final error = snapshot.error.toString();
              if (error.contains('Permission') || error.contains('permiso')) {
                mensaje = 'Sin permiso para acceder a la imagen';
              } else {
                mensaje = 'Error: ${error.split('\n').first}';
              }

              // Registrar el error para diagnóstico
              AppLogger.warning(
                'Error al verificar imagen: $mensaje para $rutaImagen',
              );
            }
            return _buildImageErrorWidget(mensaje);
          }

          // La imagen es válida, mostrarla con manejo de errores mejorado
          final file = File(rutaImagen);
          return Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              AppLogger.error(
                'Error al mostrar imagen: $rutaImagen',
                error,
                stackTrace,
              );

              String mensaje = 'Error al mostrar la imagen';
              bool recoverable = false;

              if (error.toString().contains('byteOffset') ||
                  error.toString().contains('index') ||
                  error is RangeError) {
                mensaje = 'Datos de imagen dañados';
                recoverable = true;
              } else if (error.toString().contains('decode') ||
                  error.toString().contains('PNG') ||
                  error.toString().contains('codec')) {
                mensaje = 'Formato de imagen incompatible';
                recoverable = true;
              } else if (error.toString().contains('Permission') ||
                  error.toString().contains('denied')) {
                mensaje = 'Permiso denegado para acceder a la imagen';
              }

              return _buildImageErrorWidget(mensaje, showRecover: recoverable);
            },
            gaplessPlayback: true,
            cacheWidth: 1000, // Optimización de memoria
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              // Mostrar un indicador de carga hasta que la imagen esté lista
              if (wasSynchronouslyLoaded) return child;
              return frame != null
                  ? child
                  : Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  );
            },
          );
        },
      );
    } catch (e, stack) {
      AppLogger.error(
        'Error inesperado al procesar imagen: $rutaImagen',
        e,
        stack,
      );
      return _buildImageErrorWidget(
        'Error inesperado al procesar imagen: ${e.toString().split('\n').first}',
      );
    }
  }

  // Verificar si la imagen es válida (existe y tiene tamaño mínimo) usando caché
  Future<bool> _verificarImagenValida(
    String rutaImagen,
    String cacheKey,
    String sizeCacheKey,
  ) async {
    try {
      // Validar ruta básica
      if (rutaImagen.trim().isEmpty) {
        return false;
      }

      // Usar caché para evitar verificaciones repetidas
      if (_fileExistsCache.containsKey(cacheKey)) {
        final exists = _fileExistsCache[cacheKey]!;
        if (!exists) return false;

        // También verificar el tamaño mínimo (ya cacheado)
        return (_fileSizeCache[sizeCacheKey] ?? 0) >= 100;
      }

      // No está en caché, verificar físicamente
      final file = File(rutaImagen);

      // Verificar que la ruta es absoluta
      if (!file.path.startsWith('/') &&
          !RegExp(r'^[A-Za-z]:\\').hasMatch(file.path)) {
        AppLogger.warning('Ruta de imagen no es absoluta: $rutaImagen');
        _fileExistsCache[cacheKey] = false;
        return false;
      }

      final exists = await file.exists();
      _fileExistsCache[cacheKey] = exists;

      if (!exists) {
        AppLogger.warning('Archivo de imagen no existe: $rutaImagen');
        return false;
      }

      // Verificar tamaño mínimo para asegurar que es una imagen válida
      final size = await file.length();
      _fileSizeCache[sizeCacheKey] = size;

      if (size < 100) {
        AppLogger.warning(
          'Archivo de imagen demasiado pequeño ($size bytes): $rutaImagen',
        );
        return false;
      }

      // Verificar datos mínimos para considerar como imagen válida
      try {
        final bytes = await file.openRead(0, 16).first;
        if (bytes.isEmpty) {
          AppLogger.warning('Cabecera de imagen vacía: $rutaImagen');
          return false;
        }

        // Verificar tipos comunes de imágenes por sus cabeceras
        final isJpeg =
            bytes.length > 2 &&
            bytes[0] == 0xFF &&
            bytes[1] == 0xD8 &&
            bytes[2] == 0xFF;
        final isPng =
            bytes.length > 7 &&
            bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47;
        final isGif =
            bytes.length > 3 &&
            bytes[0] == 0x47 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46;

        if (!isJpeg && !isPng && !isGif) {
          // Si no es un formato común, intentar decodificar
          AppLogger.debug(
            'Formato de imagen no identificado por cabecera para: $rutaImagen',
          );
        }

        return true;
      } catch (headerError) {
        AppLogger.warning(
          'Error al verificar cabecera de imagen: $rutaImagen - $headerError',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('Error al validar imagen: $rutaImagen', e);
      return false;
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                mensaje,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
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

  // Método optimizado para miniaturas seguras
  Widget _buildSafeThumbnail(String rutaImagen) {
    try {
      // Usar una clave similar pero específica para miniaturas
      final thumbCacheKey = 'thumb_exists_$rutaImagen';
      final thumbSizeCacheKey = 'thumb_size_$rutaImagen';

      return FutureBuilder<bool>(
        future: _verificarImagenValida(
          rutaImagen,
          thumbCacheKey,
          thumbSizeCacheKey,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade200,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data != true) {
            return Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 20,
              ),
            );
          }

          // Si la imagen es válida, mostrar miniatura
          final file = File(rutaImagen);
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: 60,
            height: 60,
            cacheWidth: 120, // Optimización para miniaturas
            errorBuilder: (context, error, stackTrace) {
              AppLogger.debug('Error en miniatura: $rutaImagen - $error');
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
        },
      );
    } catch (e) {
      AppLogger.warning('Error en miniatura: $rutaImagen - $e');
      return Container(
        width: 60,
        height: 60,
        color: Colors.grey.shade200,
        child: const Icon(Icons.error, color: Colors.grey, size: 20),
      );
    }
  }

  // Establece el estado de carga y actualiza la UI
  void setLoading(bool loading) {
    if (mounted && _isLoading != loading) {
      setState(() {
        _isLoading = loading;
      });
    }
  }
}

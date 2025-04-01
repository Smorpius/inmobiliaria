import 'dart:io';
import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSelectorMultipleWidget extends StatelessWidget {
  final List<File> imagenes;
  final int imagenPrincipalIndex;
  final Future<void> Function(ImageSource) onAgregarImagen;
  final Function(int) onEliminarImagen;
  final Function(int) onEstablecerPrincipal;
  final bool isLoading;
  final String? errorMessage;

  // Límite para prevenir problemas de memoria
  final int maxImagenes;

  const ImageSelectorMultipleWidget({
    super.key,
    required this.imagenes,
    required this.imagenPrincipalIndex,
    required this.onAgregarImagen,
    required this.onEliminarImagen,
    required this.onEstablecerPrincipal,
    this.isLoading = false,
    this.errorMessage,
    this.maxImagenes = 10,
  });

  /// Muestra el diálogo para seleccionar el origen de la imagen
  Future<void> _mostrarOpcionesImagen(BuildContext context) async {
    // Evitar abrir el diálogo si ya está en proceso de carga
    if (isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor espere, hay una operación en curso'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Verificar si se alcanzó el límite de imágenes
    if (imagenes.length >= maxImagenes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Límite de $maxImagenes imágenes alcanzado'),
          backgroundColor: Colors.amber,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _agregarImagen(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Seleccionar de la galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _agregarImagen(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      AppLogger.error(
        'Error al mostrar opciones de imagen',
        e,
        StackTrace.current,
      );
      // Check if the widget is still in the tree before using BuildContext
      if (context.mounted) {
        _mostrarError(context, 'No se pudo abrir el selector de imágenes');
      }
    }
  }

  /// Agrega una imagen con manejo de errores
  Future<void> _agregarImagen(BuildContext context, ImageSource source) async {
    try {
      await onAgregarImagen(source);
    } catch (e) {
      AppLogger.error(
        'Error al agregar imagen desde ${source == ImageSource.camera ? "cámara" : "galería"}',
        e,
        StackTrace.current,
      );
      // Check if the widget is still in the tree before using BuildContext
      if (context.mounted) {
        _mostrarError(
          context,
          'Error al procesar imagen: ${e.toString().split('\n')[0]}',
        );
      }
    }
  }

  /// Confirma la eliminación de una imagen
  void _confirmarEliminarImagen(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar imagen'),
          content: const Text(
            '¿Está seguro de que desea eliminar esta imagen?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop();
                _eliminarImagen(context, index);
              },
            ),
          ],
        );
      },
    );
  }

  /// Elimina una imagen con manejo de errores
  void _eliminarImagen(BuildContext context, int index) {
    try {
      onEliminarImagen(index);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen eliminada'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      AppLogger.error('Error al eliminar imagen', e, StackTrace.current);
      _mostrarError(context, 'No se pudo eliminar la imagen');
    }
  }

  /// Establece una imagen como principal con manejo de errores
  void _marcarComoPrincipal(BuildContext context, int index) {
    if (index == imagenPrincipalIndex) return;

    try {
      onEstablecerPrincipal(index);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen establecida como principal'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      AppLogger.error(
        'Error al establecer imagen principal',
        e,
        StackTrace.current,
      );
      _mostrarError(context, 'No se pudo establecer la imagen principal');
    }
  }

  /// Muestra un mensaje de error
  void _mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imágenes del inmueble',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Añade imágenes para mostrar el inmueble (máximo $maxImagenes)',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Mostrar mensaje de error si existe
        if (errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),

        // Grid de imágenes - optimizado para rendimiento
        if (imagenes.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: imagenes.length,
                itemBuilder: (context, index) {
                  // Uso de RepaintBoundary para optimizar el rendimiento
                  return RepaintBoundary(
                    child: _buildImageItem(
                      context,
                      index,
                      constraints.maxWidth / 3 - 8,
                    ),
                  );
                },
              );
            },
          ),

        const SizedBox(height: 16),

        // Botón para agregar imágenes con estado de carga
        Center(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => _mostrarOpcionesImagen(context),
            icon:
                isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.add_photo_alternate),
            label: Text(isLoading ? 'Procesando...' : 'Agregar imagen'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        // Nota informativa sobre la cantidad de imágenes
        if (imagenes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              'Se ha seleccionado ${imagenes.length} de $maxImagenes ${imagenes.length == 1 ? 'imagen' : 'imágenes'}',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color:
                    imagenes.length >= maxImagenes
                        ? Colors.amber.shade900
                        : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// Construye un elemento de imagen individual con mejor gestión de memoria
  Widget _buildImageItem(BuildContext context, int index, double size) {
    return Stack(
      key: ValueKey(
        'image_$index',
      ), // Clave para ayudar a la reconciliación del widget
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  index == imagenPrincipalIndex
                      ? Colors.blue
                      : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              imagenes[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              // Optimización para mejor rendimiento y gestión de memoria
              cacheWidth:
                  (size * MediaQuery.of(context).devicePixelRatio).toInt(),
              errorBuilder: (context, error, stackTrace) {
                AppLogger.error('Error al mostrar imagen', error, stackTrace);
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.red),
                  ),
                );
              },
            ),
          ),
        ),

        // Botón para eliminar imagen
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap:
                isLoading
                    ? null
                    : () => _confirmarEliminarImagen(context, index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isLoading ? Colors.grey : Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),

        // Botón para marcar como principal
        if (index != imagenPrincipalIndex)
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onTap:
                  isLoading ? null : () => _marcarComoPrincipal(context, index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isLoading ? Colors.grey : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 16),
              ),
            ),
          ),

        // Indicador de imagen principal
        if (index == imagenPrincipalIndex)
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

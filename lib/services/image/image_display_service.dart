import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Servicio responsable de la presentación de imágenes en la UI
class ImageDisplayService {
  /// Obtiene un widget para mostrar una imagen desde una ruta
  Widget getImageWidget({
    required String? imagePath,
    double width = 100,
    double height = 100,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Si no hay imagen, mostrar placeholder
    if (imagePath == null || imagePath.isEmpty) {
      return placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
    }

    // Si es URL, usar CachedNetworkImage para caché automático
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder:
            (context, url) =>
                placeholder ??
                SizedBox(
                  width: width,
                  height: height,
                  child: const CircularProgressIndicator(),
                ),
        errorWidget:
            (context, url, error) =>
                errorWidget ??
                Container(
                  width: width,
                  height: height,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
        memCacheWidth: (width * 2).toInt(),
        memCacheHeight: (height * 2).toInt(),
      );
    }

    // Para imágenes locales
    return FutureBuilder<bool>(
      future: File(imagePath).exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: const CircularProgressIndicator(),
          );
        }

        if (snapshot.data == true) {
          return Image.file(
            File(imagePath),
            width: width,
            height: height,
            fit: fit,
            cacheWidth: (width * 2).toInt(),
            cacheHeight: (height * 2).toInt(),
          );
        }

        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
      },
    );
  }
}

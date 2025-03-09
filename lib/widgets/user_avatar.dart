import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? imagePath;
  final String nombre;
  final String apellido;
  final double radius;
  final Color backgroundColor;
  final bool isActive;

  const UserAvatar({
    super.key,
    this.imagePath,
    required this.nombre,
    required this.apellido,
    this.radius = 40.0,
    this.backgroundColor = Colors.teal,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay imagen o si la ruta está vacía
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildInitialsAvatar();
    }

    // Verificar si es una URL (comienza con http:// o https://)
    if (imagePath!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath!,
        imageBuilder:
            (context, imageProvider) => CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor,
              backgroundImage: imageProvider,
            ),
        placeholder:
            (context, url) => CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey[300],
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: backgroundColor,
              ),
            ),
        errorWidget: (context, url, error) => _buildInitialsAvatar(),
        cacheKey: imagePath,
        // Configuración del caché
        memCacheHeight:
            (radius * 2 * MediaQuery.of(context).devicePixelRatio).toInt(),
        memCacheWidth:
            (radius * 2 * MediaQuery.of(context).devicePixelRatio).toInt(),
      );
    }

    // Si es una ruta local de archivo
    try {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: FileImage(File(imagePath!)),
      );
    } catch (e) {
      return _buildInitialsAvatar();
    }
  }

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }

  String _getInitials() {
    String firstInitial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    String lastInitial = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }
}

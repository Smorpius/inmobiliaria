import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/inmueble_imagen.dart';
import '../../../services/image_service.dart';

class InmuebleImageItem extends StatelessWidget {
  final InmuebleImagen imagen;
  final ImageService imageService;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const InmuebleImageItem({
    super.key,
    required this.imagen,
    required this.imageService,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<String?>(
          future: imageService.obtenerRutaCompletaImagen(imagen.rutaImagen),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              return Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            }

            return GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  border:
                      imagen.esPrincipal
                          ? Border.all(color: Colors.blue, width: 3)
                          : null,
                ),
                child: Image.file(File(snapshot.data!), fit: BoxFit.cover),
              ),
            );
          },
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: Icon(Icons.delete, color: Colors.red.shade700),
            onPressed: onDelete,
          ),
        ),
        if (imagen.esPrincipal)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }
}

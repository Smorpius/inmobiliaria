import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
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
          // Usar un futuro con tiempo límite para evitar congelamiento
          future: Future.any([
            imageService.obtenerRutaCompletaImagen(imagen.rutaImagen),
            // Timeout de 5 segundos para evitar que la UI se quede esperando indefinidamente
            Future.delayed(const Duration(seconds: 5), () => null),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            if (snapshot.hasError) {
              AppLogger.warning('Error cargando imagen: ${snapshot.error}');
              return Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Container(
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                ),
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
                child: Hero(
                  tag: 'inmueble_imagen_${imagen.id}',
                  child: Image.file(
                    File(snapshot.data!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Registro de error solo una vez, no en bucle
                      AppLogger.categoryWarning(
                        'image_load',
                        'Error al cargar imagen ${imagen.id}: $error',
                        expiration: const Duration(minutes: 5),
                      );
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.error, color: Colors.red),
                      );
                    },
                  ),
                ),
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

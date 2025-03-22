import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';
import '../../../models/inmueble_imagen.dart';

class InmuebleCard extends StatelessWidget {
  final Inmueble inmueble;
  final InmuebleImagen? imagenPrincipal;
  final String? rutaImagen;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onInactivate;
  final bool isInactivo;
  final String inactivateButtonText;
  final Color inactivateButtonColor;
  final Widget? customStateButton;

  const InmuebleCard({
    super.key,
    required this.inmueble,
    this.imagenPrincipal,
    this.rutaImagen,
    required this.onTap,
    required this.onEdit,
    required this.onInactivate,
    this.isInactivo = false,
    this.inactivateButtonText = 'Cambiar Estado',
    this.inactivateButtonColor = Colors.orange,
    this.customStateButton,
  });

  @override
  Widget build(BuildContext context) {
    // Formatea el precio para mostrar según el tipo de operación
    String precioFormateado = '';

    if (inmueble.tipoOperacion == 'venta') {
      if (inmueble.precioVenta != null) {
        precioFormateado = '\$${inmueble.precioVenta!.toStringAsFixed(2)}';
      }
    } else if (inmueble.tipoOperacion == 'renta') {
      if (inmueble.precioRenta != null) {
        precioFormateado = '\$${inmueble.precioRenta!.toStringAsFixed(2)}/mes';
      }
    } else if (inmueble.tipoOperacion == 'ambos') {
      if (inmueble.precioVenta != null) {
        precioFormateado = '\$${inmueble.precioVenta!.toStringAsFixed(2)}';
      }
      if (inmueble.precioRenta != null) {
        final separador = precioFormateado.isEmpty ? '' : ' / ';
        precioFormateado =
            '$precioFormateado$separador\$${inmueble.precioRenta!.toStringAsFixed(2)}/mes';
      }
    }

    // Obtener el estado del inmueble como texto
    String estadoInmueble = 'Disponible';
    Color estadoColor = Colors.green;

    if (inmueble.idEstado == 2) {
      estadoInmueble = 'No Disponible';
      estadoColor = Colors.red;
    } else if (inmueble.idEstado == 1) {
      estadoInmueble = 'Reservado';
      estadoColor = Colors.amber;
    }

    return Card(
      elevation: 3, // Reducido para un aspecto más sutil
      margin: const EdgeInsets.all(4), // Reducido para optimizar espacio
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          10,
        ), // Reducido para ser más compacto
        side: BorderSide(
          width: 1,
          color: isInactivo ? Colors.grey.shade300 : Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen de tamaño fijo más pequeño con etiqueta de estado
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: SizedBox(
                height: 200, // Altura fija más pequeña
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen principal o placeholder
                    rutaImagen != null && rutaImagen!.isNotEmpty
                        ? Image.file(File(rutaImagen!), fit: BoxFit.cover)
                        : const InmuebleImagePlaceholder(),

                    // Etiqueta de estado
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: estadoColor.withAlpha(
                          179,
                        ), // 0.7 en escala de 0-1 equivale a ~179 en escala 0-255
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          estadoInmueble,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Información del inmueble con padding reducido
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título con tamaño de fuente reducido
                  Text(
                    inmueble.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isInactivo ? Colors.grey : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Tipo de inmueble y operación en una sola línea
                  Row(
                    children: [
                      Icon(
                        _getIconForTipoInmueble(inmueble.tipoInmueble),
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        inmueble.tipoInmueble.capitalize(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // Precio con tamaño reducido
                  Text(
                    precioFormateado,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isInactivo ? Colors.grey : Colors.teal,
                    ),
                  ),
                ],
              ),
            ),

            // Botones más compactos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isInactivo ? Icons.check_circle : Icons.remove_circle,
                      size: 18,
                      color: isInactivo ? Colors.green : Colors.red,
                    ),
                    onPressed: onInactivate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTipoInmueble(String tipoInmueble) {
    switch (tipoInmueble.toLowerCase()) {
      case 'casa':
        return Icons.home;
      case 'departamento':
        return Icons.apartment;
      case 'terreno':
        return Icons.landscape;
      case 'oficina':
        return Icons.business;
      case 'local':
        return Icons.storefront;
      case 'bodega':
        return Icons.warehouse;
      default:
        return Icons.home_work;
    }
  }
}

// Widget auxiliar para mostrar un placeholder cuando no hay imagen
class InmuebleImagePlaceholder extends StatelessWidget {
  const InmuebleImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.home_work, size: 40, color: Colors.grey.shade400),
      ),
    );
  }
}

// Extensión para capitalizar strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';
import '../../../models/inmueble_imagen.dart';

/// Utilidades comunes para las vistas de inmuebles
class InmuebleUtils {
  /// Determina el icono según el tipo de inmueble
  static IconData getTipoInmuebleIcon(String tipoInmueble) {
    switch (tipoInmueble.toLowerCase()) {
      case 'casa':
        return Icons.home;
      case 'departamento':
        return Icons.apartment;
      case 'terreno':
        return Icons.landscape;
      case 'oficina':
        return Icons.business;
      case 'bodega':
        return Icons.warehouse;
      default:
        return Icons.real_estate_agent;
    }
  }

  /// Capitaliza la primera letra de un texto
  static String capitalizarPalabra(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  /// Formatea un monto a formato de moneda
  static String formatearMonto(double? monto) {
    if (monto == null) return 'No especificado';
    return '\$${monto.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}

/// Widget que representa una tarjeta de inmueble en el grid
class InmuebleCard extends StatelessWidget {
  final Inmueble inmueble;
  final InmuebleImagen? imagenPrincipal;
  final String? rutaImagen;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const InmuebleCard({
    super.key,
    required this.inmueble,
    this.imagenPrincipal,
    this.rutaImagen,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Color basado en el estado
    Color estadoColor = Colors.grey;
    String estadoTexto = 'Desconocido';

    switch (inmueble.idEstado) {
      case 3:
        estadoColor = Colors.green;
        estadoTexto = 'Disponible';
        break;
      case 4:
        estadoColor = Colors.red;
        estadoTexto = 'Vendido';
        break;
      case 5:
        estadoColor = Colors.orange;
        estadoTexto = 'Rentado';
        break;
      case 6:
        estadoColor = Colors.blue;
        estadoTexto = 'En negociación';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.grey[100],
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Área de imagen
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  // Imagen o placeholder
                  Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child:
                        rutaImagen != null
                            ? Hero(
                              tag:
                                  'inmueble_image_${imagenPrincipal?.id ?? inmueble.id}',
                              child: Image.file(
                                File(rutaImagen!),
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                      InmuebleUtils.getTipoInmuebleIcon(
                                        inmueble.tipoInmueble,
                                      ),
                                      size: 80,
                                      color: Colors.grey[700],
                                    ),
                              ),
                            )
                            : Icon(
                              InmuebleUtils.getTipoInmuebleIcon(
                                inmueble.tipoInmueble,
                              ),
                              size: 80,
                              color: Colors.grey[700],
                            ),
                  ),
                  // Estado del inmueble
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: estadoColor.withAlpha(204),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estadoTexto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // Tipo de operación
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(153),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        InmuebleUtils.capitalizarPalabra(
                          inmueble.tipoOperacion,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Información del inmueble
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inmueble.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        InmuebleUtils.getTipoInmuebleIcon(
                          inmueble.tipoInmueble,
                        ),
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        InmuebleUtils.capitalizarPalabra(inmueble.tipoInmueble),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (inmueble.ciudad != null && inmueble.ciudad!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            inmueble.ciudad!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    InmuebleUtils.formatearMonto(inmueble.montoTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: onEdit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

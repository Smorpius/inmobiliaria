import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';
import '../../../models/inmueble_imagen.dart';
import '../../../utils/inmueble_formatter.dart';

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
    this.inactivateButtonText = 'Cambiar estado',
    this.inactivateButtonColor = Colors.red,
    this.customStateButton,
  });

  /// Obtiene el precio formateado según el tipo de operación
  String get precioFormateado {
    if (inmueble.tipoOperacion == 'venta') {
      return inmueble.precioVenta != null
          ? InmuebleFormatter.formatMonto(inmueble.precioVenta)
          : 'Precio no disponible';
    } else if (inmueble.tipoOperacion == 'renta') {
      return inmueble.precioRenta != null
          ? '${InmuebleFormatter.formatMonto(inmueble.precioRenta)}/mes'
          : 'Precio no disponible';
    } else if (inmueble.tipoOperacion == 'ambos') {
      final venta =
          inmueble.precioVenta != null
              ? InmuebleFormatter.formatMonto(inmueble.precioVenta)
              : 'N/A';
      final renta =
          inmueble.precioRenta != null
              ? '${InmuebleFormatter.formatMonto(inmueble.precioRenta)}/mes'
              : 'N/A';
      return 'V: $venta | R: $renta';
    }
    return InmuebleFormatter.formatMonto(inmueble.montoTotal);
  }

  /// Capitaliza la primera letra de un texto
  String _capitalizarPalabra(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de imagen
            AspectRatio(
              aspectRatio: 1.5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen o placeholder
                  _buildImageWidget(),

                  // Badge de estado cuando está inactivo
                  if (isInactivo)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'NO DISPONIBLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Información del inmueble - Corregida para evitar overflow
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del inmueble
                    Text(
                      inmueble.nombre,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration:
                            isInactivo ? TextDecoration.lineThrough : null,
                        color: isInactivo ? Colors.grey : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Ubicación
                    if (inmueble.ciudad != null && inmueble.ciudad!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 10,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 1),
                            Expanded(
                              child: Text(
                                inmueble.ciudad!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Precio
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        precioFormateado,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isInactivo ? Colors.grey : Colors.teal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Tipo de inmueble y operación
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        '${_capitalizarPalabra(inmueble.tipoInmueble)} • ${_capitalizarPalabra(inmueble.tipoOperacion)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Espacio flexible para acomodar contenido
                    const Spacer(flex: 1),

                    // Botones de acción compactos
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Botón de editar
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            color: Colors.blue,
                            tooltip: 'Editar',
                            onPressed: onEdit,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 2),

                          // Botón de estado personalizado o predeterminado
                          customStateButton ??
                              TextButton.icon(
                                icon: Icon(
                                  isInactivo
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 12,
                                ),
                                label: Text(
                                  inactivateButtonText,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: inactivateButtonColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 0,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: onInactivate,
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el widget de imagen con manejo mejorado de errores
  Widget _buildImageWidget() {
    // Si no hay ruta, mostrar placeholder
    if (rutaImagen == null || rutaImagen!.isEmpty) {
      return InmuebleImagePlaceholder(tipoInmueble: inmueble.tipoInmueble);
    }

    // Intentar cargar la imagen sin verificación previa para reducir logs
    return Image.file(
      File(rutaImagen!),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Solo en caso de error mostrar placeholder
        return InmuebleImagePlaceholder(tipoInmueble: inmueble.tipoInmueble);
      },
    );
  }
}

/// Widget para mostrar un placeholder cuando no hay imagen disponible
class InmuebleImagePlaceholder extends StatelessWidget {
  final String tipoInmueble;

  const InmuebleImagePlaceholder({super.key, required this.tipoInmueble});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    // Determinar el icono según el tipo de inmueble
    switch (tipoInmueble.toLowerCase()) {
      case 'casa':
        iconData = Icons.home;
        break;
      case 'departamento':
        iconData = Icons.apartment;
        break;
      case 'terreno':
        iconData = Icons.landscape;
        break;
      case 'oficina':
        iconData = Icons.business;
        break;
      case 'bodega':
        iconData = Icons.warehouse;
        break;
      default:
        iconData = Icons.real_estate_agent;
    }

    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(iconData, size: 50, color: Colors.grey.shade400),
      ),
    );
  }
}

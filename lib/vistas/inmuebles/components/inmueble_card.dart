import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
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

  // Control para evitar registros de errores duplicados
  static final Map<String, DateTime> _ultimosLogs = {};
  static const Duration _tiempoMinimoDuplicado = Duration(minutes: 5);

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

  /// Obtiene el precio formateado según el tipo de operación con manejo seguro
  String get precioFormateado {
    try {
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
    } catch (e) {
      _registrarErrorControlado(
        'format_precio',
        'Error al formatear precio: $e',
      );
      return 'Precio no disponible';
    }
  }

  /// Capitaliza la primera letra de un texto
  String _capitalizarPalabra(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  /// Registra un error evitando duplicados en periodo corto
  void _registrarErrorControlado(String codigo, String mensaje) {
    final errorKey = '${codigo}_${inmueble.id ?? 0}';
    final ahora = DateTime.now();

    // Verificar si ya registramos este error recientemente
    if (_ultimosLogs.containsKey(errorKey)) {
      if (ahora.difference(_ultimosLogs[errorKey]!) < _tiempoMinimoDuplicado) {
        return; // Evitar registro duplicado
      }
    }

    // Registrar nuevo error
    _ultimosLogs[errorKey] = ahora;

    // Limitar tamaño del mapa para evitar memory leaks
    if (_ultimosLogs.length > 30) {
      final keysToRemove = _ultimosLogs.entries
          .toList()
          .sublist(0, _ultimosLogs.length - 20)
          .map((e) => e.key);
      for (var key in keysToRemove) {
        _ultimosLogs.remove(key);
      }
    }

    AppLogger.error(mensaje, errorKey, StackTrace.current);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  _buildImageWidget(context),

                  // Badge de estado cuando está inactivo
                  if (isInactivo)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(204),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'NO DISPONIBLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Información del inmueble
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del inmueble
                    Text(
                      inmueble.nombre,
                      style: TextStyle(
                        fontSize: 16,
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
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                inmueble.ciudad!,
                                style: TextStyle(
                                  fontSize: 12,
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
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        precioFormateado,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isInactivo ? Colors.grey : Colors.teal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Tipo de inmueble y operación
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_capitalizarPalabra(inmueble.tipoInmueble)} • ${_capitalizarPalabra(inmueble.tipoOperacion)}',
                        style: TextStyle(
                          fontSize: 12,
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
                            icon: const Icon(Icons.edit, size: 18),
                            color: Colors.blue,
                            tooltip: 'Editar',
                            onPressed: onEdit,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),

                          // Botón de estado personalizado o predeterminado
                          customStateButton ??
                              TextButton.icon(
                                icon: Icon(
                                  isInactivo
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 14,
                                ),
                                label: Text(
                                  inactivateButtonText,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: inactivateButtonColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
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
  Widget _buildImageWidget(BuildContext context) {
    // Si no hay ruta, mostrar placeholder inmediatamente para mejorar rendimiento
    if (rutaImagen == null || rutaImagen!.isEmpty) {
      return InmuebleImagePlaceholder(tipoInmueble: inmueble.tipoInmueble);
    }

    // Verificación rápida de archivo para mejorar rendimiento
    final file = File(rutaImagen!);

    return FutureBuilder<bool>(
      // Este future se resuelve más rápido que cargar la imagen completa
      future: file.exists().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => false,
      ),
      builder: (context, snapshot) {
        // Si el archivo no existe o hay error, mostrar placeholder
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            snapshot.data != true) {
          if (snapshot.hasError) {
            _registrarErrorControlado(
              'img_exists_${inmueble.id}',
              'Error al verificar existencia de imagen: ${snapshot.error}',
            );
          }
          return InmuebleImagePlaceholder(tipoInmueble: inmueble.tipoInmueble);
        }

        // Cargar imagen solo cuando sabemos que el archivo existe
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            _registrarErrorControlado(
              'img_load_${inmueble.id}',
              'Error al cargar imagen: $error',
            );
            return InmuebleImagePlaceholder(
              tipoInmueble: inmueble.tipoInmueble,
            );
          },
          // Usar memoria caché para mejorar rendimiento
          cacheWidth: (MediaQuery.of(context).size.width * 1.5).toInt(),
        );
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

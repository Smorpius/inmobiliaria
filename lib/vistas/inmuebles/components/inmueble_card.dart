import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/inmueble_utils.dart';
import '../../../models/inmueble_model.dart';
import '../../../models/inmueble_imagen.dart';
import '../../../utils/inmueble_formatter.dart';

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
    final bool estaInactivo = inmueble.idEstado == 2;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero, // Elimina el margen externo
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con indicador de estado
            Stack(
              children: [
                // Imagen del inmueble
                SizedBox(
                  height: 220, // Ajustado de 220 a 160 para mejor proporción
                  width: double.infinity,
                  child: _buildImage(),
                ),
                // Indicador de estado
                if (estaInactivo)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Text(
                        'NO DISPONIBLE',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                // Botón de editar
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Editar',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),

            // Contenido de texto
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Padding interior reducido
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nombre
                    Text(
                      inmueble.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Tamaño de fuente reducido
                        color: estaInactivo ? Colors.grey : null,
                        decoration:
                            estaInactivo ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2), // Espaciado reducido
                    // Dirección
                    Text(
                      _getDireccionCorta(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12, // Tamaño reducido
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4), // Espaciado reducido
                    // Precio
                    Text(
                      InmuebleFormatter.formatMonto(inmueble.montoTotal),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: estaInactivo ? Colors.grey : Colors.indigo,
                      ),
                    ),

                    // Tipo de inmueble y operación
                    Row(
                      children: [
                        Icon(
                          InmuebleUtils.getTipoInmuebleIcon(
                            inmueble.tipoInmueble,
                          ),
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${InmuebleFormatter.formatTipoInmueble(inmueble.tipoInmueble)} - ${InmuebleFormatter.formatTipoOperacion(inmueble.tipoOperacion)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
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

  String _getDireccionCorta() {
    List<String> partes = [];

    // CORRECCIÓN: Agregando llaves {} a todas las estructuras if
    if (inmueble.calle != null && inmueble.calle!.isNotEmpty) {
      partes.add(inmueble.calle!);
    }
    if (inmueble.colonia != null && inmueble.colonia!.isNotEmpty) {
      partes.add(inmueble.colonia!);
    }
    if (inmueble.ciudad != null && inmueble.ciudad!.isNotEmpty) {
      partes.add(inmueble.ciudad!);
    }

    return partes.isNotEmpty ? partes.join(', ') : 'Sin dirección';
  }

  Widget _buildImage() {
    if (rutaImagen != null && rutaImagen!.isNotEmpty) {
      return Image.file(
        File(rutaImagen!),
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            InmuebleUtils.getTipoInmuebleIcon(inmueble.tipoInmueble),
            size: 50, // Aumentado de 40 a 50 para mejor visualización
            color: Colors.grey[400],
          ),
        ),
      );
    }
  }
}

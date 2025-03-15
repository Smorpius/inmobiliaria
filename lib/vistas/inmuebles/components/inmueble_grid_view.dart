import 'inmueble_card.dart';
import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';
import '../../../models/inmueble_imagen.dart';

class InmuebleGridView extends StatelessWidget {
  final List<Inmueble> inmuebles;
  final Map<int, InmuebleImagen?> imagenesPrincipales;
  final Map<int, String?> rutasImagenesPrincipales;
  final Function(Inmueble) onTapInmueble;
  final Function(Inmueble) onEditInmueble;

  const InmuebleGridView({
    super.key,
    required this.inmuebles,
    required this.imagenesPrincipales,
    required this.rutasImagenesPrincipales,
    required this.onTapInmueble,
    required this.onEditInmueble,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _calculateCrossAxisCount(context);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8, // Reducido de 10 a 8
        mainAxisSpacing: 8, // Reducido de 10 a 8
        childAspectRatio: 0.99, // Aumentado para tarjetas menos altas
      ),
      itemCount: inmuebles.length,
      itemBuilder: (context, index) {
        final inmueble = inmuebles[index];
        return InmuebleCard(
          inmueble: inmueble,
          imagenPrincipal:
              inmueble.id != null ? imagenesPrincipales[inmueble.id!] : null,
          rutaImagen:
              inmueble.id != null
                  ? rutasImagenesPrincipales[inmueble.id!]
                  : null,
          onTap: () => onTapInmueble(inmueble),
          onEdit: () => onEditInmueble(inmueble),
        );
      },
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 2; // 2 columnas en pantallas pequeñas
    } else if (screenWidth < 600) {
      return 2;
    } else if (screenWidth < 900) {
      return 3; // 3 columnas en pantallas medianas
    } else {
      return 4; // 4 columnas en pantallas grandes
    }
  }
}

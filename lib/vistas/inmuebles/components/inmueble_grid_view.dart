import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';
import '../../../models/inmueble_imagen.dart';
import 'package:inmobiliaria/utils/inmueble_utils.dart';

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
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
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
    if (screenWidth < 600) {
      return 1;
    } else if (screenWidth < 900) {
      return 2;
    } else {
      return 3;
    }
  }
}

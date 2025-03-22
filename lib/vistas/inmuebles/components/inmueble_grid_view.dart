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
  final Function(Inmueble) onInactivateInmueble;
  final Widget Function(Inmueble, VoidCallback)? renderizarBotonEstado;

  const InmuebleGridView({
    super.key,
    required this.inmuebles,
    required this.imagenesPrincipales,
    required this.rutasImagenesPrincipales,
    required this.onTapInmueble,
    required this.onEditInmueble,
    required this.onInactivateInmueble,
    this.renderizarBotonEstado,
  });

  @override
  Widget build(BuildContext context) {
    // Usar MediaQuery para determinar el número de columnas según ancho de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final columns =
        screenWidth > 600
            ? 3
            : 2; // 3 columnas en tablets/desktop, 2 en móviles

    return GridView.builder(
      padding: const EdgeInsets.all(4.0), // Reducido de 8.0
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 1.20, // Modificado para tarjetas más altas que anchas
        crossAxisSpacing: 8, // Reducido de 8
        mainAxisSpacing: 8, // Reducido de 8
      ),
      itemCount: inmuebles.length,
      itemBuilder: (context, index) {
        final inmueble = inmuebles[index];
        final isInactivo = inmueble.idEstado == 2;
        final imagenPrincipal = imagenesPrincipales[inmueble.id];
        final rutaImagen = rutasImagenesPrincipales[inmueble.id];
        final buttonText = isInactivo ? 'Marcar Disponible' : 'Desactivar';
        final buttonColor = isInactivo ? Colors.green : Colors.red;

        final customButton =
            renderizarBotonEstado != null
                ? renderizarBotonEstado!(
                  inmueble,
                  () => onInactivateInmueble(inmueble),
                )
                : null;

        return InmuebleCard(
          inmueble: inmueble,
          imagenPrincipal: imagenPrincipal,
          rutaImagen: rutaImagen,
          isInactivo: isInactivo,
          onTap: () => onTapInmueble(inmueble),
          onEdit: () => onEditInmueble(inmueble),
          onInactivate: () => onInactivateInmueble(inmueble),
          inactivateButtonText: buttonText,
          inactivateButtonColor: buttonColor,
          customStateButton: customButton,
        );
      },
    );
  }
}

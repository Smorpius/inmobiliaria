import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';

class InmuebleOperationButtons extends StatelessWidget {
  final Inmueble inmueble;
  final Function(String) onOperationSelected;
  final bool isInNegotiation;
  final VoidCallback? onFinishProcess;

  const InmuebleOperationButtons({
    super.key,
    required this.inmueble,
    required this.onOperationSelected,
    this.isInNegotiation = false,
    this.onFinishProcess,
  });

  @override
  Widget build(BuildContext context) {
    // Si el inmueble está en negociación, mostrar solo el botón de finalizar proceso
    if (isInNegotiation) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
        icon: const Icon(Icons.task_alt),
        label: const Text('Finalizar proceso de negociación'),
        onPressed: onFinishProcess,
      );
    }

    // Si no está disponible, no mostrar botones
    if (inmueble.idEstado != 3) {
      return const SizedBox.shrink();
    }

    // Determinar qué botones mostrar según el tipo de operación
    return Column(
      children: [
        if (inmueble.tipoOperacion == 'venta' ||
            inmueble.tipoOperacion == 'ambos')
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            icon: const Icon(Icons.sell),
            label: const Text('Iniciar proceso de venta'),
            onPressed: () => onOperationSelected('venta'),
          ),

        if (inmueble.tipoOperacion == 'venta' &&
            inmueble.tipoOperacion == 'ambos')
          const SizedBox(height: 12),

        if (inmueble.tipoOperacion == 'renta' ||
            inmueble.tipoOperacion == 'ambos')
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            icon: const Icon(Icons.home),
            label: const Text('Iniciar proceso de renta'),
            onPressed: () => onOperationSelected('renta'),
          ),

        const SizedBox(height: 12),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          icon: const Icon(Icons.home_repair_service),
          label: const Text('Agregar servicio'),
          onPressed: () => onOperationSelected('servicio'),
        ),
      ],
    );
  }
}

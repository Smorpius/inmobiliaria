import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/inmueble_model.dart';

/// Widget que muestra los botones de operaciones disponibles para un inmueble
/// según su estado actual y tipo de operación permitida.
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
    try {
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
      final mostrarBotonVenta =
          inmueble.tipoOperacion == 'venta' ||
          inmueble.tipoOperacion == 'ambos';

      final mostrarBotonRenta =
          inmueble.tipoOperacion == 'renta' ||
          inmueble.tipoOperacion == 'ambos';

      return Column(
        children: [
          if (mostrarBotonVenta)
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

          // Corregido: La condición original nunca sería verdadera porque
          // tipoOperacion no puede ser 'venta' Y 'ambos' al mismo tiempo
          if (mostrarBotonVenta && mostrarBotonRenta)
            const SizedBox(height: 12),

          if (mostrarBotonRenta)
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
    } catch (e, stackTrace) {
      // Log cualquier error inesperado que ocurra en la UI
      AppLogger.error(
        'Error al renderizar botones de operación',
        e,
        stackTrace,
      );

      // Devolver un widget de respaldo en caso de error
      return const SizedBox(
        height: 50,
        child: Center(
          child: Text(
            'No se pudieron cargar las opciones',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }
}

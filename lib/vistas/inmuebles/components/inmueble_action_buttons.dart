import 'package:flutter/material.dart';

/// Widget que muestra los botones de acción para un inmueble.
///
/// Incluye botones para editar, cambiar estado (activar/inactivar) y
/// opcionalmente añadir un cliente interesado.
class InmuebleActionButtons extends StatelessWidget {
  /// Función a ejecutar cuando se presiona el botón de editar.
  final VoidCallback onEdit;

  /// Función a ejecutar cuando se presiona el botón de cambiar estado.
  final VoidCallback onDelete;

  /// Función opcional a ejecutar cuando se presiona el botón de agregar cliente interesado.
  final VoidCallback? onAddClienteInteresado;

  /// Indica si el inmueble está inactivo para ajustar la apariencia de los botones.
  final bool isInactivo;

  /// Indica si se debe mostrar el botón de agregar cliente interesado.
  final bool showAddClienteInteresado;

  /// Texto personalizado para el botón de cambiar estado.
  /// Si es null, se usará un texto predeterminado según [isInactivo].
  final String? deleteButtonText;

  /// Color personalizado para el botón de cambiar estado.
  /// Si es null, se usará verde para activar y rojo para inactivar.
  final Color? deleteButtonColor;

  const InmuebleActionButtons({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.onAddClienteInteresado,
    this.isInactivo = false,
    this.showAddClienteInteresado = false,
    this.deleteButtonText,
    this.deleteButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determinar el texto del botón usando el valor proporcionado o un valor predeterminado
    final textoBoton =
        deleteButtonText ??
        (isInactivo ? 'Marcar como Disponible' : 'Marcar como No Disponible');

    // Determinar el color del botón usando el valor proporcionado o un valor predeterminado
    final colorBoton =
        deleteButtonColor ?? (isInactivo ? Colors.green : Colors.red);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Botón de editar
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Botón de inactivar/reactivar
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onDelete,
            icon: Icon(isInactivo ? Icons.check_circle : Icons.remove_circle),
            label: Text(textoBoton),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorBoton,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        // Botón opcional para agregar cliente interesado
        if (showAddClienteInteresado && onAddClienteInteresado != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAddClienteInteresado,
              icon: const Icon(Icons.person_add),
              label: const Text('Agregar Interesado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

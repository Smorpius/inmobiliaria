import 'package:flutter/material.dart';

class InmuebleActionButtons extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onAddClienteInteresado;
  final bool isInactivo;
  final bool showAddClienteInteresado;
  // Parámetros para personalizar el botón de eliminar/inactivar
  final String? deleteButtonText;
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
        (isInactivo ? 'Marcar Disponible' : 'Marcar como No Disponible');

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

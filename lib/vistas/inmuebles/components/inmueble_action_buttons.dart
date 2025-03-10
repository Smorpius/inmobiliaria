import 'package:flutter/material.dart';

class InmuebleActionButtons extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isInactivo;
  final bool showAddClienteInteresado;
  final VoidCallback? onAddClienteInteresado;

  const InmuebleActionButtons({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.isInactivo,
    this.showAddClienteInteresado = false,
    this.onAddClienteInteresado,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!isInactivo)
          ElevatedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        if (!isInactivo) const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: onDelete,
          icon: Icon(isInactivo ? Icons.home : Icons.delete),
          label: Text(
            isInactivo ? 'Marcar disponible' : 'Marcar no disponible',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isInactivo ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
        if (showAddClienteInteresado && !isInactivo)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ElevatedButton.icon(
              onPressed: onAddClienteInteresado,
              icon: const Icon(Icons.person_add),
              label: const Text('Agregar cliente interesado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

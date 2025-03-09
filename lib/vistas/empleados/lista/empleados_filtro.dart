import 'package:flutter/material.dart';

class EmpleadosFiltro extends StatelessWidget {
  final bool mostrarInactivos;
  final ValueChanged<bool> onChanged;
  final bool isLoading;
  final VoidCallback onRefresh;

  const EmpleadosFiltro({
    super.key,
    required this.mostrarInactivos,
    required this.onChanged,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Mostrar inactivos',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        Switch(
          value: mostrarInactivos,
          onChanged: isLoading ? null : onChanged,
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: isLoading ? null : onRefresh,
          tooltip: 'Actualizar lista',
        ),
      ],
    );
  }
}

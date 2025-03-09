import 'package:flutter/material.dart';

class EmpleadosEmptyView extends StatelessWidget {
  final bool mostrandoInactivos;
  final VoidCallback onNuevoEmpleado;

  const EmpleadosEmptyView({
    super.key,
    required this.mostrandoInactivos,
    required this.onNuevoEmpleado,
  });

  @override
  Widget build(BuildContext context) {
    final mensaje =
        mostrandoInactivos
            ? 'No hay empleados registrados'
            : 'No hay empleados activos';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            mostrandoInactivos
                ? 'Registre un nuevo empleado para comenzar'
                : 'Todos los empleados están inactivos',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onNuevoEmpleado,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Empleado'),
          ),
        ],
      ),
    );
  }
}

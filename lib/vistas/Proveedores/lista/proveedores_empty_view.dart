import 'package:flutter/material.dart';

class ProveedoresEmptyView extends StatelessWidget {
  final bool mostrandoInactivos;
  final VoidCallback onNuevoProveedor;

  const ProveedoresEmptyView({
    super.key,
    required this.mostrandoInactivos,
    required this.onNuevoProveedor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            mostrandoInactivos
                ? 'No hay proveedores registrados'
                : 'No hay proveedores activos',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            mostrandoInactivos
                ? 'Crea tu primer proveedor para comenzar'
                : 'No se encontraron proveedores activos',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onNuevoProveedor,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Proveedor'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class InmuebleEmptyState extends StatelessWidget {
  final bool isFiltering;
  final VoidCallback onLimpiarFiltros;

  const InmuebleEmptyState({
    super.key,
    required this.isFiltering,
    required this.onLimpiarFiltros,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltering ? Icons.search_off : Icons.home_work,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltering
                ? 'No se encontraron inmuebles con los filtros aplicados'
                : 'No hay inmuebles registrados',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (isFiltering) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onLimpiarFiltros,
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
              ),
            ),
          ],
          if (!isFiltering) ...[
            const SizedBox(height: 12),
            const Text(
              'Pulse el botón + para agregar un inmueble',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

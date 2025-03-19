import 'package:flutter/material.dart';

class ProveedoresEmptyView extends StatelessWidget {
  final bool mostrandoInactivos;
  final VoidCallback onNuevoProveedor;
  final String? terminoBusqueda; // Nuevo parámetro
  final VoidCallback? onClearSearch; // Nuevo parámetro

  const ProveedoresEmptyView({
    super.key,
    required this.mostrandoInactivos,
    required this.onNuevoProveedor,
    this.terminoBusqueda,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    // Si hay término de búsqueda, mostrar mensaje específico para búsqueda sin resultados
    final bool esBusqueda =
        terminoBusqueda != null && terminoBusqueda!.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            esBusqueda ? Icons.search_off : Icons.business_center_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            esBusqueda
                ? 'No se encontraron resultados'
                : (mostrandoInactivos
                    ? 'No hay proveedores registrados'
                    : 'No hay proveedores activos'),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            esBusqueda
                ? 'No se encontraron proveedores que coincidan con "$terminoBusqueda"'
                : (mostrandoInactivos
                    ? 'Crea tu primer proveedor para comenzar'
                    : 'No se encontraron proveedores activos'),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (esBusqueda && onClearSearch != null)
            ElevatedButton.icon(
              onPressed: onClearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar búsqueda'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            )
          else
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

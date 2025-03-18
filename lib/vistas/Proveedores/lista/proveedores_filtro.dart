import 'package:flutter/material.dart';

class ProveedoresFiltro extends StatelessWidget {
  final bool mostrarInactivos;
  final Function(bool) onChanged;
  final bool isLoading;
  final VoidCallback onRefresh;

  const ProveedoresFiltro({
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
        // Interruptor para mostrar/ocultar proveedores inactivos
        Switch(
          value: mostrarInactivos,
          onChanged: isLoading ? null : onChanged,
          // MEJORA: Colores personalizados para mejorar UX
          activeColor: Colors.green,
          activeTrackColor: Colors.greenAccent,
        ),
        Text(
          mostrarInactivos ? 'Mostrando todos' : 'Sólo activos',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        // Botón de recargar
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: isLoading ? null : onRefresh,
          tooltip: 'Recargar',
        ),
      ],
    );
  }
}

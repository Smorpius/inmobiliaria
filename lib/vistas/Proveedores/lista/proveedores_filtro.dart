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
          // Colores personalizados para mejorar UX
          activeColor: Colors.orange,
          activeTrackColor: Colors.orangeAccent,
        ),
        Text(
          mostrarInactivos ? 'Solo inactivos' : 'Solo activos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            // Sombra para mejor legibilidad en cualquier fondo
            shadows: [
              Shadow(
                offset: const Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Color.fromRGBO(0, 0, 0, 0.5), // Reemplazado withOpacity
              ),
            ],
          ),
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

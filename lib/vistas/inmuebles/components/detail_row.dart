import 'package:flutter/material.dart';

/// Widget que muestra un detalle con formato consistente de icono, etiqueta y valor.
/// Usado para mostrar información en vistas de detalle de inmuebles, clientes, etc.
class DetailRow extends StatelessWidget {
  /// Etiqueta descriptiva del campo
  final String label;

  /// Valor del campo a mostrar
  final String value;

  /// Icono que representa el tipo de información
  final IconData icon;

  /// Indica si el elemento está en estado inactivo para aplicar estilo atenuado
  final bool isInactivo;

  /// Color opcional para el valor (útil para estados o valores especiales)
  final Color? valueColor;

  /// Color opcional para personalizar el ícono
  final Color iconColor;

  /// Estilo constante para la etiqueta para mejorar rendimiento
  static const TextStyle _labelStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: Colors.indigo,
  );

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.isInactivo = false,
    this.valueColor,
    this.iconColor = Colors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isInactivo ? Colors.grey : iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _labelStyle),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'No especificado',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isInactivo
                            ? Colors.grey.shade600
                            : (valueColor ?? Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

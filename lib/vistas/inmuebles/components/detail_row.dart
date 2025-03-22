import 'package:flutter/material.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isInactivo;
  final Color? valueColor; // Agregado nuevo parámetro

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.isInactivo = false,
    this.valueColor, // Parámetro opcional para el color del valor
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isInactivo
                            ? Colors.grey.shade600
                            : (valueColor ??
                                Colors
                                    .black), // Usar color proporcionado si existe
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

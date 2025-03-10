import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';

class InmuebleHeader extends StatelessWidget {
  final Inmueble inmueble;
  final bool isInactivo;

  const InmuebleHeader({
    super.key,
    required this.inmueble,
    required this.isInactivo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor:
                isInactivo ? Colors.grey.shade300 : Colors.indigo.shade100,
            child: Icon(
              Icons.home,
              size: 40,
              color: isInactivo ? Colors.grey : Colors.indigo,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            inmueble.nombre,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              decoration: isInactivo ? TextDecoration.lineThrough : null,
              color: isInactivo ? Colors.grey.shade700 : null,
            ),
            textAlign: TextAlign.center,
          ),
          if (isInactivo)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'NO DISPONIBLE',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

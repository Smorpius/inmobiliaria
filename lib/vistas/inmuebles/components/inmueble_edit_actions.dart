import 'package:flutter/material.dart';

class InmuebleEditActions extends StatelessWidget {
  final VoidCallback onActualizar;
  final VoidCallback onEliminar;

  const InmuebleEditActions({
    super.key,
    required this.onActualizar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: onActualizar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('ACTUALIZAR', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: onEliminar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('ELIMINAR', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

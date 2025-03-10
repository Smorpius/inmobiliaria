import 'package:flutter/material.dart';

class InmuebleEditForm extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController montoController;
  final TextEditingController estadoController;

  const InmuebleEditForm({
    super.key,
    required this.nombreController,
    required this.montoController,
    required this.estadoController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información del Inmueble',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese el nombre del inmueble';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: montoController,
          decoration: const InputDecoration(
            labelText: 'Monto',
            border: OutlineInputBorder(),
            prefixText: '\$ ',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese el monto';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: estadoController,
          decoration: const InputDecoration(
            labelText: 'Estado',
            border: OutlineInputBorder(),
            helperText:
                '1 = Activo, 2 = Inactivo, 3 = Disponible, 4 = Vendido, 5 = Rentado, 6 = En Negociación',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

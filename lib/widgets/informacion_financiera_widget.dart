import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InformacionFinancieraWidget extends StatelessWidget {
  final TextEditingController costoClienteController;
  final TextEditingController costoServiciosController;
  final TextEditingController comisionAgenciaController;
  final TextEditingController comisionAgenteController;
  final TextEditingController precioVentaFinalController;
  final TextEditingController margenUtilidadController; // Nuevo controlador
  final Function() onCostoChanged;
  final String? Function(String?) validarCostos;

  const InformacionFinancieraWidget({
    super.key,
    required this.costoClienteController,
    required this.costoServiciosController,
    required this.comisionAgenciaController,
    required this.comisionAgenteController,
    required this.precioVentaFinalController,
    required this.margenUtilidadController, // Nuevo parámetro
    required this.onCostoChanged,
    required this.validarCostos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Financiera',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Costo del Cliente
        TextFormField(
          controller: costoClienteController,
          decoration: const InputDecoration(
            labelText: 'Costo del Cliente',
            hintText: 'Ingrese el costo solicitado por el cliente',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
            prefixText: '\$ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          validator: validarCostos,
          onChanged: (value) => onCostoChanged(),
        ),
        const SizedBox(height: 16),

        // Costo de Servicios
        TextFormField(
          controller: costoServiciosController,
          decoration: const InputDecoration(
            labelText: 'Costo de Servicios',
            hintText: 'Ingrese el costo de servicios y proveedores',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home_repair_service),
            prefixText: '\$ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          validator: validarCostos,
          onChanged: (value) => onCostoChanged(),
        ),
        const SizedBox(height: 16),

        // Comisión Agencia (solo lectura)
        TextFormField(
          controller: comisionAgenciaController,
          decoration: const InputDecoration(
            labelText: 'Comisión Agencia (30%)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
            prefixText: '\$ ',
            helperText:
                'Calculado automáticamente como 30% del costo del cliente',
          ),
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Comisión Agente (solo lectura)
        TextFormField(
          controller: comisionAgenteController,
          decoration: const InputDecoration(
            labelText: 'Comisión Agente (3%)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
            prefixText: '\$ ',
            helperText:
                'Calculado automáticamente como 3% del costo del cliente',
          ),
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Precio Venta Final (solo lectura)
        TextFormField(
          controller: precioVentaFinalController,
          decoration: const InputDecoration(
            labelText: 'Precio de Venta Final',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.money),
            prefixText: '\$ ',
            helperText: 'Suma del costo del cliente, servicios y comisiones',
          ),
          readOnly: true,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Nuevo campo: Margen de Utilidad (solo lectura)
        TextFormField(
          controller: margenUtilidadController,
          decoration: const InputDecoration(
            labelText: 'Margen de Utilidad (%)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.trending_up),
            suffixText: '%',
            helperText: 'Porcentaje de ganancia sobre el precio final',
          ),
          readOnly: true,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InformacionFinancieraWidget extends StatelessWidget {
  final TextEditingController costoClienteController;
  final TextEditingController costoServiciosController;
  final TextEditingController comisionAgenciaController;
  final TextEditingController comisionAgenteController;
  final TextEditingController precioVentaFinalController;
  final Function() onCostoChanged;
  final String? Function(String?) validarCostos;

  const InformacionFinancieraWidget({
    super.key,
    required this.costoClienteController,
    required this.costoServiciosController,
    required this.comisionAgenciaController,
    required this.comisionAgenteController,
    required this.precioVentaFinalController,
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
            hintText: 'Precio que pide el cliente por su propiedad',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
            prefixText: '\$ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
            hintText: 'Costo de servicios de proveedores',
            prefixIcon: Icon(Icons.home_repair_service),
            border: OutlineInputBorder(),
            prefixText: '\$ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
            prefixIcon: Icon(Icons.business),
            border: OutlineInputBorder(),
            prefixText: '\$ ',
            filled: true,
            fillColor: Color.fromARGB(31, 187, 187, 187),
          ),
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Comisión Agente (solo lectura)
        TextFormField(
          controller: comisionAgenteController,
          decoration: const InputDecoration(
            labelText: 'Comisión Agente (3%)',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
            prefixText: '\$ ',
            filled: true,
            fillColor: Color.fromARGB(31, 187, 187, 187),
          ),
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Precio Venta Final (solo lectura)
        TextFormField(
          controller: precioVentaFinalController,
          decoration: const InputDecoration(
            labelText: 'PRECIO VENTA FINAL',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
            prefixText: '\$ ',
            filled: true,
            fillColor: Color.fromARGB(31, 130, 174, 255),
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          readOnly: true,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../models/inmueble_model.dart';
import '../utils/inmueble_formatter.dart';
import '../vistas/inmuebles/components/detail_row.dart';

class InmuebleFinancieroInfo extends StatelessWidget {
  final Inmueble inmueble;
  final bool isInactivo;

  const InmuebleFinancieroInfo({
    super.key,
    required this.inmueble,
    required this.isInactivo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            'Información Financiera',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isInactivo ? Colors.grey : Colors.indigo,
            ),
          ),
        ),
        DetailRow(
          label: 'Costo del Cliente',
          value: InmuebleFormatter.formatMonto(inmueble.costoCliente),
          icon: Icons.person_outline,
          isInactivo: isInactivo,
        ),
        DetailRow(
          label: 'Costo de Servicios',
          value: InmuebleFormatter.formatMonto(inmueble.costoServicios),
          icon: Icons.home_repair_service,
          isInactivo: isInactivo,
        ),
        DetailRow(
          label: 'Comisión de la Agencia (30%)',
          value: InmuebleFormatter.formatMonto(inmueble.comisionAgencia),
          icon: Icons.business,
          isInactivo: isInactivo,
        ),
        DetailRow(
          label: 'Comisión del Agente (3%)',
          value: InmuebleFormatter.formatMonto(inmueble.comisionAgente),
          icon: Icons.person,
          isInactivo: isInactivo,
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isInactivo ? Colors.grey.shade200 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DetailRow(
            label: 'PRECIO DE VENTA FINAL',
            value: InmuebleFormatter.formatMonto(inmueble.precioVentaFinal),
            icon: Icons.attach_money,
            isInactivo: isInactivo,
          ),
        ),
      ],
    );
  }
}

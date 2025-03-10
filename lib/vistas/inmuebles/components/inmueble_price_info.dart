import 'detail_row.dart';
import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';
import 'package:inmobiliaria/utils/inmueble_formatter.dart';

class InmueblePriceInfo extends StatelessWidget {
  final Inmueble inmueble;
  final bool isInactivo;

  const InmueblePriceInfo({
    super.key,
    required this.inmueble,
    required this.isInactivo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DetailRow(
          label: 'Monto total',
          value: InmuebleFormatter.formatMonto(inmueble.montoTotal),
          icon: Icons.attach_money,
          isInactivo: isInactivo,
        ),
        if (inmueble.tipoOperacion == 'venta' || inmueble.tipoOperacion == 'ambos')
          DetailRow(
            label: 'Precio de venta',
            value: InmuebleFormatter.formatMonto(inmueble.precioVenta),
            icon: Icons.monetization_on,
            isInactivo: isInactivo,
          ),
        if (inmueble.tipoOperacion == 'renta' || inmueble.tipoOperacion == 'ambos')
          DetailRow(
            label: 'Precio de renta',
            value: InmuebleFormatter.formatMonto(inmueble.precioRenta),
            icon: Icons.payments,
            isInactivo: isInactivo,
          ),
      ],
    );
  }
}
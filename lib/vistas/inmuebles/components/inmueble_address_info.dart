import 'detail_row.dart';
import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';

class InmuebleAddressInfo extends StatelessWidget {
  final Inmueble inmueble;
  final bool isInactivo;

  const InmuebleAddressInfo({
    super.key,
    required this.inmueble,
    required this.isInactivo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DetailRow(
          label: 'Dirección completa',
          value: inmueble.direccionCompleta,
          icon: Icons.location_on,
          isInactivo: isInactivo,
        ),
        // Componentes individuales de la dirección
        if (inmueble.calle != null && inmueble.calle!.isNotEmpty)
          DetailRow(
            label: 'Calle',
            value: inmueble.calle!,
            icon: Icons.signpost,
            isInactivo: isInactivo,
          ),
        if (inmueble.numero != null && inmueble.numero!.isNotEmpty)
          DetailRow(
            label: 'Número',
            value: inmueble.numero!,
            icon: Icons.confirmation_number,
            isInactivo: isInactivo,
          ),
        if (inmueble.colonia != null && inmueble.colonia!.isNotEmpty)
          DetailRow(
            label: 'Colonia',
            value: inmueble.colonia!,
            icon: Icons.holiday_village,
            isInactivo: isInactivo,
          ),
        if (inmueble.ciudad != null && inmueble.ciudad!.isNotEmpty)
          DetailRow(
            label: 'Ciudad',
            value: inmueble.ciudad!,
            icon: Icons.location_city,
            isInactivo: isInactivo,
          ),
        if (inmueble.estadoGeografico != null &&
            inmueble.estadoGeografico!.isNotEmpty)
          DetailRow(
            label: 'Estado',
            value: inmueble.estadoGeografico!,
            icon: Icons.map,
            isInactivo: isInactivo,
          ),
        if (inmueble.codigoPostal != null && inmueble.codigoPostal!.isNotEmpty)
          DetailRow(
            label: 'Código Postal',
            value: inmueble.codigoPostal!,
            icon: Icons.markunread_mailbox,
            isInactivo: isInactivo,
          ),
        if (inmueble.referencias != null && inmueble.referencias!.isNotEmpty)
          DetailRow(
            label: 'Referencias',
            value: inmueble.referencias!,
            icon: Icons.place,
            isInactivo: isInactivo,
          ),
      ],
    );
  }
}

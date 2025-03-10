import 'detail_row.dart';
import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';
import 'package:inmobiliaria/utils/inmueble_formatter.dart';

class InmuebleBasicInfo extends StatelessWidget {
  final Inmueble inmueble;
  final bool isInactivo;

  const InmuebleBasicInfo({
    super.key,
    required this.inmueble,
    required this.isInactivo,
  });

  @override
  Widget build(BuildContext context) {
    final estadoInmueble = InmuebleFormatter.obtenerEstadoInmueble(
      inmueble.idEstado,
    );

    return Column(
      children: [
        DetailRow(
          label: 'Tipo de inmueble',
          value: InmuebleFormatter.formatTipoInmueble(inmueble.tipoInmueble),
          icon: Icons.home,
          isInactivo: isInactivo,
        ),
        DetailRow(
          label: 'Tipo de operación',
          value: InmuebleFormatter.formatTipoOperacion(inmueble.tipoOperacion),
          icon: Icons.sell,
          isInactivo: isInactivo,
        ),
        DetailRow(
          label: 'Estado',
          value: estadoInmueble,
          icon: Icons.info_outline,
          isInactivo: isInactivo,
        ),
        // Características adicionales
        if (inmueble.caracteristicas != null &&
            inmueble.caracteristicas!.isNotEmpty)
          DetailRow(
            label: 'Características',
            value: inmueble.caracteristicas!,
            icon: Icons.list_alt,
            isInactivo: isInactivo,
          ),
        // Fecha de registro
        if (inmueble.fechaRegistro != null)
          DetailRow(
            label: 'Fecha de registro',
            value: inmueble.fechaRegistro.toString().split(' ')[0],
            icon: Icons.calendar_today,
            isInactivo: isInactivo,
          ),
      ],
    );
  }
}

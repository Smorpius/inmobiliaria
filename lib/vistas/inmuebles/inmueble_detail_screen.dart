import 'components/detail_row.dart';
import 'package:flutter/material.dart';
import 'components/inmueble_header.dart';
import '../../models/inmueble_model.dart';
import 'components/inmueble_basic_info.dart';
import 'components/inmueble_price_info.dart';
import 'components/inmueble_address_info.dart';
import 'components/cliente_asociado_info.dart';
import 'components/inmueble_action_buttons.dart';
import '../../controllers/cliente_controller.dart';
import 'components/clientes_interesados_section.dart';
import 'package:inmobiliaria/widgets/inmueble_imagenes_section.dart';

class InmuebleDetailScreen extends StatefulWidget {
  final Inmueble inmueble;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isInactivo;

  const InmuebleDetailScreen({
    super.key,
    required this.inmueble,
    required this.onEdit,
    required this.onDelete,
    this.isInactivo = false,
  });

  @override
  State<InmuebleDetailScreen> createState() => _InmuebleDetailScreenState();
}

class _InmuebleDetailScreenState extends State<InmuebleDetailScreen> {
  // Se eliminó la variable _inmuebleController que no se estaba utilizando
  final ClienteController _clienteController = ClienteController();

  @override
  Widget build(BuildContext context) {
    final inmueble = widget.inmueble;
    final isInactivo = widget.isInactivo;

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      color: isInactivo ? Colors.grey.shade50 : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con nombre del inmueble
            InmuebleHeader(inmueble: inmueble, isInactivo: isInactivo),

            // Sección de imágenes del inmueble
            if (inmueble.id != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: InmuebleImagenesSection(
                  inmuebleId: inmueble.id!,
                  isInactivo: isInactivo,
                ),
              ),

            const Divider(height: 40),

            // Información básica del inmueble (tipo, operación, estado)
            InmuebleBasicInfo(inmueble: inmueble, isInactivo: isInactivo),

            // Información de precios
            InmueblePriceInfo(inmueble: inmueble, isInactivo: isInactivo),

            // Dirección completa y sus componentes
            InmuebleAddressInfo(inmueble: inmueble, isInactivo: isInactivo),

            // Características del inmueble si existen
            if (inmueble.caracteristicas != null &&
                inmueble.caracteristicas!.isNotEmpty)
              DetailRow(
                label: 'Características',
                value: inmueble.caracteristicas!,
                icon: Icons.list_alt,
                isInactivo: isInactivo,
              ),

            // Información del cliente asociado
            if (inmueble.idCliente != null)
              ClienteAsociadoInfo(
                idCliente: inmueble.idCliente!,
                isInactivo: isInactivo,
                clienteController: _clienteController,
              ),

            // ID de empleado responsable
            if (inmueble.idEmpleado != null)
              DetailRow(
                label: 'Empleado responsable',
                value: 'ID: ${inmueble.idEmpleado}',
                icon: Icons.badge,
                isInactivo: isInactivo,
              ),

            // Sección de clientes interesados - solo si está en negociación
            if (inmueble.id != null && inmueble.idEstado == 6)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ClientesInteresadosSection(
                  idInmueble: inmueble.id!,
                  isInactivo: isInactivo,
                ),
              ),

            const SizedBox(height: 24),

            // Botones de acción
            InmuebleActionButtons(
              onEdit: widget.onEdit,
              onDelete: widget.onDelete,
              isInactivo: isInactivo,
              showAddClienteInteresado:
                  false, // Ya no necesitamos este botón aquí
              onAddClienteInteresado:
                  null, // Ya que la funcionalidad está en el componente
            ),
          ],
        ),
      ),
    );
  }
}

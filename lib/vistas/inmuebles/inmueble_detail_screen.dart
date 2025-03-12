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
import '../../controllers/inmueble_controller.dart';
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
  final ClienteController _clienteController = ClienteController();
  final InmuebleController _inmuebleController = InmuebleController();

  // Variable para controlar actualizaciones del estado del inmueble
  late Inmueble _inmueble;

  @override
  void initState() {
    super.initState();
    _inmueble = widget.inmueble;
  }

  // Método para recargar los datos del inmueble
  Future<void> _refreshInmueble() async {
    if (_inmueble.id == null) return;

    try {
      final inmuebles = await _inmuebleController.getInmuebles();
      final inmuebleActualizado = inmuebles.firstWhere(
        (i) => i.id == _inmueble.id,
        orElse: () => _inmueble,
      );

      if (mounted) {
        setState(() {
          _inmueble = inmuebleActualizado;
        });
      }
    } catch (e) {
      // Manejar el error silenciosamente para evitar interrumpir la experiencia
      debugPrint('Error al actualizar datos del inmueble: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final inmueble =
        _inmueble; // Usamos la versión local que puede actualizarse
    final isInactivo = widget.isInactivo;

    return Scaffold(
      appBar: AppBar(
        title: Text(inmueble.nombre),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Card(
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

              // Información del cliente asociado - CORREGIDO
              if (inmueble.idCliente != null && inmueble.id != null)
                ClienteAsociadoInfo(
                  idInmueble: inmueble.id!,
                  idCliente: inmueble.idCliente!,
                  isInactivo: isInactivo,
                  clienteController: _clienteController,
                  onClienteDesasociado: () {
                    // Actualizamos el estado cuando se desasocie un cliente
                    _refreshInmueble();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cliente desasociado del inmueble'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
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
                showAddClienteInteresado: false,
                onAddClienteInteresado: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

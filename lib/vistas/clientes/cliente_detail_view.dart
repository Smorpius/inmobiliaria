import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';
import '../../models/inmueble_model.dart';
import '../inmuebles/inmueble_detalle_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/providers/providers_global.dart';
import 'package:inmobiliaria/providers/cliente_detalle_provider.dart';

class ClienteDetailView extends ConsumerStatefulWidget {
  final Cliente cliente;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isInactivo;

  const ClienteDetailView({
    super.key,
    required this.cliente,
    required this.onEdit,
    required this.onDelete,
    this.isInactivo = false,
  });

  @override
  ConsumerState<ClienteDetailView> createState() => _ClienteDetailViewState();
}

class _ClienteDetailViewState extends ConsumerState<ClienteDetailView> {
  // Definición de la paleta de colores en RGB
  static const Color colorPrimario = Color.fromRGBO(165, 57, 45, 1); // #A5392D
  static const Color colorOscuro = Color.fromRGBO(26, 26, 26, 1); // #1A1A1A
  static const Color colorClaro = Color.fromRGBO(247, 245, 242, 1); // #F7F5F2
  static const Color colorGrisClaro = Color.fromRGBO(
    212,
    207,
    203,
    1,
  ); // #D4CFCB
  static const Color colorAcento = Color.fromRGBO(216, 86, 62, 1); // #D8563E

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      color:
          widget.isInactivo ? Color.fromRGBO(212, 207, 203, 0.3) : colorClaro,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClienteHeader(),
            const Divider(height: 32),
            _buildContactInfo(),
            const Divider(height: 32),
            _buildAddressInfo(),
            const Divider(height: 32),
            _buildInmueblesSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: widget.isInactivo ? colorGrisClaro : colorPrimario,
            foregroundColor: colorClaro,
            radius: 40,
            child: Text(
              widget.cliente.nombre.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.cliente.nombreCompleto,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              decoration: widget.isInactivo ? TextDecoration.lineThrough : null,
              color: widget.isInactivo ? colorGrisClaro : colorOscuro,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.isInactivo)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colorAcento.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'INACTIVO',
                style: TextStyle(
                  color: colorAcento,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem(Icons.phone, 'Teléfono', widget.cliente.telefono),
        _buildDetailItem(Icons.badge, 'RFC', widget.cliente.rfc),
        _buildDetailItem(Icons.assignment_ind, 'CURP', widget.cliente.curp),
        _buildDetailItem(
          Icons.category,
          'Tipo de Cliente',
          _formatTipoCliente(widget.cliente.tipoCliente),
        ),
        if (widget.cliente.correo != null)
          _buildDetailItem(Icons.email, 'Correo', widget.cliente.correo!),
        if (widget.cliente.fechaRegistro != null)
          _buildDetailItem(
            Icons.calendar_today,
            'Fecha de registro',
            widget.cliente.fechaRegistro.toString().split(' ')[0],
          ),
      ],
    );
  }

  Widget _buildAddressInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dirección',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(widget.cliente.direccionCompleta),
        const SizedBox(height: 12),
        if (widget.cliente.calle != null && widget.cliente.calle!.isNotEmpty)
          _buildDetailItem(Icons.location_on, 'Calle', widget.cliente.calle!),
        if (widget.cliente.numero != null && widget.cliente.numero!.isNotEmpty)
          _buildDetailItem(Icons.home, 'Número', widget.cliente.numero!),
        if (widget.cliente.colonia != null &&
            widget.cliente.colonia!.isNotEmpty)
          _buildDetailItem(Icons.grid_3x3, 'Colonia', widget.cliente.colonia!),
        if (widget.cliente.ciudad != null && widget.cliente.ciudad!.isNotEmpty)
          _buildDetailItem(
            Icons.location_city,
            'Ciudad',
            widget.cliente.ciudad!,
          ),
        if (widget.cliente.estadoGeografico != null &&
            widget.cliente.estadoGeografico!.isNotEmpty)
          _buildDetailItem(
            Icons.map,
            'Estado',
            widget.cliente.estadoGeografico!,
          ),
        if (widget.cliente.codigoPostal != null &&
            widget.cliente.codigoPostal!.isNotEmpty)
          _buildDetailItem(
            Icons.markunread_mailbox,
            'Código Postal',
            widget.cliente.codigoPostal!,
          ),
        if (widget.cliente.referencias != null &&
            widget.cliente.referencias!.isNotEmpty)
          _buildDetailItem(
            Icons.info_outline,
            'Referencias',
            widget.cliente.referencias!,
          ),
      ],
    );
  }

  Widget _buildInmueblesSection() {
    if (widget.cliente.id == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Inmuebles asociados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (!widget.isInactivo)
              ElevatedButton.icon(
                icon: const Icon(Icons.add_home),
                label: const Text('Asignar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: _mostrarDialogoSeleccionInmuebles,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Usando Consumer para observar el estado de clienteDetalleProvider
        Consumer(
          builder: (context, ref, child) {
            // Obtener el estado actual del provider
            final clienteDetalleState = ref.watch(
              clienteDetalleProvider(widget.cliente.id!),
            );

            if (clienteDetalleState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (clienteDetalleState.errorMessage != null) {
              return Center(
                child: Text(
                  'Error: ${clienteDetalleState.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final inmuebles = clienteDetalleState.inmuebles;
            if (inmuebles.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay inmuebles asociados a este cliente',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                for (final inmueble in inmuebles) _buildInmuebleCard(inmueble),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInmuebleCard(Map<String, dynamic> inmueble) {
    final nombreInmueble = inmueble['nombre_inmueble'] ?? 'Sin nombre';
    final direccion = [
      inmueble['calle'],
      inmueble['numero'],
      inmueble['colonia'],
      inmueble['ciudad'],
    ].where((item) => item != null && item.isNotEmpty).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getTipoInmuebleIcon(inmueble['tipo_inmueble']),
          color: Colors.teal,
        ),
        title: Text(nombreInmueble),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(direccion.isNotEmpty ? direccion : 'Sin dirección'),
            Text(
              'Operación: ${_capitalizarPalabra(inmueble['tipo_operacion'] ?? 'N/A')}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatMonto(inmueble['monto_total']),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ),
            if (!widget.isInactivo)
              IconButton(
                icon: const Icon(Icons.link_off, color: Colors.red),
                tooltip: 'Desasignar inmueble',
                onPressed: () => _desasignarInmueble(inmueble['id_inmueble']),
              ),
          ],
        ),
        onTap: () => _verDetallesInmueble(inmueble['id_inmueble']),
      ),
    );
  }

  void _verDetallesInmueble(int idInmueble) async {
    try {
      // Usando Riverpod para obtener el controller
      final inmuebleController = ref.read(inmuebleControllerProvider);
      final inmuebles = await inmuebleController.getInmuebles();

      // Encontrar el inmueble específico
      final inmueble = inmuebles.firstWhere(
        (i) => i.id == idInmueble,
        orElse: () => throw Exception('Inmueble no encontrado'),
      );

      if (!mounted) return;

      // Navegar a la pantalla de detalles
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => InmuebleDetailScreen(
                inmuebleInicial: inmueble,
                onEdit: () {}, // No permitimos edición desde aquí
                onDelete: () {}, // No permitimos eliminación desde aquí
                isInactivo: inmueble.idEstado != 3, // 3 = disponible
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar detalles del inmueble: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _desasignarInmueble(int idInmueble) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Desasignar inmueble'),
            content: const Text(
              '¿Está seguro que desea desasignar este inmueble de este cliente?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Desasignar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmar != true || widget.cliente.id == null) return;

    try {
      // Usar el notifier para desasignar el inmueble
      final success = await ref
          .read(clienteDetalleProvider(widget.cliente.id!).notifier)
          .desasignarInmueble(idInmueble);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inmueble desasignado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo desasignar el inmueble'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al desasignar inmueble: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _mostrarDialogoSeleccionInmuebles() async {
    if (widget.cliente.id == null) return;

    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargando inmuebles disponibles...'),
          duration: Duration(milliseconds: 800),
        ),
      );

      // Obtener inmuebles disponibles usando el notifier
      final inmueblesDisponibles =
          await ref
              .read(clienteDetalleProvider(widget.cliente.id!).notifier)
              .getInmueblesDisponibles();

      if (!mounted) return;

      if (inmueblesDisponibles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay inmuebles disponibles para asignar'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mostrar diálogo de selección
      Inmueble? inmuebleSeleccionado = await showDialog<Inmueble>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Seleccionar inmueble'),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: inmueblesDisponibles.length,
                  itemBuilder: (context, index) {
                    final inmueble = inmueblesDisponibles[index];
                    return ListTile(
                      leading: Icon(
                        _getTipoInmuebleIcon(inmueble.tipoInmueble),
                      ),
                      title: Text(inmueble.nombre),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inmueble.direccionCompleta),
                          Text(
                            'Monto: ${_formatMonto(inmueble.montoTotal)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () => Navigator.of(context).pop(inmueble),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
      );

      if (inmuebleSeleccionado != null && mounted) {
        _asignarInmueble(inmuebleSeleccionado);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar inmuebles disponibles: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _asignarInmueble(Inmueble inmueble) async {
    if (widget.cliente.id == null || inmueble.id == null) return;

    try {
      // Usar el notifier para asignar el inmueble
      final success = await ref
          .read(clienteDetalleProvider(widget.cliente.id!).notifier)
          .asignarInmueble(inmueble.id!);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inmueble asignado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo asignar el inmueble'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar inmueble: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!widget.isInactivo)
          ElevatedButton.icon(
            onPressed: widget.onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPrimario,
              foregroundColor: colorClaro,
            ),
          ),
        if (!widget.isInactivo) const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: widget.onDelete,
          icon: Icon(widget.isInactivo ? Icons.person_add : Icons.delete),
          label: Text(widget.isInactivo ? 'Reactivar' : 'Inactivar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isInactivo ? colorPrimario : colorAcento,
            foregroundColor: colorClaro,
          ),
        ),
      ],
    );
  }

  // Utilidades para iconos y formato
  IconData _getTipoInmuebleIcon(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'casa':
        return Icons.home;
      case 'departamento':
        return Icons.apartment;
      case 'terreno':
        return Icons.landscape;
      case 'oficina':
        return Icons.business;
      case 'bodega':
        return Icons.warehouse;
      default:
        return Icons.real_estate_agent;
    }
  }

  String _formatMonto(dynamic monto) {
    if (monto == null) return 'N/A';

    double montoDouble;
    if (monto is double) {
      montoDouble = monto;
    } else if (monto is int) {
      montoDouble = monto.toDouble();
    } else {
      try {
        montoDouble = double.parse(monto.toString());
      } catch (_) {
        return 'N/A';
      }
    }

    return '\$${montoDouble.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _formatTipoCliente(String tipo) {
    switch (tipo) {
      case 'comprador':
        return 'Comprador';
      case 'arrendatario':
        return 'Arrendatario';
      case 'ambos':
        return 'Comprador y Arrendatario';
      default:
        return tipo;
    }
  }

  String _capitalizarPalabra(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorPrimario, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colorOscuro.withAlpha((0.7 * 255).round()),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

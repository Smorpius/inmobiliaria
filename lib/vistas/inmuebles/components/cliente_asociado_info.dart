import 'package:flutter/material.dart';
import '../../../models/cliente_model.dart';
import '../../../providers/cliente_providers.dart';
import '../../../vistas/clientes/vista_clientes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClienteAsociadoInfo extends ConsumerStatefulWidget {
  final int idInmueble;
  final int idCliente;
  final bool isInactivo;
  final VoidCallback onClienteDesasociado;

  const ClienteAsociadoInfo({
    super.key,
    required this.idInmueble,
    required this.idCliente,
    required this.isInactivo,
    required this.onClienteDesasociado,
  });

  @override
  ConsumerState<ClienteAsociadoInfo> createState() =>
      _ClienteAsociadoInfoState();
}

class _ClienteAsociadoInfoState extends ConsumerState<ClienteAsociadoInfo> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Observamos el estado del cliente por ID usando el provider family
    final clienteAsyncValue = ref.watch(clientePorIdProvider(widget.idCliente));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: clienteAsyncValue.when(
        data: (cliente) {
          if (cliente == null) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text('Cliente no encontrado'),
            );
          }

          return _buildClienteInfo(cliente);
        },
        loading:
            () =>
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    ),
        error:
            (error, stack) => Text(
              'Error al cargar cliente: $error',
              style: TextStyle(color: Colors.red.shade700),
            ),
      ),
    );
  }

  Widget _buildClienteInfo(Cliente cliente) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cliente propietario',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (!widget.isInactivo)
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Cambiar'),
                onPressed: () => _mostrarDialogoCambiarCliente(context),
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con avatar y nombre
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          widget.isInactivo ? Colors.grey : Colors.teal,
                      foregroundColor: Colors.white,
                      child: Text(
                        cliente.nombre.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente.nombreCompleto,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTipoCliente(cliente.tipoCliente),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Información de contacto
                _buildInfoRow(Icons.phone, 'Teléfono', cliente.telefono),
                const SizedBox(height: 8),
                if (cliente.correo != null && cliente.correo!.isNotEmpty)
                  _buildInfoRow(Icons.email, 'Correo', cliente.correo!),

                const SizedBox(height: 16),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver detalles'),
                      onPressed: () => _verDetallesCliente(cliente),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!widget.isInactivo)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.link_off, size: 18),
                        label: const Text('Desasociar'),
                        onPressed: () => _desasociarCliente(widget.idInmueble),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.teal),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            Text(value, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
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

  void _verDetallesCliente(Cliente cliente) {
    // Obtener el controlador a través del provider
    final clienteController = ref.read(clienteControllerProvider);

    // Navegar a la pantalla de detalles del cliente
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VistaClientes(
              controller: clienteController,
              clienteInicial: cliente,
            ),
      ),
    );
  }

  Future<void> _mostrarDialogoCambiarCliente(BuildContext context) async {
    // Esta función permitiría seleccionar un cliente diferente
    // Implementación pendiente según los requisitos específicos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Método modificado para actualizar la vista después de desasociar
  Future<void> _desasociarCliente(int idInmueble) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Desasociar cliente'),
            content: const Text(
              '¿Está seguro que desea desasociar este cliente del inmueble?',
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
                  'Desasociar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener controlador a través del provider
      final clienteController = ref.read(clienteControllerProvider);

      // Desasociar el cliente del inmueble
      await clienteController.desasignarInmuebleDeCliente(idInmueble);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente desasociado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Invalidar el provider para forzar recarga
      ref.invalidate(clientePorIdProvider(widget.idCliente));

      // Notificar al padre para que actualice la UI
      widget.onClienteDesasociado();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al desasociar cliente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

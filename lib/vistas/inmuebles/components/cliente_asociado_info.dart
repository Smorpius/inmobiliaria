import 'package:flutter/material.dart';
import '../../../models/cliente_model.dart';
import '../../../controllers/cliente_controller.dart';
import '../../../vistas/clientes/vista_clientes.dart';

class ClienteAsociadoInfo extends StatefulWidget {
  final int idInmueble;
  final int idCliente;
  final bool isInactivo;
  final ClienteController clienteController;
  final VoidCallback onClienteDesasociado;

  const ClienteAsociadoInfo({
    super.key,
    required this.idInmueble,
    required this.idCliente,
    required this.isInactivo,
    required this.clienteController,
    required this.onClienteDesasociado,
  });

  @override
  State<ClienteAsociadoInfo> createState() => _ClienteAsociadoInfoState();
}

class _ClienteAsociadoInfoState extends State<ClienteAsociadoInfo> {
  bool _isLoading = false;

  // Añadir propiedad para almacenar el Future del cliente
  late Future<Cliente?> _clienteFuture;

  @override
  void initState() {
    super.initState();
    // Inicializar el Future cuando se crea el widget
    _cargarCliente();
  }

  // Método para cargar o recargar el cliente
  void _cargarCliente() {
    _clienteFuture = _getClienteById(widget.idCliente);
  }

  @override
  Widget build(BuildContext context) {
    // Usar _clienteFuture en lugar de crear un nuevo Future cada vez
    return FutureBuilder<Cliente?>(
      future: _clienteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'Error al cargar cliente: ${snapshot.error}',
              style: TextStyle(color: Colors.red.shade700),
            ),
          );
        }

        final cliente = snapshot.data;
        if (cliente == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text('Cliente no encontrado'),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                              onPressed:
                                  () => _desasociarCliente(widget.idInmueble),
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
          ),
        );
      },
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

  Future<Cliente?> _getClienteById(int id) async {
    try {
      // Primero intentamos encontrar el cliente entre los activos
      final clientes = await widget.clienteController.getClientes();
      return clientes.firstWhere((c) => c.id == id);
    } catch (e) {
      // Si no se encuentra entre los activos, buscamos entre los inactivos
      try {
        final clientesInactivos =
            await widget.clienteController.getClientesInactivos();
        return clientesInactivos.firstWhere((c) => c.id == id);
      } catch (_) {
        // Si no se encuentra en ninguna lista, retornamos null
        return null;
      }
    }
  }

  void _verDetallesCliente(Cliente cliente) {
    // Navegar a la pantalla de detalles del cliente
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VistaClientes(
              controller: widget.clienteController,
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
      // Desasociar el cliente del inmueble
      await widget.clienteController.desasignarInmuebleDeCliente(idInmueble);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente desasociado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Notificar al padre para que actualice la UI
      widget.onClienteDesasociado();

      // Ya no es necesario actualizar _clienteFuture aquí porque el padre
      // (InmuebleDetailScreen) se encargará de reconstruir este widget
      // con nuevos datos cuando se llame onClienteDesasociado()
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

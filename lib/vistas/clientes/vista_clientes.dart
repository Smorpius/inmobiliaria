import 'cliente_form_add.dart';
import 'cliente_list_view.dart';
import 'cliente_form_edit.dart';
import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';
import '../../controllers/cliente_controller.dart';

class VistaClientes extends StatefulWidget {
  const VistaClientes({super.key});

  @override
  State<VistaClientes> createState() => _VistaClientesState();
}

class _VistaClientesState extends State<VistaClientes> {
  final ClienteController _controller = ClienteController();
  List<Cliente> _clientesActivos = [];
  List<Cliente> _clientesInactivos = [];
  Cliente? _selectedCliente;
  bool _isLoading = true;
  bool _mostrandoInactivos = false;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activos = await _controller.getClientes();
      final inactivos = await _controller.getClientesInactivos();

      if (mounted) {
        setState(() {
          _clientesActivos = activos;
          _clientesInactivos = inactivos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _agregarCliente() {
    showDialog(
      context: context,
      builder:
          (context) => ClienteFormAdd(
            onClienteAdded: _cargarClientes,
            controller: _controller,
          ),
    );
  }

  void _editarCliente(Cliente cliente) {
    showDialog(
      context: context,
      builder:
          (context) => ClienteFormEdit(
            cliente: cliente,
            onClienteUpdated: _cargarClientes,
            controller: _controller,
          ),
    );
  }

  Future<void> _toggleEstadoCliente(Cliente cliente) async {
    final messenger = ScaffoldMessenger.of(context);
    final bool estaInactivo = _mostrandoInactivos;

    try {
      if (estaInactivo) {
        await _controller.reactivarCliente(cliente.id!);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Cliente reactivado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _controller.inactivarCliente(cliente.id!);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Cliente inactivado correctamente'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Deseleccionar cliente actual
      setState(() {
        _selectedCliente = null;
      });

      // Recargar los datos
      await _cargarClientes();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado del cliente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleMostrarInactivos() {
    setState(() {
      _mostrandoInactivos = !_mostrandoInactivos;
      _selectedCliente = null; // Reset de la selección
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientes =
        _mostrandoInactivos ? _clientesInactivos : _clientesActivos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
        actions: [
          // Botón para alternar entre activos e inactivos
          IconButton(
            onPressed: _toggleMostrarInactivos,
            icon: Icon(
              _mostrandoInactivos ? Icons.person : Icons.person_off,
              color: _mostrandoInactivos ? Colors.red : null,
            ),
            tooltip:
                _mostrandoInactivos
                    ? 'Ver clientes activos'
                    : 'Ver clientes inactivos',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                children: [
                  // Panel izquierdo con lista de clientes
                  Expanded(
                    flex: 3,
                    child: ClienteListView(
                      clientes: clientes,
                      selectedCliente: _selectedCliente,
                      onClienteSelected: (cliente) {
                        setState(() {
                          _selectedCliente = cliente;
                        });
                      },
                      onRefresh: _cargarClientes,
                      onEdit: _editarCliente,
                      onDelete: _toggleEstadoCliente,
                      mostrandoInactivos: _mostrandoInactivos,
                    ),
                  ),
                  // Panel derecho con detalles del cliente seleccionado
                  Expanded(
                    flex: 5,
                    child:
                        _selectedCliente == null
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_search,
                                    size: 80,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Seleccione un cliente para ver sus detalles',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClienteDetailView(
                                cliente: _selectedCliente!,
                                onEdit: () => _editarCliente(_selectedCliente!),
                                onDelete:
                                    () =>
                                        _toggleEstadoCliente(_selectedCliente!),
                                isInactivo: _mostrandoInactivos,
                              ),
                            ),
                  ),
                ],
              ),
      floatingActionButton:
          !_mostrandoInactivos
              ? FloatingActionButton(
                onPressed: _agregarCliente,
                tooltip: 'Agregar Cliente',
                child: const Icon(Icons.person_add),
              )
              : null,
    );
  }
}

// Separamos la clase ClienteDetailView para que pueda ser reutilizada
class ClienteDetailView extends StatelessWidget {
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

  // Formatea tipos de cliente para mostrar con primera letra mayúscula
  String _formatTipoCliente(String tipo) {
    switch (tipo) {
      case 'comprador':
        return 'Comprador';
      case 'arrendatario':
        return 'Arrendatario';
      case 'ambos':
        return 'Comprador y Arrendatario';
      default:
        return tipo[0].toUpperCase() + tipo.substring(1);
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isInactivo ? Colors.grey : Colors.teal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isInactivo ? Colors.grey.shade600 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        isInactivo
                            ? Colors.grey.shade300
                            : Colors.teal.shade100,
                    child: Text(
                      cliente.nombre.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isInactivo ? Colors.grey : Colors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    cliente.nombreCompleto,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      decoration:
                          isInactivo ? TextDecoration.lineThrough : null,
                      color: isInactivo ? Colors.grey.shade700 : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isInactivo)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'INACTIVO',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 40),

            // Información básica del cliente
            _buildDetailRow('Nombre', cliente.nombre, Icons.person),
            _buildDetailRow(
              'Apellido Paterno',
              cliente.apellidoPaterno,
              Icons.person,
            ),
            if (cliente.apellidoMaterno != null &&
                cliente.apellidoMaterno!.isNotEmpty)
              _buildDetailRow(
                'Apellido Materno',
                cliente.apellidoMaterno!,
                Icons.person,
              ),
            _buildDetailRow(
              'Tipo de Cliente',
              _formatTipoCliente(cliente.tipoCliente),
              Icons.category,
            ),
            _buildDetailRow('Teléfono', cliente.telefono, Icons.phone),
            _buildDetailRow('RFC', cliente.rfc, Icons.assignment_ind),
            _buildDetailRow('CURP', cliente.curp, Icons.badge),
            _buildDetailRow(
              'Correo',
              cliente.correo ?? 'No proporcionado',
              Icons.email,
            ),

            // Dirección completa
            _buildDetailRow(
              'Dirección',
              cliente.direccionCompleta,
              Icons.location_on,
            ),

            // Fecha de registro
            if (cliente.fechaRegistro != null)
              _buildDetailRow(
                'Fecha de registro',
                cliente.fechaRegistro.toString().split(' ')[0],
                Icons.calendar_today,
              ),

            // Lista de inmuebles asociados si están disponibles
            if (cliente.id != null)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: ClienteController().getInmueblesPorCliente(cliente.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 40),
                        Text(
                          'Inmuebles asociados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final inmueble = snapshot.data![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.home),
                                title: Text(inmueble['nombre'] ?? 'Sin nombre'),
                                subtitle: Text(
                                  '${inmueble['tipo_inmueble'] ?? 'N/A'} - ${inmueble['tipo_operacion'] ?? 'N/A'}',
                                ),
                                trailing: Text(
                                  inmueble['monto_total'] != null
                                      ? '\$${inmueble['monto_total']}'
                                      : 'Precio no especificado',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isInactivo)
                  ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (!isInactivo) const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: Icon(isInactivo ? Icons.person_add : Icons.delete),
                  label: Text(isInactivo ? 'Reactivar' : 'Inactivar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInactivo ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

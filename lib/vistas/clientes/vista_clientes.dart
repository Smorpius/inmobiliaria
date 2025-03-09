import 'cliente_list_view.dart';
import 'cliente_detail_view.dart';
import 'cliente_form_add.dart' as add;
import 'package:flutter/material.dart';
import 'cliente_form_edit.dart' as edit;
import '../../models/cliente_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../controllers/cliente_controller.dart';

class VistaClientes extends StatefulWidget {
  const VistaClientes({super.key});

  @override
  State<VistaClientes> createState() => _VistaClientesState();
}

class _VistaClientesState extends State<VistaClientes> {
  final ClienteController _clienteController = ClienteController();
  List<Cliente> _clientes = [];
  Cliente? _selectedCliente;
  bool _isLoading = false;
  // Estado para controlar si mostrar activos o inactivos
  bool _mostrarInactivos = false;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    setState(() => _isLoading = true);
    try {
      // Cargar clientes según el filtro seleccionado
      final clientes =
          _mostrarInactivos
              ? await _clienteController.getClientesInactivos()
              : await _clienteController.getClientes();

      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        // Limpiar la selección al cambiar la lista
        _selectedCliente = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar clientes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder:
          (context) => add.ClienteFormAdd(
            onClienteAdded: _loadClientes,
            controller: _clienteController,
          ),
    );
  }

  void _showEditClientDialog(Cliente cliente) {
    showDialog(
      context: context,
      builder:
          (context) => edit.ClienteFormEdit(
            cliente: cliente,
            onClienteUpdated: () {
              _loadClientes();
              if (_selectedCliente?.id == cliente.id) {
                setState(() => _selectedCliente = cliente);
              }
            },
            controller: _clienteController,
          ),
    );
  }

  void _confirmDeleteCliente(Cliente cliente) {
    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Confirmar Inactivación'),
            content: Text(
              '¿Está seguro que desea inactivar al cliente ${cliente.nombreCompleto}?',
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  try {
                    await _clienteController.inactivarCliente(cliente.id!);
                    if (!mounted) return;

                    _loadClientes();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cliente inactivado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al inactivar cliente: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text('Inactivar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  // Método para reactivar cliente
  void _confirmReactivateCliente(Cliente cliente) {
    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Confirmar Reactivación'),
            content: Text(
              '¿Está seguro que desea reactivar al cliente ${cliente.nombreCompleto}?',
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  try {
                    await _clienteController.reactivarCliente(cliente.id!);
                    if (!mounted) return;

                    _loadClientes();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cliente reactivado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al reactivar cliente: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Reactivar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Gestión de Clientes',
      currentRoute: '/clientes',
      actions: [
        // Selector de estado (activos/inactivos)
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              label: Text('Activos'),
              icon: Icon(Icons.check_circle),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text('Inactivos'),
              icon: Icon(Icons.cancel),
            ),
          ],
          selected: {_mostrarInactivos},
          onSelectionChanged: (Set<bool> newSelection) {
            setState(() {
              _mostrarInactivos = newSelection.first;
              _loadClientes();
            });
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadClientes,
          tooltip: 'Actualizar lista',
        ),
      ],
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ClienteListView(
                          clientes: _clientes,
                          selectedCliente: _selectedCliente,
                          onClienteSelected: (cliente) {
                            setState(() => _selectedCliente = cliente);
                          },
                          onRefresh: _loadClientes,
                          onEdit: _showEditClientDialog,
                          // Usar la acción correcta según estado
                          onDelete:
                              _mostrarInactivos
                                  ? _confirmReactivateCliente
                                  : _confirmDeleteCliente,
                          mostrandoInactivos:
                              _mostrarInactivos, // Pasar el estado
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child:
                            _selectedCliente == null
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_search,
                                        size: 100,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Seleccione un cliente para ver detalles',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ClienteDetailView(
                                  cliente: _selectedCliente!,
                                  onEdit:
                                      () => _showEditClientDialog(
                                        _selectedCliente!,
                                      ),
                                  onDelete:
                                      _mostrarInactivos
                                          ? () => _confirmReactivateCliente(
                                            _selectedCliente!,
                                          )
                                          : () => _confirmDeleteCliente(
                                            _selectedCliente!,
                                          ),
                                  isInactivo:
                                      _mostrarInactivos, // Pasar el estado de inactividad
                                ),
                      ),
                    ],
                  ),
                  // Mostrar botón de agregar solo cuando estamos viendo los activos
                  if (!_mostrarInactivos)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton.extended(
                        onPressed: _showAddClientDialog,
                        tooltip: 'Agregar nuevo cliente',
                        icon: const Icon(Icons.person_add),
                        label: const Text('Nuevo cliente'),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
    );
  }
}

import '../models/cliente_model.dart';
import 'package:flutter/material.dart';
import '../controllers/cliente_controller.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  ClientesScreenState createState() => ClientesScreenState();
}

class ClientesScreenState extends State<ClientesScreen> {
  final ClienteController _clienteController = ClienteController();
  List<Cliente> _clientes = [];
  List<Cliente> _filteredClientes = [];
  final TextEditingController _searchController = TextEditingController();
  Cliente? _selectedCliente;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    try {
      final clientes = await _clienteController.getClientes();
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _filteredClientes = clientes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar clientes: $e')));
    }
  }

  void _filterClientes(String query) {
    setState(() {
      _filteredClientes =
          _clientes
              .where(
                (cliente) =>
                    cliente.nombre.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    cliente.telefono.contains(query) ||
                    cliente.rfc.contains(query),
              )
              .toList();
    });
  }

  void _showAddClientDialog() {
    final nombreController = TextEditingController();
    final telefonoController = TextEditingController();
    final rfcController = TextEditingController();
    final curpController = TextEditingController();
    final correoController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Agregar Cliente'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: telefonoController,
                    decoration: InputDecoration(labelText: 'Teléfono'),
                  ),
                  TextField(
                    controller: rfcController,
                    decoration: InputDecoration(labelText: 'RFC'),
                  ),
                  TextField(
                    controller: curpController,
                    decoration: InputDecoration(labelText: 'CURP'),
                  ),
                  TextField(
                    controller: correoController,
                    decoration: InputDecoration(labelText: 'Correo'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  if (nombreController.text.isEmpty ||
                      telefonoController.text.isEmpty ||
                      rfcController.text.isEmpty ||
                      curpController.text.isEmpty) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Por favor, llene todos los campos obligatorios',
                        ),
                      ),
                    );
                    return;
                  }

                  final nuevoCliente = Cliente(
                    nombre: nombreController.text,
                    telefono: telefonoController.text,
                    rfc: rfcController.text,
                    curp: curpController.text,
                    correo:
                        correoController.text.isNotEmpty
                            ? correoController.text
                            : null,
                  );

                  try {
                    await _clienteController.insertCliente(nuevoCliente);
                    if (!mounted) return;
                    await _loadClientes();
                    if (!mounted) return;
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('Cliente agregado exitosamente')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error al agregar cliente: $e')),
                    );
                  }
                },
                child: Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _showEditClientDialog(Cliente cliente) {
    final nombreController = TextEditingController(text: cliente.nombre);
    final telefonoController = TextEditingController(text: cliente.telefono);
    final rfcController = TextEditingController(text: cliente.rfc);
    final curpController = TextEditingController(text: cliente.curp);
    final correoController = TextEditingController(text: cliente.correo ?? '');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Editar Cliente'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: telefonoController,
                    decoration: InputDecoration(labelText: 'Teléfono'),
                  ),
                  TextField(
                    controller: rfcController,
                    decoration: InputDecoration(labelText: 'RFC'),
                  ),
                  TextField(
                    controller: curpController,
                    decoration: InputDecoration(labelText: 'CURP'),
                  ),
                  TextField(
                    controller: correoController,
                    decoration: InputDecoration(labelText: 'Correo'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  if (nombreController.text.isEmpty ||
                      telefonoController.text.isEmpty ||
                      rfcController.text.isEmpty ||
                      curpController.text.isEmpty) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Por favor, llene todos los campos obligatorios',
                        ),
                      ),
                    );
                    return;
                  }

                  final clienteActualizado = Cliente(
                    id: cliente.id,
                    nombre: nombreController.text,
                    telefono: telefonoController.text,
                    rfc: rfcController.text,
                    curp: curpController.text,
                    correo:
                        correoController.text.isNotEmpty
                            ? correoController.text
                            : null,
                  );

                  try {
                    await _clienteController.updateCliente(clienteActualizado);
                    if (!mounted) return;
                    await _loadClientes();
                    if (!mounted) return;
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Cliente actualizado exitosamente'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar cliente: $e'),
                      ),
                    );
                  }
                },
                child: Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _confirmDeleteCliente(Cliente cliente) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirmar Eliminación'),
            content: Text(
              '¿Está seguro que desea inactivar al cliente ${cliente.nombre}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    await _clienteController.inactivarCliente(cliente.id!);
                    if (!mounted) return;
                    await _loadClientes();
                    if (!mounted) return;
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Cliente inactivado exitosamente'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error al inactivar cliente: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Inactivar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clientes')),
      body: Row(
        children: [
          // Lista de Clientes
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: _filterClientes,
                  ),
                ),
                Expanded(
                  child:
                      _filteredClientes.isEmpty
                          ? Center(child: Text('No se encontraron clientes'))
                          : ListView.builder(
                            itemCount: _filteredClientes.length,
                            itemBuilder: (context, index) {
                              final cliente = _filteredClientes[index];
                              return ListTile(
                                title: Text(cliente.nombre),
                                subtitle: Text(cliente.telefono),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed:
                                          () => _showEditClientDialog(cliente),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _confirmDeleteCliente(cliente),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedCliente = cliente;
                                  });
                                },
                              );
                            },
                          ),
                ),
              ],
            ),
          ),

          // Detalles del Cliente
          Expanded(
            flex: 3,
            child:
                _selectedCliente == null
                    ? Center(
                      child: Text(
                        'Seleccione un cliente para ver los detalles',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Detalles del Cliente',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              SizedBox(height: 16),
                              _buildDetailRow(
                                'Nombre',
                                _selectedCliente!.nombre,
                              ),
                              _buildDetailRow(
                                'Teléfono',
                                _selectedCliente!.telefono,
                              ),
                              _buildDetailRow('RFC', _selectedCliente!.rfc),
                              _buildDetailRow('CURP', _selectedCliente!.curp),
                              _buildDetailRow(
                                'Correo',
                                _selectedCliente!.correo ?? 'No disponible',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClientDialog,
        tooltip: 'Agregar nuevo cliente',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

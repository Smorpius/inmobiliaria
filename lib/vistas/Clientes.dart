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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    setState(() => _isLoading = true);
    try {
      final clientes = await _clienteController.getClientes();
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _filteredClientes = clientes;
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
                    cliente.rfc.toLowerCase().contains(query.toLowerCase()),
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
            title: const Text('Agregar Cliente'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: telefonoController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rfcController,
                    decoration: const InputDecoration(
                      labelText: 'RFC',
                      prefixIcon: Icon(Icons.assignment_ind),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: curpController,
                    decoration: const InputDecoration(
                      labelText: 'CURP',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: correoController,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  if (nombreController.text.isEmpty ||
                      telefonoController.text.isEmpty ||
                      rfcController.text.isEmpty ||
                      curpController.text.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, llene todos los campos obligatorios',
                        ),
                        backgroundColor: Colors.orange,
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
                    navigator.pop();
                    await _loadClientes();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Cliente agregado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error al agregar cliente: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
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
            title: const Text('Editar Cliente'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: telefonoController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rfcController,
                    decoration: const InputDecoration(
                      labelText: 'RFC',
                      prefixIcon: Icon(Icons.assignment_ind),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: curpController,
                    decoration: const InputDecoration(
                      labelText: 'CURP',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: correoController,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  if (nombreController.text.isEmpty ||
                      telefonoController.text.isEmpty ||
                      rfcController.text.isEmpty ||
                      curpController.text.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, llene todos los campos obligatorios',
                        ),
                        backgroundColor: Colors.orange,
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
                    idDireccion: cliente.idDireccion,
                    idEstado: cliente.idEstado,
                    fechaRegistro: cliente.fechaRegistro,
                  );

                  try {
                    await _clienteController.updateCliente(clienteActualizado);
                    navigator.pop();
                    await _loadClientes();
                    // Actualizar la selección si el cliente actual está seleccionado
                    if (_selectedCliente?.id == cliente.id) {
                      setState(() {
                        _selectedCliente = clienteActualizado;
                      });
                    }
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Cliente actualizado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar cliente: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
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
            title: const Text('Confirmar Inactivación'),
            content: Text(
              '¿Está seguro que desea inactivar al cliente ${cliente.nombre}?',
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  if (cliente.id == null) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Cliente inválido'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    await _clienteController.inactivarCliente(cliente.id!);
                    navigator.pop();

                    // Si el cliente inactivado era el seleccionado, lo deseleccionamos
                    if (_selectedCliente?.id == cliente.id) {
                      setState(() {
                        _selectedCliente = null;
                      });
                    }

                    await _loadClientes();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Cliente inactivado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClientes,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Buscar Cliente',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterClientes('');
                                },
                              ),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                            ),
                            onChanged: _filterClientes,
                          ),
                        ),
                        Expanded(
                          child:
                              _filteredClientes.isEmpty
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_search,
                                          size: 50,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No se encontraron clientes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : ListView.separated(
                                    itemCount: _filteredClientes.length,
                                    separatorBuilder:
                                        (context, index) =>
                                            const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final cliente = _filteredClientes[index];
                                      final isSelected =
                                          _selectedCliente?.id == cliente.id;

                                      return Card(
                                        elevation: isSelected ? 4 : 1,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 8,
                                        ),
                                        color:
                                            isSelected
                                                ? Colors.blue.shade50
                                                : null,
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            child: Text(
                                              cliente.nombre
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                            ),
                                          ),
                                          title: Text(
                                            cliente.nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Tel: ${cliente.telefono}\nRFC: ${cliente.rfc}',
                                          ),
                                          isThreeLine: true,
                                          onTap: () {
                                            setState(() {
                                              _selectedCliente = cliente;
                                            });
                                          },
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                tooltip: 'Editar cliente',
                                                onPressed:
                                                    () => _showEditClientDialog(
                                                      cliente,
                                                    ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Inactivar cliente',
                                                onPressed:
                                                    () => _confirmDeleteCliente(
                                                      cliente,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    flex: 3,
                    child:
                        _selectedCliente == null
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Seleccione un cliente para ver detalles',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Card(
                              margin: const EdgeInsets.all(16.0),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                                Colors.blue.shade100,
                                            child: Text(
                                              _selectedCliente!.nombre
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _selectedCliente!.nombre,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 40),
                                    _buildDetailRow(
                                      'Teléfono',
                                      _selectedCliente!.telefono,
                                      Icons.phone,
                                    ),
                                    _buildDetailRow(
                                      'RFC',
                                      _selectedCliente!.rfc,
                                      Icons.assignment_ind,
                                    ),
                                    _buildDetailRow(
                                      'CURP',
                                      _selectedCliente!.curp,
                                      Icons.badge,
                                    ),
                                    _buildDetailRow(
                                      'Correo',
                                      _selectedCliente!.correo ??
                                          'No proporcionado',
                                      Icons.email,
                                    ),
                                    if (_selectedCliente!.fechaRegistro != null)
                                      _buildDetailRow(
                                        'Fecha de registro',
                                        _selectedCliente!.fechaRegistro
                                            .toString()
                                            .split(' ')[0],
                                        Icons.calendar_today,
                                      ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed:
                                              () => _showEditClientDialog(
                                                _selectedCliente!,
                                              ),
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Editar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed:
                                              () => _confirmDeleteCliente(
                                                _selectedCliente!,
                                              ),
                                          icon: const Icon(Icons.delete),
                                          label: const Text('Inactivar'),
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
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClientDialog,
        tooltip: 'Agregar nuevo cliente',
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo cliente'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 12),
          Column(
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
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

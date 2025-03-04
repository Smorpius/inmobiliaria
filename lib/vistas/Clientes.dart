import '../models/cliente_model.dart';
import 'package:flutter/material.dart';
import '../controllers/cliente_controller.dart';

class ClientesScreen extends StatefulWidget {
  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ClienteController _clienteController = ClienteController();
  List<Cliente> _clientes = [];
  TextEditingController _searchController = TextEditingController();
  Cliente? _selectedCliente;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    final clientes = await _clienteController.getClientes();
    setState(() {
      _clientes = clientes;
    });
  }

  void _searchClientes(String query) async {
    final clientes = await _clienteController.searchClientesByName(query);
    setState(() {
      _clientes = clientes;
    });
  }

  void _selectCliente(Cliente cliente) {
    setState(() {
      _selectedCliente = cliente;
    });
  }

  void _showAddClientDialog() {
    final _nombreController = TextEditingController();
    final _telefonoController = TextEditingController();
    final _rfcController = TextEditingController();
    final _curpController = TextEditingController();
    final _correoController = TextEditingController();

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
                    controller: _nombreController,
                    decoration: InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: _telefonoController,
                    decoration: InputDecoration(labelText: 'Teléfono'),
                  ),
                  TextField(
                    controller: _rfcController,
                    decoration: InputDecoration(labelText: 'RFC'),
                  ),
                  TextField(
                    controller: _curpController,
                    decoration: InputDecoration(labelText: 'CURP'),
                  ),
                  TextField(
                    controller: _correoController,
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
                  final nuevoCliente = Cliente(
                    nombre: _nombreController.text,
                    telefono: _telefonoController.text,
                    rfc: _rfcController.text,
                    curp: _curpController.text,
                    correo: _correoController.text,
                  );

                  await _clienteController.insertCliente(nuevoCliente);
                  _loadClientes();
                  Navigator.pop(context);
                },
                child: Text('Guardar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clientes'),
        actions: [IconButton(icon: Icon(Icons.more_vert), onPressed: () {})],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: _searchClientes,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _clientes.length,
                    itemBuilder: (context, index) {
                      final cliente = _clientes[index];
                      return ListTile(
                        title: Text(cliente.nombre),
                        subtitle: Text(cliente.telefono),
                        onTap: () => _selectCliente(cliente),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child:
                  _selectedCliente == null
                      ? Text(
                        'Detalles del cliente',
                        style: TextStyle(fontSize: 18),
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Nombre: ${_selectedCliente!.nombre}',
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            'Teléfono: ${_selectedCliente!.telefono}',
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            'RFC: ${_selectedCliente!.rfc}',
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            'CURP: ${_selectedCliente!.curp}',
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            'Correo: ${_selectedCliente!.correo ?? 'No disponible'}',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClientDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}

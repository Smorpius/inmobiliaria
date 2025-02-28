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
                            'Dirección: ${_selectedCliente!.direccion}',
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
                        ],
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción para agregar un nuevo cliente
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

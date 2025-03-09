import 'cliente_card.dart';
import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';

class ClienteListView extends StatefulWidget {
  final List<Cliente> clientes;
  final Cliente? selectedCliente;
  final Function(Cliente) onClienteSelected;
  final Future<void> Function() onRefresh;
  final Function(Cliente) onEdit;
  final Function(Cliente) onDelete;
  // Nueva propiedad para indicar si se muestran inactivos
  final bool mostrandoInactivos;

  const ClienteListView({
    super.key,
    required this.clientes,
    required this.selectedCliente,
    required this.onClienteSelected,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    this.mostrandoInactivos = false,
  });

  @override
  State<ClienteListView> createState() => _ClienteListViewState();
}

class _ClienteListViewState extends State<ClienteListView> {
  final TextEditingController _searchController = TextEditingController();
  List<Cliente> _filteredClientes = [];

  @override
  void initState() {
    super.initState();
    _filteredClientes = widget.clientes;
  }

  @override
  void didUpdateWidget(ClienteListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientes != widget.clientes) {
      _filterClientes(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterClientes(String query) {
    setState(() {
      _filteredClientes =
          widget.clientes
              .where(
                (cliente) =>
                    cliente.nombreCompleto.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    cliente.telefono.contains(query) ||
                    cliente.rfc.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Título que muestra si estamos viendo clientes activos o inactivos
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          color:
              widget.mostrandoInactivos
                  ? Colors.red.shade50
                  : Colors.teal.shade50,
          child: Center(
            child: Text(
              widget.mostrandoInactivos
                  ? 'Clientes Inactivos'
                  : 'Clientes Activos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color:
                    widget.mostrandoInactivos
                        ? Colors.red.shade700
                        : Colors.teal.shade700,
              ),
            ),
          ),
        ),
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
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child:
                _filteredClientes.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.mostrandoInactivos
                                ? 'No se encontraron clientes inactivos'
                                : 'No se encontraron clientes',
                            style: const TextStyle(
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
                          (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cliente = _filteredClientes[index];
                        return ClienteCard(
                          cliente: cliente,
                          isSelected: widget.selectedCliente?.id == cliente.id,
                          onTap: () => widget.onClienteSelected(cliente),
                          onEdit: () => widget.onEdit(cliente),
                          onDelete: () => widget.onDelete(cliente),
                          isInactivo: widget.mostrandoInactivos,
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }
}

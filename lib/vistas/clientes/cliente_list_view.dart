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

  final TextEditingController _searchController = TextEditingController();
  List<Cliente> _filteredClientes = [];

  @override
  void initState() {
    super.initState();
    // Initialize _filteredClientes by applying the initial (empty) filter.
    _filterClientes(_searchController.text);
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
          color: colorPrimario, // Cambiado a color rojo sólido
          child: Center(
            child: Text(
              widget.mostrandoInactivos
                  ? 'Clientes Inactivos'
                  : 'Clientes Activos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorClaro, // Texto en color claro para contraste
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
              labelStyle: TextStyle(color: colorOscuro),
              prefixIcon: Icon(Icons.search, color: colorPrimario),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear, color: colorOscuro),
                onPressed: () {
                  _searchController.clear();
                  _filterClientes('');
                },
              ),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorGrisClaro),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorPrimario),
              ),
              filled: true,
              fillColor: colorClaro,
            ),
            onChanged: _filterClientes,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: colorPrimario,
            backgroundColor: colorClaro,
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
                            color: colorGrisClaro,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.mostrandoInactivos
                                ? 'No se encontraron clientes inactivos'
                                : 'No se encontraron clientes',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorOscuro.withAlpha((255 * 0.6).round()),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.separated(
                      itemCount: _filteredClientes.length,
                      separatorBuilder:
                          (context, index) => Divider(
                            height: 1,
                            color: colorGrisClaro.withAlpha(
                              (255 * 0.5).round(),
                            ),
                          ),
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

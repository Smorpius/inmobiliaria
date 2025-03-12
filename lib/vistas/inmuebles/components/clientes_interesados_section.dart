import 'package:flutter/material.dart';
import '../../../models/cliente_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controllers/cliente_controller.dart';
import '../../../vistas/clientes/vista_clientes.dart';
import '../../../controllers/inmueble_controller.dart';

class ClientesInteresadosSection extends StatefulWidget {
  final int idInmueble;
  final bool isInactivo;

  const ClientesInteresadosSection({
    super.key,
    required this.idInmueble,
    required this.isInactivo,
  });

  @override
  State<ClientesInteresadosSection> createState() =>
      _ClientesInteresadosSectionState();
}

class _ClientesInteresadosSectionState
    extends State<ClientesInteresadosSection> {
  final InmuebleController _inmuebleController = InmuebleController();
  final ClienteController _clienteController = ClienteController();

  // Añadir Future como propiedad de clase
  late Future<List<Map<String, dynamic>>> _clientesInteresadosFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Inicializar el Future cuando se crea el widget
    _cargarClientesInteresados();
  }

  // Método para cargar clientes interesados
  void _cargarClientesInteresados() {
    _clientesInteresadosFuture = _inmuebleController.getClientesInteresados(
      widget.idInmueble,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Clientes interesados',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        if (!widget.isInactivo)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Buscar cliente...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                      () => _mostrarDialogoAgregarClienteInteresado(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

        // FutureBuilder modificado para usar la propiedad de clase
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _clientesInteresadosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error al cargar clientes interesados: ${snapshot.error}',
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              );
            }

            final clientes = snapshot.data;
            if (clientes == null || clientes.isEmpty) {
              return _buildEmptyClientesMessage();
            }

            var clientesFiltrados = clientes;
            if (_searchQuery.isNotEmpty) {
              clientesFiltrados =
                  clientes.where((cliente) {
                    final nombreCompleto =
                        '${cliente['nombre']} ${cliente['apellido_paterno']} ${cliente['apellido_materno'] ?? ''}'
                            .toLowerCase();
                    final telefono =
                        (cliente['telefono_cliente'] ?? '').toLowerCase();
                    final correo =
                        (cliente['correo_cliente'] ?? '').toLowerCase();

                    return nombreCompleto.contains(_searchQuery) ||
                        telefono.contains(_searchQuery) ||
                        correo.contains(_searchQuery);
                  }).toList();
            }

            return _buildClientesList(clientesFiltrados);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyClientesMessage() {
    return Card(
      color: Colors.grey.shade100,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No hay clientes interesados registrados',
              style: TextStyle(fontSize: 16),
            ),
            if (!widget.isInactivo)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed:
                      () => _mostrarDialogoAgregarClienteInteresado(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Agregar cliente interesado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientesList(List<Map<String, dynamic>> clientes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
          child: Text(
            'Mostrando ${clientes.length} cliente${clientes.length != 1 ? "s" : ""}',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: clientes.length,
          itemBuilder: (context, index) {
            final cliente = clientes[index];
            final nombreCompleto =
                '${cliente['nombre']} ${cliente['apellido_paterno']} ${cliente['apellido_materno'] ?? ''}';
            final fechaInteres =
                cliente['fecha_interes'] != null
                    ? cliente['fecha_interes'].toString().split(' ')[0]
                    : 'Fecha no disponible';
            final telefono = cliente['telefono_cliente'];
            final correo = cliente['correo_cliente'];
            final idCliente = cliente['id_cliente'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: InkWell(
                onTap: () => _mostrarDetallesCliente(cliente),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.amber.shade200,
                            child: const Icon(
                              Icons.person,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombreCompleto.trim(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Desde: $fechaInteres',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.person_search),
                            tooltip: 'Ver perfil completo',
                            color: Colors.teal,
                            onPressed:
                                () => _verDetallesClienteInteresado(idCliente),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (telefono != null && telefono.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 8),
                              Text(telefono),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.call, size: 20),
                                color: Colors.teal,
                                onPressed:
                                    () => _llamarCliente(telefono.toString()),
                                tooltip: 'Llamar',
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              IconButton(
                                icon: const Icon(Icons.message, size: 20),
                                color: Colors.blue,
                                onPressed:
                                    () => _enviarMensaje(telefono.toString()),
                                tooltip: 'Mensaje SMS',
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),

                      if (correo != null && correo.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.email,
                                size: 16,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  correo.toString(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.email_outlined,
                                  size: 20,
                                ),
                                color: Colors.orange,
                                onPressed:
                                    () => _enviarEmail(correo.toString()),
                                tooltip: 'Enviar correo',
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),

                      if (cliente['comentarios'] != null &&
                          cliente['comentarios'].toString().isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.comment,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Comentarios:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(cliente['comentarios'].toString()),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _verDetallesClienteInteresado(int idCliente) async {
    try {
      Cliente? cliente;
      final clientes = await _clienteController.getClientes();

      try {
        cliente = clientes.firstWhere((c) => c.id == idCliente);
      } catch (_) {
        final inactivos = await _clienteController.getClientesInactivos();
        try {
          cliente = inactivos.firstWhere((c) => c.id == idCliente);
        } catch (_) {
          throw Exception('Cliente no encontrado');
        }
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => VistaClientes(
                controller: _clienteController,
                clienteInicial: cliente,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar detalles del cliente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _llamarCliente(String telefono) async {
    final uri = Uri.parse('tel:$telefono');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede realizar la llamada a $telefono'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _enviarMensaje(String telefono) async {
    final uri = Uri.parse('sms:$telefono');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede enviar mensaje a $telefono'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _enviarEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede enviar email a $email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDetallesCliente(Map<String, dynamic> cliente) {
    // El resto del código para mostrar detalles...
    // (Mantengo el código original ya que no requiere cambios)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          maxChildSize: 0.7,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Contenido del scrollview...
                  // (Código original)
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${cliente['nombre']} ${cliente['apellido_paterno']} ${cliente['apellido_materno'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  _buildDetailItem(
                    Icons.calendar_today,
                    'Interesado desde',
                    cliente['fecha_interes'] != null
                        ? cliente['fecha_interes'].toString().split(' ')[0]
                        : 'Fecha no disponible',
                  ),
                  const Divider(height: 20),

                  _buildDetailItem(
                    Icons.phone,
                    'Teléfono',
                    cliente['telefono_cliente'] ?? 'No disponible',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    Icons.email,
                    'Email',
                    cliente['correo_cliente'] ?? 'No disponible',
                  ),

                  if (cliente['telefono_cliente'] != null ||
                      cliente['correo_cliente'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (cliente['telefono_cliente'] != null)
                            _buildActionButton(
                              Icons.call,
                              'Llamar',
                              Colors.green,
                              () => _llamarCliente(cliente['telefono_cliente']),
                            ),
                          if (cliente['telefono_cliente'] != null)
                            _buildActionButton(
                              Icons.message,
                              'SMS',
                              Colors.blue,
                              () => _enviarMensaje(cliente['telefono_cliente']),
                            ),
                          if (cliente['correo_cliente'] != null)
                            _buildActionButton(
                              Icons.email,
                              'Email',
                              Colors.orange,
                              () => _enviarEmail(cliente['correo_cliente']),
                            ),
                          _buildActionButton(
                            Icons.person_search,
                            'Perfil',
                            Colors.teal,
                            () {
                              Navigator.pop(context);
                              _verDetallesClienteInteresado(
                                cliente['id_cliente'],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                  if (cliente['comentarios'] != null &&
                      cliente['comentarios'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comentarios:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            width: double.infinity,
                            child: Text(cliente['comentarios'].toString()),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  // Método modificado para agregar cliente interesado con recarga de datos
  void _mostrarDialogoAgregarClienteInteresado(BuildContext context) async {
    final clientes = await _clienteController.getClientes();

    if (!context.mounted) return;

    Cliente? clienteSeleccionado;
    final comentariosController = TextEditingController();
    String searchQuery = '';

    List<Cliente> filteredClientes = clientes;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Agregar Cliente Interesado'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) {
                        setStateDialog(() {
                          searchQuery = value.toLowerCase();
                          if (searchQuery.isEmpty) {
                            filteredClientes = clientes;
                          } else {
                            filteredClientes =
                                clientes.where((cliente) {
                                  return cliente.nombreCompleto
                                          .toLowerCase()
                                          .contains(searchQuery) ||
                                      cliente.telefono.toLowerCase().contains(
                                        searchQuery,
                                      ) ||
                                      (cliente.correo?.toLowerCase().contains(
                                            searchQuery,
                                          ) ??
                                          false);
                                }).toList();
                          }
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Buscar cliente',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          filteredClientes.isEmpty
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No se encontraron clientes',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredClientes.length,
                                itemBuilder: (context, index) {
                                  final cliente = filteredClientes[index];
                                  return RadioListTile<Cliente>(
                                    title: Text(cliente.nombreCompleto),
                                    subtitle: Text(
                                      '${cliente.telefono}${cliente.correo != null ? ' • ${cliente.correo}' : ''}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    value: cliente,
                                    groupValue: clienteSeleccionado,
                                    onChanged: (value) {
                                      setStateDialog(() {
                                        clienteSeleccionado = value;
                                      });
                                    },
                                  );
                                },
                              ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: comentariosController,
                      decoration: const InputDecoration(
                        labelText: 'Comentarios',
                        hintText: 'Detalles sobre el interés del cliente',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      clienteSeleccionado == null
                          ? null
                          : () async {
                            try {
                              // Registrar el cliente interesado
                              await _inmuebleController
                                  .registrarClienteInteresado(
                                    widget.idInmueble,
                                    clienteSeleccionado!.id!,
                                    comentariosController.text.isNotEmpty
                                        ? comentariosController.text
                                        : null,
                                  );

                              if (!context.mounted) return;

                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cliente interesado registrado correctamente',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // IMPORTANTE: Recargar los datos después de agregar
                              setState(() {
                                _cargarClientesInteresados();
                              });
                            } catch (e) {
                              if (!context.mounted) return;

                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al registrar cliente interesado: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

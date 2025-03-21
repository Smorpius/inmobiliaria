import 'package:flutter/material.dart';
import '../../../models/cliente_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/cliente_providers.dart';
import '../../../vistas/clientes/vista_clientes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/clientes_interesados_state.dart';

class ClientesInteresadosSection extends ConsumerWidget {
  final int idInmueble;
  final bool isInactivo;

  const ClientesInteresadosSection({
    super.key,
    required this.idInmueble,
    required this.isInactivo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientesInteresadosStateProvider(idInmueble));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Clientes interesados',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        if (!isInactivo)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      ref
                          .read(
                            clientesInteresadosStateProvider(
                              idInmueble,
                            ).notifier,
                          )
                          .actualizarBusqueda(value);
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
                      () =>
                          _mostrarDialogoAgregarClienteInteresado(context, ref),
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

        // Mostrar error si existe
        if (state.errorMessage != null)
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Error: ${state.errorMessage}',
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed:
                        () =>
                            ref
                                .read(
                                  clientesInteresadosStateProvider(
                                    idInmueble,
                                  ).notifier,
                                )
                                .cargarClientesInteresados(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),

        // Estado de carga
        if (state.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        // Sin clientes
        else if (state.clientes.isEmpty)
          _buildEmptyClientesMessage(context, ref)
        // Lista de clientes
        else
          _buildClientesList(context, ref, state.clientesFiltrados),
      ],
    );
  }

  // Widget para mostrar cuando no hay clientes interesados
  Widget _buildEmptyClientesMessage(BuildContext context, WidgetRef ref) {
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
            if (!isInactivo)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed:
                      () =>
                          _mostrarDialogoAgregarClienteInteresado(context, ref),
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

  // Widget para mostrar la lista de clientes interesados
  Widget _buildClientesList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> clientes,
  ) {
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
                onTap: () => _mostrarDetallesCliente(context, ref, cliente),
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
                                () => _verDetallesClienteInteresado(
                                  context,
                                  ref,
                                  idCliente,
                                ),
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
                                    () => _llamarCliente(
                                      context,
                                      telefono.toString(),
                                    ),
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
                                    () => _enviarMensaje(
                                      context,
                                      telefono.toString(),
                                    ),
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
                                    () => _enviarEmail(
                                      context,
                                      correo.toString(),
                                    ),
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

  // Métodos para interactuar con los clientes
  Future<void> _verDetallesClienteInteresado(
    BuildContext context,
    WidgetRef ref,
    int idCliente,
  ) async {
    try {
      // Indicar que está cargando
      final notifier = ref.read(
        clientesInteresadosStateProvider(idInmueble).notifier,
      );
      // Iniciar carga
      notifier.cargarClientesInteresados(); // Esto establecerá isLoading = true

      // Obtener controlador a través del provider
      final clienteController = ref.read(clienteControllerProvider);
      Cliente? cliente;

      // Buscar primero en clientes activos
      final clientes = await clienteController.getClientes();
      try {
        cliente = clientes.firstWhere((c) => c.id == idCliente);
      } catch (_) {
        // Si no se encuentra, buscar en inactivos
        final inactivos = await clienteController.getClientesInactivos();
        try {
          cliente = inactivos.firstWhere((c) => c.id == idCliente);
        } catch (_) {
          throw Exception('Cliente no encontrado');
        }
      }

      if (!context.mounted) return;

      // La carga terminó, recargar datos para actualizar el estado
      notifier.cargarClientesInteresados();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VistaClientes(clienteInicial: cliente),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Mostrar error
      final notifier = ref.read(
        clientesInteresadosStateProvider(idInmueble).notifier,
      );
      // Recargar para restablecer el estado y mostrar el error
      notifier.cargarClientesInteresados();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar detalles del cliente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _llamarCliente(BuildContext context, String telefono) async {
    final uri = Uri.parse('tel:$telefono');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede realizar la llamada a $telefono'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _enviarMensaje(BuildContext context, String telefono) async {
    final uri = Uri.parse('sms:$telefono');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede enviar mensaje a $telefono'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _enviarEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede enviar email a $email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDetallesCliente(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> cliente,
  ) {
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
                              () => _llamarCliente(
                                context,
                                cliente['telefono_cliente'],
                              ),
                            ),
                          if (cliente['telefono_cliente'] != null)
                            _buildActionButton(
                              Icons.message,
                              'SMS',
                              Colors.blue,
                              () => _enviarMensaje(
                                context,
                                cliente['telefono_cliente'],
                              ),
                            ),
                          if (cliente['correo_cliente'] != null)
                            _buildActionButton(
                              Icons.email,
                              'Email',
                              Colors.orange,
                              () => _enviarEmail(
                                context,
                                cliente['correo_cliente'],
                              ),
                            ),
                          _buildActionButton(
                            Icons.person_search,
                            'Perfil',
                            Colors.teal,
                            () {
                              Navigator.pop(context);
                              _verDetallesClienteInteresado(
                                context,
                                ref,
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

  // Método para mostrar el diálogo para agregar un cliente interesado
  void _mostrarDialogoAgregarClienteInteresado(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Obtener controlador y clientes a través del provider
    final clienteController = ref.read(clienteControllerProvider);
    final clientes = await clienteController.getClientes();

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
                              // Registrar al cliente interesado mediante el notifier
                              final success = await ref
                                  .read(
                                    clientesInteresadosStateProvider(
                                      idInmueble,
                                    ).notifier,
                                  )
                                  .registrarClienteInteresado(
                                    clienteSeleccionado!.id!,
                                    comentariosController.text.isNotEmpty
                                        ? comentariosController.text
                                        : null,
                                  );

                              if (!context.mounted) return;

                              Navigator.of(context).pop();

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cliente interesado registrado correctamente',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
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

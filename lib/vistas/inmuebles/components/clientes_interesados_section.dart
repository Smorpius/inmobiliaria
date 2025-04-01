import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/cliente_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/cliente_providers.dart';
import '../../../vistas/clientes/vista_clientes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/clientes_interesados_state.dart';

class ClientesInteresadosSection extends ConsumerWidget {
  final int idInmueble;
  final bool isInactivo;

  // Control de operaciones duplicadas
  static final Map<String, bool> _operacionesEnProceso = {};

  // Control para evitar logs duplicados
  static final Map<String, DateTime> _ultimosLogs = {};
  static const Duration _tiempoMinimoDuplicado = Duration(minutes: 1);

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
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          state.isLoading
                              ? Container(
                                margin: const EdgeInsets.all(8),
                                width: 16,
                                height: 16,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.teal,
                                  ),
                                ),
                              )
                              : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                      isInactivo
                          ? null
                          : () => _ejecutarOperacionSegura(
                            context,
                            ref,
                            'agregar_cliente',
                            () async => _mostrarDialogoAgregarClienteInteresado(
                              context,
                              ref,
                            ),
                          ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
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
                        () => _ejecutarOperacionSegura(
                          context,
                          ref,
                          'reintentar',
                          () async =>
                              ref
                                  .read(
                                    clientesInteresadosStateProvider(
                                      idInmueble,
                                    ).notifier,
                                  )
                                  .cargarClientesInteresados(),
                        ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        if (state.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (state.clientes.isEmpty)
          _buildEmptyClientesMessage(context, ref)
        else
          _buildClientesList(context, ref, state.clientesFiltrados),
      ],
    );
  }

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
                      () => _ejecutarOperacionSegura(
                        context,
                        ref,
                        'agregar_cliente',
                        () async => _mostrarDialogoAgregarClienteInteresado(
                          context,
                          ref,
                        ),
                      ),
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

  Widget _buildClientesList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> clientes,
  ) {
    final limitedClientes =
        clientes.length > 50 ? clientes.sublist(0, 50) : clientes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
          child: Text(
            'Mostrando ${limitedClientes.length} cliente${limitedClientes.length != 1 ? "s" : ""}${clientes.length > 50 ? " (primeros 50)" : ""}',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: limitedClientes.length,
          itemBuilder: (context, index) {
            final cliente = limitedClientes[index];
            final nombreCompleto =
                '${cliente['nombre'] ?? ""} ${cliente['apellido_paterno'] ?? ""} ${cliente['apellido_materno'] ?? ""}';
            final fechaInteres =
                cliente['fecha_interes'] != null
                    ? cliente['fecha_interes'].toString().split(' ')[0]
                    : 'Fecha no disponible';
            final telefono = cliente['telefono_cliente'];
            final correo = cliente['correo_cliente'];
            final idCliente = cliente['id_cliente'];

            if (idCliente == null) {
              _registrarAdvertencia(
                'cliente_invalido',
                'Cliente interesado sin ID encontrado en inmueble $idInmueble',
              );
              return const SizedBox.shrink();
            }

            return Card(
              key: ValueKey('cliente_$idCliente'),
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
                                () => _ejecutarOperacionSegura(
                                  context,
                                  ref,
                                  'ver_cliente_$idCliente',
                                  () async => _verDetallesClienteInteresado(
                                    context,
                                    ref,
                                    int.parse(idCliente.toString()),
                                  ),
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
                              Text(telefono.toString()),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.call, size: 20),
                                color: Colors.teal,
                                onPressed:
                                    () => _ejecutarOperacionSegura(
                                      context,
                                      ref,
                                      'llamar_$idCliente',
                                      () async => _llamarCliente(
                                        context,
                                        telefono.toString(),
                                      ),
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
                                    () => _ejecutarOperacionSegura(
                                      context,
                                      ref,
                                      'mensaje_$idCliente',
                                      () async => _enviarMensaje(
                                        context,
                                        telefono.toString(),
                                      ),
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
                                    () => _ejecutarOperacionSegura(
                                      context,
                                      ref,
                                      'email_$idCliente',
                                      () async => _enviarEmail(
                                        context,
                                        correo.toString(),
                                      ),
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

  Future<void> _ejecutarOperacionSegura(
    BuildContext context,
    WidgetRef ref,
    String identificador,
    Future<void> Function() operacion,
  ) async {
    final operacionKey = '$idInmueble-$identificador';

    if (_operacionesEnProceso[operacionKey] == true) {
      return;
    }

    _operacionesEnProceso[operacionKey] = true;

    try {
      await operacion();
    } catch (e, stack) {
      _registrarError('Error en operación $identificador', e, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_obtenerMensajeErrorFriendly(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _operacionesEnProceso[operacionKey] = false;
    }
  }

  Future<void> _verDetallesClienteInteresado(
    BuildContext context,
    WidgetRef ref,
    int idCliente,
  ) async {
    try {
      final notifier = ref.read(
        clientesInteresadosStateProvider(idInmueble).notifier,
      );
      notifier.cargarClientesInteresados();

      final clienteController = ref.read(clienteControllerProvider);
      Cliente? cliente;

      final clientes = await clienteController.getClientes();
      try {
        cliente = clientes.firstWhere((c) => c.id == idCliente);
      } catch (_) {
        final inactivos = await clienteController.getClientesInactivos();
        try {
          cliente = inactivos.firstWhere((c) => c.id == idCliente);
        } catch (_) {
          throw Exception('Cliente no encontrado');
        }
      }

      if (!context.mounted) return;

      // Recargar datos antes de navegar
      notifier.cargarClientesInteresados();

      // Navegar con resultado para actualizar al regresar
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VistaClientes(clienteInicial: cliente),
        ),
      );

      // Al regresar, verificamos si debemos recargar datos
      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualizando información de clientes...'),
            duration: Duration(seconds: 1),
          ),
        );
        await notifier.cargarClientesInteresados();
      }
    } catch (e, stack) {
      _registrarError('Error al cargar detalles de cliente', e, stack);
      if (!context.mounted) return;

      final notifier = ref.read(
        clientesInteresadosStateProvider(idInmueble).notifier,
      );
      notifier.cargarClientesInteresados();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_obtenerMensajeErrorFriendly(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _llamarCliente(BuildContext context, String telefono) async {
    final uri = Uri.parse('tel:$telefono');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('No se puede realizar la llamada');
      }
    } catch (e, stack) {
      _registrarError('Error al intentar llamar', e, stack);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede realizar la llamada a $telefono'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _enviarMensaje(BuildContext context, String telefono) async {
    final uri = Uri.parse('sms:$telefono');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('No se puede enviar mensaje');
      }
    } catch (e, stack) {
      _registrarError('Error al enviar SMS', e, stack);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede enviar mensaje a $telefono'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _enviarEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('No se puede enviar email');
      }
    } catch (e, stack) {
      _registrarError('Error al enviar email', e, stack);
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
                    '${cliente['nombre'] ?? ""} ${cliente['apellido_paterno'] ?? ""} ${cliente['apellido_materno'] ?? ""}',
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
                                cliente['telefono_cliente'].toString(),
                              ),
                            ),
                          if (cliente['telefono_cliente'] != null)
                            _buildActionButton(
                              Icons.message,
                              'SMS',
                              Colors.blue,
                              () => _enviarMensaje(
                                context,
                                cliente['telefono_cliente'].toString(),
                              ),
                            ),
                          if (cliente['correo_cliente'] != null)
                            _buildActionButton(
                              Icons.email,
                              'Email',
                              Colors.orange,
                              () => _enviarEmail(
                                context,
                                cliente['correo_cliente'].toString(),
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
                                int.parse(cliente['id_cliente'].toString()),
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

  Future<void> _mostrarDialogoAgregarClienteInteresado(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargando clientes disponibles...'),
          duration: Duration(seconds: 1),
        ),
      );

      final clienteController = ref.read(clienteControllerProvider);
      final clientes = await clienteController.getClientes();

      if (!context.mounted) return;

      if (clientes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay clientes disponibles para agregar como interesados',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Cliente? clienteSeleccionado;
      final comentariosController = TextEditingController();
      String searchQuery = '';
      List<Cliente> filteredClientes = clientes;

      final resultado = await showDialog<bool>(
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
                            filteredClientes =
                                searchQuery.isEmpty
                                    ? clientes
                                    : clientes.where((cliente) {
                                      return cliente.nombreCompleto
                                              .toLowerCase()
                                              .contains(searchQuery) ||
                                          cliente.telefono
                                              .toLowerCase()
                                              .contains(searchQuery) ||
                                          (cliente.correo
                                                  ?.toLowerCase()
                                                  .contains(searchQuery) ??
                                              false);
                                    }).toList();
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
                    onPressed: () => Navigator.of(context).pop(false),
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
                            : () => Navigator.of(context).pop(true),
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (resultado == true && clienteSeleccionado != null && context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrando cliente interesado...'),
              duration: Duration(seconds: 1),
            ),
          );

          final success = await ref
              .read(clientesInteresadosStateProvider(idInmueble).notifier)
              .registrarClienteInteresado(
                clienteSeleccionado!.id!,
                comentariosController.text.isNotEmpty
                    ? comentariosController.text
                    : null,
              );

          if (!context.mounted) return;

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cliente interesado registrado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e, stack) {
          _registrarError('Error al registrar cliente interesado', e, stack);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al registrar cliente interesado: ${_obtenerMensajeErrorFriendly(e.toString())}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stack) {
      _registrarError('Error al mostrar diálogo de clientes', e, stack);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar clientes: ${_obtenerMensajeErrorFriendly(e.toString())}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _registrarError(String mensaje, Object error, StackTrace? stackTrace) {
    final ahora = DateTime.now();
    final key = '$idInmueble-$mensaje-${error.toString()}';

    if (_ultimosLogs.containsKey(key)) {
      final ultimoRegistro = _ultimosLogs[key]!;
      if (ahora.difference(ultimoRegistro) < _tiempoMinimoDuplicado) {
        return;
      }
    }

    _ultimosLogs[key] = ahora;
    AppLogger.error(mensaje, error, stackTrace);
  }

  void _registrarAdvertencia(String tipo, String mensaje) {
    final ahora = DateTime.now();
    final key = '$idInmueble-$tipo-$mensaje';

    if (_ultimosLogs.containsKey(key)) {
      final ultimoRegistro = _ultimosLogs[key]!;
      if (ahora.difference(ultimoRegistro) < _tiempoMinimoDuplicado) {
        return;
      }
    }

    _ultimosLogs[key] = ahora;
    AppLogger.warning(mensaje);
  }

  String _obtenerMensajeErrorFriendly(String errorOriginal) {
    if (errorOriginal.contains('Connection refused') ||
        errorOriginal.contains('SocketException')) {
      return 'Error de conexión a la base de datos. Verifica tu conexión a Internet.';
    } else if (errorOriginal.contains('ObtenerClientesInteresados')) {
      if (errorOriginal.contains('Access denied')) {
        return 'No tienes permisos para ver los clientes interesados en este inmueble.';
      }
      return 'Error al obtener clientes interesados. Intenta nuevamente más tarde.';
    } else if (errorOriginal.contains('RegistrarClienteInteresado')) {
      if (errorOriginal.contains('Duplicate entry')) {
        return 'Este cliente ya está registrado como interesado en este inmueble.';
      } else if (errorOriginal.contains('foreign key constraint fails')) {
        return 'No se puede registrar este cliente debido a un problema de referencia.';
      }
      return 'Error al registrar el cliente como interesado. Verifica los datos e intenta nuevamente.';
    } else if (errorOriginal.contains('Cliente no encontrado')) {
      return 'No se encontró la información del cliente.';
    } else if (errorOriginal.contains('permission denied') ||
        errorOriginal.contains('not authorized') ||
        errorOriginal.contains('Access denied')) {
      return 'No tienes permisos para realizar esta operación.';
    } else if (errorOriginal.contains('timed out') ||
        errorOriginal.contains('timeout')) {
      return 'La operación tardó demasiado tiempo. Intenta de nuevo más tarde.';
    } else if (errorOriginal.contains('max_allowed_packet')) {
      return 'Datos demasiado grandes para procesar. Contacta al soporte técnico.';
    } else if (errorOriginal.contains('constraint') ||
        errorOriginal.contains('integrity')) {
      return 'Error de validación de datos. Revisa la información ingresada.';
    } else if (errorOriginal.contains('SQL') ||
        errorOriginal.contains('syntax')) {
      return 'Error en la consulta a la base de datos. Contacta al soporte técnico.';
    } else if (errorOriginal.length > 100) {
      return 'Ocurrió un error inesperado. Contacta al soporte técnico.';
    }
    return errorOriginal;
  }
}

import 'dart:async';
import 'cliente_form_add.dart';
import 'cliente_list_view.dart';
import 'cliente_form_edit.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';
import '../../controllers/cliente_controller.dart';
import '../../widgets/app_scaffold.dart';

class VistaClientes extends StatefulWidget {
  final ClienteController? controller;
  final Cliente? clienteInicial;

  const VistaClientes({super.key, this.controller, this.clienteInicial});

  @override
  State<VistaClientes> createState() => _VistaClientesState();
}

class _VistaClientesState extends State<VistaClientes> {
  // Definición de la paleta de colores en RGB
  static const Color colorPrimario = Color.fromRGBO(165, 57, 45, 1); // #A5392D
  static const Color colorOscuro = Color.fromRGBO(26, 26, 26, 1); // #1A1A1A
  static const Color colorClaro = Color.fromRGBO(247, 245, 242, 1); // #F7F5F2
  static const Color colorGrisClaro = Color.fromRGBO(212, 207, 203, 1); // #D4CFCB
  static const Color colorAcento = Color.fromRGBO(216, 86, 62, 1); // #D8563E

  late final ClienteController _controller;
  Cliente? _selectedCliente;
  bool _isLoading = true;
  bool _mostrandoInactivos = false;
  Timer? _autoRefreshTimer;
  List<Cliente> _clientes = [];
  final StreamController<List<Cliente>> _clientesController =
      StreamController<List<Cliente>>.broadcast();

  Stream<List<Cliente>> get _clientesStream => _clientesController.stream;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ClienteController();

    if (widget.clienteInicial != null) {
      _selectedCliente = widget.clienteInicial;
    }

    _cargarDatos();
    _iniciarActualizacionAutomatica();
  }

  void _iniciarActualizacionAutomatica() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        developer.log('Ejecutando actualización automática de clientes');
        _actualizarSilenciosamente();
      }
    });
  }

  Future<void> _actualizarSilenciosamente() async {
    try {
      await _obtenerClientes(true);
    } catch (e) {
      developer.log('Error en actualización automática: $e');
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _clientesController.close();
    super.dispose();
  }

  Future<void> _cargarDatos([bool forzarRefresco = false]) async {
    if (!mounted) return;

    developer.log('Iniciando carga de datos de clientes...');

    setState(() {
      _isLoading = true;
    });

    try {
      _clientes.clear();
      final activos = await _controller.getClientes();
      await Future.delayed(const Duration(milliseconds: 200));
      final inactivos = await _controller.getClientesInactivos();

      developer.log(
        'CLIENTES CARGADOS - Activos: ${activos.length}, Inactivos: ${inactivos.length}',
      );

      if (activos.isNotEmpty) {
        developer.log(
          'ÚLTIMO CLIENTE ACTIVO - ID: ${activos.first.id}, Nombre: ${activos.first.nombre}, Estado: ${activos.first.idEstado}',
        );
      }

      if (!mounted) return;

      setState(() {
        _clientes = [...activos, ...inactivos];
        _clientesController.add(_clientes);
        _isLoading = false;
      });

      developer.log(
        'ESTADO DE FILTRO - Mostrando inactivos: $_mostrandoInactivos',
      );

      if (_selectedCliente != null) {
        developer.log(
          'Cliente seleccionado - ID: ${_selectedCliente!.id}, Estado: ${_selectedCliente!.idEstado}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      developer.log('ERROR al cargar clientes: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar clientes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _obtenerClientes([bool silencioso = false]) async {
    if (!mounted) return;

    if (!silencioso) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final activos = await _controller.getClientes();
      final inactivos = await _controller.getClientesInactivos();

      if (mounted) {
        setState(() {
          _clientes = [...activos, ...inactivos];
          if (!silencioso) _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error al obtener clientes: $e');
      if (!silencioso && mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _agregarCliente() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => ClienteFormAdd(
            onClienteAdded: _cargarDatos,
            controller: _controller,
          ),
    );
  }

  void _editarCliente(Cliente cliente) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => ClienteFormEdit(
            cliente: cliente,
            onClienteUpdated: _cargarDatos,
            controller: _controller,
          ),
    );
  }

  Future<void> _toggleEstadoCliente(Cliente cliente) async {
    if (!mounted) return;

    final ScaffoldMessengerState messengerState = ScaffoldMessenger.of(context);
    final bool estaInactivo = _mostrandoInactivos;

    try {
      bool success = false;

      if (estaInactivo) {
        await _controller.reactivarCliente(cliente.id!);
        success = true;

        if (mounted) {
          messengerState.showSnackBar(
            SnackBar(
              content: const Text('Cliente reactivado correctamente'),
              backgroundColor: colorPrimario,
            ),
          );
        }
      } else {
        await _controller.inactivarCliente(cliente.id!);
        success = true;

        if (mounted) {
          messengerState.showSnackBar(
            SnackBar(
              content: const Text('Cliente inactivado correctamente'),
              backgroundColor: colorAcento,
            ),
          );
        }
      }

      if (mounted && success) {
        setState(() {
          _selectedCliente = null;
        });

        await _cargarDatos();
      }
    } catch (e) {
      if (mounted) {
        messengerState.showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado del cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleMostrarInactivos() {
    if (!mounted) return;

    setState(() {
      _mostrandoInactivos = !_mostrandoInactivos;
      _selectedCliente = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_clientes.isNotEmpty) {
      _clientesController.add(_clientes);
    }

    return AppScaffold(
      title: 'Gestión de Clientes',
      currentRoute: '/clientes',
      showDrawer: true, // Ocultar la barra lateral
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar lista',
          onPressed: _cargarDatos,
        ),
        IconButton(
          onPressed: _toggleMostrarInactivos,
          icon: Icon(
            _mostrandoInactivos ? Icons.person : Icons.person_off,
            color: _mostrandoInactivos ? colorAcento : null,
          ),
          tooltip:
              _mostrandoInactivos
                  ? 'Ver clientes activos'
                  : 'Ver clientes inactivos',
        ),
      ],
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: colorPrimario))
              : Stack(
                children: [
                  Row(
                    children: [
                      // Panel izquierdo con lista de clientes usando StreamBuilder
                      Expanded(
                        flex: 3,
                        child: StreamBuilder<List<Cliente>>(
                          stream: _clientesStream,
                          initialData: _clientes,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              developer.log(
                                'Error en el stream: ${snapshot.error}',
                              );
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text('No hay clientes registrados'),
                              );
                            }

                            final clientes = snapshot.data!;
                            developer.log(
                              'STREAM RECIBIDO - ${clientes.length} clientes',
                            );

                            final filteredClientes =
                                _mostrandoInactivos
                                    ? clientes
                                        .where(
                                          (c) =>
                                              c.idEstado != null &&
                                              c.idEstado != 1,
                                        )
                                        .toList()
                                    : clientes
                                        .where(
                                          (c) =>
                                              c.idEstado == null ||
                                              c.idEstado == 1,
                                        )
                                        .toList();

                            developer.log(
                              'CLIENTES FILTRADOS - ${filteredClientes.length} clientes después del filtro (mostrandoInactivos: $_mostrandoInactivos)',
                            );

                            if (filteredClientes.isNotEmpty) {
                              final primerCliente = filteredClientes.first;
                              developer.log(
                                'PRIMER CLIENTE FILTRADO - ID: ${primerCliente.id}, Nombre: ${primerCliente.nombre}, Estado: ${primerCliente.idEstado}',
                              );
                            }

                            return ClienteListView(
                              clientes: filteredClientes,
                              selectedCliente: _selectedCliente,
                              onClienteSelected: (cliente) {
                                setState(() {
                                  _selectedCliente = cliente;
                                });
                              },
                              onRefresh: _cargarDatos,
                              onEdit: _editarCliente,
                              onDelete: _toggleEstadoCliente,
                              mostrandoInactivos: _mostrandoInactivos,
                            );
                          },
                        ),
                      ),
                      // Panel derecho con detalles del cliente seleccionado
                      Expanded(
                        flex: 5,
                        child:
                            _selectedCliente == null
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_search,
                                        size: 80,
                                        color: colorGrisClaro,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Seleccione un cliente para ver sus detalles',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: colorOscuro.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: _buildClienteDetail(_selectedCliente!),
                                ),
                      ),
                    ],
                  ),
                  // Botón flotante colocado dentro del Stack
                  if (!_mostrandoInactivos)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton(
                        backgroundColor: colorPrimario,
                        foregroundColor: colorClaro,
                        onPressed: _agregarCliente,
                        tooltip: 'Agregar Cliente',
                        child: const Icon(Icons.person_add),
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildClienteDetail(Cliente cliente) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      color: _mostrandoInactivos ? colorGrisClaro.withOpacity(0.3) : colorClaro,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        _mostrandoInactivos ? colorGrisClaro : colorPrimario,
                    foregroundColor: colorClaro,
                    radius: 40,
                    child: Text(
                      cliente.nombre.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    cliente.nombreCompleto,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      decoration:
                          _mostrandoInactivos
                              ? TextDecoration.lineThrough
                              : null,
                      color: _mostrandoInactivos ? colorGrisClaro : colorOscuro,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_mostrandoInactivos)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorAcento.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'INACTIVO',
                        style: TextStyle(
                          color: colorAcento,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 32),

            // Información de contacto
            _buildDetailItem(Icons.phone, 'Teléfono', cliente.telefono),
            _buildDetailItem(Icons.badge, 'RFC', cliente.rfc),
            _buildDetailItem(Icons.assignment_ind, 'CURP', cliente.curp),
            _buildDetailItem(
              Icons.category,
              'Tipo de Cliente',
              _formatTipoCliente(cliente.tipoCliente),
            ),
            if (cliente.correo != null)
              _buildDetailItem(Icons.email, 'Correo', cliente.correo!),

            if (cliente.fechaRegistro != null)
              _buildDetailItem(
                Icons.calendar_today,
                'Fecha de registro',
                cliente.fechaRegistro.toString().split(' ')[0],
              ),

            const Divider(height: 32),

            // Dirección
            const Text(
              'Dirección',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(cliente.direccionCompleta),

            const SizedBox(height: 32),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_mostrandoInactivos)
                  ElevatedButton.icon(
                    onPressed: () => _editarCliente(cliente),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimario,
                      foregroundColor: colorClaro,
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _toggleEstadoCliente(cliente),
                  icon: Icon(
                    _mostrandoInactivos ? Icons.person_add : Icons.delete,
                  ),
                  label: Text(_mostrandoInactivos ? 'Reactivar' : 'Inactivar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _mostrandoInactivos ? colorPrimario : colorAcento,
                    foregroundColor: colorClaro,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTipoCliente(String tipo) {
    switch (tipo) {
      case 'comprador':
        return 'Comprador';
      case 'arrendatario':
        return 'Arrendatario';
      case 'ambos':
        return 'Comprador y Arrendatario';
      default:
        return tipo;
    }
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorPrimario, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colorOscuro.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

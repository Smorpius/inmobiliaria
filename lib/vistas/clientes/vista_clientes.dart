import 'dart:async';
import 'cliente_form_add.dart';
import 'cliente_list_view.dart';
import 'cliente_form_edit.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';
import '../../controllers/cliente_controller.dart';

class VistaClientes extends StatefulWidget {
  final ClienteController? controller;
  final Cliente? clienteInicial; // Cambiado a opcional

  const VistaClientes({
    super.key,
    this.controller,
    this.clienteInicial, // Ya no es requerido
  });

  @override
  State<VistaClientes> createState() => _VistaClientesState();
}

class _VistaClientesState extends State<VistaClientes> {
  late final ClienteController _controller;
  Cliente? _selectedCliente;
  bool _isLoading = true;
  bool _mostrandoInactivos = false;

  // Timer para actualización automática
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ClienteController();

    // Si hay un cliente inicial, seleccionarlo
    if (widget.clienteInicial != null) {
      _selectedCliente = widget.clienteInicial;
    }

    // Cargar clientes inicialmente
    _cargarDatos();

    // Iniciar actualización automática
    _iniciarActualizacionAutomatica();
  }

  void _iniciarActualizacionAutomatica() {
    // Cancelar timer existente si hay uno
    _autoRefreshTimer?.cancel();

    // Crear nuevo timer que se ejecuta cada 30 segundos
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        developer.log('Ejecutando actualización automática de clientes');
        // Cargar datos sin mostrar indicador de carga para no interrumpir al usuario
        _actualizarSilenciosamente();
      }
    });
  }

  // Cargar datos sin mostrar indicador de carga
  Future<void> _actualizarSilenciosamente() async {
    try {
      await _obtenerClientes(true);
    } catch (e) {
      developer.log('Error en actualización automática: $e');
      // No mostrar errores al usuario para actualizaciones en segundo plano
    }
  }

  @override
  void dispose() {
    // Cancelar el timer de actualización automática
    _autoRefreshTimer?.cancel();
    _clientesController.close(); // Cerrar el StreamController
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _obtenerClientes();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
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

  // Almacenamiento local de clientes para el StreamBuilder personalizado
  List<Cliente> _clientes = [];

  // StreamController personalizado para simular un stream de actualizaciones
  final StreamController<List<Cliente>> _clientesController =
      StreamController<List<Cliente>>.broadcast();

  Stream<List<Cliente>> get _clientesStream => _clientesController.stream;

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

    // Capturar context al comienzo para evitar el uso después de operación asíncrona
    final ScaffoldMessengerState messengerState = ScaffoldMessenger.of(context);
    final bool estaInactivo = _mostrandoInactivos;

    try {
      bool success = false;

      if (estaInactivo) {
        await _controller.reactivarCliente(cliente.id!);
        success = true;

        // Verificar que el widget sigue montado antes de mostrar SnackBar
        if (mounted) {
          messengerState.showSnackBar(
            const SnackBar(
              content: Text('Cliente reactivado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _controller.inactivarCliente(cliente.id!);
        success = true;

        // Verificar que el widget sigue montado antes de mostrar SnackBar
        if (mounted) {
          messengerState.showSnackBar(
            const SnackBar(
              content: Text('Cliente inactivado correctamente'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Deseleccionar cliente actual y actualizar datos solo si sigue montado
      if (mounted && success) {
        setState(() {
          _selectedCliente = null;
        });

        // Actualizar la lista de clientes
        await _cargarDatos();
      }
    } catch (e) {
      // Verificar que el widget sigue montado antes de mostrar error
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
      _selectedCliente = null; // Reset de la selección
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cada vez que se construye el widget, actualizamos el stream
    if (_clientes.isNotEmpty) {
      _clientesController.add(_clientes);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
        actions: [
          // Botón para actualización manual (opcional)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar lista',
            onPressed: _cargarDatos,
          ),
          // Botón para alternar entre activos e inactivos
          IconButton(
            onPressed: _toggleMostrarInactivos,
            icon: Icon(
              _mostrandoInactivos ? Icons.person : Icons.person_off,
              color: _mostrandoInactivos ? Colors.red : null,
            ),
            tooltip:
                _mostrandoInactivos
                    ? 'Ver clientes activos'
                    : 'Ver clientes inactivos',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                children: [
                  // Panel izquierdo con lista de clientes usando StreamBuilder
                  Expanded(
                    flex: 3,
                    child: StreamBuilder<List<Cliente>>(
                      stream: _clientesStream,
                      initialData: _clientes,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final clientes = snapshot.data!;
                        final filteredClientes =
                            _mostrandoInactivos
                                ? clientes
                                    .where((c) => c.idEstado != 1)
                                    .toList()
                                : clientes
                                    .where((c) => c.idEstado == 1)
                                    .toList();

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
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Seleccione un cliente para ver sus detalles',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
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
      floatingActionButton:
          !_mostrandoInactivos
              ? FloatingActionButton(
                onPressed: _agregarCliente,
                tooltip: 'Agregar Cliente',
                child: const Icon(Icons.person_add),
              )
              : null,
    );
  }

  Widget _buildClienteDetail(Cliente cliente) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      color: _mostrandoInactivos ? Colors.grey.shade100 : null,
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
                        _mostrandoInactivos ? Colors.grey : Colors.teal,
                    foregroundColor: Colors.white,
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
                      color: _mostrandoInactivos ? Colors.grey.shade700 : null,
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
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'INACTIVO',
                        style: TextStyle(
                          color: Colors.red.shade700,
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
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
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
                        _mostrandoInactivos ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
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
          Icon(icon, color: Colors.teal, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade700,
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

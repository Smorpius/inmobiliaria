import 'dart:async';
import 'package:intl/intl.dart';
import '../utils/applogger.dart';
import '../models/cliente_model.dart';
import 'package:flutter/material.dart';
import '../controllers/cliente_controller.dart';
import '../models/cliente_interesado_model.dart';
import '../controllers/inmueble_controller.dart';

class ClientesInteresadosWidget extends StatefulWidget {
  final int idInmueble;
  final bool isNegociacion;

  // Agregamos opción para controlar la cantidad máxima de registros mostrados
  final int maxRegistrosVisibles;

  const ClientesInteresadosWidget({
    super.key,
    required this.idInmueble,
    this.isNegociacion = false,
    this.maxRegistrosVisibles = 20,
  });

  @override
  State<ClientesInteresadosWidget> createState() =>
      _ClientesInteresadosWidgetState();
}

class _ClientesInteresadosWidgetState extends State<ClientesInteresadosWidget> {
  // Controladores mediante lazy loading para reducir inicializaciones innecesarias
  late final InmuebleController _inmuebleController = InmuebleController();
  late final ClienteController _clienteController = ClienteController();
  final _comentariosController = TextEditingController();

  // Uso de listas inicializadas para evitar nulos
  List<ClienteInteresado> _clientesInteresados = [];
  List<Cliente> _clientesDisponibles = [];

  // Stream controller para cancelar operaciones pendientes
  StreamController<bool>? _loadingController;

  int? _clienteSeleccionadoId;
  bool _isLoading = true;
  bool _isAddingInterest = false;
  bool _procesandoOperacion = false;
  String? _errorMessage;

  // Tiempo de espera máximo para operaciones
  final _tiempoEsperaMax = const Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _loadingController = StreamController<bool>();
    // Usar Future.microtask para evitar llamadas en build inicial
    Future.microtask(() => _cargarDatos());
  }

  @override
  void dispose() {
    // Limpiar recursos para prevenir memory leaks
    _comentariosController.dispose();
    _loadingController?.close();
    _loadingController = null;
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Uso de Future.wait para cargar datos en paralelo
      final results = await Future.wait([
        _inmuebleController
            .getClientesInteresados(widget.idInmueble)
            .timeout(
              _tiempoEsperaMax,
              onTimeout: () {
                throw TimeoutException(
                  'Tiempo de espera agotado al cargar clientes interesados',
                );
              },
            ),
        _clienteController.getClientes().timeout(
          _tiempoEsperaMax,
          onTimeout: () {
            throw TimeoutException(
              'Tiempo de espera agotado al cargar clientes',
            );
          },
        ),
      ]);

      if (!mounted) return;

      final interesadosData = results[0] as List<Map<String, dynamic>>;
      final clientes = results[1] as List<Cliente>;

      // Limitar la cantidad de registros procesados para mejorar rendimiento
      final interesadosLimitados =
          interesadosData.take(widget.maxRegistrosVisibles).toList();

      final interesados =
          interesadosLimitados
              .map((data) => ClienteInteresado.fromMap(data))
              .toList();

      // Filtrar clientes que ya están interesados para evitar duplicados
      final clientesIds = interesados.map((e) => e.idCliente).toSet();
      final clientesDisponiblesFiltrados =
          clientes
              .where((cliente) => !clientesIds.contains(cliente.id))
              .toList();

      setState(() {
        _clientesInteresados = interesados;
        _clientesDisponibles = clientesDisponiblesFiltrados;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error(
        'Error al cargar datos de clientes interesados',
        e,
        StackTrace.current,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      _mostrarError('Error al cargar clientes interesados: $e');
    }
  }

  Future<void> _registrarClienteInteresado() async {
    if (_clienteSeleccionadoId == null) {
      _mostrarError('Debe seleccionar un cliente');
      return;
    }

    if (_procesandoOperacion) {
      _mostrarError('Procesando operación anterior, espere un momento');
      return;
    }

    setState(() {
      _procesandoOperacion = true;
      _isLoading = true;
    });

    try {
      final comentario =
          _comentariosController.text.trim().isNotEmpty
              ? _comentariosController.text.trim()
              : null;

      await _inmuebleController
          .registrarClienteInteresado(
            widget.idInmueble,
            _clienteSeleccionadoId!,
            comentario,
          )
          .timeout(
            _tiempoEsperaMax,
            onTimeout: () {
              throw TimeoutException(
                'Tiempo de espera agotado al registrar cliente interesado',
              );
            },
          );

      // Limpiar campos
      _comentariosController.clear();

      if (!mounted) return;

      setState(() {
        _clienteSeleccionadoId = null;
        _isAddingInterest = false;
      });

      // Recargar la lista
      await _cargarDatos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente registrado como interesado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppLogger.error(
        'Error al registrar cliente interesado',
        e,
        StackTrace.current,
      );

      if (!mounted) return;

      _mostrarError('Error al registrar cliente interesado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _procesandoOperacion = false;
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),

        // Mensaje de error si existe
        if (_errorMessage != null && !_isLoading)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _cargarDatos,
                  tooltip: 'Reintentar',
                ),
              ],
            ),
          ),

        // Formulario para agregar cliente interesado
        if (_isAddingInterest) _buildFormularioAgregar(),

        // Estado de carga o contenido
        _isLoading
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(),
              ),
            )
            : _buildListaClientesInteresados(),
      ],
    );
  }

  Widget _buildHeader() {
    final color = widget.isNegociacion ? Colors.amber : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.people_alt, color: color.shade800),
          const SizedBox(width: 8),
          Text(
            'Clientes Interesados',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color.shade800,
            ),
          ),
          const Spacer(),
          if (!_isAddingInterest && !_isLoading)
            TextButton.icon(
              onPressed: () => setState(() => _isAddingInterest = true),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFormularioAgregar() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registrar cliente interesado',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Dropdown optimizado con una clave para preservar estado
            DropdownButtonFormField<int>(
              key: const ValueKey('cliente-dropdown'),
              decoration: const InputDecoration(
                labelText: 'Seleccione Cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              value: _clienteSeleccionadoId,
              items:
                  _clientesDisponibles
                      .map(
                        (cliente) => DropdownMenuItem(
                          value: cliente.id,
                          child: Text(
                            cliente.nombreCompleto,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() => _clienteSeleccionadoId = value);
              },
              isExpanded: true,
              hint: const Text('Seleccione un cliente'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _comentariosController,
              decoration: const InputDecoration(
                labelText: 'Comentarios (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _procesandoOperacion
                          ? null
                          : () => setState(() {
                            _isAddingInterest = false;
                            _clienteSeleccionadoId = null;
                            _comentariosController.clear();
                          }),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                      _procesandoOperacion ? null : _registrarClienteInteresado,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon:
                      _procesandoOperacion
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.save),
                  label: const Text('Registrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaClientesInteresados() {
    if (_clientesInteresados.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No hay clientes interesados registrados.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _clientesInteresados.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final interesado = _clientesInteresados[index];
        final fecha = DateFormat('dd/MM/yyyy').format(interesado.fechaInteres);

        // Usar claves para optimizar reconstrucción
        return ListTile(
          key: ValueKey('cliente-interesado-${interesado.id}'),
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              interesado.nombreCliente.isNotEmpty
                  ? interesado.nombreCliente.substring(0, 1).toUpperCase()
                  : '?',
              style: TextStyle(color: Colors.blue.shade800),
            ),
          ),
          title: Text(
            interesado.nombreCompleto,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datos de contacto
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(interesado.telefono),
                ],
              ),

              // Email si existe
              if (interesado.correo != null)
                Row(
                  children: [
                    const Icon(Icons.email, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        interesado.correo!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              // Fecha de interés
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text('Interesado desde: $fecha'),
                ],
              ),

              // Comentarios si existen
              if (interesado.comentarios != null &&
                  interesado.comentarios!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comentarios:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        interesado.comentarios!,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          isThreeLine: true,
        );
      },
    );
  }
}

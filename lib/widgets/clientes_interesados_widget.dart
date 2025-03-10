import 'package:intl/intl.dart';
import '../models/cliente_model.dart';
import 'package:flutter/material.dart';
import '../controllers/cliente_controller.dart';
import '../models/cliente_interesado_model.dart';
import '../controllers/inmueble_controller.dart';

class ClientesInteresadosWidget extends StatefulWidget {
  final int idInmueble;
  final bool isNegociacion;

  const ClientesInteresadosWidget({
    super.key,
    required this.idInmueble,
    this.isNegociacion = false,
  });

  @override
  State<ClientesInteresadosWidget> createState() =>
      _ClientesInteresadosWidgetState();
}

class _ClientesInteresadosWidgetState extends State<ClientesInteresadosWidget> {
  final InmuebleController _inmuebleController = InmuebleController();
  final ClienteController _clienteController = ClienteController();
  final _comentariosController = TextEditingController();

  List<ClienteInteresado> _clientesInteresados = [];
  List<Cliente> _clientesDisponibles = [];
  int? _clienteSeleccionadoId;
  bool _isLoading = true;
  bool _isAddingInterest = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _comentariosController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar clientes interesados
      final interesadosData = await _inmuebleController.getClientesInteresados(
        widget.idInmueble,
      );

      final interesados =
          interesadosData
              .map((data) => ClienteInteresado.fromMap(data))
              .toList();

      // Cargar clientes disponibles para el selector
      final clientes = await _clienteController.getClientes();

      if (mounted) {
        setState(() {
          _clientesInteresados = interesados;
          _clientesDisponibles = clientes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clientes interesados: $e')),
        );
      }
    }
  }

  Future<void> _registrarClienteInteresado() async {
    if (_clienteSeleccionadoId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione un cliente')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _inmuebleController.registrarClienteInteresado(
        widget.idInmueble,
        _clienteSeleccionadoId!,
        _comentariosController.text.isNotEmpty
            ? _comentariosController.text
            : null,
      );

      // Limpiar campos
      _comentariosController.clear();
      setState(() {
        _clienteSeleccionadoId = null;
        _isAddingInterest = false;
      });

      // Recargar la lista
      await _cargarDatos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente registrado como interesado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar cliente interesado: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                widget.isNegociacion
                    ? Colors.amber.shade50
                    : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.people_alt,
                color:
                    widget.isNegociacion ? Colors.amber.shade800 : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Clientes Interesados',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color:
                      widget.isNegociacion
                          ? Colors.amber.shade800
                          : Colors.blue,
                ),
              ),
              const Spacer(),
              if (!_isAddingInterest)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAddingInterest = true;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Formulario para agregar cliente interesado
        if (_isAddingInterest)
          Card(
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
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccione Cliente',
                      border: OutlineInputBorder(),
                    ),
                    value: _clienteSeleccionadoId,
                    items:
                        _clientesDisponibles.map((cliente) {
                          return DropdownMenuItem(
                            value: cliente.id,
                            child: Text(cliente.nombreCompleto),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _clienteSeleccionadoId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _comentariosController,
                    decoration: const InputDecoration(
                      labelText: 'Comentarios (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isAddingInterest = false;
                            _clienteSeleccionadoId = null;
                            _comentariosController.clear();
                          });
                        },
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _registrarClienteInteresado,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Registrar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Lista de clientes interesados
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_clientesInteresados.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay clientes interesados registrados.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _clientesInteresados.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final interesado = _clientesInteresados[index];
              final fecha = DateFormat(
                'dd/MM/yyyy',
              ).format(interesado.fechaInteres);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    interesado.nombreCliente.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ),
                title: Text(interesado.nombreCompleto),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teléfono: ${interesado.telefono}'),
                    if (interesado.correo != null)
                      Text('Email: ${interesado.correo}'),
                    Text('Fecha de interés: $fecha'),
                    if (interesado.comentarios != null &&
                        interesado.comentarios!.isNotEmpty)
                      Text(
                        'Comentarios: ${interesado.comentarios}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
                isThreeLine: true,
              );
            },
          ),
      ],
    );
  }
}

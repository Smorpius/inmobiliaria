import 'package:flutter/material.dart';
import '../models/inmueble_model.dart';
import '../controllers/cliente_controller.dart';
import '../controllers/inmueble_controller.dart';
import '../models/cliente_model.dart'; // Importación añadida

class AgregarInmuebleScreen extends StatefulWidget {
  const AgregarInmuebleScreen({super.key});

  @override
  State<AgregarInmuebleScreen> createState() => _AgregarInmuebleScreenState();
}

class _AgregarInmuebleScreenState extends State<AgregarInmuebleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _calleController = TextEditingController();
  final _numeroController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _estadoController = TextEditingController(text: '1');
  final _codigoPostalController = TextEditingController();
  final _montoController = TextEditingController();

  final ClienteController _clienteController = ClienteController();
  final InmuebleController _inmuebleController = InmuebleController();

  // Cambiado el tipo de List<Map<String, dynamic>> a List<Cliente>
  List<Cliente> _clientesDisponibles = [];
  int? _clienteSeleccionado;

  bool _isLoading = false;
  bool _clientesLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() => _clientesLoading = true);
    try {
      final clientes = await _clienteController.getClientes();
      if (!mounted) return;
      setState(() {
        _clientesDisponibles = clientes;
        _clientesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar clientes: $e')));
      setState(() => _clientesLoading = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _calleController.dispose();
    _numeroController.dispose();
    _ciudadController.dispose();
    _estadoController.dispose();
    _codigoPostalController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Inmueble'), elevation: 2),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Sección de información general
            const Text(
              'Información General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Inmueble',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _montoController,
              decoration: const InputDecoration(
                labelText: 'Monto Total',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un monto';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Sección de dirección
            const Text(
              'Dirección',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _calleController,
              decoration: const InputDecoration(
                labelText: 'Calle',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _numeroController,
                    decoration: const InputDecoration(
                      labelText: 'Número',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _codigoPostalController,
                    decoration: const InputDecoration(
                      labelText: 'Código Postal',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _ciudadController,
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Sección de cliente
            const Text(
              'Información del Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _clientesLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  value: _clienteSeleccionado,
                  // Actualizado para usar propiedades de Cliente en lugar de un mapa
                  items:
                      _clientesDisponibles
                          .map(
                            (cliente) => DropdownMenuItem<int>(
                              value: cliente.id,
                              child: Text(cliente.nombre),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _clienteSeleccionado = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor seleccione un cliente';
                    }
                    return null;
                  },
                ),
            const SizedBox(height: 32),

            // Botón de guardar
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _guardarInmueble,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'GUARDAR INMUEBLE',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarInmueble() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Aquí podrías implementar la lógica para primero guardar la dirección
      // y obtener su ID para asociarla al inmueble

      final inmueble = Inmueble(
        nombre: _nombreController.text,
        montoTotal: double.tryParse(_montoController.text) ?? 0,
        idEstado: int.tryParse(_estadoController.text) ?? 1,
        idCliente: _clienteSeleccionado,
        fechaRegistro: DateTime.now(),
      );

      await _inmuebleController.insertInmueble(inmueble);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inmueble guardado correctamente')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar inmueble: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

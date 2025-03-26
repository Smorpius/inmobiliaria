import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../models/venta_model.dart';
import '../../../models/inmueble_model.dart';
import '../../../providers/cliente_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/providers/venta_providers.dart';

class RegistrarVentaScreen extends ConsumerStatefulWidget {
  final Inmueble inmueble;

  const RegistrarVentaScreen({super.key, required this.inmueble});

  @override
  ConsumerState<RegistrarVentaScreen> createState() =>
      _RegistrarVentaScreenState();
}

class _RegistrarVentaScreenState extends ConsumerState<RegistrarVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ingresoController = TextEditingController();
  final _comisionProveedoresController = TextEditingController();
  int? _clienteSeleccionado;
  bool _isLoading = false;
  DateTime _fechaVenta = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Inicializar con valores del inmueble si están disponibles
    if (widget.inmueble.precioVentaFinal != null) {
      _ingresoController.text = widget.inmueble.precioVentaFinal.toString();
    }
    _clienteSeleccionado = widget.inmueble.idCliente;
  }

  @override
  void dispose() {
    _ingresoController.dispose();
    _comisionProveedoresController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaVenta,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaVenta) {
      setState(() {
        _fechaVenta = picked;
      });
    }
  }

  Future<void> _registrarVenta() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete los campos correctamente'),
        ),
      );
      return;
    }

    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un cliente')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ingreso = double.parse(_ingresoController.text);
      final comisionProveedores =
          _comisionProveedoresController.text.isEmpty
              ? 0.0
              : double.parse(_comisionProveedoresController.text);

      final utilidadBruta = ingreso - comisionProveedores;
      final utilidadNeta = utilidadBruta;

      final venta = Venta(
        idCliente: _clienteSeleccionado!,
        idInmueble: widget.inmueble.id!,
        fechaVenta: _fechaVenta,
        ingreso: ingreso,
        comisionProveedores: comisionProveedores,
        utilidadBruta: utilidadBruta,
        utilidadNeta: utilidadNeta,
      );

      final ventaController = ref.read(ventaControllerProvider);
      await ventaController.crearVenta(venta);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta registrada correctamente')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al registrar venta: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsyncValue = ref.watch(clientesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Venta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inmueble: ${widget.inmueble.nombre}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tipo: ${widget.inmueble.tipoInmueble} - Operación: ${widget.inmueble.tipoOperacion}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Precio de Venta Final: \$${widget.inmueble.precioVentaFinal?.toStringAsFixed(2) ?? 'No definido'}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Selección de Cliente
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cliente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      clientesAsyncValue.when(
                        data:
                            (clientes) => DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Seleccione el Cliente',
                                border: OutlineInputBorder(),
                              ),
                              value: _clienteSeleccionado,
                              items:
                                  clientes.map((cliente) {
                                    return DropdownMenuItem<int>(
                                      value: cliente.id,
                                      child: Text(cliente.nombreCompleto),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _clienteSeleccionado = value;
                                });
                              },
                            ),
                        loading:
                            () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        error: (error, stackTrace) => Text('Error: $error'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Detalles de la Venta
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles de la Venta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fecha de venta
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Fecha de Venta',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            controller: TextEditingController(
                              text: DateFormat(
                                'dd/MM/yyyy',
                              ).format(_fechaVenta),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Ingreso
                      TextFormField(
                        controller: _ingresoController,
                        decoration: const InputDecoration(
                          labelText: 'Ingreso',
                          hintText: 'Monto recibido por la venta',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el monto recibido';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingrese un valor numérico válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Comisión de Proveedores
                      TextFormField(
                        controller: _comisionProveedoresController,
                        decoration: const InputDecoration(
                          labelText: 'Comisión de Proveedores',
                          hintText: 'Opcional',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business_center),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón de registrar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registrarVenta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'REGISTRAR VENTA',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

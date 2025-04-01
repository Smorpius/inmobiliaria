import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/contrato_renta_model.dart';
import '../../providers/cliente_providers.dart';
import '../../providers/contrato_renta_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/providers/inmuebles_disponibles_provider.dart';

class RegistrarContratoScreen extends ConsumerStatefulWidget {
  const RegistrarContratoScreen({super.key});

  @override
  ConsumerState<RegistrarContratoScreen> createState() =>
      _RegistrarContratoScreenState();
}

class _RegistrarContratoScreenState
    extends ConsumerState<RegistrarContratoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _condicionesController = TextEditingController();
  int? _clienteSeleccionado;
  int? _inmuebleSeleccionado;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 365));
  bool _isLoading = false;

  @override
  void dispose() {
    _montoController.dispose();
    _condicionesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFechaFin) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFechaFin ? _fechaFin : _fechaInicio,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        if (isFechaFin) {
          _fechaFin = picked;
        } else {
          _fechaInicio = picked;
        }
      });
    }
  }

  Future<void> _registrarContrato() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos')),
      );
      return;
    }

    if (_clienteSeleccionado == null || _inmuebleSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un cliente y un inmueble')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final contrato = ContratoRenta(
        idInmueble: _inmuebleSeleccionado!,
        idCliente: _clienteSeleccionado!,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        montoMensual: double.parse(_montoController.text),
        condicionesAdicionales: _condicionesController.text,
      );

      final controller = ref.read(contratoRentaControllerProvider);
      await controller.registrarContrato(contrato);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrato registrado correctamente')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar contrato: $e')),
        );
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
    final inmueblesAsyncValue = ref.watch(inmueblesDisponiblesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Contrato de Renta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Selección de cliente
              clientesAsyncValue.when(
                data: (clientes) {
                  return DropdownButtonFormField<int>(
                    value: _clienteSeleccionado,
                    items:
                        clientes
                            .map(
                              (cliente) => DropdownMenuItem<int>(
                                value: cliente.id,
                                child: Text(
                                  '${cliente.nombre} ${cliente.apellidoPaterno}',
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _clienteSeleccionado = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Seleccione un cliente',
                    ),
                    validator:
                        (value) =>
                            value == null
                                ? 'Debe seleccionar un cliente'
                                : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error al cargar clientes: $e'),
              ),

              const SizedBox(height: 16),

              // Selección de inmueble
              inmueblesAsyncValue.when(
                data: (inmuebles) {
                  return DropdownButtonFormField<int>(
                    value: _inmuebleSeleccionado,
                    items:
                        inmuebles
                            .map(
                              (inmueble) => DropdownMenuItem<int>(
                                value: inmueble.id,
                                child: Text(inmueble.nombre),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _inmuebleSeleccionado = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Seleccione un inmueble',
                    ),
                    validator:
                        (value) =>
                            value == null
                                ? 'Debe seleccionar un inmueble'
                                : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error al cargar inmuebles: $e'),
              ),

              const SizedBox(height: 16),

              // Fecha de inicio
              ListTile(
                title: const Text('Fecha de inicio'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaInicio)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, false),
                ),
              ),

              const SizedBox(height: 16),

              // Fecha de fin
              ListTile(
                title: const Text('Fecha de fin'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaFin)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, true),
                ),
              ),

              const SizedBox(height: 16),

              // Monto mensual
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto mensual',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el monto mensual';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un monto válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Condiciones adicionales
              TextFormField(
                controller: _condicionesController,
                decoration: const InputDecoration(
                  labelText: 'Condiciones adicionales',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Botón de registrar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registrarContrato,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Registrar Contrato'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

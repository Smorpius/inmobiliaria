import 'package:flutter/material.dart';
import '../../models/pago_renta_model.dart';
import '../../providers/pago_renta_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrarPagoRentaScreen extends ConsumerStatefulWidget {
  final int idContrato;

  const RegistrarPagoRentaScreen({super.key, required this.idContrato});

  @override
  ConsumerState<RegistrarPagoRentaScreen> createState() =>
      _RegistrarPagoRentaScreenState();
}

class _RegistrarPagoRentaScreenState
    extends ConsumerState<RegistrarPagoRentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _comentariosController = TextEditingController();
  DateTime _fechaPago = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _montoController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaPago,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaPago) {
      setState(() {
        _fechaPago = picked;
      });
    }
  }

  Future<void> _registrarPago() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pago = PagoRenta(
        idContrato: widget.idContrato,
        monto: double.parse(_montoController.text),
        fechaPago: _fechaPago,
        comentarios: _comentariosController.text,
      );

      final controller = ref.read(pagoRentaControllerProvider);
      await controller.registrarPago(pago);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado correctamente')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al registrar pago: $e')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Pago de Renta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Fecha de pago
              ListTile(
                title: const Text('Fecha de Pago'),
                subtitle: Text(
                  '${_fechaPago.day}/${_fechaPago.month}/${_fechaPago.year}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              const SizedBox(height: 16),

              // Monto
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el monto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Comentarios
              TextFormField(
                controller: _comentariosController,
                decoration: const InputDecoration(
                  labelText: 'Comentarios',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Botón de registrar
              ElevatedButton(
                onPressed: _isLoading ? null : _registrarPago,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Registrar Pago'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

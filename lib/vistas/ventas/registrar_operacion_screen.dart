import 'package:intl/intl.dart';
import '../../utils/applogger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/venta_model.dart';
import '../../models/inmueble_model.dart';
import '../../providers/venta_providers.dart';
import '../../models/contrato_renta_model.dart';
import '../../providers/cliente_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/contrato_renta_controller.dart';
import '../../providers/inmuebles_disponibles_provider.dart';

class RegistrarOperacionScreen extends ConsumerStatefulWidget {
  final Inmueble inmueble;

  const RegistrarOperacionScreen({super.key, required this.inmueble});

  @override
  ConsumerState<RegistrarOperacionScreen> createState() =>
      _RegistrarOperacionScreenState();
}

class _RegistrarOperacionScreenState
    extends ConsumerState<RegistrarOperacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _comisionProveedoresController = TextEditingController();
  final _condicionesController = TextEditingController();
  int? _clienteSeleccionado;
  bool _isLoading = false;
  DateTime _fechaOperacion = DateTime.now();
  DateTime _fechaFinRenta = DateTime.now().add(
    const Duration(days: 365),
  ); // Por defecto un año
  String _tipoOperacionSeleccionada = 'venta'; // Por defecto
  final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');

  @override
  void initState() {
    super.initState();
    // Determinar el tipo de operación basado en el inmueble
    if (widget.inmueble.tipoOperacion == 'renta') {
      _tipoOperacionSeleccionada = 'renta';
    } else if (widget.inmueble.tipoOperacion == 'venta') {
      _tipoOperacionSeleccionada = 'venta';
    }

    // Pre-llenar el monto según el tipo de operación
    _establecerMontoInicial();
  }

  void _establecerMontoInicial() {
    if (_tipoOperacionSeleccionada == 'venta' &&
        widget.inmueble.precioVenta != null) {
      _montoController.text =
          widget.inmueble.precioVentaFinal?.toString() ??
          widget.inmueble.precioVenta.toString();
    } else if (_tipoOperacionSeleccionada == 'renta' &&
        widget.inmueble.precioRenta != null) {
      _montoController.text = widget.inmueble.precioRenta.toString();
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _comisionProveedoresController.dispose();
    _condicionesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFechaFin) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFechaFin ? _fechaFinRenta : _fechaOperacion,
      firstDate: isFechaFin ? _fechaOperacion : DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              surface: Colors.teal.shade50,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFechaFin) {
          // Validar que fecha fin sea posterior a fecha inicio
          if (picked.isBefore(_fechaOperacion)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'La fecha de fin debe ser posterior a la fecha de inicio',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          _fechaFinRenta = picked;
        } else {
          _fechaOperacion = picked;
          // Si la fecha de operación es posterior a la fecha fin, actualizamos la fecha fin
          if (_fechaFinRenta.isBefore(_fechaOperacion)) {
            _fechaFinRenta = _fechaOperacion.add(const Duration(days: 365));
          }
        }
      });
    }
  }

  Future<void> _registrarOperacion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validación más estricta del cliente seleccionado
    if (_clienteSeleccionado == null || _clienteSeleccionado! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debe seleccionar un cliente válido para registrar la operación',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool resultado = false;

      if (_tipoOperacionSeleccionada == 'venta') {
        // Log para debugging
        AppLogger.info(
          'Registrando venta con clienteID: $_clienteSeleccionado',
        );

        // Crear objeto de venta con validación adicional
        final venta = Venta(
          idCliente: _clienteSeleccionado!,
          idInmueble: widget.inmueble.id!,
          fechaVenta: _fechaOperacion,
          ingreso: double.parse(_montoController.text),
          comisionProveedores:
              _comisionProveedoresController.text.isNotEmpty
                  ? double.parse(_comisionProveedoresController.text)
                  : 0.0,
          // La utilidad bruta y neta se calculan automáticamente en el constructor
        );

        // Registrar la venta
        resultado = await ref
            .read(ventasStateProvider.notifier)
            .registrarVenta(venta);
      } else {
        // Log para debugging
        AppLogger.info(
          'Registrando contrato de renta con clienteID: $_clienteSeleccionado',
        );

        // Crear objeto de contrato de renta con validación adicional
        final contratoRenta = ContratoRenta(
          idInmueble: widget.inmueble.id!,
          idCliente: _clienteSeleccionado!,
          fechaInicio: _fechaOperacion,
          fechaFin: _fechaFinRenta,
          montoMensual: double.parse(_montoController.text),
          condicionesAdicionales:
              _condicionesController.text.isEmpty
                  ? null
                  : _condicionesController.text,
        );
        // Registrar el contrato de renta
        final controller = ContratoRentaController();
        try {
          final idContrato = await controller.registrarContrato(contratoRenta);
          resultado = idContrato > 0;
        } finally {
          controller.dispose();
        }
      }

      if (!mounted) return;

      if (resultado) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tipoOperacionSeleccionada == 'venta'
                  ? 'Venta registrada exitosamente'
                  : 'Contrato de renta registrado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Forzar actualización del provider de inmuebles disponibles
        ref.invalidate(inmueblesDisponiblesProvider);

        // Regresar a la pantalla anterior con resultado positivo
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar la operación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error al registrar operación', e, stackTrace);

      if (!mounted) return;

      // Mensaje de error más específico y descriptivo
      final mensaje = e.toString().toLowerCase();
      String errorMensaje;

      if (mensaje.contains('id_cliente') || mensaje.contains('cliente')) {
        errorMensaje =
            'Error: Problema con la selección de cliente. Por favor, seleccione otro cliente e intente nuevamente.';
      } else if (mensaje.contains('id_inmueble') ||
          mensaje.contains('inmueble')) {
        errorMensaje =
            'Error: Problema con el inmueble seleccionado. Por favor, regrese y seleccione otro inmueble.';
      } else if (mensaje.contains('fecha')) {
        errorMensaje =
            'Error: Problema con la fecha seleccionada. Por favor, verifique e intente nuevamente.';
      } else if (mensaje.contains('monto') || mensaje.contains('ingreso')) {
        errorMensaje =
            'Error: Problema con el monto ingresado. Por favor, verifique e intente nuevamente.';
      } else {
        // Mensaje genérico pero más informativo
        errorMensaje =
            'Error al registrar la operación: ${e.toString().split('\n').first}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMensaje),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
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
    final bool esRenta = _tipoOperacionSeleccionada == 'renta';
    final String tipoOperacionTexto = esRenta ? 'Renta' : 'Venta';

    // Determinar si mostrar comisión de proveedores (solo para venta)
    final mostrarComisionProveedores = _tipoOperacionSeleccionada == 'venta';
    // Determinar si mostrar condiciones (solo para renta)
    final mostrarCondiciones = _tipoOperacionSeleccionada == 'renta';
    // Determinar si mostrar fecha fin (solo para renta)
    final mostrarFechaFin = _tipoOperacionSeleccionada == 'renta';

    // Cambiar el título del campo según el tipo de operación
    final montoLabel = esRenta ? 'Monto Mensual' : 'Monto de Venta';

    return Scaffold(
      appBar: AppBar(title: Text('Registrar $tipoOperacionTexto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del inmueble
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.inmueble.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.inmueble.direccionCompleta,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            esRenta ? Icons.home : Icons.sell,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Operación: $tipoOperacionTexto',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Selección de cliente
              const Text(
                'Cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              clientesAsyncValue.when(
                data: (clientes) {
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Seleccionar cliente',
                    ),
                    value: _clienteSeleccionado,
                    items:
                        clientes.map((cliente) {
                          return DropdownMenuItem<int>(
                            value: cliente.id,
                            child: Text(
                              cliente.nombreCompleto,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
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
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => Text(
                      'Error al cargar clientes: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
              ),
              const SizedBox(height: 16),

              // Fecha de operación
              const Text(
                'Fecha de Operación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd/MM/yyyy').format(_fechaOperacion)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fecha de fin (solo para renta)
              if (mostrarFechaFin) ...[
                const Text(
                  'Fecha de Fin de Contrato',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Text(DateFormat('dd/MM/yyyy').format(_fechaFinRenta)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Monto
              Text(
                montoLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un monto';
                  }
                  try {
                    final monto = double.parse(value);
                    if (monto <= 0) {
                      return 'El monto debe ser mayor a cero';
                    }
                  } catch (e) {
                    return 'Por favor ingrese un valor numérico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Comisión proveedores (solo para venta)
              if (mostrarComisionProveedores) ...[
                const Text(
                  'Comisión de Proveedores',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _comisionProveedoresController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Condiciones adicionales (solo para renta)
              if (mostrarCondiciones) ...[
                const Text(
                  'Condiciones Adicionales (Opcional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _condicionesController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ingrese condiciones especiales del contrato',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              ],

              // Botón de registro
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registrarOperacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : Text(
                            'REGISTRAR ${tipoOperacionTexto.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

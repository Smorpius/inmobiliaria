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
import '../../utils/app_colors.dart'; // Importar AppColors
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

  // Límites para validación de montos extremos
  static const double montoMinimo = 100.0;
  static const double montoMaximoVenta = 100000000.0; // 100 millones
  static const double montoMaximoRenta = 1000000.0; // 1 millón mensual
  bool _inmuebleDisponible =
      true; // Para verificar disponibilidad en tiempo real

  // Variables para almacenar los valores específicos de cada tipo de operación
  String _montoVentaStr = '';
  String _montoRentaStr = '';
  double? _comisionProveedoresVenta;
  String _condicionesRenta = '';

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

    // Verificar disponibilidad del inmueble
    _verificarDisponibilidadInmueble();

    // Configurar listener para verificar disponibilidad periódicamente
    // Esta verificación se ejecutará cada 30 segundos mientras el formulario esté abierto
    _configurarVerificacionPeriodica();
  }

  // Método para verificar la disponibilidad periódicamente
  void _configurarVerificacionPeriodica() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _verificarDisponibilidadInmueble();
        _configurarVerificacionPeriodica(); // Programar la siguiente verificación
      }
    });
  }

  Future<void> _verificarDisponibilidadInmueble() async {
    // Esta función verificaría en tiempo real si el inmueble sigue disponible
    // Se podría implementar una consulta al API o base de datos
    try {
      // Simulamos una verificación en tiempo real consultando el provider
      final inmuebles = await ref.read(inmueblesDisponiblesProvider.future);
      final inmuebleActualizado = inmuebles.firstWhere(
        (i) => i.id == widget.inmueble.id,
        orElse: () => widget.inmueble,
      );

      if (mounted) {
        final disponibleAntes = _inmuebleDisponible;
        setState(() {
          // Verificamos si el inmueble está disponible (idEstado = 3 para disponible)
          _inmuebleDisponible = inmuebleActualizado.idEstado == 3;

          // Solo mostrar advertencia si cambia de disponible a no disponible
          if (disponibleAntes && !_inmuebleDisponible) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'ADVERTENCIA: Este inmueble acaba de cambiar a no disponible. '
                    'Otro usuario podría estar registrando una operación con él.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 8),
                ),
              );
            });
          }
        });
      }
    } catch (e) {
      AppLogger.warning('Error al verificar disponibilidad del inmueble: $e');
      // Si hay error, no cambiamos el estado de disponibilidad
    }
  }

  void _establecerMontoInicial() {
    if (_tipoOperacionSeleccionada == 'venta' &&
        widget.inmueble.precioVenta != null) {
      final precioStr =
          widget.inmueble.precioVentaFinal?.toString() ??
          widget.inmueble.precioVenta.toString();
      _montoController.text = precioStr;
      _montoVentaStr = precioStr;
    } else if (_tipoOperacionSeleccionada == 'renta' &&
        widget.inmueble.precioRenta != null) {
      final precioStr = widget.inmueble.precioRenta.toString();
      _montoController.text = precioStr;
      _montoRentaStr = precioStr;
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
          if (_fechaFinRenta.isBefore(_fechaOperacion)) {
            _fechaFinRenta = _fechaOperacion.add(const Duration(days: 365));
          }
        }
      });
    }
  }

  Future<void> _mostrarDialogoConfirmacion() async {
    // Verificar que el widget siga montado antes de continuar
    if (!mounted) return;

    final String tipoOperacion =
        _tipoOperacionSeleccionada == 'venta' ? 'venta' : 'contrato de renta';
    final String monto = formatCurrency.format(
      double.tryParse(_montoController.text) ?? 0,
    );
    final String cliente =
        ref
            .read(clientesProvider)
            .value
            ?.firstWhere(
              (c) => c.id == _clienteSeleccionado,
              orElse: () => throw Exception('Cliente no encontrado'),
            )
            .nombreCompleto ??
        'No seleccionado';

    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Confirmar $tipoOperacion'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Está seguro que desea registrar esta ${_tipoOperacionSeleccionada == 'venta' ? 'venta' : 'renta'}?',
                ),
                const SizedBox(height: 16),
                Text('Inmueble: ${widget.inmueble.nombre}'),
                Text('Cliente: $cliente'),
                Text(
                  'Monto: $monto ${_tipoOperacionSeleccionada == 'renta' ? 'mensual' : ''}',
                ),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaOperacion)}',
                ),
                if (_tipoOperacionSeleccionada == 'renta')
                  Text(
                    'Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaFinRenta)}',
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('CONFIRMAR'),
              ),
            ],
          ),
    );

    // Verificar mounted después del diálogo
    if (!mounted) return;

    if (confirmacion == true) {
      await _procesarRegistroOperacion();
    }
  }

  Future<void> _procesarRegistroOperacion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool resultado = false;

      if (_tipoOperacionSeleccionada == 'venta') {
        AppLogger.info(
          'Registrando venta con clienteID: $_clienteSeleccionado',
        );

        final venta = Venta(
          idCliente: _clienteSeleccionado!,
          idInmueble: widget.inmueble.id!,
          fechaVenta: _fechaOperacion,
          ingreso: double.parse(_montoController.text),
          comisionProveedores:
              _comisionProveedoresController.text.isNotEmpty
                  ? double.parse(_comisionProveedoresController.text)
                  : 0.0,
        );

        resultado = await ref
            .read(ventasStateProvider.notifier)
            .registrarVenta(venta);
      } else {
        AppLogger.info(
          'Registrando contrato de renta con clienteID: $_clienteSeleccionado',
        );

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

        ref.invalidate(inmueblesDisponiblesProvider);

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

  Future<void> _registrarOperacion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

    // Verificamos que el widget siga montado antes de cada operación asíncrona
    if (!mounted) return;

    await _verificarDisponibilidadInmueble();

    // Verificamos nuevamente después de la operación asíncrona
    if (!mounted) return;

    if (!_inmuebleDisponible) {
      // Usamos un contexto específico para este diálogo y NO lo guardamos
      // como variable. En su lugar, verificaremos mounted inmediatamente
      // después de que el diálogo se cierre
      final continuarAunqueNoDisponible = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              // Usamos el contexto del builder aquí
              title: const Text('Inmueble no disponible'),
              content: const Text(
                'Este inmueble aparece como no disponible en el sistema. '
                '¿Está seguro de que desea continuar con el registro?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('CANCELAR'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('CONTINUAR DE TODOS MODOS'),
                ),
              ],
            ),
      );

      // Verificar mounted inmediatamente después de que el diálogo se cierre
      if (!mounted) return;

      if (continuarAunqueNoDisponible != true) {
        return;
      }
    }

    // Verificar mounted nuevamente antes del siguiente diálogo
    if (!mounted) return;

    // Mostramos el diálogo de confirmación
    await _mostrarDialogoConfirmacion();
  }

  // Método para cambiar el tipo de operación (venta/renta) y actualizar campos relacionados
  void _cambiarTipoOperacion(String nuevoTipo) {
    if (_tipoOperacionSeleccionada == nuevoTipo) return;

    // Guardar los valores actuales según el tipo actual
    if (_tipoOperacionSeleccionada == 'venta') {
      _montoVentaStr = _montoController.text;
      _comisionProveedoresVenta =
          _comisionProveedoresController.text.isNotEmpty
              ? double.tryParse(_comisionProveedoresController.text)
              : null;
    } else if (_tipoOperacionSeleccionada == 'renta') {
      _montoRentaStr = _montoController.text;
      _condicionesRenta = _condicionesController.text;
    }

    // Actualizar el tipo de operación
    setState(() {
      _tipoOperacionSeleccionada = nuevoTipo;

      // Restaurar valores guardados para el nuevo tipo
      if (nuevoTipo == 'venta') {
        _montoController.text =
            _montoVentaStr.isNotEmpty
                ? _montoVentaStr
                : (widget.inmueble.precioVentaFinal?.toString() ??
                    widget.inmueble.precioVenta?.toString() ??
                    '');

        if (_comisionProveedoresVenta != null) {
          _comisionProveedoresController.text =
              _comisionProveedoresVenta.toString();
        } else {
          _comisionProveedoresController.clear();
        }
      } else {
        _montoController.text =
            _montoRentaStr.isNotEmpty
                ? _montoRentaStr
                : (widget.inmueble.precioRenta?.toString() ?? '');

        _condicionesController.text = _condicionesRenta;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsyncValue = ref.watch(clientesProvider);
    final bool esRenta = _tipoOperacionSeleccionada == 'renta';
    final String tipoOperacionTexto = esRenta ? 'Renta' : 'Venta';

    final mostrarComisionProveedores = _tipoOperacionSeleccionada == 'venta';
    final mostrarCondiciones = _tipoOperacionSeleccionada == 'renta';
    final mostrarFechaFin = _tipoOperacionSeleccionada == 'renta';

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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                          if (widget.inmueble.tipoOperacion == 'ambos')
                            Row(
                              children: [
                                const Text('Cambiar a: '),
                                TextButton.icon(
                                  onPressed:
                                      esRenta
                                          ? () => _cambiarTipoOperacion('venta')
                                          : () =>
                                              _cambiarTipoOperacion('renta'),
                                  icon: Icon(
                                    esRenta ? Icons.sell : Icons.home,
                                    size: 16,
                                  ),
                                  label: Text(esRenta ? 'Venta' : 'Renta'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Indicador de disponibilidad
                      if (!_inmuebleDisponible)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(
                              51,
                            ), // 0.2 de opacidad equivale aproximadamente a alpha 51 (0.2 * 255 = 51)
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Inmueble posiblemente no disponible',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _verificarDisponibilidadInmueble,
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Verificar',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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

                    // Validación de montos extremos
                    if (monto < montoMinimo) {
                      return 'El monto parece ser demasiado bajo (mínimo: ${formatCurrency.format(montoMinimo)})';
                    }

                    final limiteSuperior =
                        _tipoOperacionSeleccionada == 'venta'
                            ? montoMaximoVenta
                            : montoMaximoRenta;

                    if (monto > limiteSuperior) {
                      String mensaje =
                          'El monto parece ser extremadamente alto';
                      if (_tipoOperacionSeleccionada == 'renta') {
                        mensaje += ' para una renta mensual';
                      }
                      mensaje +=
                          ' (límite: ${formatCurrency.format(limiteSuperior)})';
                      return mensaje;
                    }
                  } catch (e) {
                    return 'Por favor ingrese un valor numérico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registrarOperacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primario, // Cambiado a AppColors.primario
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

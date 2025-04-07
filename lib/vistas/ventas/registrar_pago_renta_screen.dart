import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/pago_renta_model.dart';
import '../../providers/pago_renta_provider.dart';
import '../../providers/contrato_renta_provider.dart';
import '../../models/comprobante_movimiento_model.dart';
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
  final List<ComprobanteMovimiento> _comprobantes = [];
  final _formatoMoneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

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

  void _agregarComprobante() async {
    // Implementación de agregar comprobante
    // Usamos el selector de comprobantes desde un diálogo personalizado
    final comprobante = await _mostrarSelectorComprobantes();

    if (comprobante != null && mounted) {
      setState(() {
        _comprobantes.add(comprobante);
      });
    }
  }

  Future<ComprobanteMovimiento?> _mostrarSelectorComprobantes() async {
    // Esta función muestra un diálogo para seleccionar un comprobante
    // Podríamos usar aquí un widget personalizado o una pantalla completa
    return showDialog<ComprobanteMovimiento>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleccionar comprobante'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Seleccionar de galería'),
                  onTap: () async {
                    Navigator.of(context).pop(
                      ComprobanteMovimiento(
                        idMovimiento: 0,
                        rutaArchivo: 'assets/temp/imagen_ejemplo.jpg',
                        tipoComprobante: 'recibo',
                        descripcion: 'Comprobante de pago',
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Tomar foto'),
                  onTap: () async {
                    Navigator.of(context).pop(
                      ComprobanteMovimiento(
                        idMovimiento: 0,
                        rutaArchivo: 'assets/temp/foto_ejemplo.jpg',
                        tipoComprobante: 'recibo',
                        descripcion: 'Comprobante de pago',
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  void _eliminarComprobante(ComprobanteMovimiento comprobante) {
    setState(() {
      _comprobantes.remove(comprobante);
    });
  }

  Future<void> _registrarPago() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos correctamente'),
        ),
      );
      return;
    }

    if (_comprobantes.isEmpty) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('¿Continuar sin comprobantes?'),
              content: const Text(
                'No has adjuntado ningún comprobante de pago. ¿Deseas continuar de todas formas?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continuar'),
                ),
              ],
            ),
      );

      if (confirmar != true) {
        return;
      }
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
      final idPago = await controller.registrarPago(pago);

      // Si hay comprobantes, guardarlos asociados al pago
      if (_comprobantes.isNotEmpty && idPago > 0) {
        for (var comprobante in _comprobantes) {
          // Asociar el comprobante con el pago recién creado
          await controller.asociarComprobantePago(idPago, comprobante);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_obtenerMensajeError(e)),
            backgroundColor: Colors.red,
          ),
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

  // Método para personalizar los mensajes de error según el tipo
  String _obtenerMensajeError(dynamic error) {
    if (error.toString().contains('conexión')) {
      return 'Error de conexión. Verifica tu conexión a internet e inténtalo de nuevo.';
    } else if (error.toString().contains('autenticación') ||
        error.toString().contains('autorización')) {
      return 'Error de autenticación. Cierra sesión y vuelve a ingresar.';
    } else {
      return 'Error al registrar pago: ${error.toString()}';
    }
  }

  // Método para validar la información del cliente
  void _validarInformacionCliente(dynamic contrato) {
    if (contrato.clienteNombreCompleto == null ||
        contrato.clienteNombreCompleto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advertencia: Información del cliente incompleta'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener información del contrato para mostrarla
    final contratoAsyncValue = ref.watch(
      contratoRentaDetalleProvider(widget.idContrato),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Pago de Renta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Información del contrato
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: contratoAsyncValue.when(
                    data: (contrato) {
                      _validarInformacionCliente(contrato);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contrato #${contrato.id}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cliente: ${contrato.clienteNombreCompleto ?? "No disponible"}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (contrato.nombreCliente != null)
                            Text('Nombre: ${contrato.nombreCliente}'),
                          if (contrato.apellidoCliente != null)
                            Text('Apellido: ${contrato.apellidoCliente}'),
                          const SizedBox(height: 8),
                          Text('Inmueble ID: ${contrato.idInmueble}'),
                          const Divider(),
                          Text(
                            'Fechas de contrato:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Inicio: ${DateFormat('dd/MM/yyyy').format(contrato.fechaInicio)}',
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Fin: ${DateFormat('dd/MM/yyyy').format(contrato.fechaFin)}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Estado: ${contrato.estadoRenta ?? (contrato.estaVigente ? "Vigente" : "No vigente")}',
                            style: TextStyle(
                              color:
                                  contrato.estaVigente
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Monto mensual: ${_formatoMoneda.format(contrato.montoMensual)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (contrato.porcentajeAvance > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Progreso del contrato: ${contrato.porcentajeAvance.toStringAsFixed(1)}%',
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: contrato.porcentajeAvance / 100,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      contrato.estaProximoAVencer
                                          ? Colors.amber
                                          : Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, _) => Text(
                          'Error al cargar detalles del contrato: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                  ),
                ),
              ),

              // Fecha de pago
              ListTile(
                title: const Text('Fecha de Pago'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaPago)),
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
                  if (double.parse(value) <= 0) {
                    return 'El monto debe ser mayor a cero';
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

              // Sección de comprobantes
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Comprobantes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),

                    if (_comprobantes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text('No hay comprobantes adjuntos'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comprobantes.length,
                        itemBuilder: (context, index) {
                          final comprobante = _comprobantes[index];
                          return ListTile(
                            leading: Icon(
                              comprobante.tipoArchivo == 'pdf'
                                  ? Icons.picture_as_pdf
                                  : Icons.image,
                              color:
                                  comprobante.tipoArchivo == 'pdf'
                                      ? Colors.red
                                      : Colors.blue,
                            ),
                            title: Text(
                              comprobante.descripcion ??
                                  'Comprobante ${index + 1}',
                            ),
                            subtitle: Text(
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(comprobante.fechaCarga),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed:
                                  () => _eliminarComprobante(comprobante),
                            ),
                            onTap: () {
                              // Ver detalle del comprobante
                            },
                          );
                        },
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Comprobante'),
                          onPressed: _agregarComprobante,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botón de registrar
              ElevatedButton(
                onPressed: _isLoading ? null : _registrarPago,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    _isLoading
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(width: 12),
                            Text('Registrando pago...'),
                          ],
                        )
                        : const Text('Registrar Pago'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

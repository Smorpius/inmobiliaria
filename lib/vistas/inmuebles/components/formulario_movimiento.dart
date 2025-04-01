import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/inmueble_model.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/cliente_providers.dart';
import '../../../models/movimiento_renta_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/inmueble_renta_provider.dart';
import '../../../models/comprobante_movimiento_model.dart';

class FormularioMovimiento extends ConsumerStatefulWidget {
  final Inmueble inmueble;
  final VoidCallback onSuccess;

  const FormularioMovimiento({
    super.key,
    required this.inmueble,
    required this.onSuccess,
  });

  @override
  ConsumerState<FormularioMovimiento> createState() =>
      _FormularioMovimientoState();
}

class _FormularioMovimientoState extends ConsumerState<FormularioMovimiento> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();
  final _comentariosController = TextEditingController();

  DateTime _fechaMovimiento = DateTime.now();
  String _tipoMovimiento = 'ingreso';
  bool _isLoading = false;
  bool _imagenSubiendo = false;

  // Para las imágenes/comprobantes
  List<Map<String, dynamic>> _imagenesTemporal = [];
  int? _imagenPrincipalIndex;

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clienteAsyncValue = ref.watch(
      clientePorIdProvider(widget.inmueble.idCliente ?? 0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de información básica
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información General',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cliente asociado
                    clienteAsyncValue.when(
                      data: (cliente) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cliente asociado:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${cliente?.nombre ?? 'N/A'} ${cliente?.apellidoPaterno ?? ''}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (cliente?.telefono != null &&
                                cliente!.telefono.isNotEmpty)
                              Text(
                                'Tel: ${cliente.telefono}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        );
                      },
                      loading:
                          () => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      error:
                          (error, _) => Text(
                            'Error al cargar cliente: ${error.toString()}',
                            style: const TextStyle(color: Colors.red),
                          ),
                    ),

                    const Divider(),
                    // Tipo de movimiento
                    const Text(
                      'Tipo de movimiento:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Ingreso'),
                            value: 'ingreso',
                            groupValue: _tipoMovimiento,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _tipoMovimiento = value;
                                });
                              }
                            },
                            activeColor: Colors.green,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Egreso'),
                            value: 'egreso',
                            groupValue: _tipoMovimiento,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _tipoMovimiento = value;
                                });
                              }
                            },
                            activeColor: Colors.red,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tarjeta de detalles del movimiento
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalles del Movimiento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fecha del movimiento
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Fecha del Movimiento',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: DateFormat(
                              'dd/MM/yyyy',
                            ).format(_fechaMovimiento),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Concepto
                    TextFormField(
                      controller: _conceptoController,
                      decoration: const InputDecoration(
                        labelText: 'Concepto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Ej: Pago de renta, Mantenimiento...',
                      ),
                      validator: _validarConcepto,
                    ),

                    const SizedBox(height: 16),

                    // Monto
                    TextFormField(
                      controller: _montoController,
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                        prefixText: '\$ ',
                        hintText: 'Ej: 5000.00',
                        helperText:
                            _tipoMovimiento == 'ingreso'
                                ? 'Ingrese el monto recibido'
                                : 'Ingrese el monto pagado',
                        helperStyle: TextStyle(
                          color:
                              _tipoMovimiento == 'ingreso'
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validarMonto,
                    ),

                    const SizedBox(height: 16),

                    // Comentarios
                    TextFormField(
                      controller: _comentariosController,
                      decoration: const InputDecoration(
                        labelText: 'Comentarios (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.comment),
                        hintText: 'Detalles adicionales...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Comprobantes / Imágenes
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildImageSelector()],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón de registro
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registrarMovimiento,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _tipoMovimiento == 'ingreso'
                          ? Colors.green
                          : Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          'Registrar ${_tipoMovimiento == 'ingreso' ? 'Ingreso' : 'Egreso'}',
                          style: const TextStyle(fontSize: 16),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget personalizado para selector de imágenes
  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Comprobantes (${_imagenesTemporal.length})',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            ElevatedButton.icon(
              onPressed: _imagenSubiendo ? null : () => _agregarImagen(),
              icon:
                  _imagenSubiendo
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.add_photo_alternate),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_imagenesTemporal.isEmpty)
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('No hay comprobantes añadidos'),
          ),
        if (_imagenesTemporal.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imagenesTemporal.length,
              itemBuilder: (context, index) {
                final imagen = _imagenesTemporal[index];
                final esImagenPrincipal = _imagenPrincipalIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      // Imagen
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                esImagenPrincipal
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                            width: esImagenPrincipal ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.file(imagen['file'], fit: BoxFit.cover),
                        ),
                      ),

                      // Botón para eliminar
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => _eliminarImagen(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Botón para marcar como principal
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _establecerImagenPrincipal(index),
                          child: Container(
                            color:
                                esImagenPrincipal
                                    ? Colors.blue.withAlpha(178) // ~0.7 * 255
                                    : Colors.black.withAlpha(128), // 0.5 * 255
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              esImagenPrincipal ? 'Principal' : 'Marcar',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaMovimiento,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaMovimiento) {
      setState(() {
        _fechaMovimiento = picked;
      });
    }
  }

  // Validaciones
  String? _validarConcepto(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un concepto';
    }
    if (value.length < 3) {
      return 'El concepto debe tener al menos 3 caracteres';
    }
    return null;
  }

  String? _validarMonto(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un monto';
    }
    try {
      final monto = double.parse(value);
      if (monto <= 0) {
        return 'El monto debe ser mayor a cero';
      }
    } catch (e) {
      return 'Ingrese un valor numérico válido';
    }
    return null;
  }

  // Métodos para manejar imágenes
  Future<void> _agregarImagen() async {
    setState(() {
      _imagenSubiendo = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() {
          _imagenSubiendo = false;
        });
        return;
      }

      final file = File(pickedFile.path);

      // En un entorno real, aquí subirías el archivo al servidor
      final nuevaImagen = {'tempPath': pickedFile.path, 'file': file};

      setState(() {
        _imagenesTemporal.add(nuevaImagen);
        if (_imagenesTemporal.length == 1) {
          _imagenPrincipalIndex = 0;
        }
      });
    } catch (e, stack) {
      AppLogger.error('Error al agregar imagen', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _imagenSubiendo = false;
        });
      }
    }
  }

  void _eliminarImagen(int index) {
    setState(() {
      _imagenesTemporal.removeAt(index);
      if (_imagenPrincipalIndex == index) {
        _imagenPrincipalIndex = _imagenesTemporal.isNotEmpty ? 0 : null;
      } else if (_imagenPrincipalIndex != null &&
          _imagenPrincipalIndex! > index) {
        _imagenPrincipalIndex = _imagenPrincipalIndex! - 1;
      }
    });
  }

  void _establecerImagenPrincipal(int index) {
    setState(() {
      _imagenPrincipalIndex = index;
    });
  }

  Future<void> _registrarMovimiento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.inmueble.idCliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay cliente asociado a este inmueble'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final monto = double.parse(_montoController.text);

      // Crear el objeto MovimientoRenta
      final movimiento = MovimientoRenta(
        idInmueble: widget.inmueble.id!,
        idCliente: widget.inmueble.idCliente!,
        tipoMovimiento: _tipoMovimiento,
        concepto: _conceptoController.text,
        monto: monto,
        fechaMovimiento: _fechaMovimiento,
        mesCorrespondiente:
            '${_fechaMovimiento.year}-${_fechaMovimiento.month.toString().padLeft(2, '0')}',
        comentarios:
            _comentariosController.text.isEmpty
                ? null
                : _comentariosController.text,
      );

      // Registrar el movimiento directamente usando el controlador
      // para obtener el ID del movimiento inmediatamente
      final idMovimiento = await ref
          .read(movimientoRentaControllerProvider)
          .registrarMovimiento(movimiento);

      // Refrescar la lista de movimientos después de registrar
      await ref
          .read(movimientosRentaStateProvider(widget.inmueble.id!).notifier)
          .cargarMovimientos(widget.inmueble.id!);

      // Si hay imágenes, registrarlas como comprobantes
      if (_imagenesTemporal.isNotEmpty) {
        for (int i = 0; i < _imagenesTemporal.length; i++) {
          final imagen = _imagenesTemporal[i];
          final esImagenPrincipal = _imagenPrincipalIndex == i;

          // Crear un modelo de comprobante
          final comprobante = ComprobanteMovimiento(
            idMovimiento: idMovimiento,
            rutaImagen:
                imagen['tempPath'], // En producción sería una ruta de servidor
            descripcion: 'Comprobante de ${movimiento.concepto}',
            esPrincipal: esImagenPrincipal,
          );

          // Registrar el comprobante
          await ref
              .read(movimientoRentaControllerProvider)
              .agregarComprobante(comprobante);
        }
      }

      // Verificar que el widget aún esté montado después de operaciones asíncronas
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_tipoMovimiento == 'ingreso' ? 'Ingreso' : 'Egreso'} registrado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Limpiar el formulario
      _conceptoController.clear();
      _montoController.clear();
      _comentariosController.clear();
      setState(() {
        _fechaMovimiento = DateTime.now();
        _imagenesTemporal = [];
        _imagenPrincipalIndex = null;
      });

      // Llamar al callback de éxito
      widget.onSuccess();
    } catch (e, stack) {
      AppLogger.error('Error al registrar movimiento', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().split('\n').first}'),
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
}

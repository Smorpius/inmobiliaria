import 'dart:io';
import 'package:intl/intl.dart';
import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../models/inmueble_model.dart';
import 'package:path/path.dart' as path;
import '../models/movimiento_renta_model.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/inmueble_renta_provider.dart';
import '../models/comprobante_movimiento_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistorialTransaccionesWidget extends ConsumerStatefulWidget {
  final Inmueble inmueble;
  final bool esRenta; // Determina si es renta o venta

  const HistorialTransaccionesWidget({
    super.key,
    required this.inmueble,
    this.esRenta = true,
  });

  @override
  ConsumerState<HistorialTransaccionesWidget> createState() =>
      _HistorialTransaccionesWidgetState();
}

class _HistorialTransaccionesWidgetState
    extends ConsumerState<HistorialTransaccionesWidget> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();
  bool _isLoadingForm = false;
  bool _showForm = false;
  DateTime _fechaMovimiento = DateTime.now();
  // Se comenta la variable no utilizada para evitar warnings
  // int? _movimientoSeleccionadoId;

  // Para archivos PDF/comprobantes
  bool _archivoSubiendo = false;
  List<Map<String, dynamic>> _archivosTemporal = [];

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.indigo),
                    const SizedBox(width: 8),
                    const Text(
                      'Historial de Transacciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (widget.esRenta) // Solo mostrar botón para rentas
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Capturar Movimiento'),
                    onPressed: () {
                      setState(() {
                        _showForm = !_showForm;
                        // _movimientoSeleccionadoId = null; // Ya no se utiliza
                      });
                    },
                  ),
              ],
            ),
            const Divider(),

            // Formulario para capturar nuevo movimiento
            if (_showForm) _buildFormularioMovimiento(),

            // Lista de movimientos
            _buildListaMovimientos(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioMovimiento() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Capturar Movimiento',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),

          // Descripción/Concepto
          TextFormField(
            controller: _conceptoController,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
              hintText: 'Ej: Pago de mensualidad, importe, reparación, etc.',
              helperText: '1. Descripción del movimiento',
            ),
            validator: _validarConcepto,
          ),
          const SizedBox(height: 16),

          // Monto
          TextFormField(
            controller: _montoController,
            decoration: const InputDecoration(
              labelText: 'Monto (USD)',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
              hintText: '0.00',
              helperText: '2. Importe que se pagó en este movimiento',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _validarMonto,
          ),
          const SizedBox(height: 16),

          // Fecha
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha',
                border: OutlineInputBorder(),
                helperText: '3. Fecha del movimiento',
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('dd/MM/yyyy').format(_fechaMovimiento)),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sección para adjuntar archivos
          _buildArchivoSelector(),
          const SizedBox(height: 24),

          // Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _isLoadingForm
                        ? null
                        : () {
                          setState(() {
                            _showForm = false;
                            _limpiarFormulario();
                          });
                        },
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isLoadingForm ? null : _guardarMovimiento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child:
                    _isLoadingForm
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Confirmar',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildArchivoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Comprobantes (${_archivosTemporal.length})',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            ElevatedButton.icon(
              onPressed: _archivoSubiendo ? null : _agregarArchivo,
              icon:
                  _archivoSubiendo
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.upload_file),
              label: const Text('Adjuntar PDF'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_archivosTemporal.isEmpty)
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('No hay comprobantes adjuntos'),
          ),
        if (_archivosTemporal.isNotEmpty)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _archivosTemporal.length,
              itemBuilder: (context, index) {
                final archivo = _archivosTemporal[index];
                final nombreArchivo =
                    archivo['tempPath'].toString().split('/').last;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blueGrey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        nombreArchivo.length > 15
                            ? '${nombreArchivo.substring(0, 12)}...'
                            : nombreArchivo,
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _eliminarArchivo(index),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
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

  Widget _buildListaMovimientos() {
    return Consumer(
      builder: (context, ref, child) {
        final movimientosAsyncValue = ref.watch(
          movimientosPorInmuebleProvider(widget.inmueble.id!),
        );

        return movimientosAsyncValue.when(
          data: (movimientos) {
            if (movimientos.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No hay transacciones registradas',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movimientos.length,
              itemBuilder: (context, index) {
                final movimiento = movimientos[index];
                final esPago =
                    movimiento.concepto.toLowerCase().contains('pago') ||
                    movimiento.tipoMovimiento == 'ingreso';

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  color: esPago ? Colors.green.shade50 : Colors.orange.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color:
                          esPago
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: esPago ? Colors.green : Colors.orange,
                      child: Icon(
                        esPago ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      movimiento.concepto,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(movimiento.fechaMovimiento)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(
                            symbol: '\$',
                            locale: 'es_MX',
                          ).format(movimiento.monto),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                esPago
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          movimiento.tipoMovimiento,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Ver detalles del movimiento y sus comprobantes
                      _verDetallesMovimiento(movimiento);
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) =>
                  Center(child: Text('Error al cargar movimientos: $error')),
        );
      },
    );
  }

  void _verDetallesMovimiento(MovimientoRenta movimiento) {
    // Ya no utilizamos _movimientoSeleccionadoId
    // setState(() {
    //   _movimientoSeleccionadoId = movimiento.id;
    // });

    // Mostrar diálogo con detalles y comprobantes
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detalles del Movimiento'),
            content: SizedBox(
              width: double.maxFinite,
              child: _buildDetallesMovimiento(movimiento),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetallesMovimiento(MovimientoRenta movimiento) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoDetalle('Concepto', movimiento.concepto),
        _buildInfoDetalle(
          'Monto',
          NumberFormat.currency(
            symbol: '\$',
            locale: 'es_MX',
          ).format(movimiento.monto),
        ),
        _buildInfoDetalle(
          'Fecha',
          DateFormat('dd/MM/yyyy').format(movimiento.fechaMovimiento),
        ),
        _buildInfoDetalle('Tipo', movimiento.tipoMovimiento),
        if (movimiento.comentarios != null &&
            movimiento.comentarios!.isNotEmpty)
          _buildInfoDetalle('Comentarios', movimiento.comentarios!),

        const Divider(height: 24),
        const Text(
          'Comprobantes:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Lista de comprobantes
        SizedBox(
          height: 200,
          child: _buildComprobantesMovimiento(movimiento.id!),
        ),
      ],
    );
  }

  Widget _buildComprobantesMovimiento(int idMovimiento) {
    return Consumer(
      builder: (context, ref, child) {
        final comprobantesAsyncValue = ref.watch(
          comprobantesPorMovimientoProvider(idMovimiento),
        );

        return comprobantesAsyncValue.when(
          data: (comprobantes) {
            if (comprobantes.isEmpty) {
              return const Center(
                child: Text('No hay comprobantes para este movimiento'),
              );
            }

            return ListView.builder(
              itemCount: comprobantes.length,
              itemBuilder: (context, index) {
                final comprobante = comprobantes[index];
                final esPdf =
                    comprobante.tipoArchivo == 'pdf' ||
                    comprobante.rutaArchivo.toLowerCase().endsWith('.pdf');

                return ListTile(
                  leading: Icon(
                    esPdf ? Icons.picture_as_pdf : Icons.image,
                    color: esPdf ? Colors.red : Colors.blue,
                  ),
                  title: Text(
                    comprobante.descripcion ?? 'Comprobante ${index + 1}',
                  ),
                  subtitle: Text(path.basename(comprobante.rutaArchivo)),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_red_eye),
                    onPressed: () {
                      // Abrir el visor de PDF o imagen
                      // Implementar según la funcionalidad existente
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) =>
                  Center(child: Text('Error al cargar comprobantes: $error')),
        );
      },
    );
  }

  Widget _buildInfoDetalle(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Métodos para validación
  String? _validarConcepto(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese una descripción';
    }
    if (value.length < 3) {
      return 'La descripción debe tener al menos 3 caracteres';
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

  // Métodos para manejar la UI
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

  Future<void> _agregarArchivo() async {
    setState(() {
      _archivoSubiendo = true;
    });

    try {
      // Mostrar opciones para seleccionar PDF o imagen
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Seleccionar tipo de archivo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                    title: const Text('Archivo PDF'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _seleccionarPDF();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.image, color: Colors.blue),
                    title: const Text('Imagen (Recibo)'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _seleccionarImagen();
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _archivoSubiendo = false;
                    });
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            ),
      );
    } catch (e, stack) {
      AppLogger.error('Error al mostrar opciones de archivo', e, stack);
      if (mounted) {
        setState(() {
          _archivoSubiendo = false;
        });
      }
    }
  }

  Future<void> _seleccionarPDF() async {
    try {
      // Aquí implementaríamos la selección de PDF usando file_picker
      // Por ahora, simulamos con ImagePicker y establecemos tipo como PDF
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        setState(() {
          _archivoSubiendo = false;
        });
        return;
      }

      final file = File(pickedFile.path);
      // En una implementación real, verificaríamos que sea realmente un PDF
      final nuevoArchivo = {
        'tempPath': pickedFile.path,
        'file': file,
        'tipo': 'pdf',
      };

      setState(() {
        _archivosTemporal.add(nuevoArchivo);
        _archivoSubiendo = false;
      });
    } catch (e, stack) {
      AppLogger.error('Error al seleccionar PDF', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _archivoSubiendo = false;
        });
      }
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() {
          _archivoSubiendo = false;
        });
        return;
      }

      final file = File(pickedFile.path);
      final nuevaImagen = {
        'tempPath': pickedFile.path,
        'file': file,
        'tipo': 'imagen',
      };

      setState(() {
        _archivosTemporal.add(nuevaImagen);
        _archivoSubiendo = false;
      });
    } catch (e, stack) {
      AppLogger.error('Error al seleccionar imagen', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _archivoSubiendo = false;
        });
      }
    }
  }

  void _eliminarArchivo(int index) {
    setState(() {
      _archivosTemporal.removeAt(index);
    });
  }

  void _limpiarFormulario() {
    _conceptoController.clear();
    _montoController.clear();
    _fechaMovimiento = DateTime.now();
    setState(() {
      _archivosTemporal = [];
    });
  }

  Future<void> _guardarMovimiento() async {
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
      _isLoadingForm = true;
    });

    try {
      final monto = double.parse(_montoController.text);

      // Crear el objeto MovimientoRenta
      final movimiento = MovimientoRenta(
        idInmueble: widget.inmueble.id!,
        idCliente: widget.inmueble.idCliente!,
        tipoMovimiento: 'ingreso', // Por defecto para rentas es ingreso
        concepto: _conceptoController.text,
        monto: monto,
        fechaMovimiento: _fechaMovimiento,
        mesCorrespondiente:
            '${_fechaMovimiento.year}-${_fechaMovimiento.month.toString().padLeft(2, '0')}',
      );

      // Registrar el movimiento
      final idMovimiento = await ref
          .read(movimientoRentaControllerProvider)
          .registrarMovimiento(movimiento);

      // Refrescar la lista de movimientos
      await ref
          .read(movimientosRentaStateProvider(widget.inmueble.id!).notifier)
          .cargarMovimientos(widget.inmueble.id!);

      // Si hay archivos, registrarlos como comprobantes
      if (_archivosTemporal.isNotEmpty) {
        for (final archivo in _archivosTemporal) {
          final comprobante = ComprobanteMovimiento(
            idMovimiento: idMovimiento,
            rutaArchivo: archivo['tempPath'],
            tipoArchivo: archivo['tipo'], // Tipo dinámico según selección
            descripcion: 'Comprobante de ${_conceptoController.text}',
            esPrincipal: true,
            tipoComprobante: 'otro',
          );

          // Registrar el comprobante
          await ref
              .read(movimientoRentaControllerProvider)
              .agregarComprobante(comprobante);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movimiento registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _showForm = false;
          _limpiarFormulario();
        });
      }
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
          _isLoadingForm = false;
        });
      }
    }
  }
}

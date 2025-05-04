import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import 'package:path/path.dart' as path;
import '../../../models/inmueble_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import '../../../models/movimiento_renta_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/inmueble_renta_provider.dart';
import '../../../providers/contrato_renta_provider.dart';
import '../../../models/comprobante_movimiento_model.dart';
import '../../../utils/archivo_utils.dart'; // Añadir importación para ArchivoUtils
import 'package:inmobiliaria/vistas/inmuebles/components/registro_movimientos_renta_screen.dart';

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
  final _numeroReferenciaController = TextEditingController();
  final _emisorController = TextEditingController();
  final _receptorController = TextEditingController();

  DateTime _fechaMovimiento = DateTime.now();
  String _tipoMovimiento = 'ingreso';
  bool _isLoading = false;
  bool _archivoSubiendo = false;

  // Concepto seleccionado
  String? _conceptoSeleccionado;

  // Listas de conceptos predefinidos
  final List<String> _conceptosIngreso = [
    'Pago de renta',
    'Depósito de garantía',
    'Indemnización',
    'Factura',
    'Reembolso',
    'Otro ingreso',
  ];

  final List<String> _conceptosEgreso = [
    'Mantenimiento',
    'Reparación',
    'Servicios',
    'Impuestos',
    'Factura',
    'Comisión',
    'Otro egreso',
  ];

  // Indica si se ha seleccionado factura como concepto
  bool get _esFactura => _conceptoSeleccionado?.toLowerCase() == 'factura';

  // Para los archivos/comprobantes - modificado para soportar PDF e imágenes
  List<Map<String, dynamic>> _archivosTemporal = [];
  int? _archivoPrincipalIndex;

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    _comentariosController.dispose();
    _numeroReferenciaController.dispose();
    _emisorController.dispose();
    _receptorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clienteAsyncValue = ref.watch(
      clientePorInmuebleProvider(widget.inmueble.id ?? 0),
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
                              '${cliente?.nombre ?? 'Cliente no asignado'} ${cliente?.apellidoPaterno ?? ''}',
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

                    // Concepto (lista desplegable)
                    DropdownButtonFormField<String>(
                      value: _conceptoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Concepto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      hint: const Text('Seleccione un concepto'),
                      items:
                          (_tipoMovimiento == 'ingreso'
                                  ? _conceptosIngreso
                                  : _conceptosEgreso)
                              .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              })
                              .toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor seleccione un concepto';
                        }
                        return null;
                      },
                      onChanged: (newValue) {
                        setState(() {
                          _conceptoSeleccionado = newValue;
                          _conceptoController.text = newValue ?? '';
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Número de referencia (solo visible cuando es factura)
                    if (_esFactura) ...[
                      TextFormField(
                        controller: _numeroReferenciaController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Referencia (Factura)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                          hintText: 'Ej: FACT-123456',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El número de referencia es requerido para facturas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campos específicos para facturas (emisor y receptor)
                      TextFormField(
                        controller: _emisorController,
                        decoration: const InputDecoration(
                          labelText: 'Emisor de la Factura',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                          hintText: 'Ej: Proveedor de servicios',
                        ),
                        validator: (value) {
                          if (_esFactura && (value == null || value.isEmpty)) {
                            return 'El emisor es requerido para facturas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _receptorController,
                        decoration: const InputDecoration(
                          labelText: 'Receptor de la Factura',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          hintText: 'Ej: Inmobiliaria',
                        ),
                        validator: (value) {
                          if (_esFactura && (value == null || value.isEmpty)) {
                            return 'El receptor es requerido para facturas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

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

            // Comprobantes / Archivos (Modifcado para incluir PDFs)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildFileSelector()],
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

  // Widget personalizado para selector de archivos (imágenes y PDFs)
  Widget _buildFileSelector() {
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
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _archivoSubiendo ? null : () => _agregarPDF(),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _archivoSubiendo ? null : () => _agregarImagen(),
                  icon:
                      _archivoSubiendo
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.add_photo_alternate),
                  label: const Text('Imagen'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_archivosTemporal.isEmpty)
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('No hay comprobantes añadidos'),
          ),
        if (_archivosTemporal.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _archivosTemporal.length,
              itemBuilder: (context, index) {
                final archivo = _archivosTemporal[index];
                final esPDF = archivo['esPDF'] ?? false;
                final esArchivoPrincipal = _archivoPrincipalIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      // Contenedor para mostrar archivo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                esArchivoPrincipal
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                            width: esArchivoPrincipal ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child:
                              esPDF
                                  ? Container(
                                    color: Colors.grey.shade100,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red.shade700,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          archivo['filename'] ??
                                              'documento.pdf',
                                          style: const TextStyle(fontSize: 10),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  )
                                  : Image.file(
                                    archivo['file'],
                                    fit: BoxFit.cover,
                                  ),
                        ),
                      ),

                      // Botón para eliminar
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => _eliminarArchivo(index),
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
                          onTap: () => _establecerArchivoPrincipal(index),
                          child: Container(
                            color:
                                esArchivoPrincipal
                                    ? Colors.blue.withAlpha(178)
                                    : Colors.black.withAlpha(128),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              esArchivoPrincipal ? 'Principal' : 'Marcar',
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

        // Campo para notas adicionales del comprobante
        if (_archivosTemporal.isNotEmpty) ...[
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Notas adicionales para el comprobante',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note_add),
              hintText: 'Información adicional sobre el comprobante...',
            ),
            maxLines: 2,
            onChanged: (value) {
              // Almacenar las notas para usar al crear el comprobante
              if (_archivoPrincipalIndex != null &&
                  _archivosTemporal.isNotEmpty) {
                _archivosTemporal[_archivoPrincipalIndex!]['notasAdicionales'] =
                    value;
              }
            },
          ),
        ],
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

  // Métodos para manejar archivos (imágenes y PDFs)
  Future<void> _agregarImagen() async {
    setState(() {
      _archivoSubiendo = true;
    });

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
      final filename = path.basename(pickedFile.path);

      // Validar tamaño del archivo (máximo 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        // 10MB
        throw Exception('El archivo excede el tamaño máximo permitido (10MB)');
      }

      // En un entorno real, aquí subirías el archivo al servidor
      final nuevaImagen = {
        'tempPath': pickedFile.path,
        'file': file,
        'esPDF': false,
        'filename': filename,
        'fileSize': fileSize, // Almacenar el tamaño para referencia
      };

      setState(() {
        _archivosTemporal.add(nuevaImagen);
        if (_archivosTemporal.length == 1) {
          _archivoPrincipalIndex = 0;
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
          _archivoSubiendo = false;
        });
      }
    }
  }

  Future<void> _agregarPDF() async {
    setState(() {
      _archivoSubiendo = true;
    });

    try {
      final typeGroup = XTypeGroup(label: 'PDF', extensions: ['pdf']);
      final file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file == null) {
        setState(() {
          _archivoSubiendo = false;
        });
        return;
      }

      final filename = path.basename(file.path);

      // Validar tamaño del archivo (máximo 10MB)
      final fileSize = await File(file.path).length();
      if (fileSize > 10 * 1024 * 1024) {
        // 10MB
        throw Exception('El archivo excede el tamaño máximo permitido (10MB)');
      }

      final nuevoPdf = {
        'tempPath': file.path,
        'file': File(file.path),
        'esPDF': true,
        'filename': filename,
        'fileSize': fileSize, // Almacenar el tamaño para referencia
      };

      setState(() {
        _archivosTemporal.add(nuevoPdf);
        if (_archivosTemporal.length == 1) {
          _archivoPrincipalIndex = 0;
        }
      });
    } catch (e, stack) {
      AppLogger.error('Error al agregar PDF', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _archivoSubiendo = false;
        });
      }
    }
  }

  void _eliminarArchivo(int index) {
    setState(() {
      _archivosTemporal.removeAt(index);
      if (_archivoPrincipalIndex == index) {
        _archivoPrincipalIndex = _archivosTemporal.isNotEmpty ? 0 : null;
      } else if (_archivoPrincipalIndex != null &&
          _archivoPrincipalIndex! > index) {
        _archivoPrincipalIndex = _archivoPrincipalIndex! - 1;
      }
    });
  }

  void _establecerArchivoPrincipal(int index) {
    setState(() {
      _archivoPrincipalIndex = index;
    });
  }

  Future<String> _guardarArchivoPermanente(
    File archivoTemporal,
    String nombreBase,
  ) async {
    try {
      // Usar la utilidad centralizada para guardar archivos de forma consistente
      String ruta = await ArchivoUtils.guardarArchivoPermanente(
        archivoTemporal,
        nombreBase,
        subDirectorio: 'movimientos',
      );

      AppLogger.info('Comprobante guardado con ruta relativa: $ruta');
      return ruta;
    } catch (e, stack) {
      AppLogger.error('Error al guardar archivo permanente', e, stack);
      throw Exception('No se pudo guardar el comprobante: $e');
    }
  }

  Future<void> _registrarMovimiento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Intentar obtener el cliente usando el nuevo método
    int? idCliente;

    try {
      // Buscar primero en el inmueble directamente
      if (widget.inmueble.idCliente != null && widget.inmueble.idCliente! > 0) {
        idCliente = widget.inmueble.idCliente;
      } else {
        // Si no tiene cliente directo, buscar en contratos activos
        final contratos = await ref.read(contratosRentaProvider.future);
        final contratosActivos =
            contratos
                .where(
                  (c) => c.idInmueble == widget.inmueble.id && c.idEstado == 1,
                )
                .toList() ??
            [];

        // Revisar si hay contratos activos para este inmueble
        if (contratosActivos.isNotEmpty) {
          // Tomar el cliente del primer contrato activo
          idCliente = contratosActivos.first.idCliente;
        } else {
          // Si no hay contratos, mostrar error
          // Verificar que el widget aún esté montado
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró un cliente asociado al inmueble'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (idCliente == null) {
        // Verificar que el widget aún esté montado
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo determinar el cliente para el movimiento',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } catch (e) {
      // Verificar si el widget sigue montado
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este inmueble no tiene un cliente asociado. Primero debe asignar un cliente o crear un contrato de renta.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Creamos una lista para guardar las rutas permanentes de archivos
    // para poder limpiarlas en caso de error
    List<String> rutasPermanentes = [];

    try {
      final monto = double.parse(_montoController.text);

      // Crear el objeto MovimientoRenta con el idCliente obtenido
      final movimiento = MovimientoRenta(
        idInmueble: widget.inmueble.id!,
        idCliente:
            idCliente, // Eliminado el operador ! ya que ya está garantizado que no es nulo
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

      // Registrar el movimiento usando el notifier
      final success = await ref
          .read(movimientosRentaStateProvider(widget.inmueble.id!).notifier)
          .registrarMovimiento(movimiento);

      if (!success) {
        throw Exception('No se pudo registrar el movimiento');
      }

      // Extraer el ID del movimiento recién registrado
      final idMovimiento =
          ref
              .read(movimientosRentaStateProvider(widget.inmueble.id!))
              .ultimoIdRegistrado;

      if (idMovimiento == null) {
        AppLogger.warning('No se pudo obtener el ID del movimiento registrado');
        throw Exception('Error al recuperar el ID del movimiento registrado');
      }

      AppLogger.info(
        'Movimiento registrado con ID: $idMovimiento, procesando comprobantes...',
      );

      // Si hay archivos, registrarlos como comprobantes
      bool errorComprobantes = false;
      List<String> erroresComprobantes = [];
      List<int> comprobantesRegistrados = [];

      // Si es una factura, validar el formato del número de referencia
      if (_esFactura) {
        final referenciaRegex = RegExp(r'^[A-Za-z0-9\-\/]{5,30}$');
        if (_numeroReferenciaController.text.isEmpty ||
            !referenciaRegex.hasMatch(_numeroReferenciaController.text)) {
          throw Exception(
            'Número de referencia inválido. Debe tener entre 5 y 30 caracteres y contener solo letras, números, guiones o barras.',
          );
        }
      }

      if (_archivosTemporal.isNotEmpty) {
        for (int i = 0; i < _archivosTemporal.length; i++) {
          try {
            final archivo = _archivosTemporal[i];
            final esArchivoPrincipal = _archivoPrincipalIndex == i;
            final esPDF = archivo['esPDF'] ?? false;

            // Validaciones previas para comprobantes tipo factura
            if (_esFactura) {
              // Validar emisor (mínimo 3 caracteres)
              if (_emisorController.text.trim().length < 3) {
                errorComprobantes = true;
                erroresComprobantes.add(
                  'El emisor debe tener al menos 3 caracteres para facturas',
                );
                continue;
              }

              // Validar receptor (mínimo 3 caracteres)
              if (_receptorController.text.trim().length < 3) {
                errorComprobantes = true;
                erroresComprobantes.add(
                  'El receptor debe tener al menos 3 caracteres para facturas',
                );
                continue;
              }
            }

            // Guardar el archivo en una ubicación permanente
            final rutaPermanente = await _guardarArchivoPermanente(
              archivo['file'],
              'movimiento_$idMovimiento',
            );

            // Guardar la ruta para limpiar en caso de error
            rutasPermanentes.add(rutaPermanente);

            // Crear un modelo de comprobante
            final comprobante = ComprobanteMovimiento(
              idMovimiento: idMovimiento,
              rutaArchivo: rutaPermanente,
              descripcion: 'Comprobante de ${movimiento.concepto}',
              esPrincipal: esArchivoPrincipal,
              tipoComprobante: _determinarTipoComprobante(movimiento, esPDF),
              tipoArchivo: esPDF ? 'pdf' : 'imagen',
              fechaCarga: DateTime.now(),
              metodoPago:
                  _esFactura
                      ? 'efectivo' // Para facturas usamos valores de la lista de métodos válidos
                      : movimiento.tipoMovimiento == 'ingreso'
                      ? 'efectivo'
                      : 'otro',
              emisor:
                  _esFactura
                      ? _emisorController
                          .text // Personalizado para facturas
                      : movimiento.tipoMovimiento == 'ingreso'
                      ? widget.inmueble.nombre
                      : 'Proveedor de servicios',
              receptor:
                  _esFactura
                      ? _receptorController
                          .text // Personalizado para facturas
                      : movimiento.tipoMovimiento == 'ingreso'
                      ? 'Inmobiliaria'
                      : widget.inmueble.nombre,
              conceptoMovimiento: movimiento.concepto,
              montoMovimiento: movimiento.monto,
              numeroReferencia:
                  _esFactura ? _numeroReferenciaController.text : null,
              fechaEmision:
                  _fechaMovimiento, // Asegurarse de incluir la fecha de emisión
            );

            // Registrar el comprobante usando el notifier en lugar del controlador directamente
            final comprobanteSuccess = await ref
                .read(
                  movimientosRentaStateProvider(widget.inmueble.id!).notifier,
                )
                .agregarComprobante(comprobante);

            if (!comprobanteSuccess) {
              errorComprobantes = true;
              erroresComprobantes.add(
                'Error al registrar comprobante ${i + 1}',
              );
            } else {
              AppLogger.info('Comprobante ${i + 1} registrado correctamente');

              // Registrar el ID del comprobante para actualizar la vista posteriormente
              final idComprobante = await _obtenerUltimoIdComprobante(
                idMovimiento,
              );
              if (idComprobante != null) {
                comprobantesRegistrados.add(idComprobante);
              }
            }
          } catch (e) {
            errorComprobantes = true;
            erroresComprobantes.add(
              'Error en comprobante ${i + 1}: ${e.toString().split('\n').first}',
            );
            AppLogger.error(
              'Error al registrar comprobante ${i + 1}',
              e,
              StackTrace.current,
            );
          }
        }
      }

      // IMPORTANTE: Guardar variables en variables locales antes de llamar a ScaffoldMessenger
      // para evitar problemas de contexto desmontado
      final bool mostrarErrorComprobantes = errorComprobantes;
      final List<String> erroresParaMostrar = List.from(erroresComprobantes);

      // Actualizar la lista de comprobantes si se registraron exitosamente
      if (comprobantesRegistrados.isNotEmpty) {
        // Invalidar el caché del provider de comprobantes para que se recargue
        ref.invalidate(comprobantesPorMovimientoProvider(idMovimiento));
        AppLogger.info('Lista de comprobantes actualizada');
      }

      // IMPORTANTE: Invalidar aquí todos los providers relacionados para forzar la actualización
      // de los datos en todas las partes de la aplicación
      ref.invalidate(movimientosRentaStateProvider(widget.inmueble.id!));
      ref.invalidate(movimientosPorInmuebleProvider(widget.inmueble.id!));

      // Si existe un provider de resumen, también invalidarlo
      final resumenParams = ResumenRentaParams(
        idInmueble: widget.inmueble.id!,
        anio: _fechaMovimiento.year,
        mes: _fechaMovimiento.month,
      );
      ref.invalidate(resumenRentaPorMesProvider(resumenParams));

      // Forzar la recarga de los contratos si también están relacionados
      ref.invalidate(contratosRentaProvider);

      // Verificar que el widget aún esté montado después de operaciones asíncronas
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_tipoMovimiento == 'ingreso' ? 'Ingreso' : 'Egreso'} registrado correctamente${mostrarErrorComprobantes ? ', pero hubo problemas con algunos comprobantes' : ''}',
            ),
            backgroundColor:
                mostrarErrorComprobantes ? Colors.orange : Colors.green,
            duration:
                mostrarErrorComprobantes
                    ? const Duration(seconds: 5)
                    : const Duration(seconds: 3),
            action:
                mostrarErrorComprobantes
                    ? SnackBarAction(
                      label: 'Detalles',
                      onPressed: () {
                        // Asegurarse de que el widget siga montado antes de mostrar el diálogo
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text(
                                    'Problemas con comprobantes',
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children:
                                          erroresParaMostrar
                                              .map(
                                                (error) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 8.0,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: Colors.red,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(error),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: const Text('Cerrar'),
                                    ),
                                  ],
                                ),
                          );
                        }
                      },
                    )
                    : null,
          ),
        );
      }

      // Limpiar el formulario
      _conceptoController.clear();
      _montoController.clear();
      _comentariosController.clear();
      _numeroReferenciaController.clear();
      _emisorController.clear();
      _receptorController.clear();

      setState(() {
        _fechaMovimiento = DateTime.now();
        _archivosTemporal = [];
        _archivoPrincipalIndex = null;
        _conceptoSeleccionado = null;
      });

      // Llamar al callback de éxito
      widget.onSuccess();
    } catch (e, stack) {
      AppLogger.error('Error al registrar movimiento', e, stack);

      // Si hay rutas permanentes generadas pero falló el registro, limpiarlas
      if (rutasPermanentes.isNotEmpty) {
        _limpiarArchivosHuerfanos(rutasPermanentes);
      }

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

  // Determina el tipo de comprobante basado en el movimiento y el tipo de archivo
  String _determinarTipoComprobante(MovimientoRenta movimiento, bool esPDF) {
    // Si es una factura según el concepto seleccionado
    if (_esFactura) {
      return 'factura';
    }

    if (movimiento.tipoMovimiento == 'ingreso') {
      return 'recibo';
    }

    // En vez de 'documento' o 'imagen', usar 'otro' que sí está en el ENUM
    return 'otro';
  }

  // Obtiene el ID del último comprobante registrado para un movimiento
  Future<int?> _obtenerUltimoIdComprobante(int idMovimiento) async {
    try {
      final comprobantes = await ref.read(
        comprobantesPorMovimientoProvider(idMovimiento).future,
      );
      if (comprobantes.isNotEmpty) {
        // Ordenar por ID descendente y tomar el primero
        comprobantes.sort((a, b) => b.id?.compareTo(a.id ?? 0) ?? 0);
        return comprobantes.first.id;
      }
      return null;
    } catch (e) {
      AppLogger.warning('Error al obtener el último ID de comprobante: $e');
      return null;
    }
  }

  // Elimina archivos huérfanos en caso de error
  Future<void> _limpiarArchivosHuerfanos(List<String> rutas) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      for (final rutaRelativa in rutas) {
        try {
          final rutaCompleta = path.join(appDir.path, rutaRelativa);
          final archivo = File(rutaCompleta);
          if (await archivo.exists()) {
            await archivo.delete();
            AppLogger.info('Archivo huérfano eliminado: $rutaRelativa');
          }
        } catch (e) {
          AppLogger.warning('Error al eliminar archivo huérfano: $e');
        }
      }
    } catch (e) {
      AppLogger.warning('Error al limpiar archivos huérfanos: $e');
    }
  }
}

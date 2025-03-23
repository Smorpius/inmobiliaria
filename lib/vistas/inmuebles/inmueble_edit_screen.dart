import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import '../../models/inmueble_model.dart';
import '../../models/inmueble_imagen.dart';
import '../../services/image_service.dart';
import '../../providers/inmueble_providers.dart';
import './components/inmueble_edit_actions.dart';
import './components/inmueble_image_gallery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/inmueble_validation_service.dart';

class InmuebleEditScreen extends ConsumerStatefulWidget {
  final Inmueble inmueble;

  const InmuebleEditScreen({super.key, required this.inmueble});

  @override
  ConsumerState<InmuebleEditScreen> createState() => _InmuebleEditScreenState();
}

class _InmuebleEditScreenState extends ConsumerState<InmuebleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioVentaController = TextEditingController();
  final _precioRentaController = TextEditingController();
  final _montoController = TextEditingController();
  final _caracteristicasController = TextEditingController();

  // Controladores para dirección
  final _calleController = TextEditingController();
  final _numeroController = TextEditingController();
  final _coloniaController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _estadoController = TextEditingController();
  final _codigoPostalController = TextEditingController();
  final _referenciasController = TextEditingController();

  // Variable para el estado del inmueble
  int _estadoSeleccionado = 3; // Por defecto: 'Disponible'

  // Mapa de estados de inmueble
  final Map<int, String> _estadosInmueble = {
    2: 'No disponible',
    3: 'Disponible',
    4: 'Vendido',
    5: 'Rentado',
    6: 'En negociación',
  };

  String _tipoInmuebleSeleccionado = 'casa';
  String _tipoOperacionSeleccionado = 'venta';

  final List<String> _tiposInmueble = [
    'casa',
    'departamento',
    'terreno',
    'oficina',
    'local',
    'bodega',
  ];

  final List<String> _tiposOperacion = ['venta', 'renta', 'ambos'];

  bool _isLoading = false;
  List<InmuebleImagen> _imagenes = [];
  final _imageService = ImageService();
  final _validationService = InmuebleValidationService();

  @override
  void initState() {
    super.initState();
    _cargarDatosInmueble();
    _cargarImagenesInmueble();
  }

  void _cargarDatosInmueble() {
    // Cargar datos básicos
    _nombreController.text = widget.inmueble.nombre;
    _montoController.text = widget.inmueble.montoTotal.toString();
    _tipoInmuebleSeleccionado = widget.inmueble.tipoInmueble;
    _tipoOperacionSeleccionado = widget.inmueble.tipoOperacion;

    // Cargar el estado actual del inmueble
    _estadoSeleccionado = widget.inmueble.idEstado ?? 3;

    // Cargar precios según tipo de operación
    if (widget.inmueble.precioVenta != null) {
      _precioVentaController.text = widget.inmueble.precioVenta.toString();
    }
    if (widget.inmueble.precioRenta != null) {
      _precioRentaController.text = widget.inmueble.precioRenta.toString();
    }

    // Cargar características
    if (widget.inmueble.caracteristicas != null) {
      _caracteristicasController.text = widget.inmueble.caracteristicas!;
    }

    // Cargar dirección
    if (widget.inmueble.calle != null) {
      _calleController.text = widget.inmueble.calle!;
    }
    if (widget.inmueble.numero != null) {
      _numeroController.text = widget.inmueble.numero!;
    }
    if (widget.inmueble.colonia != null) {
      _coloniaController.text = widget.inmueble.colonia!;
    }
    if (widget.inmueble.ciudad != null) {
      _ciudadController.text = widget.inmueble.ciudad!;
    }
    if (widget.inmueble.estadoGeografico != null) {
      _estadoController.text = widget.inmueble.estadoGeografico!;
    }
    if (widget.inmueble.codigoPostal != null) {
      _codigoPostalController.text = widget.inmueble.codigoPostal!;
    }
    if (widget.inmueble.referencias != null) {
      _referenciasController.text = widget.inmueble.referencias!;
    }
  }

  Future<void> _cargarImagenesInmueble() async {
    if (widget.inmueble.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener las imágenes del inmueble desde la base de datos
      final controller = ref.read(inmuebleControllerProvider);
      final imagenes = await controller.getImagenesInmueble(
        widget.inmueble.id!,
      );

      if (!mounted) return;

      setState(() {
        _imagenes = imagenes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar imágenes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Editar Inmueble',
      currentRoute: '/inmuebles',
      showDrawer: false,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Galería de imágenes
                      if (widget.inmueble.id != null)
                        InmuebleImageGallery(
                          inmuebleId: widget.inmueble.id,
                          imagenes: _imagenes,
                          isLoading: _isLoading,
                          imageService: _imageService,
                          inmuebleController: ref.read(
                            inmuebleControllerProvider,
                          ),
                          onImagenesUpdated: (imagenes) {
                            setState(() {
                              _imagenes = imagenes;
                            });
                          },
                        ),

                      const SizedBox(height: 24),

                      // Información general
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
                              TextFormField(
                                controller: _nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  border: OutlineInputBorder(),
                                ),
                                validator: _validationService.validarNombre,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _tipoInmuebleSeleccionado,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de Inmueble',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    _tiposInmueble.map((String tipo) {
                                      return DropdownMenuItem<String>(
                                        value: tipo,
                                        child: Text(tipo.capitalize()),
                                      );
                                    }).toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      _tipoInmuebleSeleccionado = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _tipoOperacionSeleccionado,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de Operación',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    _tiposOperacion.map((String tipo) {
                                      return DropdownMenuItem<String>(
                                        value: tipo,
                                        child: Text(tipo.capitalize()),
                                      );
                                    }).toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      _tipoOperacionSeleccionado = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                value: _estadoSeleccionado,
                                decoration: const InputDecoration(
                                  labelText: 'Estado del Inmueble',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    _estadosInmueble.entries.map((entry) {
                                      return DropdownMenuItem<int>(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      );
                                    }).toList(),
                                onChanged: (int? value) {
                                  if (value != null) {
                                    setState(() {
                                      _estadoSeleccionado = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              if (_tipoOperacionSeleccionado == 'venta' ||
                                  _tipoOperacionSeleccionado == 'ambos')
                                TextFormField(
                                  controller: _precioVentaController,
                                  decoration: const InputDecoration(
                                    labelText: 'Precio de Venta',
                                    border: OutlineInputBorder(),
                                    prefixText: '\$ ',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator:
                                      (value) =>
                                          _validationService.validarPrecioVenta(
                                            value,
                                            _tipoOperacionSeleccionado,
                                          ),
                                ),
                              if (_tipoOperacionSeleccionado == 'venta' ||
                                  _tipoOperacionSeleccionado == 'ambos')
                                const SizedBox(height: 12),
                              if (_tipoOperacionSeleccionado == 'renta' ||
                                  _tipoOperacionSeleccionado == 'ambos')
                                TextFormField(
                                  controller: _precioRentaController,
                                  decoration: const InputDecoration(
                                    labelText: 'Precio de Renta',
                                    border: OutlineInputBorder(),
                                    prefixText: '\$ ',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator:
                                      (value) =>
                                          _validationService.validarPrecioRenta(
                                            value,
                                            _tipoOperacionSeleccionado,
                                          ),
                                ),
                              if (_tipoOperacionSeleccionado == 'renta' ||
                                  _tipoOperacionSeleccionado == 'ambos')
                                const SizedBox(height: 12),
                              TextFormField(
                                controller: _montoController,
                                decoration: const InputDecoration(
                                  labelText: 'Monto Total',
                                  border: OutlineInputBorder(),
                                  prefixText: '\$ ',
                                ),
                                keyboardType: TextInputType.number,
                                validator: _validationService.validarMonto,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _caracteristicasController,
                                decoration: const InputDecoration(
                                  labelText: 'Características',
                                  border: OutlineInputBorder(),
                                  hintText:
                                      'Ej: 3 recámaras, 2 baños, jardín...',
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Dirección
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dirección',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _calleController,
                                decoration: const InputDecoration(
                                  labelText: 'Calle',
                                  border: OutlineInputBorder(),
                                ),
                                validator: _validationService.validarCalle,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _numeroController,
                                      decoration: const InputDecoration(
                                        labelText: 'Número',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _coloniaController,
                                      decoration: const InputDecoration(
                                        labelText: 'Colonia',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _ciudadController,
                                decoration: const InputDecoration(
                                  labelText: 'Ciudad',
                                  border: OutlineInputBorder(),
                                ),
                                validator: _validationService.validarCiudad,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _estadoController,
                                      decoration: const InputDecoration(
                                        labelText: 'Estado',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator:
                                          _validationService.validarEstado,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
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
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _referenciasController,
                                decoration: const InputDecoration(
                                  labelText: 'Referencias',
                                  border: OutlineInputBorder(),
                                  hintText: 'Puntos de referencia cercanos...',
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Botones de acción
                      InmuebleEditActions(
                        onActualizar: _actualizarInmueble,
                        onEliminar: () => _mostrarDialogoEliminar(context),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // Función actualizada para editar inmueble
  Future<void> _actualizarInmueble() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor corrija los campos con error'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parsear valores
      final double? precioVenta =
          _precioVentaController.text.isNotEmpty
              ? double.tryParse(_precioVentaController.text)
              : null;

      final double? precioRenta =
          _precioRentaController.text.isNotEmpty
              ? double.tryParse(_precioRentaController.text)
              : null;

      final double montoTotal = double.tryParse(_montoController.text) ?? 0.0;

      // Crear inmueble actualizado usando el valor del dropdown para idEstado
      final inmuebleActualizado = Inmueble(
        id: widget.inmueble.id,
        nombre: _nombreController.text,
        tipoInmueble: _tipoInmuebleSeleccionado,
        tipoOperacion: _tipoOperacionSeleccionado,
        precioVenta: precioVenta,
        precioRenta: precioRenta,
        montoTotal: montoTotal,
        caracteristicas:
            _caracteristicasController.text.isEmpty
                ? null
                : _caracteristicasController.text,
        calle: _calleController.text,
        numero: _numeroController.text.isEmpty ? null : _numeroController.text,
        colonia:
            _coloniaController.text.isEmpty ? null : _coloniaController.text,
        ciudad: _ciudadController.text,
        estadoGeografico: _estadoController.text,
        codigoPostal:
            _codigoPostalController.text.isEmpty
                ? null
                : _codigoPostalController.text,
        idDireccion: widget.inmueble.idDireccion,
        idEstado: _estadoSeleccionado,
        idCliente: widget.inmueble.idCliente,
        idEmpleado: widget.inmueble.idEmpleado,
        fechaRegistro: widget.inmueble.fechaRegistro,
        referencias:
            _referenciasController.text.isEmpty
                ? null
                : _referenciasController.text,
        // Preservar propiedades financieras
        costoCliente: widget.inmueble.costoCliente,
        costoServicios: widget.inmueble.costoServicios,
        comisionAgencia: widget.inmueble.comisionAgencia,
        comisionAgente: widget.inmueble.comisionAgente,
        precioVentaFinal: widget.inmueble.precioVentaFinal,
      );

      // Actualizar inmueble
      final controller = ref.read(inmuebleControllerProvider);
      await controller.updateInmueble(inmuebleActualizado);

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inmueble actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Invalidar proveedores para refrescar datos
      ref.invalidate(inmueblesProvider);

      // Regresar a la pantalla anterior con resultado positivo
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar inmueble: $e'),
          backgroundColor: Colors.red,
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

  void _mostrarDialogoEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Inmueble'),
          content: const Text(
            '¿Está seguro que desea eliminar este inmueble? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _eliminarInmueble();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarInmueble() async {
    // Verificar que el inmueble tenga ID
    if (widget.inmueble.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar un inmueble sin ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(inmuebleControllerProvider);

      // Verificar que el inmueble existe
      final exists = await controller.verificarExistenciaInmueble(
        widget.inmueble.id!,
      );
      if (!exists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El inmueble ya no existe en la base de datos'),
            backgroundColor: Colors.orange,
          ),
        );

        // Regresar a la pantalla anterior
        Navigator.pop(context, true);
        return;
      }

      // Primero eliminar todas las imágenes asociadas
      if (_imagenes.isNotEmpty) {
        for (var imagen in _imagenes) {
          if (imagen.id != null) {
            try {
              await controller.eliminarImagenInmueble(imagen.id!);

              // Verificar que la ruta no esté vacía antes de intentar eliminar el archivo
              if (imagen.rutaImagen.isNotEmpty) {
                await _imageService.eliminarImagenInmueble(imagen.rutaImagen);
              }
            } catch (e) {
              // Continuar con la siguiente imagen si hay error
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Advertencia: No se pudo eliminar imagen ${imagen.id}: $e',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }
        }
      }

      // Luego eliminar el inmueble
      await controller.deleteInmueble(widget.inmueble.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inmueble eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Invalidar proveedores para refrescar datos
      ref.invalidate(inmueblesProvider);

      // Regresar a la pantalla de lista
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar inmueble: $e'),
          backgroundColor: Colors.red,
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
  void dispose() {
    // Liberar controladores
    _nombreController.dispose();
    _precioVentaController.dispose();
    _precioRentaController.dispose();
    _montoController.dispose();
    _caracteristicasController.dispose();
    _calleController.dispose();
    _numeroController.dispose();
    _coloniaController.dispose();
    _ciudadController.dispose();
    _estadoController.dispose();
    _codigoPostalController.dispose();
    _referenciasController.dispose();
    super.dispose();
  }
}

// Extensión para capitalizar strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

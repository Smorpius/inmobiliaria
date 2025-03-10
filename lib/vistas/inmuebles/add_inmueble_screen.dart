import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inmobiliaria/widgets/informacion_general_widget.dart';
import 'package:inmobiliaria/controllers/inmueble_form_controller.dart';
import 'package:inmobiliaria/services/inmueble_validation_service.dart';
import 'package:inmobiliaria/widgets/image_selector_multiple_widget.dart';

class AgregarInmuebleScreen extends StatefulWidget {
  const AgregarInmuebleScreen({super.key});

  @override
  State<AgregarInmuebleScreen> createState() => _AgregarInmuebleScreenState();
}

class _AgregarInmuebleScreenState extends State<AgregarInmuebleScreen> {
  final InmuebleFormController _controller = InmuebleFormController();
  final InmuebleValidationService _validationService =
      InmuebleValidationService();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      await _controller.cargarClientes();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller.formState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Inmueble'), elevation: 2),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_controller.formState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _controller.formState.formKey,
        child: ListView(
          children: [
            // Sección de imágenes
            ImageSelectorMultipleWidget(
              imagenes: _controller.formState.imagenesTemporal,
              imagenPrincipalIndex: _controller.formState.imagenPrincipalIndex,
              onAgregarImagen: _agregarImagen,
              onEliminarImagen: _eliminarImagen,
              onEstablecerPrincipal: _establecerImagenPrincipal,
              isLoading: _controller.formState.isLoading,
            ),
            const SizedBox(height: 24),

            // Sección de información general
            InformacionGeneralWidget(
              nombreController: _controller.formState.nombreController,
              tipoInmuebleSeleccionado:
                  _controller.formState.tipoInmuebleSeleccionado,
              tipoOperacionSeleccionado:
                  _controller.formState.tipoOperacionSeleccionado,
              precioVentaController:
                  _controller.formState.precioVentaController,
              precioRentaController:
                  _controller.formState.precioRentaController,
              montoController: _controller.formState.montoController,
              caracteristicasController:
                  _controller.formState.caracteristicasController,
              tiposInmueble: _controller.formState.tiposInmueble,
              tiposOperacion: _controller.formState.tiposOperacion,
              onTipoInmuebleChanged: (value) {
                setState(() {
                  _controller.formState.tipoInmuebleSeleccionado = value!;
                });
              },
              onTipoOperacionChanged: (value) {
                setState(() {
                  _controller.formState.tipoOperacionSeleccionado = value!;
                });
              },
              validarNombre: (value) => _validationService.validarNombre(value),
              validarMonto: (value) => _validationService.validarMonto(value),
              validarPrecioVenta:
                  (value) => _validationService.validarPrecioVenta(
                    value,
                    _controller.formState.tipoOperacionSeleccionado,
                  ),
              validarPrecioRenta:
                  (value) => _validationService.validarPrecioRenta(
                    value,
                    _controller.formState.tipoOperacionSeleccionado,
                  ),
            ),
            const SizedBox(height: 24),

            // Sección de dirección
            DireccionWidget(
              calleController: _controller.formState.calleController,
              numeroController: _controller.formState.numeroController,
              coloniaController: _controller.formState.coloniaController,
              ciudadController: _controller.formState.ciudadController,
              estadoGeograficoController:
                  _controller.formState.estadoGeograficoController,
              codigoPostalController:
                  _controller.formState.codigoPostalController,
              referenciasController:
                  _controller.formState.referenciasController,
              validarCalle: (value) => _validationService.validarCalle(value),
              validarCiudad: (value) => _validationService.validarCiudad(value),
              validarEstado: (value) => _validationService.validarEstado(value),
            ),
            const SizedBox(height: 24),

            // Sección de asignación
            AsignacionWidget(
              clientesLoading: _controller.formState.clientesLoading,
              clientesDisponibles: _controller.formState.clientesDisponibles,
              clienteSeleccionado: _controller.formState.clienteSeleccionado,
              onClienteChanged: (value) {
                setState(() {
                  _controller.formState.clienteSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 32),

            // Botón de guardar
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _guardarInmueble,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _controller.formState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'GUARDAR INMUEBLE',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _agregarImagen(ImageSource source) async {
    try {
      // Limitar a un máximo de 10 imágenes
      if (_controller.formState.imagenesTemporal.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Máximo 10 imágenes permitidas')),
        );
        return;
      }

      await _controller.agregarImagen(source);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _eliminarImagen(int index) {
    setState(() {
      _controller.eliminarImagen(index);
    });
  }

  void _establecerImagenPrincipal(int index) {
    setState(() {
      _controller.establecerImagenPrincipal(index);
    });
  }

  Future<void> _guardarInmueble() async {
    if (!_controller.validarFormulario()) return;

    setState(() {
      _controller.formState.isLoading = true;
    });

    try {
      await _controller.guardarInmueble();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inmueble agregado correctamente')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar inmueble: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _controller.formState.isLoading = false;
        });
      }
    }
  }
}

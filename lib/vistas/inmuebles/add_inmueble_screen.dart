import '../../utils/applogger.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/informacion_general_widget.dart';
import '../../controllers/inmueble_form_controller.dart';
import '../../services/inmueble_validation_service.dart';
import '../../widgets/image_selector_multiple_widget.dart';

class AgregarInmuebleScreen extends StatefulWidget {
  const AgregarInmuebleScreen({super.key});

  @override
  State<AgregarInmuebleScreen> createState() => _AgregarInmuebleScreenState();
}

class _AgregarInmuebleScreenState extends State<AgregarInmuebleScreen> {
  final InmuebleFormController _controller = InmuebleFormController();
  final InmuebleValidationService _validationService =
      InmuebleValidationService();

  // Controlar operaciones en progreso para evitar duplicados
  bool _cargandoDatos = false;
  bool _guardandoInmueble = false;
  bool _operacionImagen = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (_cargandoDatos) return;

    _cargandoDatos = true;

    try {
      AppLogger.info('Iniciando carga de datos para formulario de inmueble');
      await _controller.cargarClientes();
      if (mounted) setState(() {});
      AppLogger.info('Datos cargados exitosamente');
    } catch (e, stackTrace) {
      AppLogger.error('Error al cargar datos iniciales', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar datos: ${e.toString().split('\n').first}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _cargandoDatos = false;
    }
  }

  @override
  void dispose() {
    AppLogger.info('Liberando recursos de AgregarInmuebleScreen');
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
                if (value != null) {
                  setState(() {
                    _controller.formState.tipoInmuebleSeleccionado = value;
                  });
                }
              },
              onTipoOperacionChanged: (value) {
                if (value != null) {
                  setState(() {
                    _controller.formState.tipoOperacionSeleccionado = value;
                  });
                }
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
    // Evitar múltiples operaciones simultáneas
    if (_operacionImagen) {
      AppLogger.warning('Operación de imagen ya en curso, ignorando solicitud');
      return;
    }

    _operacionImagen = true;

    try {
      // Limitar a un máximo de 10 imágenes
      if (_controller.formState.imagenesTemporal.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Máximo 10 imágenes permitidas'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      AppLogger.info('Agregando imagen de fuente: ${source.name}');
      await _controller.agregarImagen(source);
      if (mounted) setState(() {});
    } catch (e, stackTrace) {
      AppLogger.error('Error al seleccionar imagen', e, stackTrace);

      if (mounted) {
        final esErrorFormato = e.toString().contains('formato');
        final esErrorPermiso =
            e.toString().contains('permission') ||
            e.toString().contains('permiso');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              esErrorFormato
                  ? 'Formato de imagen no compatible'
                  : esErrorPermiso
                  ? 'No se tienen permisos para acceder a las imágenes'
                  : 'Error al seleccionar imagen: ${e.toString().split('\n').first}',
            ),
            backgroundColor: esErrorPermiso ? Colors.orange : Colors.red,
          ),
        );
      }
    } finally {
      _operacionImagen = false;
    }
  }

  void _eliminarImagen(int index) {
    try {
      AppLogger.info('Eliminando imagen en posición: $index');
      setState(() {
        _controller.eliminarImagen(index);
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error al eliminar imagen', e, stackTrace);
    }
  }

  void _establecerImagenPrincipal(int index) {
    try {
      AppLogger.info('Estableciendo imagen principal en posición: $index');
      setState(() {
        _controller.establecerImagenPrincipal(index);
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error al establecer imagen principal', e, stackTrace);
    }
  }

  Future<void> _guardarInmueble() async {
    // Evitar guardado múltiple
    if (_guardandoInmueble) {
      AppLogger.warning('Operación de guardado en curso, ignorando solicitud');
      return;
    }

    // Validar formulario
    if (!_controller.validarFormulario()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor complete correctamente todos los campos requeridos',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _guardandoInmueble = true;

    setState(() {
      _controller.formState.isLoading = true;
    });

    try {
      AppLogger.info('Iniciando proceso de guardado de inmueble');
      final idInmueble = await _controller.guardarInmueble();
      AppLogger.info('Inmueble guardado exitosamente con ID: $idInmueble');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inmueble agregado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      AppLogger.error('Error al guardar inmueble', e, stackTrace);

      if (!mounted) return;

      final esErrorConexion =
          e.toString().toLowerCase().contains('conexión') ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('timeout');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esErrorConexion
                ? 'Error de conexión con la base de datos. Intente nuevamente.'
                : 'Error al guardar inmueble: ${e.toString().split('\n').first}',
          ),
          backgroundColor: esErrorConexion ? Colors.orange : Colors.red,
        ),
      );
    } finally {
      _guardandoInmueble = false;

      if (mounted) {
        setState(() {
          _controller.formState.isLoading = false;
        });
      }
    }
  }
}

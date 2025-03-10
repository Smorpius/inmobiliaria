import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import '../../models/inmueble_model.dart';
import '../../models/inmueble_imagen.dart';
import 'components/inmueble_edit_form.dart';
import 'components/inmueble_edit_actions.dart';
import 'components/inmueble_image_gallery.dart';
import '../../controllers/inmueble_controller.dart';
import '../../services/image_service.dart'; // Corregida la ruta de importación

class InmuebleEditScreen extends StatefulWidget {
  final Inmueble inmueble;

  const InmuebleEditScreen({super.key, required this.inmueble});

  @override
  State<InmuebleEditScreen> createState() => InmuebleEditScreenState();
}

class InmuebleEditScreenState extends State<InmuebleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final InmuebleController _inmuebleController = InmuebleController();
  final ImageService _imageService = ImageService();

  // Controladores para el formulario
  late TextEditingController _nombreController;
  late TextEditingController _montoController;
  late TextEditingController _estadoController;

  // Estado para las imágenes
  List<InmuebleImagen> _imagenes = [];
  bool _isLoading = false;
  bool _cargandoImagenes = true;

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
    _cargarImagenes();
  }

  void _inicializarControladores() {
    _nombreController = TextEditingController(text: widget.inmueble.nombre);
    _montoController = TextEditingController(
      text: widget.inmueble.montoTotal.toString(),
    );
    _estadoController = TextEditingController(
      text: widget.inmueble.idEstado?.toString() ?? '1',
    );
  }

  Future<void> _cargarImagenes() async {
    if (widget.inmueble.id == null) {
      if (mounted) setState(() => _cargandoImagenes = false);
      return;
    }

    try {
      final imagenes = await _inmuebleController.getImagenesInmueble(
        widget.inmueble.id!,
      );
      if (mounted) {
        setState(() {
          _imagenes = imagenes;
          _cargandoImagenes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar imágenes: $e')));
        setState(() => _cargandoImagenes = false);
      }
    }
  }

  Future<void> _actualizarInmueble() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final inmuebleActualizado = Inmueble(
        id: widget.inmueble.id,
        nombre: _nombreController.text,
        montoTotal: double.tryParse(_montoController.text) ?? 0,
        idEstado: int.tryParse(_estadoController.text) ?? 1,
        // Mantener los demás campos que no se editan aquí
        idCliente: widget.inmueble.idCliente,
        fechaRegistro: widget.inmueble.fechaRegistro,
        idDireccion: widget.inmueble.idDireccion,
        tipoInmueble: widget.inmueble.tipoInmueble,
        tipoOperacion: widget.inmueble.tipoOperacion,
        precioVenta: widget.inmueble.precioVenta,
        precioRenta: widget.inmueble.precioRenta,
        caracteristicas: widget.inmueble.caracteristicas,
        calle: widget.inmueble.calle,
        numero: widget.inmueble.numero,
        colonia: widget.inmueble.colonia,
        ciudad: widget.inmueble.ciudad,
        estadoGeografico: widget.inmueble.estadoGeografico,
        codigoPostal: widget.inmueble.codigoPostal,
        referencias: widget.inmueble.referencias,
        idEmpleado: widget.inmueble.idEmpleado,
      );

      await _inmuebleController.updateInmueble(inmuebleActualizado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inmueble actualizado correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar inmueble: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarInmueble() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar inmueble'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este inmueble? '
              'Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      if (widget.inmueble.id != null) {
        // Eliminar imágenes físicas - usamos el método correcto del servicio
        await _eliminarImagenesInmueble(widget.inmueble.id!);
        if (!mounted) return;

        // Eliminar inmueble en la base de datos
        await _inmuebleController.deleteInmueble(widget.inmueble.id!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inmueble eliminado correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar inmueble: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Método auxiliar para eliminar imágenes de un inmueble
  Future<bool> _eliminarImagenesInmueble(int idInmueble) async {
    try {
      // Para cada imagen del inmueble, eliminarla usando el servicio
      for (var imagen in _imagenes) {
        await _imageService.eliminarImagenInmueble(imagen.rutaImagen);
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar imágenes: $e')),
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    _estadoController.dispose();
    super.dispose();
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
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección de imágenes
          InmuebleImageGallery(
            inmuebleId: widget.inmueble.id,
            imagenes: _imagenes,
            isLoading: _cargandoImagenes,
            imageService: _imageService,
            inmuebleController: _inmuebleController,
            onImagenesUpdated: (imagenes) {
              setState(() => _imagenes = imagenes);
            },
          ),

          const SizedBox(height: 24),

          // Formulario de edición
          InmuebleEditForm(
            nombreController: _nombreController,
            montoController: _montoController,
            estadoController: _estadoController,
          ),

          const SizedBox(height: 24),

          // Botones de acción
          InmuebleEditActions(
            onActualizar: _actualizarInmueble,
            onEliminar: _eliminarInmueble,
          ),
        ],
      ),
    );
  }
}

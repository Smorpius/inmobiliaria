import 'dart:io';
import '../models/inmueble_model.dart';
import '../models/inmueble_imagen.dart';
import '../services/image_service.dart';
import '../models/inmueble_form_state.dart';
import '../controllers/cliente_controller.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/inmueble_controller.dart';

class InmuebleFormController {
  final InmuebleFormState formState = InmuebleFormState();
  final ClienteController _clienteController = ClienteController();
  final InmuebleController _inmuebleController = InmuebleController();
  final ImageService _imageService = ImageService();

  // Cargar clientes disponibles
  Future<void> cargarClientes() async {
    formState.clientesLoading = true;
    try {
      final clientes = await _clienteController.getClientes();
      formState.clientesDisponibles = clientes;
    } catch (e) {
      rethrow;
    } finally {
      formState.clientesLoading = false;
    }
  }

  // Crear inmueble a partir del estado actual del formulario
  Inmueble crearInmuebleDesdeForm() {
    double? precioVenta;
    double? precioRenta;

    if (formState.tipoOperacionSeleccionado == 'venta') {
      precioVenta = double.tryParse(formState.precioVentaController.text);
    } else {
      precioRenta = double.tryParse(formState.precioRentaController.text);
    }

    return Inmueble(
      nombre: formState.nombreController.text,
      montoTotal: double.parse(formState.montoController.text),
      tipoInmueble: formState.tipoInmuebleSeleccionado,
      tipoOperacion: formState.tipoOperacionSeleccionado,
      precioVenta: precioVenta,
      precioRenta: precioRenta,
      idEstado: 3, // Estado disponible por defecto
      idCliente: formState.clienteSeleccionado,
      idEmpleado: formState.empleadoSeleccionado,
      caracteristicas: formState.caracteristicasController.text,
      calle: formState.calleController.text,
      numero: formState.numeroController.text,
      colonia: formState.coloniaController.text,
      ciudad: formState.ciudadController.text,
      estadoGeografico: formState.estadoGeograficoController.text,
      codigoPostal: formState.codigoPostalController.text,
      referencias: formState.referenciasController.text,
    );
  }

  // Guardar inmueble en la base de datos y sus imágenes
  Future<int> guardarInmueble() async {
    final inmueble = crearInmuebleDesdeForm();
    final int idInmueble = await _inmuebleController.insertInmueble(inmueble);

    // Si hay imágenes, guardarlas
    if (formState.imagenesTemporal.isNotEmpty) {
      await _guardarImagenesInmueble(idInmueble);
    }

    return idInmueble;
  }

  // Método para guardar las imágenes del inmueble
  Future<void> _guardarImagenesInmueble(int idInmueble) async {
    for (int i = 0; i < formState.imagenesTemporal.length; i++) {
      final File imagen = formState.imagenesTemporal[i];

      // Guardar imagen en almacenamiento
      final rutaRelativa = await _imageService.guardarImagenInmueble(
        imagen,
        idInmueble,
      );

      if (rutaRelativa != null) {
        // Crear objeto para base de datos
        final nuevaImagen = InmuebleImagen(
          idInmueble: idInmueble,
          rutaImagen: rutaRelativa,
          descripcion: 'Imagen de inmueble',
          esPrincipal:
              i ==
              formState
                  .imagenPrincipalIndex, // La primera es la principal por defecto
        );

        // Guardar en base de datos
        await _inmuebleController.agregarImagenInmueble(nuevaImagen);
      }
    }
  }

  // Añadir imagen a la lista temporal
  Future<void> agregarImagen(ImageSource source) async {
    final imagen = await _imageService.cargarImagenDesdeDispositivo(source);
    if (imagen != null) {
      formState.imagenesTemporal.add(imagen);
    }
  }

  // Eliminar imagen de la lista temporal
  void eliminarImagen(int index) {
    if (index >= 0 && index < formState.imagenesTemporal.length) {
      // Si es la imagen principal, ajustar el índice
      if (formState.imagenPrincipalIndex == index) {
        formState.imagenPrincipalIndex =
            formState.imagenesTemporal.isEmpty ? 0 : 0;
      } else if (formState.imagenPrincipalIndex > index) {
        formState.imagenPrincipalIndex--;
      }

      formState.imagenesTemporal.removeAt(index);
    }
  }

  // Establecer imagen principal
  void establecerImagenPrincipal(int index) {
    if (index >= 0 && index < formState.imagenesTemporal.length) {
      formState.imagenPrincipalIndex = index;
    }
  }

  // Validar formulario
  bool validarFormulario() {
    return formState.formKey.currentState?.validate() ?? false;
  }
}

import 'dart:io';
import '../utils/applogger.dart';
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

  bool _procesandoOperacion =
      false; // Control para evitar operaciones duplicadas

  // Cargar clientes disponibles
  Future<void> cargarClientes() async {
    if (_procesandoOperacion) return; // Evitar múltiples llamadas simultáneas

    formState.clientesLoading = true;
    _procesandoOperacion = true;

    try {
      AppLogger.info('Cargando lista de clientes disponibles');
      final clientes = await _clienteController.getClientes();
      formState.clientesDisponibles = clientes;
      AppLogger.info('${clientes.length} clientes cargados correctamente');
    } catch (e, stackTrace) {
      AppLogger.error('Error al cargar clientes', e, stackTrace);
      rethrow;
    } finally {
      formState.clientesLoading = false;
      _procesandoOperacion = false;
    }
  }

  // Crear inmueble a partir del estado actual del formulario
  Inmueble crearInmuebleDesdeForm() {
    try {
      double? precioVenta;
      double? precioRenta;

      if (formState.tipoOperacionSeleccionado == 'venta' ||
          formState.tipoOperacionSeleccionado == 'ambos') {
        precioVenta = double.tryParse(formState.precioVentaController.text);
      }

      if (formState.tipoOperacionSeleccionado == 'renta' ||
          formState.tipoOperacionSeleccionado == 'ambos') {
        precioRenta = double.tryParse(formState.precioRentaController.text);
      }

      AppLogger.debug(
        'Creando objeto inmueble: ${formState.nombreController.text}, '
        'tipo: ${formState.tipoInmuebleSeleccionado}, '
        'operación: ${formState.tipoOperacionSeleccionado}',
      );

      return Inmueble(
        nombre: formState.nombreController.text,
        montoTotal: double.tryParse(formState.montoController.text) ?? 0.0,
        tipoInmueble: formState.tipoInmuebleSeleccionado,
        tipoOperacion: formState.tipoOperacionSeleccionado,
        precioVenta: precioVenta,
        precioRenta: precioRenta,
        idEstado: 3, // Estado disponible por defecto
        idCliente: formState.clienteSeleccionado,
        idEmpleado: formState.empleadoSeleccionado,
        caracteristicas:
            formState.caracteristicasController.text.isEmpty
                ? null
                : formState.caracteristicasController.text,
        calle: formState.calleController.text,
        numero:
            formState.numeroController.text.isEmpty
                ? null
                : formState.numeroController.text,
        colonia:
            formState.coloniaController.text.isEmpty
                ? null
                : formState.coloniaController.text,
        ciudad: formState.ciudadController.text,
        estadoGeografico: formState.estadoGeograficoController.text,
        codigoPostal:
            formState.codigoPostalController.text.isEmpty
                ? null
                : formState.codigoPostalController.text,
        referencias:
            formState.referenciasController.text.isEmpty
                ? null
                : formState.referenciasController.text,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al crear objeto inmueble', e, stackTrace);
      // Retornar un inmueble mínimo en caso de error para evitar null exceptions
      return Inmueble(
        nombre: 'Error',
        montoTotal: 0,
        tipoInmueble: 'casa',
        tipoOperacion: 'venta',
        ciudad: '',
        estadoGeografico: '',
      );
    }
  }

  // Guardar inmueble en la base de datos y sus imágenes
  Future<int> guardarInmueble() async {
    if (_procesandoOperacion) {
      AppLogger.warning('Ya hay una operación de guardado en progreso');
      throw Exception('Operación en progreso, por favor espere');
    }

    _procesandoOperacion = true;

    try {
      AppLogger.info('Iniciando proceso de guardado de inmueble');

      final inmueble = crearInmuebleDesdeForm();
      final int idInmueble = await _inmuebleController.insertInmueble(inmueble);
      AppLogger.info('Inmueble guardado exitosamente con ID: $idInmueble');

      // Si hay imágenes, guardarlas
      if (formState.imagenesTemporal.isNotEmpty) {
        AppLogger.info(
          'Procesando ${formState.imagenesTemporal.length} imágenes para el inmueble',
        );
        await _guardarImagenesInmueble(idInmueble);
      }

      return idInmueble;
    } catch (e, stackTrace) {
      AppLogger.error('Error al guardar inmueble', e, stackTrace);
      rethrow;
    } finally {
      _procesandoOperacion = false;
    }
  }

  // Método para guardar las imágenes del inmueble
  Future<void> _guardarImagenesInmueble(int idInmueble) async {
    int imagenesGuardadas = 0;
    int errores = 0;

    AppLogger.info(
      'Iniciando guardado de ${formState.imagenesTemporal.length} imágenes',
    );

    for (int i = 0; i < formState.imagenesTemporal.length; i++) {
      try {
        final File imagen = formState.imagenesTemporal[i];

        // Verificar que el archivo existe y es válido
        if (!await imagen.exists() || await imagen.length() == 0) {
          AppLogger.warning('Imagen inválida o inexistente en posición $i');
          errores++;
          continue;
        }

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
            esPrincipal: i == formState.imagenPrincipalIndex,
          );

          // Guardar en base de datos usando el procedimiento almacenado AgregarImagenInmueble
          final idImagen = await _inmuebleController.agregarImagenInmueble(
            nuevaImagen,
          );
          AppLogger.info('Imagen guardada con ID: $idImagen');
          imagenesGuardadas++;
        } else {
          AppLogger.warning('No se pudo guardar la imagen en posición $i');
          errores++;
        }
      } catch (e, stackTrace) {
        AppLogger.error('Error al guardar imagen #$i', e, stackTrace);
        errores++;
      }
    }

    AppLogger.info(
      'Proceso de guardado de imágenes finalizado. '
      'Guardadas: $imagenesGuardadas, Errores: $errores',
    );
  }

  // Añadir imagen a la lista temporal
  Future<void> agregarImagen(ImageSource source) async {
    try {
      AppLogger.info('Cargando imagen desde: ${source.toString()}');
      final imagen = await _imageService.cargarImagenDesdeDispositivo(source);

      if (imagen != null) {
        formState.imagenesTemporal.add(imagen);
        AppLogger.info(
          'Imagen añadida a la lista temporal (total: ${formState.imagenesTemporal.length})',
        );
      } else {
        AppLogger.info(
          'El usuario canceló la selección de imagen o hubo un error',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error al agregar imagen', e, stackTrace);
    }
  }

  // Eliminar imagen de la lista temporal
  void eliminarImagen(int index) {
    try {
      if (index < 0 || index >= formState.imagenesTemporal.length) {
        AppLogger.warning(
          'Intento de eliminar imagen con índice fuera de rango: $index',
        );
        return;
      }

      // Si es la imagen principal, ajustar el índice
      if (formState.imagenPrincipalIndex == index) {
        formState.imagenPrincipalIndex =
            formState.imagenesTemporal.isEmpty ? 0 : 0;
        AppLogger.info('Reajustando índice de imagen principal a 0');
      } else if (formState.imagenPrincipalIndex > index) {
        formState.imagenPrincipalIndex--;
        AppLogger.info(
          'Reajustando índice de imagen principal a ${formState.imagenPrincipalIndex}',
        );
      }

      formState.imagenesTemporal.removeAt(index);
      AppLogger.info(
        'Imagen eliminada en posición $index (restantes: ${formState.imagenesTemporal.length})',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al eliminar imagen', e, stackTrace);
    }
  }

  // Establecer imagen principal
  void establecerImagenPrincipal(int index) {
    try {
      if (index < 0 || index >= formState.imagenesTemporal.length) {
        AppLogger.warning(
          'Intento de establecer como principal una imagen con índice fuera de rango: $index',
        );
        return;
      }

      formState.imagenPrincipalIndex = index;
      AppLogger.info('Imagen en posición $index establecida como principal');
    } catch (e, stackTrace) {
      AppLogger.error('Error al establecer imagen principal', e, stackTrace);
    }
  }

  // Validar formulario
  bool validarFormulario() {
    try {
      final esValido = formState.formKey.currentState?.validate() ?? false;
      AppLogger.info(
        'Validación de formulario: ${esValido ? 'exitosa' : 'fallida'}',
      );
      return esValido;
    } catch (e, stackTrace) {
      AppLogger.error('Error al validar formulario', e, stackTrace);
      return false;
    }
  }

  // Liberar recursos cuando el controlador ya no se necesita
  void dispose() {
    try {
      // Liberar los controladores de texto y otros recursos si es necesario
      AppLogger.info('Liberando recursos de InmuebleFormController');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al liberar recursos del controlador',
        e,
        stackTrace,
      );
    }
  }
}

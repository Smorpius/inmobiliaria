import 'dart:io';
import 'dart:async';
import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../models/inmueble_imagen.dart';
import '../services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/inmueble_controller.dart';
import '../utils/app_colors.dart'; // Agregando AppColors

class ImagenSelectorWidget extends StatefulWidget {
  final int idInmueble;
  final Function() onImagenCargada;

  const ImagenSelectorWidget({
    super.key,
    required this.idInmueble,
    required this.onImagenCargada,
  });

  @override
  State<ImagenSelectorWidget> createState() => _ImagenSelectorWidgetState();
}

class _ImagenSelectorWidgetState extends State<ImagenSelectorWidget> {
  final ImageService _imageService = ImageService();
  final InmuebleController _inmuebleController = InmuebleController();
  final TextEditingController _descripcionController = TextEditingController();

  // Variables de estado
  bool _cargando = false;
  File? _imagenSeleccionada;
  bool _operacionEnProceso = false;
  String? _errorMensaje;

  // Constante para tiempo de espera máximo
  static const Duration _timeoutDuration = Duration(seconds: 30);

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  /// Selecciona una imagen de la cámara o galería con mejor manejo de errores y estados
  Future<void> _seleccionarImagen(ImageSource source) async {
    // Evitar operaciones duplicadas
    if (_operacionEnProceso) {
      _mostrarSnackbar('Hay una operación en curso, por favor espere');
      return;
    }

    try {
      setState(() {
        _cargando = true;
        _operacionEnProceso = true;
        _errorMensaje = null;
      });

      // Usar timeout para evitar que la operación se bloquee indefinidamente
      final imagen = await _imageService
          .cargarImagenDesdeDispositivo(source)
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              throw TimeoutException(
                'La selección de imagen tardó demasiado tiempo',
              );
            },
          );

      // Verificar si el widget todavía está montado antes de actualizar el estado
      if (!mounted) return;

      if (imagen != null) {
        // Validar tamaño de la imagen (máximo 10MB)
        final tamanoBytes = await imagen.length();
        if (tamanoBytes > 10 * 1024 * 1024) {
          throw Exception('La imagen es demasiado grande (máximo 10MB)');
        }

        setState(() {
          _imagenSeleccionada = imagen;
          _errorMensaje = null;
        });
      }
    } catch (e, stackTrace) {
      if (!mounted) return;

      AppLogger.error('Error al seleccionar imagen', e, stackTrace);
      setState(() {
        _errorMensaje = _formatearMensajeError(e);
      });
      _mostrarSnackbar('Error al seleccionar imagen: $_errorMensaje');
    } finally {
      // Asegurar que el estado de carga se actualice incluso si hay errores
      if (mounted) {
        setState(() {
          _cargando = false;
          _operacionEnProceso = false;
        });
      }
    }
  }

  /// Guarda la imagen con control de operaciones concurrentes y mejor manejo de errores
  Future<void> _guardarImagen() async {
    // Validaciones iniciales
    if (_imagenSeleccionada == null) {
      _mostrarSnackbar('No hay imagen seleccionada');
      return;
    }

    if (_operacionEnProceso) {
      _mostrarSnackbar('Hay una operación en curso, por favor espere');
      return;
    }

    if (widget.idInmueble <= 0) {
      _mostrarSnackbar('ID de inmueble inválido');
      return;
    }

    try {
      setState(() {
        _cargando = true;
        _operacionEnProceso = true;
        _errorMensaje = null;
      });

      // Paso 1: Guardar imagen en almacenamiento con timeout
      final rutaRelativa = await _imageService
          .guardarImagenInmueble(_imagenSeleccionada!, widget.idInmueble)
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              throw TimeoutException(
                'Tiempo de espera agotado al guardar la imagen',
              );
            },
          );

      // Verificar si el widget sigue montado después de operación asíncrona
      if (!mounted) return;

      // Validar resultado del guardado
      if (rutaRelativa == null || rutaRelativa.isEmpty) {
        throw Exception('No se pudo guardar la imagen en el almacenamiento');
      }

      // Paso 2: Crear modelo de imagen para BD
      final nuevaImagen = InmuebleImagen(
        idInmueble: widget.idInmueble,
        rutaImagen: rutaRelativa,
        descripcion: _descripcionController.text.trim(),
        esPrincipal: false, // Por defecto no es principal
        fechaCarga: DateTime.now(),
      );

      // Paso 3: Guardar información en la base de datos con timeout
      final idImagen = await _inmuebleController
          .agregarImagenInmueble(nuevaImagen)
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              throw TimeoutException(
                'Tiempo de espera agotado al registrar imagen en base de datos',
              );
            },
          );

      // Verificar si el widget sigue montado después de la segunda operación asíncrona
      if (!mounted) return;

      // Verificar resultado del registro en BD
      if (idImagen <= 0) {
        throw Exception('Error al registrar la imagen en la base de datos');
      }

      _mostrarSnackbar('Imagen cargada correctamente');
      widget.onImagenCargada(); // Notificar que se cargó una imagen

      // Limpiar selección solo en caso de éxito
      _limpiarSeleccion();
    } catch (e, stackTrace) {
      // Verificar si el widget sigue montado antes de actualizar estado
      if (!mounted) return;

      AppLogger.error('Error al guardar imagen', e, stackTrace);
      setState(() {
        _errorMensaje = _formatearMensajeError(e);
      });
      _mostrarSnackbar('Error al guardar imagen: $_errorMensaje');
    } finally {
      // Asegurar que el estado de carga se actualice incluso si hay errores
      if (mounted) {
        setState(() {
          _cargando = false;
          _operacionEnProceso = false;
        });
      }
    }
  }

  /// Limpia la selección actual
  void _limpiarSeleccion() {
    setState(() {
      _imagenSeleccionada = null;
      _descripcionController.clear();
      _errorMensaje = null;
    });
  }

  /// Formatea el mensaje de error para hacerlo más amigable
  String _formatearMensajeError(dynamic error) {
    final mensaje = error.toString();

    // Si es timeout, mostrar mensaje claro
    if (error is TimeoutException) {
      return 'La operación tardó demasiado tiempo. Intente de nuevo.';
    }

    // Si contiene mensajes de excepciones específicas, extraer la parte relevante
    if (mensaje.contains('Exception:')) {
      final parts = mensaje.split('Exception:');
      return parts.last.trim();
    }

    // Limitar longitud del mensaje para evitar desbordamientos en UI
    if (mensaje.length > 100) {
      return '${mensaje.substring(0, 100)}...';
    }

    return mensaje;
  }

  /// Muestra un snackbar de manera segura verificando que el widget esté montado
  void _mostrarSnackbar(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título con contador de operaciones
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Agregar nueva imagen',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_operacionEnProceso)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Mensaje de error si existe
            if (_errorMensaje != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.withAlpha(AppColors.error, 50),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.withAlpha(AppColors.error, 200),
                  ),
                ),
                child: Text(
                  _errorMensaje!,
                  style: TextStyle(color: AppColors.error),
                ),
              ),

            // Selector de imágenes o vista previa
            if (_imagenSeleccionada == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _cargando
                            ? null
                            : () => _seleccionarImagen(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        _cargando
                            ? null
                            : () => _seleccionarImagen(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  // Vista previa de imagen con optimización para evitar congelamientos
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _imagenSeleccionada!,
                        fit: BoxFit.contain,
                        frameBuilder: (
                          context,
                          child,
                          frame,
                          wasSynchronouslyLoaded,
                        ) {
                          if (wasSynchronouslyLoaded) return child;
                          return frame != null
                              ? child
                              : const Center(
                                child: CircularProgressIndicator(),
                              );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          AppLogger.error(
                            'Error al mostrar imagen',
                            error,
                            stackTrace,
                          );
                          return const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.red,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción de la imagen',
                      border: OutlineInputBorder(),
                      hintText: 'Describa brevemente la imagen',
                    ),
                    maxLines: 2,
                    maxLength: 200, // Limitar longitud para evitar problemas
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed:
                            _operacionEnProceso ? null : _limpiarSeleccion,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancelar'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _operacionEnProceso ? null : _guardarImagen,
                        icon:
                            _cargando
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.save),
                        label: Text(_cargando ? 'Guardando...' : 'Guardar'),
                      ),
                    ],
                  ),
                ],
              ),

            // Indicador de carga general
            if (_cargando && _imagenSeleccionada == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

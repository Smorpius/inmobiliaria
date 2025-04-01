import 'inmueble_image_item.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/inmueble_imagen.dart';
import '../../../services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/inmueble_controller.dart';

class InmuebleImageGallery extends StatefulWidget {
  final int? inmuebleId;
  final List<InmuebleImagen> imagenes;
  final bool isLoading;
  final ImageService imageService;
  final InmuebleController inmuebleController;
  final Function(List<InmuebleImagen>) onImagenesUpdated;

  const InmuebleImageGallery({
    super.key,
    required this.inmuebleId,
    required this.imagenes,
    required this.isLoading,
    required this.imageService,
    required this.inmuebleController,
    required this.onImagenesUpdated,
  });

  @override
  State<InmuebleImageGallery> createState() => _InmuebleImageGalleryState();
}

class _InmuebleImageGalleryState extends State<InmuebleImageGallery> {
  // Control para evitar operaciones duplicadas y mensajes de error repetitivos
  bool _procesandoOperacion = false;

  // Control para limitar operaciones simultáneas
  final _operacionesSemaforo = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Imágenes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (!widget.isLoading)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Añadir'),
                    onPressed:
                        _estaProcesoActivo('general') ? null : _agregarImagen,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (widget.imagenes.isEmpty)
              _buildNoImagesPlaceholder()
            else
              _buildImageGallery(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoImagesPlaceholder() {
    return Container(
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No hay imágenes disponibles',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: widget.imagenes.length,
      itemBuilder: (context, index) {
        final imagen = widget.imagenes[index];
        return InmuebleImageItem(
          imagen: imagen,
          imageService: widget.imageService,
          onTap: () => _showImagenOpciones(imagen),
          onDelete: () => _eliminarImagen(imagen),
        );
      },
    );
  }

  void _agregarImagen() {
    if (_activarProceso('general')) {
      showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _seleccionarImagen(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Seleccionar de galería'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _seleccionarImagen(ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        },
      ).whenComplete(() => _desactivarProceso('general'));
    }
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    if (!_activarProceso('seleccionImagen')) return;

    try {
      if (widget.inmuebleId == null) {
        if (!mounted) return;
        AppLogger.warning('Intento de agregar imagen a un inmueble sin ID');
        _mostrarSnackbar('Guarde el inmueble antes de agregar imágenes');
        return;
      }

      AppLogger.info(
        'Seleccionando imagen para inmueble ID: ${widget.inmuebleId}',
      );
      final imagen = await widget.imageService.cargarImagenDesdeDispositivo(
        source,
      );

      if (imagen == null || !mounted) {
        AppLogger.info(
          'Usuario canceló la selección de imagen o widget desmontado',
        );
        return;
      }

      // Verificar si la imagen es válida
      if (!await imagen.exists() || await imagen.length() == 0) {
        if (!mounted) return;
        _mostrarSnackbar('La imagen seleccionada no es válida');
        return;
      }

      // Si es la primera imagen, se marca como principal
      final esPrincipal = widget.imagenes.isEmpty;
      AppLogger.info(
        'Guardando imagen para inmueble ID: ${widget.inmuebleId}, principal: $esPrincipal',
      );

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardando imagen...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Guardar imagen en almacenamiento
      final rutaRelativa = await widget.imageService.guardarImagenInmueble(
        imagen,
        widget.inmuebleId!,
      );

      if (rutaRelativa == null || !mounted) {
        if (mounted) {
          AppLogger.error(
            'Error al guardar imagen para inmueble ID: ${widget.inmuebleId}',
            null,
            StackTrace.current,
          );
          _mostrarSnackbar('Error al guardar la imagen');
        }
        return;
      }

      // Crear objeto para base de datos
      final nuevaImagen = InmuebleImagen(
        idInmueble: widget.inmuebleId!,
        rutaImagen: rutaRelativa,
        descripcion: 'Imagen del inmueble',
        esPrincipal: esPrincipal,
      );

      // Guardar en base de datos usando el procedimiento almacenado a través del controlador
      final idImagen = await widget.inmuebleController.agregarImagenInmueble(
        nuevaImagen,
      );

      if (idImagen > 0 && mounted) {
        AppLogger.info('Imagen guardada exitosamente con ID: $idImagen');

        // Recargar imágenes después de agregar una nueva
        if (widget.inmuebleId != null) {
          final imagenesFrescas = await widget.inmuebleController
              .getImagenesInmueble(widget.inmuebleId!);

          if (mounted) {
            widget.onImagenesUpdated(imagenesFrescas);
            _mostrarSnackbar('Imagen agregada correctamente');
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error al agregar imagen', e, stackTrace);
      if (mounted) {
        _mostrarSnackbar(
          'Error al agregar imagen: ${e.toString().split('\n').first}',
        );
      }
    } finally {
      _desactivarProceso('seleccionImagen');
    }
  }

  Future<void> _eliminarImagen(InmuebleImagen imagen) async {
    if (!_activarProceso('eliminarImagen_${imagen.id}')) return;

    try {
      // Validar que la imagen tiene un ID
      if (imagen.id == null) {
        AppLogger.warning('Intento de eliminar una imagen sin ID');
        if (mounted) {
          _mostrarSnackbar('No se puede eliminar una imagen sin ID');
        }
        return;
      }

      // Confirmar eliminación
      if (!mounted) return;
      final confirmar = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Eliminar imagen'),
              content: const Text(
                '¿Está seguro que desea eliminar esta imagen?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
      );

      if (confirmar != true || !mounted) return;

      AppLogger.info('Eliminando imagen ID: ${imagen.id}');

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eliminando imagen...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Primero eliminar la imagen físicamente usando ImageService
      final eliminadaArchivo = await widget.imageService.eliminarImagenInmueble(
        imagen.rutaImagen,
      );
      if (!eliminadaArchivo) {
        AppLogger.warning(
          'No se pudo eliminar el archivo: ${imagen.rutaImagen}',
        );
      }

      // Luego eliminar de la base de datos usando el procedimiento almacenado a través del controlador
      final eliminado = await widget.inmuebleController.eliminarImagenInmueble(
        imagen.id!,
      );

      if (!mounted) return;

      if (eliminado) {
        AppLogger.info('Imagen ID: ${imagen.id} eliminada correctamente');

        // Recargar imágenes
        if (widget.inmuebleId != null) {
          final imagenesFrescas = await widget.inmuebleController
              .getImagenesInmueble(widget.inmuebleId!);

          if (mounted) {
            widget.onImagenesUpdated(imagenesFrescas);
            _mostrarSnackbar('Imagen eliminada correctamente');
          }
        }
      } else {
        AppLogger.warning(
          'No se pudo eliminar la imagen ID: ${imagen.id} de la base de datos',
        );
        if (mounted) {
          _mostrarSnackbar('Error al eliminar la imagen de la base de datos');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error al eliminar imagen', e, stackTrace);
      if (mounted) {
        _mostrarSnackbar(
          'Error al eliminar imagen: ${e.toString().split('\n').first}',
        );
      }
    } finally {
      _desactivarProceso('eliminarImagen_${imagen.id}');
    }
  }

  Future<void> _showImagenOpciones(InmuebleImagen imagen) async {
    if (!_activarProceso('opciones_${imagen.id}')) return;

    try {
      if (imagen.id == null) {
        AppLogger.warning('Intento de mostrar opciones para imagen sin ID');
        return;
      }

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Establecer como imagen principal'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _marcarComoPrincipal(imagen);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Editar descripción'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _editarDescripcion(imagen);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Eliminar imagen',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _eliminarImagen(imagen);
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al mostrar opciones de imagen', e, stackTrace);
    } finally {
      _desactivarProceso('opciones_${imagen.id}');
    }
  }

  Future<void> _marcarComoPrincipal(InmuebleImagen imagen) async {
    if (!_activarProceso('marcarPrincipal_${imagen.id}')) return;

    try {
      if (imagen.id == null) {
        AppLogger.warning('Intento de marcar como principal una imagen sin ID');
        return;
      }

      if (imagen.esPrincipal) {
        AppLogger.info('La imagen ID: ${imagen.id} ya es la imagen principal');
        if (mounted) {
          _mostrarSnackbar('Esta imagen ya es la principal');
        }
        return;
      }

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualizando imagen principal...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      AppLogger.info('Marcando imagen ID: ${imagen.id} como principal');
      final actualizado = await widget.inmuebleController
          .marcarImagenComoPrincipal(imagen.id!, imagen.idInmueble);

      if (!mounted) return;

      if (actualizado && widget.inmuebleId != null) {
        AppLogger.info('Imagen principal actualizada correctamente');

        final imagenesFrescas = await widget.inmuebleController
            .getImagenesInmueble(widget.inmuebleId!);

        if (mounted) {
          widget.onImagenesUpdated(imagenesFrescas);
          _mostrarSnackbar('Imagen principal actualizada');
        }
      } else {
        if (mounted) {
          _mostrarSnackbar('No se pudo actualizar la imagen principal');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error al establecer imagen principal', e, stackTrace);
      if (mounted) {
        _mostrarSnackbar(
          'Error al establecer imagen principal: ${e.toString().split('\n').first}',
        );
      }
    } finally {
      _desactivarProceso('marcarPrincipal_${imagen.id}');
    }
  }

  Future<void> _editarDescripcion(InmuebleImagen imagen) async {
    if (!_activarProceso('editarDescripcion_${imagen.id}')) return;

    try {
      if (imagen.id == null) {
        AppLogger.warning('Intento de editar descripción de imagen sin ID');
        return;
      }

      if (!mounted) return;

      final controllerDescripcion = TextEditingController(
        text: imagen.descripcion ?? '',
      );

      final nuevaDescripcion = await showDialog<String>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Editar descripción'),
              content: TextField(
                controller: controllerDescripcion,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100, // Limitando a 100 caracteres según el modelo
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.of(ctx).pop(controllerDescripcion.text),
                  child: const Text('Guardar'),
                ),
              ],
            ),
      );

      // Si se canceló o no hubo cambios, no hacemos nada
      if (nuevaDescripcion == null ||
          nuevaDescripcion.trim() == (imagen.descripcion ?? '').trim() ||
          !mounted) {
        return;
      }

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualizando descripción...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      AppLogger.info('Actualizando descripción de imagen ID: ${imagen.id}');
      final actualizado = await widget.inmuebleController
          .actualizarDescripcionImagen(imagen.id!, nuevaDescripcion.trim());

      if (!mounted) return;

      if (actualizado && widget.inmuebleId != null) {
        AppLogger.info('Descripción de imagen actualizada correctamente');

        final imagenesFrescas = await widget.inmuebleController
            .getImagenesInmueble(widget.inmuebleId!);

        if (mounted) {
          widget.onImagenesUpdated(imagenesFrescas);
          _mostrarSnackbar('Descripción actualizada');
        }
      } else {
        if (mounted) {
          _mostrarSnackbar('No se pudo actualizar la descripción');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al actualizar descripción de imagen',
        e,
        stackTrace,
      );
      if (mounted) {
        _mostrarSnackbar(
          'Error al actualizar descripción: ${e.toString().split('\n').first}',
        );
      }
    } finally {
      _desactivarProceso('editarDescripcion_${imagen.id}');
    }
  }

  // Método para mostrar SnackBar con verificación de estado mounted
  void _mostrarSnackbar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // Control de operaciones concurrentes por tipo
  bool _activarProceso(String tipo) {
    if (_operacionesSemaforo[tipo] == true) {
      AppLogger.info(
        'Operación "$tipo" ya en proceso, ignorando solicitud duplicada',
      );
      return false;
    }
    _operacionesSemaforo[tipo] = true;
    _procesandoOperacion = true;
    return true;
  }

  void _desactivarProceso(String tipo) {
    _operacionesSemaforo[tipo] = false;
    // Verificar si todas las operaciones han terminado
    _procesandoOperacion = _operacionesSemaforo.values.any((activo) => activo);
  }

  bool _estaProcesoActivo(String tipo) {
    return _operacionesSemaforo[tipo] == true || _procesandoOperacion;
  }
}

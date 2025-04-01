import 'dart:io';
import 'dart:async';
import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../models/inmueble_imagen.dart';
import '../services/image_service.dart';
import '../controllers/inmueble_controller.dart';
import '../vistas/inmuebles/galeria_pantalla_completa.dart';

class GaleriaImagenesWidget extends StatefulWidget {
  final int idInmueble;
  final bool permitirEdicion;
  final Function()? onImagenesActualizadas;

  const GaleriaImagenesWidget({
    super.key,
    required this.idInmueble,
    this.permitirEdicion = true,
    this.onImagenesActualizadas,
  });

  @override
  State<GaleriaImagenesWidget> createState() => _GaleriaImagenesWidgetState();
}

class _GaleriaImagenesWidgetState extends State<GaleriaImagenesWidget> {
  // Controlador con inyección de dependencia para facilitar testing
  late final InmuebleController _inmuebleController;
  late final ImageService _imageService;

  // Gestión de estado con valores por defecto para evitar nulos
  List<InmuebleImagen> _imagenes = [];
  bool _cargando = true;
  bool _error = false;
  String _errorMensaje = '';
  int _imagenActual = 0;

  // Para evitar operaciones duplicadas
  bool _operacionEnProceso = false;

  // Caché de rutas de imágenes para mejorar rendimiento
  final Map<String, String> _rutasImagenesCache = {};

  // Control de timeouts para operaciones
  final Duration _timeoutOperaciones = const Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    // Inicializar controladores
    _inmuebleController = InmuebleController();
    _imageService = ImageService();

    // Cargar datos iniciales con retraso mínimo para permitir que el widget se monte
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarImagenes();
    });
  }

  /// Carga las imágenes del inmueble con manejo de errores mejorado
  Future<void> _cargarImagenes() async {
    // Evitar múltiples cargas simultáneas
    if (_operacionEnProceso) return;

    _operacionEnProceso = true;

    if (mounted) {
      setState(() {
        _cargando = true;
        _error = false;
      });
    }

    try {
      // Usar timeout para evitar operaciones bloqueadas indefinidamente
      final imagenes = await _inmuebleController
          .getImagenesInmueble(widget.idInmueble)
          .timeout(
            _timeoutOperaciones,
            onTimeout: () {
              throw TimeoutException(
                'Tiempo de espera agotado al cargar imágenes',
              );
            },
          );

      // Verificar que el widget siga montado antes de actualizar el estado
      if (!mounted) return;

      // Setear el estado una sola vez para optimizar rendimiento
      setState(() {
        _imagenes = imagenes;
        _cargando = false;

        // Resetear índice si es necesario
        if (_imagenActual >= imagenes.length && imagenes.isNotEmpty) {
          _imagenActual = 0;
        }
      });
    } catch (e) {
      AppLogger.error(
        'Error al cargar imágenes del inmueble ${widget.idInmueble}',
        e,
        StackTrace.current,
      );

      if (!mounted) return;

      final esErrorConexion =
          e.toString().contains('socket') ||
          e.toString().contains('connection') ||
          e.toString().contains('closed') ||
          e.toString().contains('timeout');

      setState(() {
        _cargando = false;
        _error = true;
        _errorMensaje =
            esErrorConexion
                ? 'Error de conexión con la base de datos. Intente más tarde.'
                : 'Error al cargar imágenes: ${e.toString().split('\n')[0]}';
      });

      _mostrarSnackbar(_errorMensaje);
    } finally {
      _operacionEnProceso = false;
    }
  }

  /// Obtiene la ruta completa de una imagen con caché
  Future<String?> _obtenerRutaImagen(String rutaRelativa) async {
    // Verificar primero en la caché local
    if (_rutasImagenesCache.containsKey(rutaRelativa)) {
      final rutaCompleta = _rutasImagenesCache[rutaRelativa];
      if (rutaCompleta != null && await File(rutaCompleta).exists()) {
        return rutaCompleta;
      }
      // Si la ruta en caché ya no existe, eliminarla de la caché
      _rutasImagenesCache.remove(rutaRelativa);
    }

    // Si no está en caché, obtenerla del servicio
    try {
      final rutaCompleta = await _imageService.obtenerRutaCompletaImagen(
        rutaRelativa,
      );
      if (rutaCompleta != null) {
        // Guardar en caché local
        _rutasImagenesCache[rutaRelativa] = rutaCompleta;
      }
      return rutaCompleta;
    } catch (e) {
      AppLogger.error('Error al obtener ruta de imagen: $rutaRelativa', e);
      return null;
    }
  }

  /// Marca una imagen como principal con manejo de errores mejorado
  Future<void> _marcarComoPrincipal(InmuebleImagen imagen) async {
    if (_operacionEnProceso) {
      _mostrarSnackbar('Por favor espere, hay una operación en curso');
      return;
    }

    _operacionEnProceso = true;

    if (mounted) {
      setState(() => _cargando = true);
    }

    try {
      // Verificar que la imagen tenga un ID válido
      if (imagen.id == null || imagen.id! <= 0) {
        throw Exception('La imagen no tiene un ID válido');
      }

      await _inmuebleController
          .marcarImagenComoPrincipal(imagen.id!, widget.idInmueble)
          .timeout(
            _timeoutOperaciones,
            onTimeout: () {
              throw TimeoutException(
                'Tiempo de espera agotado al marcar imagen como principal',
              );
            },
          );

      if (!mounted) return;

      // Notificar cambios
      _mostrarSnackbar('Imagen establecida como principal');

      // Actualizar vista
      if (widget.onImagenesActualizadas != null) {
        widget.onImagenesActualizadas!();
      }

      // Recargar imágenes para reflejar el cambio
      await _cargarImagenes();
    } catch (e) {
      AppLogger.error(
        'Error al marcar imagen como principal',
        e,
        StackTrace.current,
      );

      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = true;
        _errorMensaje =
            'Error al establecer imagen principal: ${e.toString().split('\n')[0]}';
      });

      _mostrarSnackbar(_errorMensaje);
    } finally {
      if (mounted) {
        setState(() => _operacionEnProceso = false);
      } else {
        _operacionEnProceso = false;
      }
    }
  }

  /// Elimina una imagen con confirmación y manejo de errores mejorado
  Future<void> _eliminarImagen(InmuebleImagen imagen) async {
    // Evitar operaciones duplicadas
    if (_operacionEnProceso) {
      _mostrarSnackbar('Por favor espere, hay una operación en curso');
      return;
    }

    // Solicitar confirmación
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar imagen'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta imagen? Esta acción no se puede deshacer.',
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

    // Verificar que el widget aún esté montado
    if (!mounted) return;

    // Proceder con la eliminación si fue confirmado
    if (confirmado == true && imagen.id != null) {
      _operacionEnProceso = true;

      setState(() => _cargando = true);

      try {
        // Primero intentar eliminar físicamente la imagen
        if (imagen.rutaImagen.isNotEmpty) {
          try {
            await _imageService
                .eliminarImagenInmueble(imagen.rutaImagen)
                .timeout(const Duration(seconds: 5));
          } catch (e) {
            AppLogger.warning(
              'No se pudo eliminar el archivo físico: ${imagen.rutaImagen}. '
              'Continuando con la eliminación del registro.',
            );
          }
        }

        // Luego eliminar el registro de la base de datos
        await _inmuebleController
            .eliminarImagenInmueble(imagen.id!)
            .timeout(
              _timeoutOperaciones,
              onTimeout: () {
                throw TimeoutException(
                  'Tiempo de espera agotado al eliminar imagen',
                );
              },
            );

        if (!mounted) return;

        // Notificar éxito
        _mostrarSnackbar('Imagen eliminada correctamente');

        // Notificar actualización
        if (widget.onImagenesActualizadas != null) {
          widget.onImagenesActualizadas!();
        }

        // Actualizar la vista
        await _cargarImagenes();
      } catch (e) {
        AppLogger.error('Error al eliminar imagen', e, StackTrace.current);

        if (!mounted) return;

        setState(() {
          _cargando = false;
          _error = true;
          _errorMensaje =
              'Error al eliminar imagen: ${e.toString().split('\n')[0]}';
        });

        _mostrarSnackbar(_errorMensaje);
      } finally {
        if (mounted) {
          setState(() => _operacionEnProceso = false);
        } else {
          _operacionEnProceso = false;
        }
      }
    }
  }

  /// Edita la descripción de una imagen con validación
  Future<void> _editarDescripcion(InmuebleImagen imagen) async {
    // Evitar operaciones duplicadas
    if (_operacionEnProceso) {
      _mostrarSnackbar('Por favor espere, hay una operación en curso');
      return;
    }

    // Controlador para el campo de texto
    final TextEditingController controller = TextEditingController(
      text: imagen.descripcion ?? '',
    );

    // Diálogo para editar la descripción
    final nuevaDescripcion = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar descripción'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                ),
                const SizedBox(height: 8),
                const Text(
                  'La descripción ayuda a identificar la imagen y es útil para accesibilidad',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  final texto = controller.text.trim();
                  Navigator.of(context).pop(texto.isNotEmpty ? texto : null);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    // Verificar que el widget aún esté montado
    if (!mounted) return;

    // Proceder con la actualización si hay cambios
    if (nuevaDescripcion != null &&
        nuevaDescripcion != imagen.descripcion &&
        imagen.id != null) {
      _operacionEnProceso = true;

      setState(() => _cargando = true);

      try {
        await _inmuebleController
            .actualizarDescripcionImagen(imagen.id!, nuevaDescripcion)
            .timeout(
              _timeoutOperaciones,
              onTimeout: () {
                throw TimeoutException(
                  'Tiempo de espera agotado al actualizar descripción',
                );
              },
            );

        if (!mounted) return;

        // Mostrar mensaje de éxito
        _mostrarSnackbar('Descripción actualizada correctamente');

        // Actualizar la vista
        await _cargarImagenes();
      } catch (e) {
        AppLogger.error(
          'Error al actualizar descripción',
          e,
          StackTrace.current,
        );

        if (!mounted) return;

        setState(() {
          _cargando = false;
          _error = true;
          _errorMensaje =
              'Error al actualizar descripción: ${e.toString().split('\n')[0]}';
        });

        _mostrarSnackbar(_errorMensaje);
      } finally {
        if (mounted) {
          setState(() => _operacionEnProceso = false);
        } else {
          _operacionEnProceso = false;
        }
      }
    }
  }

  /// Muestra un SnackBar de forma segura verificando el contexto
  void _mostrarSnackbar(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Verifica si una imagen es la principal
  bool _esPrincipal(InmuebleImagen imagen) {
    return imagen.esPrincipal == true;
  }

  /// Abre la galería en pantalla completa
  void _verEnPantallaCompleta() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => GaleriaPantallaCompleta(
              idInmueble: widget.idInmueble,
              initialIndex: _imagenActual,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Caso de carga inicial
    if (_cargando && _imagenes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando imágenes...'),
          ],
        ),
      );
    }

    // Caso de error sin datos
    if (_error && _imagenes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMensaje),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarImagenes,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Caso sin imágenes disponibles
    if (_imagenes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('No hay imágenes disponibles para este inmueble'),
            ],
          ),
        ),
      );
    }

    // Caso con imágenes disponibles
    final imagenActual = _imagenes[_imagenActual];

    return Column(
      children: [
        // Indicador de carga superpuesto cuando sea necesario
        if (_cargando) const LinearProgressIndicator(),

        // Visor de imagen principal
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen principal con soporte para zoom
              Hero(
                tag: 'imagen_${widget.idInmueble}_${imagenActual.id}',
                child: FutureBuilder<String?>(
                  future: _obtenerRutaImagen(imagenActual.rutaImagen),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || snapshot.data == null) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'Error: ${snapshot.error ?? 'Imagen no disponible'}',
                            ),
                          ],
                        ),
                      );
                    }

                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Image.file(
                        File(snapshot.data!),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          AppLogger.error(
                            'Error al cargar imagen ${imagenActual.rutaImagen}',
                            error,
                            stackTrace,
                          );
                          return const Icon(Icons.broken_image, size: 80);
                        },
                      ),
                    );
                  },
                ),
              ),

              // Indicador de imagen principal
              if (_esPrincipal(imagenActual))
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha((255 * 0.8).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 18, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Principal',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Descripción de la imagen
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            imagenActual.descripcion ?? 'Sin descripción',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),

        // Botón para ver en pantalla completa
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: _verEnPantallaCompleta,
            icon: const Icon(Icons.fullscreen),
            label: const Text('Ver pantalla completa'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ),

        // Controles para imágenes cuando se permite edición
        if (widget.permitirEdicion)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_esPrincipal(imagenActual))
                  ElevatedButton.icon(
                    onPressed:
                        _operacionEnProceso
                            ? null
                            : () => _marcarComoPrincipal(imagenActual),
                    icon: const Icon(Icons.star),
                    label: const Text('Marcar como principal'),
                  ),
                if (_esPrincipal(imagenActual))
                  const Chip(
                    avatar: Icon(Icons.star, color: Colors.amber),
                    label: Text('Imagen principal'),
                    backgroundColor: Color(0x33FFC107), // Amber con opacidad
                  ),
                IconButton(
                  onPressed:
                      _operacionEnProceso
                          ? null
                          : () => _editarDescripcion(imagenActual),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar descripción',
                ),
                IconButton(
                  onPressed:
                      _operacionEnProceso
                          ? null
                          : () => _eliminarImagen(imagenActual),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  tooltip: 'Eliminar imagen',
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Carrusel de miniaturas
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imagenes.length,
            itemBuilder: (context, index) {
              final imagen = _imagenes[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () {
                    if (_imagenActual != index) {
                      setState(() {
                        _imagenActual = index;
                      });
                    }
                  },
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            _imagenActual == index
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                        width: _imagenActual == index ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Miniatura de imagen con caché
                        FutureBuilder<String?>(
                          future: _obtenerRutaImagen(imagen.rutaImagen),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError || snapshot.data == null) {
                              return const Center(
                                child: Icon(Icons.broken_image, size: 24),
                              );
                            }

                            return Image.file(
                              File(snapshot.data!),
                              fit: BoxFit.cover,
                              cacheWidth: 160, // Optimización para miniaturas
                              errorBuilder:
                                  (context, error, _) =>
                                      const Icon(Icons.broken_image, size: 24),
                            );
                          },
                        ),

                        // Indicador de imagen principal
                        if (_esPrincipal(imagen))
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              color: Colors.amber.withAlpha(179),
                              child: const Icon(
                                Icons.star,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // No es necesario liberar _inmuebleController ni _imageService
    // ya que son servicios globales gestionados por la aplicación
    _rutasImagenesCache.clear();
    super.dispose();
  }
}

/// Función para abrir la galería en pantalla completa
void abrirGaleriaPantallaCompleta(
  BuildContext context,
  int idInmueble, {
  int initialIndex = 0,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (context) => GaleriaPantallaCompleta(
            idInmueble: idInmueble,
            initialIndex: initialIndex,
          ),
    ),
  );
}

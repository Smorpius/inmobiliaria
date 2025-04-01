import 'dart:io';
import 'dart:async';
import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../services/mysql_helper.dart';
import '../models/inmueble_imagen.dart';
import '../providers/providers_global.dart';
import 'package:image_picker/image_picker.dart';
import '../models/inmueble_imagenes_state.dart';
import '../widgets/inmueble_imagen_carousel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../vistas/inmuebles/galeria_pantalla_completa.dart';

/// Provider para acceder al servicio de base de datos
final dbServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Widget para mostrar y gestionar imágenes de un inmueble con manejo optimizado de errores
class InmuebleImagenesSection extends ConsumerWidget {
  final int inmuebleId;
  final bool isInactivo;

  // Constantes para evitar números mágicos
  static const double _carouselHeight = 240.0;
  static const Duration _reconexionDelay = Duration(seconds: 2);
  static const Duration _imagenValidacionTimeout = Duration(seconds: 5);

  const InmuebleImagenesSection({
    super.key,
    required this.inmuebleId,
    this.isInactivo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      // Listener optimizado para reintentar automáticamente en caso de error de conexión
      ref.listen<InmuebleImagenesState>(
        inmuebleImagenesStateProvider(inmuebleId),
        (previous, next) {
          if (!context.mounted || next.errorMessage == null) return;

          final esErrorConexion =
              next.errorMessage!.contains('socket') ||
              next.errorMessage!.contains('connection') ||
              next.errorMessage!.contains('closed');

          final esMySqlError =
              next.errorMessage!.contains('MySQL') ||
              next.errorMessage!.contains('MySqlProtocol');

          if ((esErrorConexion || esMySqlError) && context.mounted) {
            Future.delayed(_reconexionDelay, () {
              if (!context.mounted) return;

              if (esMySqlError) {
                ref.read(dbServiceProvider).reiniciarConexion().then((_) {
                  if (context.mounted) {
                    AppLogger.info(
                      'Reconexión MySQL completada, recargando imágenes',
                    );
                    ref
                        .read(
                          inmuebleImagenesStateProvider(inmuebleId).notifier,
                        )
                        .cargarImagenes();
                  }
                });
              } else {
                AppLogger.info(
                  'Reintentando cargar imágenes tras error de conexión',
                );
                ref
                    .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
                    .cargarImagenes();
              }
            });
          }
        },
      );

      // Observar el estado de las imágenes
      final state = ref.watch(inmuebleImagenesStateProvider(inmuebleId));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la sección
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Imágenes del inmueble',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Contenido principal según el estado
          if (state.isLoading && state.imagenes.isEmpty)
            const SizedBox(
              height: _carouselHeight,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.errorMessage != null)
            _buildErrorMessage(context, ref, state.errorMessage!)
          else if (state.imagenes.isEmpty)
            _buildEmptyImagesMessage(context, ref)
          else
            _buildImagesCarousel(context, ref, state),

          // Botón para verificar y reparar imágenes dañadas
          if (state.imagenes.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.healing),
                label: const Text('Verificar y reparar imágenes'),
                onPressed:
                    () => limpiarImagenesDanadas(context, ref, state.imagenes),
              ),
            ),

          // Botón para ver galería completa
          if (state.imagenes.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Ver todas'),
                onPressed: () => _abrirGaleriaPantallaCompleta(context),
              ),
            ),
        ],
      );
    } catch (e) {
      AppLogger.error(
        'Error al renderizar InmuebleImagenesSection',
        e,
        StackTrace.current,
      );

      final esErrorConexion =
          e.toString().contains('socket') ||
          e.toString().contains('connection') ||
          e.toString().contains('closed');

      final esMySqlError =
          e.toString().contains('MySQL') ||
          e.toString().contains('MySqlProtocol');

      return Container(
        height: _carouselHeight,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                esErrorConexion
                    ? Icons.wifi_off
                    : esMySqlError
                    ? Icons.storage_outlined
                    : Icons.error_outline,
                size: 48,
                color:
                    esErrorConexion || esMySqlError
                        ? Colors.orange
                        : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                esErrorConexion
                    ? "Problema de conexión a la base de datos.\nIntente nuevamente más tarde."
                    : esMySqlError
                    ? "Error de comunicación con la base de datos.\nPor favor, reintente en unos momentos."
                    : "Error al cargar la sección de imágenes: ${e.toString().split('\n').first}",
                style: TextStyle(
                  color:
                      esErrorConexion || esMySqlError
                          ? Colors.orange.shade800
                          : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (esErrorConexion || esMySqlError)
                ElevatedButton.icon(
                  onPressed: () {
                    if (!context.mounted) return;

                    if (esMySqlError) {
                      ref.read(dbServiceProvider).reiniciarConexion().then((_) {
                        if (context.mounted) {
                          ref.invalidate(
                            inmuebleImagenesStateProvider(inmuebleId),
                          );
                        }
                      });
                    } else {
                      ref.invalidate(inmuebleImagenesStateProvider(inmuebleId));
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
            ],
          ),
        ),
      );
    }
  }

  /// Construye un mensaje de error contextual según el tipo de error
  Widget _buildErrorMessage(
    BuildContext context,
    WidgetRef ref,
    String errorMessage,
  ) {
    final esMySqlError =
        errorMessage.contains('MySQL') ||
        errorMessage.contains('MySqlProtocol');
    final esErrorConexion =
        errorMessage.contains('socket') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('closed');
    final esErrorFormato =
        errorMessage.contains('format') || errorMessage.contains('RangeError');

    IconData iconoError;
    String mensajeError;
    Color colorError;

    if (esMySqlError) {
      iconoError = Icons.storage_outlined;
      mensajeError = 'Error de comunicación con la base de datos';
      colorError = Colors.orange;
    } else if (esErrorConexion) {
      iconoError = Icons.wifi_off;
      mensajeError = 'Problema de conexión a la base de datos';
      colorError = Colors.orange.shade700;
    } else if (esErrorFormato) {
      iconoError = Icons.file_copy_outlined;
      mensajeError = 'Error en el formato de los datos de imagen';
      colorError = Colors.red.shade300;
    } else {
      iconoError = Icons.error_outline;
      mensajeError =
          'Error al cargar imágenes: ${errorMessage.split('\n').first}';
      colorError = Colors.red;
    }

    return SizedBox(
      height: _carouselHeight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconoError, size: 40, color: colorError),
            const SizedBox(height: 16),
            Text(
              mensajeError,
              style: TextStyle(color: colorError),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (esMySqlError || esErrorConexion) {
                  ref.read(dbServiceProvider).reiniciarConexion().then((_) {
                    ref.invalidate(inmuebleImagenesStateProvider(inmuebleId));
                  });
                } else {
                  ref
                      .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
                      .cargarImagenes();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un mensaje para cuando no hay imágenes disponibles
  Widget _buildEmptyImagesMessage(BuildContext context, WidgetRef ref) {
    return Container(
      height: _carouselHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay imágenes para este inmueble',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (!isInactivo) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _mostrarOpcionesAgregarImagen(context, ref),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Agregar imagen'),
            ),
          ],
        ],
      ),
    );
  }

  /// Construye el carrusel de imágenes con manejo optimizado de errores
  Widget _buildImagesCarousel(
    BuildContext context,
    WidgetRef ref,
    InmuebleImagenesState state,
  ) {
    return Stack(
      children: [
        InmuebleImagenCarousel(
          imagenes: state.imagenes,
          onImagenTap:
              isInactivo
                  ? null
                  : (index) => _mostrarMenuOpciones(context, ref, index),
          onAddTap:
              isInactivo
                  ? null
                  : () => _mostrarOpcionesAgregarImagen(context, ref),
          errorBuilder: (context, error, stackTrace) {
            final esErrorBytes =
                error.toString().contains('byteOffset') ||
                error.toString().contains('index') ||
                error is RangeError;

            final esErrorFormato =
                error.toString().contains('decode') ||
                error.toString().contains('codec') ||
                error.toString().contains('PNG');

            AppLogger.categoryWarning(
              'image_error',
              'Error al procesar imagen: ${error.toString().split('\n').first}',
              expiration: const Duration(minutes: 5),
            );

            return Container(
              height: _carouselHeight,
              color: Colors.grey.shade200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      esErrorBytes
                          ? Icons.broken_image
                          : esErrorFormato
                          ? Icons.image_not_supported
                          : Icons.error_outline,
                      size: 48,
                      color:
                          esErrorBytes || esErrorFormato
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      esErrorBytes
                          ? "Los datos de esta imagen están dañados"
                          : esErrorFormato
                          ? "Formato de imagen incompatible"
                          : "Error al procesar las imágenes",
                      style: TextStyle(
                        color:
                            esErrorBytes || esErrorFormato
                                ? Colors.orange.shade700
                                : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        esErrorBytes || esErrorFormato
                            ? "Para resolver este problema, elimine esta imagen y suba una nueva."
                            : "Intente recargar la página.",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(
                          inmuebleImagenesStateProvider(inmuebleId),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Indicador de carga superpuesto
        if (state.isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  /// Método optimizado para agregar imágenes con validaciones completas
  Future<void> _agregarImagen(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final imageService = ref.read(imageServiceProvider);

      final File? imagen = await imageService.pickImage(source);
      if (imagen == null) return;

      if (!await imagen.exists()) {
        if (!context.mounted) return;
        _mostrarSnackbarError(
          context,
          'No se pudo acceder al archivo de imagen',
        );
        return;
      }

      if (await imagen.length() < 100) {
        if (!context.mounted) return;
        _mostrarSnackbarError(context, 'Archivo de imagen dañado o vacío');
        return;
      }

      if (await imagen.length() > 10 * 1024 * 1024) {
        if (!context.mounted) return;
        _mostrarSnackbarError(
          context,
          'La imagen es demasiado grande (máximo 10MB)',
        );
        return;
      }

      try {
        final bytes = await imagen.readAsBytes();
        await decodeImageFromList(
          bytes.sublist(0, bytes.length > 1024 ? 1024 : bytes.length),
        ).timeout(_imagenValidacionTimeout);
      } catch (decodeError) {
        if (!context.mounted) return;
        _mostrarSnackbarError(
          context,
          'El archivo no es una imagen válida: ${decodeError.toString().split('\n').first}',
        );
        return;
      }

      if (!context.mounted) return;

      final descripcion = await _mostrarDialogoDescripcion(context);
      if (descripcion == null) return;

      if (!context.mounted) return;

      await ref
          .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
          .agregarImagen(imagen, descripcion);
    } catch (e) {
      AppLogger.error('Error al agregar imagen', e, StackTrace.current);

      if (!context.mounted) return;

      final esErrorConexion =
          e.toString().contains('socket') ||
          e.toString().contains('connection');
      final esMySqlError =
          e.toString().contains('MySQL') ||
          e.toString().contains('MySqlProtocol');
      final esErrorImagen =
          e.toString().contains('ImagePicker') || e.toString().contains('file');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esErrorImagen
                ? 'Error al procesar la imagen. Intente con otra.'
                : esErrorConexion || esMySqlError
                ? 'Error de conexión con la base de datos.'
                : 'Error al agregar imagen: ${e.toString().split('\n').first}',
          ),
          backgroundColor:
              esErrorImagen
                  ? Colors.amber
                  : (esErrorConexion || esMySqlError)
                  ? Colors.orange
                  : Colors.red,
          action:
              (esErrorConexion || esMySqlError)
                  ? SnackBarAction(
                    label: 'Reintentar',
                    onPressed: () {
                      if (esMySqlError) {
                        ref.read(dbServiceProvider).reiniciarConexion().then((
                          _,
                        ) {
                          if (context.mounted) {
                            _agregarImagen(context, ref, source);
                          }
                        });
                      } else if (context.mounted) {
                        _agregarImagen(context, ref, source);
                      }
                    },
                  )
                  : null,
        ),
      );
    }
  }

  /// Verifica si una imagen es válida con timeout para prevenir bloqueos
  Future<bool> verificarImagenValida(File file) async {
    try {
      if (!file.existsSync() || await file.length() < 100) {
        return false;
      }

      final bytes = await file.readAsBytes().timeout(
        _imagenValidacionTimeout,
        onTimeout:
            () =>
                throw TimeoutException(
                  'Tiempo de espera agotado al leer imagen',
                ),
      );

      if (bytes.length < 8) return false;

      final isJpeg =
          bytes.length > 2 &&
          bytes[0] == 0xFF &&
          bytes[1] == 0xD8 &&
          bytes[2] == 0xFF;
      final isPng =
          bytes.length > 7 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47;
      final isGif =
          bytes.length > 3 &&
          bytes[0] == 0x47 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46;

      if (!(isJpeg || isPng || isGif)) {
        try {
          await decodeImageFromList(
            bytes.length > 1024 ? bytes.sublist(0, 1024) : bytes,
          ).timeout(_imagenValidacionTimeout);
        } catch (e) {
          AppLogger.warning('Formato de imagen no reconocido: ${file.path}');
          return false;
        }
      }

      return true;
    } catch (e) {
      AppLogger.warning(
        'Error al validar imagen: ${file.path} - ${e.toString().split('\n').first}',
      );
      return false;
    }
  }

  /// Identifica y elimina imágenes dañadas con confirmación del usuario
  Future<void> limpiarImagenesDanadas(
    BuildContext context,
    WidgetRef ref,
    List<InmuebleImagen> imagenes,
  ) async {
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Verificando imágenes...')));

    final List<InmuebleImagen> imagenesDanadas = [];
    for (final imagen in imagenes) {
      try {
        final file = File(imagen.rutaImagen);
        final esValida = await verificarImagenValida(file);

        if (!esValida && imagen.id != null) {
          imagenesDanadas.add(imagen);
        }
      } catch (e) {
        if (imagen.id != null) {
          imagenesDanadas.add(imagen);
        }
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    if (imagenesDanadas.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontraron imágenes dañadas'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    if (!context.mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Imágenes dañadas detectadas'),
            content: Text(
              'Se encontraron ${imagenesDanadas.length} imágenes dañadas. '
              '¿Desea eliminarlas para resolver el problema?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar imágenes dañadas'),
              ),
            ],
          ),
    );

    if (confirmar != true || !context.mounted) return;

    final notifier = ref.read(
      inmuebleImagenesStateProvider(inmuebleId).notifier,
    );
    int eliminadas = 0;

    for (final imagen in imagenesDanadas) {
      if (imagen.id != null) {
        try {
          await notifier.eliminarImagen(imagen.id!);
          eliminadas++;
        } catch (e) {
          AppLogger.error(
            'Error al eliminar imagen dañada: ${imagen.id}',
            e,
            StackTrace.current,
          );
        }
      }
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Se ${eliminadas > 0 ? "eliminaron $eliminadas" : "intentó eliminar"} '
          '${imagenesDanadas.length} ${imagenesDanadas.length == 1 ? "imagen dañada" : "imágenes dañadas"}',
        ),
        backgroundColor: eliminadas > 0 ? Colors.green : Colors.orange,
      ),
    );
  }

  /// Abre la galería en pantalla completa con manejo de errores
  void _abrirGaleriaPantallaCompleta(BuildContext context) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => GaleriaPantallaCompleta(
                idInmueble: inmuebleId,
                initialIndex: 0,
              ),
        ),
      );
    } catch (e) {
      AppLogger.error('Error al abrir la galería', e, StackTrace.current);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al abrir la galería: ${e.toString().split('\n').first}',
            ),
          ),
        );
      }
    }
  }

  /// Muestra opciones para agregar imágenes desde distintas fuentes
  void _mostrarOpcionesAgregarImagen(BuildContext context, WidgetRef ref) {
    if (isInactivo) return;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Seleccionar de la galería'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _agregarImagen(context, ref, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Tomar una foto'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _agregarImagen(context, ref, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
    );
  }

  /// Muestra un diálogo para ingresar la descripción de la imagen con validaciones
  Future<String?> _mostrarDialogoDescripcion(BuildContext context) async {
    if (!context.mounted) return null;

    final controllerDescripcion = TextEditingController();

    return showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Descripción de la imagen'),
            content: TextField(
              controller: controllerDescripcion,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ingrese una descripción para la imagen',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 255,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  final texto =
                      controllerDescripcion.text.isEmpty
                          ? 'Imagen del inmueble'
                          : controllerDescripcion.text;
                  Navigator.of(dialogContext).pop(texto);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  /// Muestra el menú de opciones para una imagen específica
  Future<void> _mostrarMenuOpciones(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) async {
    if (isInactivo) return;

    try {
      final state = ref.read(inmuebleImagenesStateProvider(inmuebleId));
      if (state.imagenes.isEmpty || index >= state.imagenes.length) return;

      final imagen = state.imagenes[index];

      if (!context.mounted) return;

      await showModalBottomSheet(
        context: context,
        builder:
            (dialogContext) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Editar descripción'),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      if (context.mounted) {
                        _editarDescripcion(context, ref, imagen);
                      }
                    },
                  ),
                  if (!imagen.esPrincipal)
                    ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: const Text('Marcar como principal'),
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        if (context.mounted) {
                          _marcarComoPrincipal(context, ref, imagen);
                        }
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Eliminar imagen',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      if (context.mounted) {
                        _eliminarImagen(context, ref, imagen);
                      }
                    },
                  ),
                ],
              ),
            ),
      );
    } catch (e) {
      AppLogger.error('Error en el menú de opciones', e, StackTrace.current);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error en el menú de opciones: ${e.toString().split('\n').first}',
          ),
        ),
      );
    }
  }

  /// Permite editar la descripción de una imagen
  Future<void> _editarDescripcion(
    BuildContext context,
    WidgetRef ref,
    InmuebleImagen imagen,
  ) async {
    if (imagen.id == null || !context.mounted) return;

    try {
      final descripcionController = TextEditingController(
        text: imagen.descripcion ?? '',
      );

      final nuevaDescripcion = await showDialog<String>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Descripción de la imagen'),
              content: TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ingrese una descripción para la imagen',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 255,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.of(
                        dialogContext,
                      ).pop(descripcionController.text),
                  child: const Text('Guardar'),
                ),
              ],
            ),
      );

      if (nuevaDescripcion != null && context.mounted) {
        await ref
            .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
            .actualizarDescripcion(imagen.id!, nuevaDescripcion);
      }
    } catch (e) {
      AppLogger.error('Error al editar descripción', e, StackTrace.current);

      if (!context.mounted) return;

      final esErrorConexion =
          e.toString().contains('socket') ||
          e.toString().contains('connection') ||
          e.toString().contains('closed');
      final esMySqlError =
          e.toString().contains('MySQL') ||
          e.toString().contains('MySqlProtocol');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esErrorConexion
                ? 'Error de conexión. Intente más tarde.'
                : esMySqlError
                ? 'Error de comunicación con la base de datos. Intente nuevamente.'
                : 'Error al editar descripción: ${e.toString().split('\n').first}',
          ),
          backgroundColor:
              esErrorConexion || esMySqlError ? Colors.orange : Colors.red,
          action:
              esErrorConexion || esMySqlError
                  ? SnackBarAction(
                    label: 'Reintentar',
                    onPressed: () {
                      if (esMySqlError) {
                        ref.read(dbServiceProvider).reiniciarConexion().then((
                          _,
                        ) {
                          if (context.mounted) {
                            _editarDescripcion(context, ref, imagen);
                          }
                        });
                      } else if (context.mounted) {
                        _editarDescripcion(context, ref, imagen);
                      }
                    },
                  )
                  : null,
        ),
      );
    }
  }

  Future<void> _marcarComoPrincipal(
    BuildContext context,
    WidgetRef ref,
    InmuebleImagen imagen,
  ) async {
    if (imagen.id == null || !context.mounted) return;

    try {
      // Obtener el notifier a través del provider
      final notifier = ref.read(
        inmuebleImagenesStateProvider(inmuebleId).notifier,
      );

      // Marcar como principal
      await notifier.marcarComoPrincipal(imagen.id!);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen establecida como principal'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppLogger.error('Error al marcar como principal', e, StackTrace.current);

      if (!context.mounted) return;

      final esErrorConexion =
          e.toString().contains('socket') ||
          e.toString().contains('connection') ||
          e.toString().contains('closed');
      final esMySqlError =
          e.toString().contains('MySQL') ||
          e.toString().contains('MySqlProtocol');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esErrorConexion
                ? 'Error de conexión. Intente más tarde.'
                : esMySqlError
                ? 'Error de comunicación con la base de datos. Intente nuevamente.'
                : 'Error al marcar como principal: ${e.toString().split('\n').first}',
          ),
          backgroundColor:
              esErrorConexion || esMySqlError ? Colors.orange : Colors.red,
          action:
              esErrorConexion || esMySqlError
                  ? SnackBarAction(
                    label: 'Reintentar',
                    onPressed: () {
                      if (esMySqlError) {
                        ref
                            .read(databaseServiceProvider)
                            .reiniciarConexion()
                            .then((_) {
                              if (context.mounted) {
                                _marcarComoPrincipal(context, ref, imagen);
                              }
                            });
                      } else if (context.mounted) {
                        _marcarComoPrincipal(context, ref, imagen);
                      }
                    },
                  )
                  : null,
        ),
      );
    }
  }

  /// Elimina una imagen con confirmación previa
  Future<void> _eliminarImagen(
    BuildContext context,
    WidgetRef ref,
    InmuebleImagen imagen,
  ) async {
    if (imagen.id == null || !context.mounted) return;

    try {
      final confirmado = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Eliminar imagen'),
              content: const Text(
                '¿Está seguro que desea eliminar esta imagen?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
      );

      if (confirmado == true && context.mounted) {
        await ref
            .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
            .eliminarImagen(imagen.id!);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error al eliminar imagen', e, StackTrace.current);

      if (!context.mounted) return;

      final esErrorConexion =
          e.toString().contains('socket') ||
          e.toString().contains('connection') ||
          e.toString().contains('closed');
      final esMySqlError =
          e.toString().contains('MySQL') ||
          e.toString().contains('MySqlProtocol');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esErrorConexion
                ? 'Error de conexión. Intente más tarde.'
                : esMySqlError
                ? 'Error de comunicación con la base de datos. Intente nuevamente.'
                : 'Error al eliminar imagen: ${e.toString().split('\n').first}',
          ),
          backgroundColor:
              esErrorConexion || esMySqlError ? Colors.orange : Colors.red,
          action:
              esErrorConexion || esMySqlError
                  ? SnackBarAction(
                    label: 'Reintentar',
                    onPressed: () {
                      if (esMySqlError) {
                        ref.read(dbServiceProvider).reiniciarConexion().then((
                          _,
                        ) {
                          if (context.mounted) {
                            _eliminarImagen(context, ref, imagen);
                          }
                        });
                      } else if (context.mounted) {
                        _eliminarImagen(context, ref, imagen);
                      }
                    },
                  )
                  : null,
        ),
      );
    }
  }

  /// Muestra un snackbar de error con formato consistente
  void _mostrarSnackbarError(BuildContext context, String mensaje) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}

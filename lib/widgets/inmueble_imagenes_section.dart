import 'dart:io';
import 'package:flutter/material.dart';
import '../models/inmueble_imagen.dart';
import '../providers/providers_global.dart';
import '../models/inmueble_imagenes_state.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/inmueble_imagen_carousel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../vistas/inmuebles/galeria_pantalla_completa.dart';
import '../services/mysql_helper.dart'; // Importación para el servicio de MySQL

// Definición del proveedor de base de datos
final dbServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

class InmuebleImagenesSection extends ConsumerWidget {
  final int inmuebleId;
  final bool isInactivo;
  // Propiedad para controlar reintentos
  final int maxReintentos = 2;

  const InmuebleImagenesSection({
    super.key,
    required this.inmuebleId,
    this.isInactivo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      // Listener para reintentar automáticamente en caso de error de conexión
      ref.listen<InmuebleImagenesState>(
        inmuebleImagenesStateProvider(inmuebleId),
        (previous, next) {
          if (next.errorMessage != null &&
              (next.errorMessage!.contains('socket') ||
                  next.errorMessage!.contains('MySQL') ||
                  next.errorMessage!.contains('MySqlProtocol')) &&
              context.mounted) {
            // Reintento automático para errores de conexión y MySQL
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                // Para errores de MySQL, primero reiniciar la conexión
                if (next.errorMessage!.contains('MySQL') ||
                    next.errorMessage!.contains('MySqlProtocol')) {
                  ref.read(dbServiceProvider).reiniciarConexion().then((_) {
                    if (context.mounted) {
                      ref
                          .read(
                            inmuebleImagenesStateProvider(inmuebleId).notifier,
                          )
                          .cargarImagenes();
                    }
                  });
                } else {
                  ref
                      .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
                      .cargarImagenes();
                }
              }
            });
          }
        },
      );

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

          // Contenido principal con estado
          if (state.isLoading && state.imagenes.isEmpty)
            const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.errorMessage != null)
            _buildErrorMessage(context, ref, state.errorMessage!)
          else if (state.imagenes.isEmpty)
            _buildEmptyImagesMessage(context, ref)
          else
            _buildImagesCarousel(context, ref, state),

          // Botón para limpiar imágenes dañadas - Nueva funcionalidad
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
      // Si el error parece relacionado con conexión o MySQL, mostrar mensaje específico
      final esErrorConexion =
          e.toString().contains('socket') ||
          e.toString().contains('connection') ||
          e.toString().contains('closed');
      final esMySqlError =
          e.toString().contains('MySQL') ||
          e.toString().contains('MySqlProtocol');

      return Container(
        height: 200,
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
                    : "Error al cargar la sección de imágenes: $e",
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
                    if (context.mounted) {
                      if (esMySqlError) {
                        ref.read(dbServiceProvider).reiniciarConexion().then((
                          _,
                        ) {
                          ref.invalidate(
                            inmuebleImagenesStateProvider(inmuebleId),
                          );
                        });
                      } else {
                        ref.invalidate(
                          inmuebleImagenesStateProvider(inmuebleId),
                        );
                      }
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

  Widget _buildErrorMessage(
    BuildContext context,
    WidgetRef ref,
    String errorMessage,
  ) {
    // Determinar el tipo de error para mostrar mensajes más específicos
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
      mensajeError = 'Error al cargar imágenes: $errorMessage';
      colorError = Colors.red;
    }

    return SizedBox(
      height: 240,
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
                // Primero intentar reiniciar la conexión y luego recargar las imágenes
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

  Widget _buildEmptyImagesMessage(BuildContext context, WidgetRef ref) {
    return Container(
      height: 240,
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

  // Método que construye el carrusel con manejo de errores
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

            return Container(
              height: 240,
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

        if (state.isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  // Método mejorado para agregar imágenes
  Future<void> _agregarImagen(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final imageService = ref.read(imageServiceProvider);

      final File? imagen = await imageService.pickImage(source);
      if (imagen == null) return;

      // Verificación completa del archivo de imagen
      if (!imagen.existsSync()) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo acceder al archivo de imagen'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Verificar tamaño mínimo
      if (imagen.lengthSync() < 100) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archivo de imagen dañado o vacío'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Verificar tamaño máximo
      if (imagen.lengthSync() > 10 * 1024 * 1024) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La imagen es demasiado grande (máximo 10MB)'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Intentar decodificar
      try {
        final bytes = await imagen.readAsBytes();
        await decodeImageFromList(
          bytes.sublist(0, bytes.length > 1024 ? 1024 : bytes.length),
        );
      } catch (decodeError) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El archivo no es una imagen válida: ${decodeError.toString().split("\n").first}',
            ),
            backgroundColor: Colors.red,
          ),
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
                : 'Error al agregar imagen: ${e.toString().split("\n").first}',
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

  // Método para verificar si una imagen es válida
  Future<bool> verificarImagenValida(File file) async {
    try {
      if (!file.existsSync() || file.lengthSync() < 100) {
        return false;
      }

      final bytes = await file.readAsBytes();
      if (bytes.length < 8) return false;

      // Verificar formatos comunes de imagen
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
          );
        } catch (e) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Método para limpiar imágenes dañadas
  Future<void> limpiarImagenesDanadas(
    BuildContext context,
    WidgetRef ref,
    List<InmuebleImagen> imagenes,
  ) async {
    if (!context.mounted) return;

    final List<InmuebleImagen> imagenesDanadas = [];

    for (final imagen in imagenes) {
      final file = File(imagen.rutaImagen);
      final esValida = await verificarImagenValida(file);

      if (!esValida && imagen.id != null) {
        imagenesDanadas.add(imagen);
      }
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

    for (final imagen in imagenesDanadas) {
      if (imagen.id != null) {
        await notifier.eliminarImagen(imagen.id!);
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Se eliminaron ${imagenesDanadas.length} imágenes dañadas',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir la galería: $e')),
        );
      }
    }
  }

  void _mostrarOpcionesAgregarImagen(BuildContext context, WidgetRef ref) {
    if (isInactivo) return; // No mostrar opciones si está inactivo

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

  // Corregido para verificar context.mounted antes de mostrar el diálogo
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

  Future<void> _mostrarMenuOpciones(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) async {
    if (isInactivo) return; // No mostrar menú si está inactivo

    try {
      final state = ref.read(inmuebleImagenesStateProvider(inmuebleId));
      if (state.imagenes.isEmpty || index >= state.imagenes.length) return;

      final imagen = state.imagenes[index];

      // Verificar que el contexto esté montado antes de mostrar el modal
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
      // Manejar cualquier error inesperado
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en el menú de opciones: $e')),
      );
    }
  }

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

      // Verificar que el contexto siga montado después de la operación asíncrona
      if (nuevaDescripcion != null && context.mounted) {
        ref
            .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
            .actualizarDescripcion(imagen.id!, nuevaDescripcion);
      }
    } catch (e) {
      // Verificar que el contexto esté montado antes de mostrar el snackbar
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
                : 'Error al editar descripción: $e',
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
                      } else {
                        if (context.mounted) {
                          _editarDescripcion(context, ref, imagen);
                        }
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
    if (imagen.id == null || imagen.esPrincipal || !context.mounted) return;

    try {
      ref
          .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
          .marcarComoPrincipal(imagen.id!);
    } catch (e) {
      // Verificar que el contexto esté montado antes de mostrar el snackbar
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
                : 'Error al marcar como principal: $e',
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
                            _marcarComoPrincipal(context, ref, imagen);
                          }
                        });
                      } else {
                        if (context.mounted) {
                          _marcarComoPrincipal(context, ref, imagen);
                        }
                      }
                    },
                  )
                  : null,
        ),
      );
    }
  }

  Future<void> _eliminarImagen(
    BuildContext context,
    WidgetRef ref,
    InmuebleImagen imagen,
  ) async {
    if (imagen.id == null || !context.mounted) return;

    try {
      // Confirmar eliminación
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

      // Verificar que el contexto siga montado después de la operación asíncrona
      if (confirmado == true && context.mounted) {
        ref
            .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
            .eliminarImagen(imagen.id!);
      }
    } catch (e) {
      // Verificar que el contexto esté montado antes de mostrar el snackbar
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
                : 'Error al eliminar imagen: $e',
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
                      } else {
                        if (context.mounted) {
                          _eliminarImagen(context, ref, imagen);
                        }
                      }
                    },
                  )
                  : null,
        ),
      );
    }
  }
}

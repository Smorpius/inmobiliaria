import 'dart:io';
import 'package:flutter/material.dart';
import '../models/inmueble_imagen.dart';
import '../providers/providers_global.dart';
import '../models/inmueble_imagenes_state.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/inmueble_imagen_carousel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../vistas/inmuebles/galeria_pantalla_completa.dart';

class InmuebleImagenesSection extends ConsumerWidget {
  final int inmuebleId;
  final bool isInactivo;

  const InmuebleImagenesSection({
    super.key,
    required this.inmuebleId,
    this.isInactivo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
  }

  Widget _buildErrorMessage(
    BuildContext context,
    WidgetRef ref,
    String errorMessage,
  ) {
    return SizedBox(
      height: 240,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error al cargar imágenes: $errorMessage',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  () =>
                      ref
                          .read(
                            inmuebleImagenesStateProvider(inmuebleId).notifier,
                          )
                          .cargarImagenes(),
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

  Widget _buildImagesCarousel(
    BuildContext context,
    WidgetRef ref,
    InmuebleImagenesState state,
  ) {
    return Stack(
      children: [
        InmuebleImagenCarousel(
          imagenes: state.imagenes,
          onImagenTap: (index) => _mostrarMenuOpciones(context, ref, index),
          onAddTap:
              isInactivo
                  ? null
                  : () => _mostrarOpcionesAgregarImagen(context, ref),
        ),

        // Mostrar indicador de carga si está procesando
        if (state.isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  void _abrirGaleriaPantallaCompleta(BuildContext context) {
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

  Future<void> _agregarImagen(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final imageService = ref.read(imageServiceProvider);

      // Obtener la imagen
      final File? imagen = await imageService.pickImage(source);
      if (imagen == null) return;

      // Verificar si el contexto sigue montado
      if (!context.mounted) return;

      // Mostrar diálogo para agregar descripción
      final descripcion = await _mostrarDialogoDescripcion(context);
      if (descripcion == null) return;

      // Verificar nuevamente si el contexto sigue montado
      if (!context.mounted) return;

      // Agregar imagen usando el notifier
      ref
          .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
          .agregarImagen(imagen, descripcion);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al agregar imagen: $e')));
      }
    }
  }

  // Este método fue marcado con la advertencia
  Future<String?> _mostrarDialogoDescripcion(BuildContext context) async {
    // Guardar controlador fuera de la operación asíncrona
    final controllerDescripcion = TextEditingController();

    // No accedemos a context después del await
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
                onPressed:
                    () => Navigator.of(dialogContext).pop(
                      controllerDescripcion.text.isEmpty
                          ? 'Imagen del inmueble'
                          : controllerDescripcion.text,
                    ),
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

    final state = ref.read(inmuebleImagenesStateProvider(inmuebleId));
    if (state.imagenes.isEmpty || index >= state.imagenes.length) return;

    final imagen = state.imagenes[index];

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

    // Verificar si el contexto sigue montado después del await
    if (!context.mounted) return;
  }

  Future<void> _editarDescripcion(
    BuildContext context,
    WidgetRef ref,
    InmuebleImagen imagen,
  ) async {
    if (imagen.id == null) return;

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
      ref
          .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
          .actualizarDescripcion(imagen.id!, nuevaDescripcion);
    }
  }

  Future<void> _marcarComoPrincipal(
    BuildContext context,
    WidgetRef ref,
    InmuebleImagen imagen,
  ) async {
    if (imagen.id == null || imagen.esPrincipal) return;

    ref
        .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
        .marcarComoPrincipal(imagen.id!);
  }

  Future<void> _eliminarImagen(
    BuildContext context,
    WidgetRef ref,
    InmuebleImagen imagen,
  ) async {
    if (imagen.id == null) return;

    // Confirmar eliminación
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Eliminar imagen'),
            content: const Text('¿Está seguro que desea eliminar esta imagen?'),
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
      ref
          .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
          .eliminarImagen(imagen.id!);
    }
  }
}

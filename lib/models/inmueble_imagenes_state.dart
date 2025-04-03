import 'dart:io';
import '../models/inmueble_imagen.dart';
import '../providers/providers_global.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InmuebleImagenesState {
  final List<InmuebleImagen> imagenes;
  final bool isLoading;
  final String? errorMessage;

  const InmuebleImagenesState({
    required this.imagenes,
    required this.isLoading,
    this.errorMessage,
  });

  // Constructor para estado inicial
  factory InmuebleImagenesState.initial() =>
      const InmuebleImagenesState(imagenes: [], isLoading: true);

  InmuebleImagenesState copyWith({
    List<InmuebleImagen>? imagenes,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InmuebleImagenesState(
      imagenes: imagenes ?? this.imagenes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class InmuebleImagenesNotifier extends StateNotifier<InmuebleImagenesState> {
  final Ref _ref;
  final int inmuebleId;

  InmuebleImagenesNotifier(this._ref, this.inmuebleId)
    : super(InmuebleImagenesState.initial()) {
    cargarImagenes();
  }

  Future<void> cargarImagenes() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final controller = _ref.read(inmuebleControllerProvider);
      final imagenes = await controller.getImagenesInmueble(inmuebleId);

      // Asegurarse que no hay duplicados por ruta de imagen
      final imagenesUnicas = _removerDuplicados(imagenes);

      state = state.copyWith(imagenes: imagenesUnicas, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar imágenes: $e',
      );
    }
  }

  // Método para remover duplicados basado en ruta de imagen
  List<InmuebleImagen> _removerDuplicados(List<InmuebleImagen> imagenes) {
    final Map<String, InmuebleImagen> imagenesMap = {};
    for (var imagen in imagenes) {
      imagenesMap[imagen.rutaImagen] = imagen;
    }
    return imagenesMap.values.toList();
  }

  Future<void> agregarImagen(File imagen, String descripcion) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final imageService = _ref.read(imageServiceProvider);
      final controller = _ref.read(inmuebleControllerProvider);

      // Guardar imagen en directorio
      final rutaRelativa = await imageService.saveImage(
        imagen,
        'inmuebles',
        'inmueble_$inmuebleId',
      );

      if (rutaRelativa == null) {
        throw Exception('Error al guardar la imagen');
      }

      // Determinar si es principal
      final esPrincipal = state.imagenes.isEmpty;

      // Crear objeto de imagen
      final nuevaImagen = InmuebleImagen(
        idInmueble: inmuebleId,
        rutaImagen: rutaRelativa,
        descripcion: descripcion,
        esPrincipal: esPrincipal,
        fechaCarga: DateTime.now(),
      );

      // Guardar en base de datos
      final idImagen = await controller.agregarImagenInmueble(nuevaImagen);

      if (idImagen <= 0) {
        throw Exception('Error al agregar imagen a la base de datos');
      }

      // En lugar de recargar todas las imágenes, actualizar el estado directamente
      final nuevaImagen2 = InmuebleImagen(
        id: idImagen,
        idInmueble: inmuebleId,
        rutaImagen: rutaRelativa,
        descripcion: descripcion,
        esPrincipal: esPrincipal,
        fechaCarga: DateTime.now(),
      );

      // Actualizar el estado agregando sólo la nueva imagen
      final imagenesActualizadas = [...state.imagenes, nuevaImagen2];

      state = state.copyWith(imagenes: imagenesActualizadas, isLoading: false);

      // Actualizar imágenes principales si es necesario
      if (esPrincipal) {
        _ref.invalidate(imagenesPrincipalesProvider);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al agregar imagen: $e',
      );
    }
  }

  Future<void> eliminarImagen(int imageId) async {
    try {
      if (imageId <= 0) return;

      // Buscar la imagen
      final imagen = state.imagenes.firstWhere((img) => img.id == imageId);
      final esPrincipal = imagen.esPrincipal;
      final rutaImagen = imagen.rutaImagen;

      state = state.copyWith(isLoading: true, errorMessage: null);

      final controller = _ref.read(inmuebleControllerProvider);
      final imageService = _ref.read(imageServiceProvider);

      // Eliminar de base de datos
      final eliminado = await controller.eliminarImagenInmueble(imageId);

      if (!eliminado) {
        throw Exception('Error al eliminar imagen de la base de datos');
      }

      // Eliminar archivo físico
      await imageService.deleteImage(rutaImagen);

      // Actualizar el estado eliminando la imagen del array
      final imagenesActualizadas =
          state.imagenes.where((img) => img.id != imageId).toList();
      state = state.copyWith(imagenes: imagenesActualizadas, isLoading: false);

      // Si era principal, invalidar provider de imágenes principales
      if (esPrincipal) {
        _ref.invalidate(imagenesPrincipalesProvider);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al eliminar imagen: $e',
      );
    }
  }

  Future<void> marcarComoPrincipal(int imageId) async {
    try {
      if (imageId <= 0) return;

      // Verificar si la imagen ya es principal
      final imagen = state.imagenes.firstWhere((img) => img.id == imageId);
      if (imagen.esPrincipal) return;

      state = state.copyWith(isLoading: true, errorMessage: null);

      final controller = _ref.read(inmuebleControllerProvider);

      // Marcar como principal en la base de datos
      final actualizado = await controller.marcarImagenComoPrincipal(
        imageId,
        inmuebleId,
      );

      if (!actualizado) {
        throw Exception('Error al marcar imagen como principal');
      }

      // En lugar de recargar todas las imágenes, actualizar directamente el estado
      final imagenesActualizadas =
          state.imagenes.map((img) {
            // La imagen seleccionada es principal, las demás no
            return img.id == imageId
                ? InmuebleImagen(
                  id: img.id,
                  idInmueble: img.idInmueble,
                  rutaImagen: img.rutaImagen,
                  descripcion: img.descripcion,
                  esPrincipal: true,
                  fechaCarga: img.fechaCarga,
                )
                : InmuebleImagen(
                  id: img.id,
                  idInmueble: img.idInmueble,
                  rutaImagen: img.rutaImagen,
                  descripcion: img.descripcion,
                  esPrincipal: false,
                  fechaCarga: img.fechaCarga,
                );
          }).toList();

      state = state.copyWith(imagenes: imagenesActualizadas, isLoading: false);

      // Invalidar provider de imágenes principales
      _ref.invalidate(imagenesPrincipalesProvider);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al marcar imagen como principal: $e',
      );
    }
  }

  Future<void> actualizarDescripcion(
    int imageId,
    String nuevaDescripcion,
  ) async {
    try {
      if (imageId <= 0) return;

      state = state.copyWith(isLoading: true, errorMessage: null);

      final controller = _ref.read(inmuebleControllerProvider);

      // Actualizar descripción en la base de datos
      final actualizado = await controller.actualizarDescripcionImagen(
        imageId,
        nuevaDescripcion,
      );

      if (!actualizado) {
        throw Exception('Error al actualizar descripción de imagen');
      }

      // En lugar de recargar todas las imágenes, actualizar el estado directamente
      final imagenesActualizadas =
          state.imagenes.map((img) {
            if (img.id == imageId) {
              return InmuebleImagen(
                id: img.id,
                idInmueble: img.idInmueble,
                rutaImagen: img.rutaImagen,
                descripcion: nuevaDescripcion,
                esPrincipal: img.esPrincipal,
                fechaCarga: img.fechaCarga,
              );
            }
            return img;
          }).toList();

      state = state.copyWith(imagenes: imagenesActualizadas, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar descripción: $e',
      );
    }
  }
}

// Provider para gestionar imágenes de un inmueble específico
final inmuebleImagenesStateProvider = StateNotifierProvider.family<
  InmuebleImagenesNotifier,
  InmuebleImagenesState,
  int
>((ref, inmuebleId) {
  return InmuebleImagenesNotifier(ref, inmuebleId);
});

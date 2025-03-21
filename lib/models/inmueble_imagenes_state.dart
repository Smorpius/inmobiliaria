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
  factory InmuebleImagenesState.initial() => const InmuebleImagenesState(
    imagenes: [],
    isLoading: true,
  );

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
  
  InmuebleImagenesNotifier(this._ref, this.inmuebleId) : 
    super(InmuebleImagenesState.initial()) {
    cargarImagenes();
  }
  
  Future<void> cargarImagenes() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final controller = _ref.read(inmuebleControllerProvider);
      final imagenes = await controller.getImagenesInmueble(inmuebleId);
      
      state = state.copyWith(
        imagenes: imagenes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar imágenes: $e',
      );
    }
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
        'inmueble_$inmuebleId'
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
      
      // Recargar imágenes
      await cargarImagenes();
      
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
      
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final controller = _ref.read(inmuebleControllerProvider);
      final imageService = _ref.read(imageServiceProvider);
      
      // Eliminar de base de datos
      final eliminado = await controller.eliminarImagenInmueble(imageId);
      
      if (!eliminado) {
        throw Exception('Error al eliminar imagen de la base de datos');
      }
      
      // Eliminar archivo físico
      await imageService.deleteImage(imagen.rutaImagen);
      
      // Recargar imágenes
      await cargarImagenes();
      
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
        inmuebleId
      );
      
      if (!actualizado) {
        throw Exception('Error al marcar imagen como principal');
      }
      
      // Recargar imágenes
      await cargarImagenes();
      
      // Invalidar provider de imágenes principales
      _ref.invalidate(imagenesPrincipalesProvider);
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al marcar imagen como principal: $e',
      );
    }
  }
  
  Future<void> actualizarDescripcion(int imageId, String nuevaDescripcion) async {
    try {
      if (imageId <= 0) return;
      
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final controller = _ref.read(inmuebleControllerProvider);
      
      // Actualizar descripción en la base de datos
      final actualizado = await controller.actualizarDescripcionImagen(
        imageId, 
        nuevaDescripcion
      );
      
      if (!actualizado) {
        throw Exception('Error al actualizar descripción de imagen');
      }
      
      // Recargar imágenes
      await cargarImagenes();
      
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
    int>((ref, inmuebleId) {
  return InmuebleImagenesNotifier(ref, inmuebleId);
});
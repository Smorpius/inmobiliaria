import 'dart:io';
import 'dart:async';
import '../utils/applogger.dart';
import '../widgets/user_avatar.dart';
import '../utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import 'package:image_picker/image_picker.dart';

class ImageSelectorWidget extends StatefulWidget {
  final String? imagePath;
  final String nombre;
  final String apellido;
  final bool isLoading;
  final Function(String) onImageSelected;
  final Function(String) onError;

  const ImageSelectorWidget({
    super.key,
    this.imagePath,
    required this.nombre,
    required this.apellido,
    required this.isLoading,
    required this.onImageSelected,
    required this.onError,
  });

  @override
  State<ImageSelectorWidget> createState() => _ImageSelectorWidgetState();
}

class _ImageSelectorWidgetState extends State<ImageSelectorWidget> {
  // Servicio de imágenes para operaciones optimizadas
  final ImageService _imageService = ImageService();

  // Control de estado
  bool _isMounted = true;
  bool _procesandoImagen = false;
  bool _errorCargaImagen = false;

  // Cache para evitar accesos repetitivos al sistema de archivos
  File? _cachedImageFile;
  DateTime? _cachedImageTime;
  String? _lastImagePath;

  // Timeout para operaciones
  static const Duration _timeoutOperation = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    // Cargar imagen inicial de manera eficiente
    _precargarImagen();
  }

  @override
  void didUpdateWidget(ImageSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recargar imagen solo si cambió la ruta
    if (widget.imagePath != oldWidget.imagePath) {
      _precargarImagen();
    }
  }

  /// Precarga la imagen de manera eficiente
  Future<void> _precargarImagen() async {
    // Evitar operaciones duplicadas o durante carga
    if (_procesandoImagen || widget.isLoading || !_isMounted) return;
    if (widget.imagePath == _lastImagePath && _cachedImageFile != null) return;

    setState(() {
      _errorCargaImagen = false;
      _procesandoImagen = true;
    });

    try {
      if (widget.imagePath == null || widget.imagePath!.isEmpty) {
        _limpiarCache();
        return;
      }

      // Verificar si la imagen existe
      final file = File(widget.imagePath!);
      final existe = await file.exists().timeout(
        _timeoutOperation,
        onTimeout: () {
          throw TimeoutException(
            'Tiempo de espera agotado al verificar archivo',
          );
        },
      );

      if (!_isMounted) return;

      if (existe) {
        setState(() {
          _cachedImageFile = file;
          _cachedImageTime = DateTime.now();
          _lastImagePath = widget.imagePath;
          _errorCargaImagen = false;
        });
      } else {
        _limpiarCache();
        AppLogger.warning('Imagen no encontrada: ${widget.imagePath}');
      }
    } catch (e) {
      if (!_isMounted) return;

      setState(() {
        _errorCargaImagen = true;
        _limpiarCache();
      });

      AppLogger.error('Error al cargar imagen', e, StackTrace.current);
    } finally {
      if (_isMounted) {
        setState(() => _procesandoImagen = false);
      }
    }
  }

  /// Limpia la caché de imágenes
  void _limpiarCache() {
    _cachedImageFile = null;
    _lastImagePath = null;
  }

  /// Selecciona una imagen con manejo optimizado de errores
  Future<void> _seleccionarImagen() async {
    // Prevenir múltiples operaciones simultáneas
    if (_procesandoImagen || widget.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor espere, hay una operación en curso'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _procesandoImagen = true);

    // Mostrar diálogo de opciones en lugar de directamente mostrar carga
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleccionar imagen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galería'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );

    // Si canceló la selección
    if (source == null) {
      setState(() => _procesandoImagen = false);
      return;
    }

    // Mostrar diálogo de carga
    if (!mounted) return;
    if (!context.mounted) return;
    DialogHelper.mostrarDialogoCarga(context, 'Procesando imagen...');

    try {
      // Usar método optimizado del servicio con manejo de compresión
      final pickedFile = await _imageService.pickImageFromGallery().timeout(
        _timeoutOperation,
        onTimeout:
            () =>
                throw TimeoutException(
                  'La selección de imagen está tomando demasiado tiempo',
                ),
      );

      // Cerrar diálogo de carga
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Si no seleccionó imagen
      if (pickedFile == null || !mounted) return;

      // Validar tamaño de archivo
      final fileSize = await pickedFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        // 10MB
        throw Exception('La imagen es demasiado grande (máximo 10MB)');
      }

      // Optimizar y procesar imagen
      final optimizedImage = await _imageService.optimizeImage(pickedFile);
      widget.onImageSelected(optimizedImage.path);

      // Actualizar caché inmediatamente
      if (_isMounted) {
        setState(() {
          _cachedImageFile = optimizedImage;
          _cachedImageTime = DateTime.now();
          _lastImagePath = optimizedImage.path;
          _errorCargaImagen = false;
        });
      }
    } on UnsupportedError catch (e) {
      widget.onError('Formato de imagen no soportado: ${e.message}');
      AppLogger.error('Error de formato de imagen', e, StackTrace.current);
    } on TimeoutException catch (e) {
      widget.onError('La operación tardó demasiado tiempo. Intente de nuevo.');
      AppLogger.error('Timeout al procesar imagen', e, StackTrace.current);
    } on Exception catch (e) {
      widget.onError(
        'Error al seleccionar imagen: ${e.toString().split('\n')[0]}',
      );
      AppLogger.error('Error al seleccionar imagen', e, StackTrace.current);
    } catch (e) {
      widget.onError('Error inesperado: ${e.toString().split('\n')[0]}');
      AppLogger.error(
        'Error desconocido al procesar imagen',
        e,
        StackTrace.current,
      );
    } finally {
      // Cerrar diálogo de carga si todavía está abierto
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (_isMounted) {
        setState(() => _procesandoImagen = false);
      }
    }
  }

  /// Construye la visualización de la imagen con manejo eficiente de caché
  Widget _buildImageDisplay() {
    // Usar caché si está disponible y es reciente
    if (_cachedImageFile != null &&
        _lastImagePath == widget.imagePath &&
        _cachedImageTime != null &&
        DateTime.now().difference(_cachedImageTime!) <
            const Duration(minutes: 5)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.file(
          _cachedImageFile!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          cacheWidth: 200, // Optimización para memoria
          cacheHeight: 200,
          errorBuilder: (context, error, stackTrace) {
            AppLogger.error(
              'Error al mostrar imagen en caché',
              error,
              stackTrace,
            );
            return _buildFallbackAvatar(isError: true);
          },
        ),
      );
    }

    // Si hay error conocido, evitar intentar cargar la imagen
    if (_errorCargaImagen) {
      return _buildFallbackAvatar(isError: true);
    }

    // Si no hay imagen o está procesando
    if (widget.imagePath == null ||
        widget.imagePath!.isEmpty ||
        _procesandoImagen) {
      return _buildFallbackAvatar();
    }

    // Cargar la imagen de manera eficiente
    return FutureBuilder<bool>(
      future: _verificarImagen(),
      builder: (context, snapshot) {
        // Mostrar indicador durante la verificación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        // Si la imagen existe y es válida
        if (snapshot.hasData &&
            snapshot.data == true &&
            _cachedImageFile != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.file(
              _cachedImageFile!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              cacheWidth: 200, // Optimización para memoria
              cacheHeight: 200,
              errorBuilder: (context, error, stackTrace) {
                AppLogger.error('Error al mostrar imagen', error, stackTrace);
                return _buildFallbackAvatar(isError: true);
              },
            ),
          );
        }

        // Imagen no válida o error
        return _buildFallbackAvatar(isError: snapshot.hasError);
      },
    );
  }

  /// Verifica si la imagen existe y es válida de manera optimizada
  Future<bool> _verificarImagen() async {
    try {
      if (_cachedImageFile != null && _lastImagePath == widget.imagePath) {
        return true;
      }

      if (widget.imagePath == null || widget.imagePath!.isEmpty) {
        return false;
      }

      final file = File(widget.imagePath!);
      if (!await file.exists()) {
        return false;
      }

      // Verificar que sea realmente una imagen válida (primeros bytes)
      final bytes = await file.openRead(0, 50).first;
      if (bytes.isEmpty) {
        return false;
      }

      // Actualizar caché
      if (_isMounted) {
        _cachedImageFile = file;
        _cachedImageTime = DateTime.now();
        _lastImagePath = widget.imagePath;
      }

      return true;
    } catch (e) {
      AppLogger.error('Error al verificar imagen', e, StackTrace.current);
      return false;
    }
  }

  Widget _buildFallbackAvatar({bool isError = false}) {
    return UserAvatar(
      imagePath: null,
      nombre: widget.nombre.isEmpty ? (isError ? "!" : "U") : widget.nombre,
      apellido:
          widget.apellido.isEmpty ? (isError ? "!" : "S") : widget.apellido,
      radius: 50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          GestureDetector(
            onTap:
                (widget.isLoading || _procesandoImagen)
                    ? null
                    : _seleccionarImagen,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                _buildImageDisplay(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            icon:
                _procesandoImagen || widget.isLoading
                    ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.photo_camera),
            label: Text(
              _procesandoImagen || widget.isLoading
                  ? "Procesando..."
                  : "Seleccionar imagen",
            ),
            onPressed:
                (widget.isLoading || _procesandoImagen)
                    ? null
                    : _seleccionarImagen,
            style: TextButton.styleFrom(foregroundColor: Colors.teal),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }
}

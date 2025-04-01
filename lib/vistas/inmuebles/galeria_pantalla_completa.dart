import 'dart:io';
import '../../utils/applogger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/inmueble_imagen.dart';
import '../../services/image_service.dart';
import '../../controllers/inmueble_controller.dart';

class GaleriaPantallaCompleta extends StatefulWidget {
  final int idInmueble;
  final int initialIndex;

  const GaleriaPantallaCompleta({
    super.key,
    required this.idInmueble,
    this.initialIndex = 0,
  });

  @override
  State<GaleriaPantallaCompleta> createState() =>
      _GaleriaPantallaCompletaState();
}

class _GaleriaPantallaCompletaState extends State<GaleriaPantallaCompleta> {
  final InmuebleController _inmuebleController = InmuebleController();
  final ImageService _imageService = ImageService();
  List<InmuebleImagen>? _imagenes;
  bool _cargando = true;
  bool _errorCarga = false;
  late PageController _pageController;
  int _paginaActual = 0;
  bool _procesandoOperacion = false;
  
  // Para caché de rutas de imágenes
  final Map<int, String?> _rutasImagenesCache = {};

  @override
  void initState() {
    super.initState();
    _paginaActual = widget.initialIndex;
    _pageController = PageController(initialPage: _paginaActual);
    
    // Cargar imágenes en segundo plano para evitar bloqueos en la UI
    Future.microtask(() => _cargarImagenes());

    // Poner la pantalla en modo inmersivo
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Limpiar caché para liberar memoria
    _rutasImagenesCache.clear();
    // Restaurar UI normal al salir
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _cargarImagenes() async {
    if (_procesandoOperacion) return; // Evitar múltiples llamadas simultáneas
    
    _procesandoOperacion = true;
    
    try {
      AppLogger.info('Cargando imágenes para inmueble ${widget.idInmueble}');
      
      // Utiliza el método del controlador que internamente usa withConnection
      final imagenes = await _inmuebleController.getImagenesInmueble(
        widget.idInmueble,
      );
      
      // Verificar que el widget sigue montado antes de actualizar el estado
      if (mounted) {
        setState(() {
          _imagenes = imagenes;
          _cargando = false;
          _errorCarga = false;
          
          // Precarga las rutas de las primeras imágenes para mejor rendimiento
          _precargarRutasImagenes(imagenes);
        });
        
        AppLogger.info(
          'Cargadas ${imagenes.length} imágenes para inmueble ${widget.idInmueble}'
        );
      }
    } catch (e, stackTrace) {
      // Registrar error usando AppLogger
      AppLogger.error(
        'Error al cargar imágenes de inmueble ${widget.idInmueble}', 
        e, 
        stackTrace
      );
      
      // Solo actualizar UI si el widget está montado
      if (mounted) {
        setState(() {
          _cargando = false;
          _errorCarga = true;
        });
        
        // Solo mostrar SnackBar si el widget está montado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar imágenes: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      _procesandoOperacion = false;
    }
  }
  
  // Método para precargar rutas de imágenes y mejorar rendimiento
  void _precargarRutasImagenes(List<InmuebleImagen> imagenes) {
    // Precargar solo las primeras 3 imágenes para equilibrar rendimiento
    final cantidadPrecargar = imagenes.length < 3 ? imagenes.length : 3;
    
    for (int i = 0; i < cantidadPrecargar; i++) {
      int index = (widget.initialIndex + i) % imagenes.length;
      _obtenerRutaImagen(index);
    }
  }
  
  // Método optimizado para obtener ruta de imagen con caché
  Future<String?> _obtenerRutaImagen(int index) async {
    if (_imagenes == null || _imagenes!.isEmpty || index >= _imagenes!.length) {
      return null;
    }
    
    // Si ya está en caché, retornar inmediatamente
    if (_rutasImagenesCache.containsKey(index)) {
      return _rutasImagenesCache[index];
    }
    
    try {
      final imagen = _imagenes![index];
      final ruta = await _imageService.obtenerRutaCompletaImagen(
        imagen.rutaImagen,
      );
      
      // Guardar en caché para futuras consultas
      _rutasImagenesCache[index] = ruta;
      
      return ruta;
    } catch (e) {
      // Evitar logs duplicados
      AppLogger.warning('Error al obtener ruta de imagen: ${e.toString().split('\n').first}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Manejo de estado de carga inicial
    if (_cargando && _imagenes == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Manejo de estado de error
    if (_errorCarga) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar imágenes',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _cargando ? null : _cargarImagenes,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Manejo de ausencia de imágenes
    if (_imagenes == null || _imagenes!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            'No hay imágenes disponibles',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Vista principal de galería
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_paginaActual + 1} / ${_imagenes!.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: GestureDetector(
        onTap: _toggleAppBarVisibility,
        child: PageView.builder(
          controller: _pageController,
          itemCount: _imagenes!.length,
          onPageChanged: (index) {
            setState(() {
              _paginaActual = index;
            });
            // Precargar siguiente imagen para mejor experiencia
            if (index < _imagenes!.length - 1) {
              _obtenerRutaImagen(index + 1);
            }
          },
          itemBuilder: (context, index) {
            return _buildImageView(index);
          },
        ),
      ),
      // Mostrar descripción en la parte inferior
      bottomSheet: _buildDescriptionSheet(),
    );
  }
  
  // Control para mostrar/ocultar la AppBar
  bool _appBarVisible = true;
  void _toggleAppBarVisibility() {
    setState(() {
      _appBarVisible = !_appBarVisible;
      if (_appBarVisible) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    });
  }
  
  // Widget para la visualización de imágenes con loading states
  Widget _buildImageView(int index) {
    return FutureBuilder<String?>(
      future: _obtenerRutaImagen(index),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image,
                  size: 100,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar imagen',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        // Verificar si el archivo existe antes de mostrarlo
        final file = File(snapshot.data!);
        return FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, existsSnapshot) {
            if (existsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (existsSnapshot.data != true) {
              return const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 100,
                  color: Colors.grey,
                ),
              );
            }

            return Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    AppLogger.warning(
                      'Error al renderizar imagen: ${error.toString()}',
                    );
                    return const Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Widget para la descripción en parte inferior
  Widget _buildDescriptionSheet() {
    if (!_appBarVisible || _imagenes == null || _paginaActual >= _imagenes!.length) {
      return const SizedBox.shrink(); // No mostrar si la AppBar está oculta
    }
    
    return Container(
      color: Colors.black.withAlpha(179),
      padding: const EdgeInsets.all(16.0),
      child: Text(
        _imagenes![_paginaActual].descripcion ?? 'Sin descripción',
        style: const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Método auxiliar para abrir la galería en pantalla completa desde cualquier parte
void abrirGaleriaPantallaCompleta(
  BuildContext context,
  int idInmueble, {
  int initialIndex = 0,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => GaleriaPantallaCompleta(
        idInmueble: idInmueble,
        initialIndex: initialIndex,
      ),
    ),
  );
}
import 'dart:io';
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
  late PageController _pageController;
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    _paginaActual = widget.initialIndex;
    _pageController = PageController(initialPage: _paginaActual);
    _cargarImagenes();

    // Poner la pantalla en modo inmersivo
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restaurar UI normal al salir
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _cargarImagenes() async {
    try {
      final imagenes = await _inmuebleController.getImagenesInmueble(
        widget.idInmueble,
      );
      if (mounted) {
        setState(() {
          _imagenes = imagenes;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar imágenes: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _imagenes == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

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
        onTap: () {
          // Mostrar/ocultar AppBar al tocar (opcional)
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: _imagenes!.length,
          onPageChanged: (index) {
            setState(() {
              _paginaActual = index;
            });
          },
          itemBuilder: (context, index) {
            return FutureBuilder<String?>(
              future: _imageService.obtenerRutaCompletaImagen(
                _imagenes![index].rutaImagen,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
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
                      File(snapshot.data!),
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      // Opcional: mostrar descripción en la parte inferior
      bottomSheet: Container(
        // Corrección: reemplazado withOpacity por withAlpha (0.7 * 255 ≈ 179)
        color: Colors.black.withAlpha(179),
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _imagenes![_paginaActual].descripcion ?? 'Sin descripción',
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
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
      builder:
          (context) => GaleriaPantallaCompleta(
            idInmueble: idInmueble,
            initialIndex: initialIndex,
          ),
    ),
  );
}

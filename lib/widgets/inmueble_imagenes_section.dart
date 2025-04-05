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
import 'dart:math' as math; // Adding proper import for math functions

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
            SizedBox(
              height: _carouselHeight,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Cargando imágenes...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else if (state.errorMessage != null)
            _buildErrorMessage(context, ref, state.errorMessage!)
          else if (state.imagenes.isEmpty)
            _buildEmptyImagesMessage(context, ref)
          else
            _buildImagesCarousel(context, ref, state),

          // Información de cómo actualizar las imágenes
          if (!isInactivo && state.imagenes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón para verificar y reparar imágenes dañadas
                  TextButton.icon(
                    icon: const Icon(Icons.healing, size: 16),
                    label: const Text(
                      'Reparar imágenes',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed:
                        () => limpiarImagenesDanadas(
                          context,
                          ref,
                          state.imagenes,
                        ),
                  ),

                  // Botón para ver galería completa
                  TextButton.icon(
                    icon: const Icon(Icons.photo_library, size: 16),
                    label: const Text(
                      'Ver galería',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _abrirGaleriaPantallaCompleta(context),
                  ),
                ],
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
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
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
    final esErrorPermiso =
        errorMessage.contains('permission') ||
        errorMessage.contains('denied') ||
        errorMessage.contains('access');

    IconData iconoError;
    String mensajeError;
    Color colorError;
    String mensajeAyuda = '';

    if (esMySqlError) {
      iconoError = Icons.storage_outlined;
      mensajeError = 'Error de comunicación con la base de datos';
      colorError = Colors.orange;
      mensajeAyuda = 'Verifique la conexión a la base de datos y reintente';
    } else if (esErrorConexion) {
      iconoError = Icons.wifi_off;
      mensajeError = 'Problema de conexión a la base de datos';
      colorError = Colors.orange.shade700;
      mensajeAyuda = 'Compruebe su conexión a internet y reintente';
    } else if (esErrorFormato) {
      iconoError = Icons.file_copy_outlined;
      mensajeError = 'Error en el formato de los datos de imagen';
      colorError = Colors.red.shade300;
      mensajeAyuda =
          'Las imágenes pueden estar dañadas o en formato no compatible';
    } else if (esErrorPermiso) {
      iconoError = Icons.no_encryption_gmailerrorred;
      mensajeError = 'Sin permiso para acceder a las imágenes';
      colorError = Colors.red.shade700;
      mensajeAyuda =
          'Verifique los permisos de acceso a las carpetas de imágenes';
    } else {
      iconoError = Icons.error_outline;
      mensajeError = 'Error al cargar imágenes';
      colorError = Colors.red;
      mensajeAyuda = errorMessage.split('\n').first;
    }

    return Container(
      height: _carouselHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconoError, size: 48, color: colorError),
            const SizedBox(height: 16),
            Text(
              mensajeError,
              style: TextStyle(
                color: colorError,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (mensajeAyuda.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  mensajeAyuda,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
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
            if (!isInactivo)
              TextButton(
                onPressed: () => _mostrarOpcionesAgregarImagen(context, ref),
                child: const Text('Agregar nueva imagen'),
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
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
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
    // Verificar si hay al menos una imagen con ruta accesible
    bool hayImagenesValidas = false;
    for (var imagen in state.imagenes) {
      if (imagen.rutaImagen.isNotEmpty &&
          File(imagen.rutaImagen).existsSync()) {
        hayImagenesValidas = true;
        break;
      }
    }

    if (!hayImagenesValidas) {
      return Container(
        height: _carouselHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Las imágenes están registradas pero no se pueden acceder a los archivos',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prueba agregar nuevas imágenes o reparar las existentes',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed:
                    () => limpiarImagenesDanadas(context, ref, state.imagenes),
                icon: const Icon(Icons.healing),
                label: const Text('Reparar imágenes'),
              ),
            ],
          ),
        ),
      );
    }

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
            height: _carouselHeight,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  /// Verifica si una imagen es válida con timeout para prevenir bloqueos
  Future<bool> verificarImagenValida(File file) async {
    try {
      AppLogger.info('Verificando imagen: ${file.path}');

      // Verificación inicial básica
      if (!file.existsSync()) {
        AppLogger.warning('Archivo de imagen no existe: ${file.path}');
        return false;
      }

      final fileSize = await file.length();
      if (fileSize <= 0) {
        AppLogger.warning('Archivo de imagen vacío (0 bytes): ${file.path}');
        return false;
      }

      // Usamos el mismo umbral que en InmuebleImagenCarousel (100 bytes)
      if (fileSize < 100) {
        AppLogger.warning(
          'Archivo de imagen demasiado pequeño ($fileSize bytes): ${file.path}',
        );
        return false;
      }

      // Para archivos grandes, solo verificamos la cabecera para evitar bloqueos
      if (fileSize > 1024 * 1024) {
        // > 1MB
        try {
          final bytes = await file.openRead(0, 16).first;
          if (bytes.isEmpty) {
            AppLogger.warning('Cabecera de imagen vacía: ${file.path}');
            return false;
          }

          // Verificar formatos comunes por su cabecera
          final isJpeg =
              bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
          final isPng =
              bytes.length > 7 &&
              bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E;
          final isGif =
              bytes.length > 3 &&
              bytes[0] == 0x47 &&
              bytes[1] == 0x49 &&
              bytes[2] == 0x46;
          final isBmp =
              bytes.length > 1 && bytes[0] == 0x42 && bytes[1] == 0x4D;
          final isWebp =
              bytes.length > 11 &&
              bytes[0] == 0x52 &&
              bytes[1] == 0x49 &&
              bytes[2] == 0x46 &&
              bytes[8] == 0x57 &&
              bytes[9] == 0x45 &&
              bytes[10] == 0x42;

          if (isJpeg || isPng || isGif || isBmp || isWebp) {
            // Si detectamos un formato válido por cabecera, lo consideramos válido
            AppLogger.info('Imagen válida por cabecera: ${file.path}');
            return true;
          }
        } catch (e) {
          AppLogger.warning(
            'Error al leer cabecera de imagen: ${file.path} - $e',
          );
        }
      }

      // Para archivos pequeños o si no pudimos verificar por cabecera
      // Intentamos abrir el archivo como imagen
      try {
        // Solo leemos los primeros bytes para minimizar uso de memoria
        final bytesLength =
            fileSize < 10240
                ? fileSize.toInt()
                : 10240; // Max 10KB para verificación
        final bytes = await file.readAsBytes().timeout(
          _imagenValidacionTimeout,
        );
        final chunk =
            bytes.length > bytesLength ? bytes.sublist(0, bytesLength) : bytes;

        // Usamos decodeImageFromList que es el método que usa Flutter para renderizar imágenes
        await decodeImageFromList(chunk).timeout(_imagenValidacionTimeout);
        AppLogger.info('Imagen válida por decodificación: ${file.path}');
        return true;
      } catch (decodeError) {
        AppLogger.warning(
          'Error al decodificar imagen ${file.path}: $decodeError',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error(
        'Error general al validar imagen: ${file.path}',
        e,
        StackTrace.current,
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

    // Mostrar estado de inicio
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Verificando imágenes...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    // Recopilar información de imágenes dañadas
    final List<InmuebleImagen> imagenesDanadas = [];
    final List<String> razonesErrores = [];
    final Set<String> rutasProcesadas = {}; // Para evitar duplicados por ruta

    for (final imagen in imagenes) {
      try {
        // Verificar si ya procesamos una imagen con esta ruta
        if (rutasProcesadas.contains(imagen.rutaImagen)) {
          continue;
        }

        rutasProcesadas.add(imagen.rutaImagen);
        final file = File(imagen.rutaImagen);

        // Verificar si el archivo existe
        if (!file.existsSync()) {
          if (imagen.id != null) {
            imagenesDanadas.add(imagen);
            razonesErrores.add("No se encuentra el archivo: ${file.path}");
          }
          continue;
        }

        // Verificar si es una imagen válida
        final esValida = await verificarImagenValida(file);

        if (!esValida && imagen.id != null) {
          imagenesDanadas.add(imagen);
          razonesErrores.add("Imagen inválida o dañada: ${file.path}");
        }
      } catch (e) {
        if (imagen.id != null && !rutasProcesadas.contains(imagen.rutaImagen)) {
          imagenesDanadas.add(imagen);
          razonesErrores.add(
            "Error en la verificación: ${e.toString().split('\n').first}",
          );
          rutasProcesadas.add(imagen.rutaImagen);
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

    // Mostrar diálogo con lista de imágenes dañadas
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Se encontraron ${imagenesDanadas.length} imágenes dañadas',
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: math.min(imagenesDanadas.length, 10),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(
                      Icons.broken_image,
                      color: Colors.orange,
                    ),
                    title: Text(
                      'Imagen ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      index < razonesErrores.length
                          ? razonesErrores[index]
                          : 'Imagen dañada',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  'Eliminar ${imagenesDanadas.length} imágenes dañadas',
                ),
              ),
            ],
          ),
    );

    if (confirmar != true || !context.mounted) return;

    // Mostrar indicador de progreso
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Eliminando imágenes dañadas...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    // Eliminar las imágenes dañadas
    final notifier = ref.read(
      inmuebleImagenesStateProvider(inmuebleId).notifier,
    );
    int eliminadas = 0;
    final Set<int> idsEliminados = {}; // Evitar eliminar duplicados por ID

    for (final imagen in imagenesDanadas) {
      if (imagen.id != null && !idsEliminados.contains(imagen.id)) {
        try {
          await notifier.eliminarImagen(imagen.id!);
          idsEliminados.add(imagen.id!);
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Mostrar resultado final
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Se ${eliminadas > 0 ? "eliminaron $eliminadas" : "intentó eliminar"} '
          'de ${imagenesDanadas.length} ${imagenesDanadas.length == 1 ? "imagen dañada" : "imágenes dañadas"}',
        ),
        backgroundColor: eliminadas > 0 ? Colors.green : Colors.orange,
      ),
    );

    // Si hubo errores al eliminar algunas imágenes, mostrar un mensaje adicional
    if (eliminadas < imagenesDanadas.length && context.mounted) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Algunas imágenes no pudieron ser eliminadas. Inténtelo nuevamente más tarde.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }
  }

  /// Abre la galería en pantalla completa
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
            backgroundColor: Colors.red,
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
            'Error al mostrar opciones: ${e.toString().split('\n').first}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Método optimizado para agregar imágenes con validaciones completas
  Future<void> _agregarImagen(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final imageService = ref.read(imageServiceProvider);

      // Mostrar indicador de progreso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Seleccionando imagen...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // Seleccionar imagen
      final File? imagen = await imageService.pickImage(source);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (imagen == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selección de imagen cancelada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Validaciones de la imagen
      if (!await imagen.exists()) {
        if (!context.mounted) return;
        _mostrarSnackbarError(
          context,
          'No se pudo acceder al archivo de imagen',
        );
        return;
      }

      final tamanoImagen = await imagen.length();

      if (tamanoImagen < 100) {
        if (!context.mounted) return;
        _mostrarSnackbarError(context, 'Archivo de imagen dañado o vacío');
        return;
      }

      if (tamanoImagen > 10 * 1024 * 1024) {
        if (!context.mounted) return;
        _mostrarSnackbarError(
          context,
          'La imagen es demasiado grande (máximo 10MB)',
        );
        return;
      }

      // Validar que es una imagen válida intentando decodificarla
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

      // Solicitar descripción de la imagen
      if (!context.mounted) return;
      final descripcion = await _mostrarDialogoDescripcion(context);
      if (descripcion == null) return;

      if (!context.mounted) return;

      // Mostrar indicador de carga durante el proceso de subida
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Guardando imagen...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Subir la imagen
      await ref
          .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
          .agregarImagen(imagen, descripcion);

      // Actualizar las imágenes principales si es necesario
      ref.invalidate(imagenesPrincipalesProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen agregada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stack) {
      AppLogger.error('Error al agregar imagen', e, stack);

      if (!context.mounted) return;

      final esErrorConexion =
          e.toString().contains('socket') ||
          e.toString().contains('connection');
      final esMySqlError =
          e.toString().contains('MySQL') ||
          e.toString().contains('MySqlProtocol');
      final esErrorImagen =
          e.toString().contains('ImagePicker') ||
          e.toString().contains('file') ||
          e.toString().contains('permission');

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

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
        // Mostrar indicador de progreso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Actualizando descripción...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );

        await ref
            .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
            .actualizarDescripcion(imagen.id!, nuevaDescripcion);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Descripción actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

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

  /// Marca una imagen como principal
  Future<void> _marcarComoPrincipal(
    BuildContext context,
    WidgetRef ref,
    InmuebleImagen imagen,
  ) async {
    if (imagen.id == null || !context.mounted) return;

    try {
      // Mostrar indicador de progreso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Marcando como principal...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // Obtener el notifier a través del provider
      final notifier = ref.read(
        inmuebleImagenesStateProvider(inmuebleId).notifier,
      );

      // Marcar como principal
      await notifier.marcarComoPrincipal(imagen.id!);

      // Actualizar las imágenes principales
      ref.invalidate(imagenesPrincipalesProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

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

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

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
                        ref.read(dbServiceProvider).reiniciarConexion().then((
                          _,
                        ) {
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿Está seguro que desea eliminar esta imagen?'),
                  if (imagen.esPrincipal)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.amber.shade700),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber.shade800,
                            ),
                            const SizedBox(width: 8.0),
                            const Expanded(
                              child: Text(
                                'Esta es la imagen principal. Si la elimina, deberá establecer otra imagen como principal.',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
        // Mostrar indicador de progreso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Eliminando imagen...'),
              ],
            ),
            duration: Duration(seconds: 15),
          ),
        );

        final eraImagenPrincipal = imagen.esPrincipal;

        await ref
            .read(inmuebleImagenesStateProvider(inmuebleId).notifier)
            .eliminarImagen(imagen.id!);

        // Si era la imagen principal, actualizar la lista de imágenes principales
        if (eraImagenPrincipal) {
          ref.invalidate(imagenesPrincipalesProvider);
        }

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
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

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

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
                helperText: 'Ejemplo: Vista frontal del inmueble',
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

import 'dart:io';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inmobiliaria/utils/applogger.dart';
import 'package:inmobiliaria/services/mysql_helper.dart';
import 'package:inmobiliaria/models/inmueble_imagen.dart';

/// Clase para validar imágenes
class ImageValidator {
  /// Valida una imagen y devuelve el resultado de la validación
  Future<ImageValidationResult> validateImage(File imageFile) async {
    try {
      // Verificar si el archivo existe
      if (!await imageFile.exists()) {
        return ImageValidationResult(false, 'El archivo no existe');
      }

      // Verificar si es realmente una imagen
      final bytes = await imageFile.readAsBytes();
      if (bytes.length < 10) {
        return ImageValidationResult(
          false,
          'El archivo no parece ser una imagen válida',
        );
      }

      // Verificar el tamaño máximo (10MB)
      const int maxSizeBytes = 10 * 1024 * 1024;
      if (bytes.length > maxSizeBytes) {
        return ImageValidationResult(
          false,
          'La imagen excede el tamaño máximo permitido (10MB)',
        );
      }

      return ImageValidationResult(true, '');
    } catch (e) {
      return ImageValidationResult(false, 'Error al validar imagen: $e');
    }
  }
}

/// Resultado de la validación de imagen
class ImageValidationResult {
  final bool isValid;
  final String errorMessage;

  ImageValidationResult(this.isValid, this.errorMessage);
}

/// Servicio para gestionar operaciones con imágenes (carga, validación, almacenamiento)
class ImageService {
  final ImageValidator _validator = ImageValidator();
  final DatabaseService _db;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Control para evitar logs duplicados
  bool _procesandoError = false;

  // Directorio base para almacenamiento de imágenes
  static const String _baseImageDirectory = 'images';
  static const String _inmuebleDirectory = 'inmuebles';

  ImageService({DatabaseService? dbService})
    : _db = dbService ?? DatabaseService();

  /// Carga una imagen desde el dispositivo (cámara o galería)
  Future<File?> cargarImagenDesdeDispositivo(ImageSource source) async {
    try {
      AppLogger.info(
        'Seleccionando imagen desde ${source == ImageSource.camera ? 'cámara' : 'galería'}',
      );

      // Seleccionar imagen con ImagePicker
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Calidad moderada para reducir tamaño
        maxHeight: 1200,
        maxWidth: 1200,
      );

      if (pickedFile == null) {
        AppLogger.info('Selección de imagen cancelada por el usuario');
        return null;
      }

      // Convertir XFile a File
      final File imageFile = File(pickedFile.path);

      // Validar el archivo de imagen
      final validationResult = await _validator.validateImage(imageFile);
      if (!validationResult.isValid) {
        AppLogger.warning('Imagen no válida: ${validationResult.errorMessage}');
        return null;
      }

      return imageFile;
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al cargar imagen', e, stackTrace);
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Guarda la imagen para un inmueble y devuelve la ruta relativa
  Future<String?> guardarImagenInmueble(File imagen, int idInmueble) async {
    try {
      AppLogger.info('Guardando imagen para inmueble ID: $idInmueble');

      // 1. Validar la imagen
      final validationResult = await _validator.validateImage(imagen);
      if (!validationResult.isValid) {
        AppLogger.warning('Imagen no válida: ${validationResult.errorMessage}');
        return null;
      }

      // 2. Crear estructura de directorios si no existe
      final Directory baseDir = await _getInmuebleImageDirectory(idInmueble);
      if (!await baseDir.exists()) {
        await baseDir.create(recursive: true);
      }

      // 3. Generar nombre único para el archivo
      final String uniqueId = _uuid.v4();
      final String extension = path.extension(imagen.path).toLowerCase();
      final String fileName = 'img_${idInmueble}_$uniqueId$extension';

      // 4. Construir ruta completa donde guardar la imagen
      final File destinationFile = File(path.join(baseDir.path, fileName));

      // 5. Copiar el archivo con manejo de errores
      await imagen.copy(destinationFile.path);

      // 6. Construir ruta relativa para almacenar en BD
      final String rutaRelativa = path
          .join(_inmuebleDirectory, idInmueble.toString(), fileName)
          .replaceAll(
            '\\',
            '/',
          ); // Normalizar separadores para mayor compatibilidad

      AppLogger.info('Imagen guardada en: $rutaRelativa');
      return rutaRelativa;
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al guardar imagen del inmueble', e, stackTrace);
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Elimina una imagen de un inmueble
  Future<bool> eliminarImagenInmueble(String rutaRelativa) async {
    try {
      AppLogger.info('Eliminando imagen: $rutaRelativa');

      // Convertir ruta relativa a ruta completa
      final File imageFile = await _getFileFromRelativePath(rutaRelativa);

      // Verificar si el archivo existe
      if (!await imageFile.exists()) {
        AppLogger.warning('El archivo a eliminar no existe: $rutaRelativa');
        return true; // Consideramos éxito si el archivo ya no existe
      }

      // Eliminar el archivo
      await imageFile.delete();
      AppLogger.info('Archivo eliminado correctamente: $rutaRelativa');
      return true;
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al eliminar imagen', e, stackTrace);
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Obtiene imágenes asociadas a un inmueble desde la base de datos
  Future<List<InmuebleImagen>> obtenerImagenesInmueble(int idInmueble) async {
    try {
      AppLogger.info('Consultando imágenes para inmueble ID: $idInmueble');

      return await _db.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerImagenesInmueble(?)', [
          idInmueble,
        ]);

        final List<InmuebleImagen> imagenes = [];
        for (var row in results) {
          try {
            if (row.fields['id_imagen'] != null &&
                row.fields['id_inmueble'] != null &&
                row.fields['ruta_imagen'] != null) {
              imagenes.add(InmuebleImagen.fromMap(row.fields));
            }
          } catch (e) {
            AppLogger.warning('Error al procesar registro de imagen: $e');
          }
        }

        AppLogger.info(
          'Se encontraron ${imagenes.length} imágenes para el inmueble $idInmueble',
        );
        return imagenes;
      });
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al consultar imágenes del inmueble',
          e,
          stackTrace,
        );
        _procesandoError = false;
      }
      return [];
    }
  }

  /// Obtiene la imagen principal de un inmueble
  Future<InmuebleImagen?> obtenerImagenPrincipal(int idInmueble) async {
    try {
      AppLogger.info(
        'Obteniendo imagen principal para inmueble ID: $idInmueble',
      );

      return await _db.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerImagenPrincipal(?)', [
          idInmueble,
        ]);

        if (results.isEmpty ||
            results.first.fields.isEmpty ||
            results.first.fields['id_imagen'] == null) {
          AppLogger.info(
            'No se encontró imagen principal para inmueble: $idInmueble',
          );
          return null;
        }

        return InmuebleImagen.fromMap(results.first.fields);
      });
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al obtener imagen principal', e, stackTrace);
        _procesandoError = false;
      }
      return null;
    }
  }

  /// Registra una nueva imagen en la base de datos
  Future<int> registrarImagenInmueble(InmuebleImagen imagen) async {
    try {
      AppLogger.info(
        'Registrando imagen en BD para inmueble ID: ${imagen.idInmueble}, '
        'es principal: ${imagen.esPrincipal}',
      );

      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn
              .query('CALL AgregarImagenInmueble(?, ?, ?, ?, @id_imagen_out)', [
                imagen.idInmueble,
                imagen.rutaImagen,
                imagen.descripcion,
                imagen.esPrincipal ? 1 : 0,
              ]);

          final result = await conn.query('SELECT @id_imagen_out as id');
          if (result.isEmpty || result.first['id'] == null) {
            await conn.query('ROLLBACK');
            throw Exception('No se pudo obtener el ID de la imagen agregada');
          }

          final idImagen = result.first['id'] as int;
          await conn.query('COMMIT');
          AppLogger.info('Imagen registrada con ID: $idImagen');
          return idImagen;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error(
            'Error en transacción al registrar imagen',
            e,
            StackTrace.current,
          );
          rethrow;
        }
      });
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al registrar imagen en BD', e, stackTrace);
        _procesandoError = false;
      }
      return 0;
    }
  }

  /// Establece una imagen como la principal para el inmueble
  Future<bool> marcarImagenComoPrincipal(int idImagen, int idInmueble) async {
    try {
      AppLogger.info(
        'Marcando imagen $idImagen como principal para inmueble $idInmueble',
      );

      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL MarcarImagenComoPrincipal(?, ?)', [
            idImagen,
            idInmueble,
          ]);

          await conn.query('COMMIT');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error(
            'Error en transacción al marcar imagen como principal',
            e,
            StackTrace.current,
          );
          rethrow;
        }
      });
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al marcar imagen como principal', e, stackTrace);
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Actualiza la descripción de una imagen
  Future<bool> actualizarDescripcionImagen(
    int idImagen,
    String nuevaDescripcion,
  ) async {
    try {
      AppLogger.info('Actualizando descripción de imagen ID: $idImagen');

      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL ActualizarDescripcionImagen(?, ?)', [
            idImagen,
            nuevaDescripcion,
          ]);

          await conn.query('COMMIT');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error(
            'Error en transacción al actualizar descripción',
            e,
            StackTrace.current,
          );
          rethrow;
        }
      });
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al actualizar descripción de imagen',
          e,
          stackTrace,
        );
        _procesandoError = false;
      }
      return false;
    }
  }

  /// Limpia imágenes huérfanas (sin referencia en la BD)
  Future<int> limpiarImagenesHuerfanas() async {
    try {
      AppLogger.info('Iniciando limpieza de imágenes huérfanas');

      return await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query(
            'CALL LimpiarImagenesHuerfanas(@imagenes_eliminadas)',
          );

          final result = await conn.query(
            'SELECT @imagenes_eliminadas as eliminadas',
          );
          if (result.isEmpty || result.first.fields['eliminadas'] == null) {
            await conn.query('ROLLBACK');
            throw Exception(
              'No se pudo obtener el número de imágenes eliminadas',
            );
          }

          final int eliminadas = result.first.fields['eliminadas'] as int;
          await conn.query('COMMIT');

          AppLogger.info(
            'Limpieza completada. Imágenes huérfanas eliminadas: $eliminadas',
          );
          return eliminadas;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error(
            'Error en transacción al limpiar imágenes huérfanas',
            e,
            StackTrace.current,
          );
          rethrow;
        }
      });
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al limpiar imágenes huérfanas', e, stackTrace);
        _procesandoError = false;
      }
      return 0;
    }
  }

  /// Obtiene el directorio para las imágenes de un inmueble
  Future<Directory> _getInmuebleImageDirectory(int idInmueble) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dirPath = path.join(
      appDir.path,
      _baseImageDirectory,
      _inmuebleDirectory,
      idInmueble.toString(),
    );
    return Directory(dirPath);
  }

  /// Convierte una ruta relativa a un File
  Future<File> _getFileFromRelativePath(String relativePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fullPath = path.join(appDir.path, _baseImageDirectory, relativePath);
    return File(fullPath);
  }

  /// Verifica si una imagen existe físicamente
  Future<bool> verificarExistenciaImagenFisica(String rutaImagen) async {
    try {
      final file = await _getFileFromRelativePath(rutaImagen);
      final existe = await file.exists();
      final tamanoValido = existe ? await file.length() > 100 : false;
      return existe && tamanoValido;
    } catch (e) {
      AppLogger.warning('Error al verificar existencia física de imagen: $e');
      return false;
    }
  }
}

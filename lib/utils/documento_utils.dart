import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../utils/applogger.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Utilidad para manejar archivos de documentación como comprobantes y contratos
class DocumentoUtils {
  /// Extensiones de archivos permitidas para documentos
  static const List<String> extensionesPermitidas = [
    'jpg',
    'jpeg',
    'png',
    'pdf',
    'doc',
    'docx',
  ];

  /// Tamaño máximo de archivo permitido (en bytes) - 10 MB
  static const int tamanoMaximoBytes = 10 * 1024 * 1024;

  /// Directorio base para almacenar documentos
  static const String _directorioBase = 'documentos';

  /// Guarda un archivo de documento y devuelve la ruta relativa donde se guardó
  ///
  /// [bytes] - Los bytes del archivo a guardar
  /// [extension] - La extensión del archivo (sin punto)
  /// [subcarpeta] - Subcarpeta donde guardar (ej: 'comprobantes', 'contratos')
  /// [idReferencia] - ID de la entidad a la que está asociado el documento
  /// [nombreArchivo] - Nombre base del archivo (opcional)
  static Future<String> guardarDocumento({
    required Uint8List bytes,
    required String extension,
    required String subcarpeta,
    required int idReferencia,
    String? nombreArchivo,
  }) async {
    try {
      // Validar la extensión
      final extensionLimpia = extension.toLowerCase().replaceAll('.', '');
      if (!extensionesPermitidas.contains(extensionLimpia)) {
        throw ArgumentError('Tipo de archivo no permitido: $extension');
      }

      // Validar el tamaño
      if (bytes.length > tamanoMaximoBytes) {
        throw ArgumentError('El archivo excede el tamaño máximo permitido');
      }

      // Crear nombre de archivo único
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final uuid = const Uuid().v4().substring(0, 8);
      final nombre =
          nombreArchivo?.isNotEmpty == true
              ? '${_sanitizarNombreArchivo(nombreArchivo!)}_$timestamp'
              : '${subcarpeta}_${idReferencia}_$timestamp';

      final nombreCompleto = '${nombre}_$uuid.$extensionLimpia';

      // Construir la ruta del directorio
      final dirBase = await _obtenerDirectorioDocumentos();
      final directorioFinal = path.join(
        dirBase.path,
        _directorioBase,
        subcarpeta,
        idReferencia.toString(),
      );

      // Crear el directorio si no existe
      final dir = Directory(directorioFinal);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      // Construir la ruta completa del archivo
      final rutaCompleta = path.join(directorioFinal, nombreCompleto);

      // Escribir el archivo
      final file = File(rutaCompleta);
      await file.writeAsBytes(bytes);

      // Devolver la ruta relativa para almacenar en la base de datos
      final rutaRelativa = path.join(
        _directorioBase,
        subcarpeta,
        idReferencia.toString(),
        nombreCompleto,
      );
      return rutaRelativa;
    } catch (e, stackTrace) {
      AppLogger.error('Error al guardar documento', e, stackTrace);
      rethrow;
    }
  }

  /// Guarda un documento desde un archivo local y devuelve la ruta relativa
  static Future<String> guardarDesdeArchivo({
    required String rutaArchivo,
    required String subcarpeta,
    required int idReferencia,
    String? nombreArchivo,
  }) async {
    try {
      final file = File(rutaArchivo);
      if (!await file.exists()) {
        throw FileSystemException('El archivo no existe', rutaArchivo);
      }

      final bytes = await file.readAsBytes();
      final extension = path.extension(rutaArchivo).replaceAll('.', '');

      return await guardarDocumento(
        bytes: bytes,
        extension: extension,
        subcarpeta: subcarpeta,
        idReferencia: idReferencia,
        nombreArchivo: nombreArchivo,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al guardar documento desde archivo',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Elimina un documento usando la ruta relativa
  static Future<bool> eliminarDocumento(String rutaRelativa) async {
    try {
      final dirBase = await _obtenerDirectorioDocumentos();
      final rutaCompleta = path.join(dirBase.path, rutaRelativa);

      final file = File(rutaCompleta);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error al eliminar documento', e, stackTrace);
      return false;
    }
  }

  /// Obtiene un archivo como bytes desde su ruta relativa
  static Future<Uint8List?> obtenerBytesDocumento(String rutaRelativa) async {
    try {
      final dirBase = await _obtenerDirectorioDocumentos();
      final rutaCompleta = path.join(dirBase.path, rutaRelativa);

      final file = File(rutaCompleta);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Error al leer documento', e, stackTrace);
      return null;
    }
  }

  /// Obtiene la ruta completa a un documento a partir de su ruta relativa
  static Future<String> obtenerRutaCompleta(String rutaRelativa) async {
    final dirBase = await _obtenerDirectorioDocumentos();
    return path.join(dirBase.path, rutaRelativa);
  }

  /// Verifica si un documento existe en el sistema de archivos
  static Future<bool> verificarExistenciaDocumento(String rutaRelativa) async {
    try {
      final dirBase = await _obtenerDirectorioDocumentos();
      final rutaCompleta = path.join(dirBase.path, rutaRelativa);

      final file = File(rutaCompleta);
      return await file.exists();
    } catch (e) {
      AppLogger.warning('Error al verificar existencia del documento: $e');
      return false;
    }
  }

  /// Obtiene el tamaño de un documento en bytes
  static Future<int> obtenerTamanoDocumento(String rutaRelativa) async {
    try {
      final dirBase = await _obtenerDirectorioDocumentos();
      final rutaCompleta = path.join(dirBase.path, rutaRelativa);

      final file = File(rutaCompleta);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      AppLogger.warning('Error al obtener tamaño del documento: $e');
      return 0;
    }
  }

  /// Copia un documento a una nueva ubicación
  static Future<String?> copiarDocumento({
    required String rutaRelativa,
    required String nuevaSubcarpeta,
    required int idReferencia,
    String? nuevoNombre,
  }) async {
    try {
      // Obtener los bytes del documento original
      final bytes = await obtenerBytesDocumento(rutaRelativa);
      if (bytes == null) return null;

      // Extraer la extensión del archivo original
      final extension = path.extension(rutaRelativa).replaceAll('.', '');

      // Guardar como nuevo documento
      return await guardarDocumento(
        bytes: bytes,
        extension: extension,
        subcarpeta: nuevaSubcarpeta,
        idReferencia: idReferencia,
        nombreArchivo: nuevoNombre,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al copiar documento', e, stackTrace);
      return null;
    }
  }

  /// Valida si una extensión de archivo es permitida para documentos
  static bool esExtensionPermitida(String extension) {
    final extensionLimpia = extension.toLowerCase().replaceAll('.', '');
    return extensionesPermitidas.contains(extensionLimpia);
  }

  /// Determina si un documento es un PDF según su ruta
  static bool esPDF(String rutaArchivo) {
    return rutaArchivo.toLowerCase().endsWith('.pdf');
  }

  /// Determina si un documento es una imagen según su ruta
  static bool esImagen(String rutaArchivo) {
    final extensionesImagen = ['jpg', 'jpeg', 'png'];
    final extension = path
        .extension(rutaArchivo)
        .toLowerCase()
        .replaceAll('.', '');
    return extensionesImagen.contains(extension);
  }

  /// Determina si un documento es un documento de Word según su ruta
  static bool esDocumentoWord(String rutaArchivo) {
    final extensionesWord = ['doc', 'docx'];
    final extension = path
        .extension(rutaArchivo)
        .toLowerCase()
        .replaceAll('.', '');
    return extensionesWord.contains(extension);
  }

  /// Sanitiza un nombre de archivo para eliminar caracteres no permitidos
  static String _sanitizarNombreArchivo(String nombre) {
    // Reemplazar caracteres no permitidos en nombres de archivo
    return nombre
        .replaceAll(
          RegExp(r'[<>:"/\\|?*]'),
          '_',
        ) // Caracteres no permitidos en Windows
        .replaceAll(' ', '_') // Espacios a guiones bajos
        .replaceAll(
          RegExp(r'[^\w\-.]'),
          '',
        ); // Solo mantener alfanuméricos, guiones y puntos
  }

  /// Obtiene el directorio base para documentos (application documents directory)
  static Future<Directory> _obtenerDirectorioDocumentos() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'La funcionalidad de archivos no está soportada en web',
      );
    }

    return await getApplicationDocumentsDirectory();
  }

  /// Genera una ruta para almacenar comprobantes de movimientos
  static String generarRutaRelativaComprobantesMovimiento(int idMovimiento) {
    return path.join(
      _directorioBase,
      'comprobantes_movimiento',
      idMovimiento.toString(),
    );
  }

  /// Genera una ruta para almacenar comprobantes de ventas
  static String generarRutaRelativaComprobantesVenta(int idVenta) {
    return path.join(_directorioBase, 'comprobantes_venta', idVenta.toString());
  }

  /// Genera una ruta para almacenar contratos de renta
  static String generarRutaRelativaContratosRenta(int idContrato) {
    return path.join(_directorioBase, 'contratos_renta', idContrato.toString());
  }

  /// Genera una ruta para almacenar contratos de venta
  static String generarRutaRelativaContratosVenta(int idVenta) {
    return path.join(_directorioBase, 'contratos_venta', idVenta.toString());
  }

  /// Mueve un archivo de una ubicación temporal a la ubicación final de documentos
  static Future<String> moverArchivoTemporal({
    required String rutaTemporal,
    required String subcarpeta,
    required int idReferencia,
    String? nombreArchivo,
  }) async {
    try {
      return await guardarDesdeArchivo(
        rutaArchivo: rutaTemporal,
        subcarpeta: subcarpeta,
        idReferencia: idReferencia,
        nombreArchivo: nombreArchivo,
      );
    } finally {
      // Intentar eliminar el archivo temporal
      try {
        final tempFile = File(rutaTemporal);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        // Ignorar errores al eliminar archivos temporales
        AppLogger.warning('No se pudo eliminar archivo temporal: $e');
      }
    }
  }
}

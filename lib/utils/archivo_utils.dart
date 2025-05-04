import 'dart:io';
import '../utils/applogger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Clase de utilidades para manejo de archivos y rutas
class ArchivoUtils {
  /// Directorios internos relativos (ahora públicos para ser accesibles desde fuera)
  static const String dirComprobantes = 'comprobantes';
  static const String dirContratos = 'contratos';
  static const String dirTemp = 'temp';

  // Mantener copias privadas para uso interno
  static const String _dirComprobantes = dirComprobantes;
  static const String _dirContratos = dirContratos;
  static const String _dirTemp = dirTemp;

  /// Ruta relativa para documentos
  static const String _rutaRelativaDocumentos = 'assets/documentos';

  /// Normaliza una ruta de archivo para garantizar consistencia
  static String normalizarRuta(String rutaArchivo) {
    if (rutaArchivo.isEmpty) return '';

    // Convertir a formato estándar con barras diagonales forward
    String normalizada = rutaArchivo
        .replaceAll('\\\\', '/')
        .replaceAll('\\', '/');

    // Eliminar caracteres problemáticos y espacios extras
    normalizada = normalizada.trim().replaceAll('//', '/').replaceAll(' ', '_');

    // Definir los directorios conocidos para verificación
    final directoriosConocidos = [
      _dirComprobantes,
      _dirContratos,
      _dirTemp,
      '$_dirComprobantes/movimientos',
      '$_dirComprobantes/ventas',
      '$_dirComprobantes/rentas',
      '$_dirContratos/venta',
      '$_dirContratos/renta',
    ];

    // Extraer nombre del archivo si está dentro de un directorio conocido
    for (final dir in directoriosConocidos) {
      if (normalizada.contains('$dir/')) {
        final partes = normalizada.split('$dir/');
        if (partes.length > 1) {
          // Tomar la última parte después del directorio conocido
          normalizada = '$dir/${partes.last}';
          break;
        }
      }
    }

    // Si no tiene un prefijo de directorio conocido, añadir el directorio por defecto
    bool tieneDirectorioConocido = false;
    for (final dir in directoriosConocidos) {
      if (normalizada.startsWith('$dir/') || normalizada == dir) {
        tieneDirectorioConocido = true;
        break;
      }
    }

    if (!tieneDirectorioConocido && !normalizada.startsWith('/')) {
      normalizada = '$_dirComprobantes/$normalizada';
    }

    // Eliminar duplicados de directorios
    for (final dir in directoriosConocidos) {
      final patronDuplicado = '$dir/$dir/';
      while (normalizada.contains(patronDuplicado)) {
        normalizada = normalizada.replaceAll(patronDuplicado, '$dir/');
      }
    }

    return normalizada;
  }

  /// Obtiene el directorio raíz de la aplicación según la plataforma
  static Future<Directory> _obtenerDirectorioRaizAplicacion() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'La funcionalidad de archivos no está disponible en Web',
      );
    }

    if (Platform.isAndroid || Platform.isIOS) {
      // Para móviles, usar el directorio de la aplicación
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Para escritorio, intentar obtener el directorio del ejecutable
      try {
        // Obtener el directorio donde se está ejecutando la aplicación
        final String exePath = Platform.resolvedExecutable;
        final String exeDir = path.dirname(exePath);

        // Navegar hacia arriba para llegar a la raíz del proyecto
        // Asumimos que los binarios están en build/windows/runner/Release o similar
        final String projectRoot = exeDir.split('build').first;
        return Directory(projectRoot);
      } catch (e) {
        AppLogger.error(
          'Error al obtener directorio raíz en escritorio',
          e,
          StackTrace.current,
        );
        // Como respaldo, usar el directorio de documentos
        return await getApplicationDocumentsDirectory();
      }
    } else {
      // Para otras plataformas, usar el directorio de documentos
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Obtiene la ruta base para documentos
  static Future<String> _obtenerRutaBaseDocumentos() async {
    try {
      final Directory appDir = await _obtenerDirectorioRaizAplicacion();

      // Primero intentar con la ruta relativa predeterminada (assets/documentos)
      final String rutaBase = path.join(appDir.path, _rutaRelativaDocumentos);
      final Directory dirDocumentos = Directory(rutaBase);

      // Verificar si existe la estructura con assets/documentos
      if (await dirDocumentos.exists()) {
        AppLogger.info('Usando directorio de documentos: $rutaBase');
        return rutaBase;
      }

      // Si no existe, intentar con la estructura alternativa (documentos)
      final String rutaAlternativa = path.join(
        appDir.path,
        _rutaRelativaDocumentos.replaceFirst('assets/', ''),
      );
      final Directory dirAlternativo = Directory(rutaAlternativa);

      if (await dirAlternativo.exists()) {
        AppLogger.info(
          'Usando directorio alternativo de documentos: $rutaAlternativa',
        );
        return rutaAlternativa;
      }

      // Si ninguno existe, crear el directorio predeterminado
      await dirDocumentos.create(recursive: true);
      AppLogger.info('Creado directorio de documentos: $rutaBase');
      return rutaBase;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al obtener ruta base de documentos',
        e,
        stackTrace,
      );

      // Fallback: usar directorio de documentos del usuario
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String rutaFallback = path.join(
        appDir.path,
        'inmobiliaria/documentos',
      );

      // Crear el directorio de respaldo si no existe
      final Directory dirFallback = Directory(rutaFallback);
      if (!await dirFallback.exists()) {
        await dirFallback.create(recursive: true);
      }

      return rutaFallback;
    }
  }

  /// Obtiene la ruta completa de un archivo desde una ruta relativa
  static Future<String> obtenerRutaCompleta(String rutaRelativa) async {
    // Intentar primero con la ruta base actual
    final String rutaBase = await _obtenerRutaBaseDocumentos();
    final rutaNormalizada = normalizarRuta(rutaRelativa);
    final rutaCompleta = path.join(rutaBase, rutaNormalizada);

    // Verificar si existe el archivo
    if (await File(rutaCompleta).exists()) {
      AppLogger.debug('Archivo encontrado en ruta principal: $rutaCompleta');
      return rutaCompleta;
    }

    // Si no existe, intentar sin el prefijo 'assets/'
    String rutaBaseAlternativa = rutaBase;
    if (rutaBase.startsWith('assets/')) {
      rutaBaseAlternativa = rutaBase.replaceFirst('assets/', '');
    }

    final rutaAlternativa = path.join(rutaBaseAlternativa, rutaNormalizada);

    // Log para depuración
    AppLogger.debug('Intentando ruta alternativa: $rutaAlternativa');

    return rutaAlternativa;
  }

  /// Verifica la existencia de un archivo, intentando múltiples ubicaciones si es necesario
  static Future<bool> verificarExistenciaArchivo(String rutaRelativa) async {
    try {
      final String rutaBase = await _obtenerRutaBaseDocumentos();
      final rutaNormalizada = normalizarRuta(rutaRelativa);
      final nombreArchivo = path.basename(rutaRelativa);

      // Lista de posibles ubicaciones a probar en orden de prioridad
      final ubicaciones =
          [
            // 1. Ruta normalizada completa (con assets)
            path.join(rutaBase, rutaNormalizada),

            // 2. Ruta normalizada sin prefijo assets (si aplica)
            rutaBase.startsWith('assets/')
                ? path.join(
                  rutaBase.replaceFirst('assets/', ''),
                  rutaNormalizada,
                )
                : null,

            // 3. Solo el nombre del archivo en la raíz
            path.join(rutaBase, nombreArchivo),

            // 4. El nombre del archivo en cada directorio conocido
            path.join(rutaBase, _dirComprobantes, nombreArchivo),
            path.join(rutaBase, _dirContratos, nombreArchivo),
            path.join(rutaBase, _dirTemp, nombreArchivo),

            // 5. Buscar en subdirectorios comunes
            path.join(rutaBase, _dirComprobantes, 'movimientos', nombreArchivo),
            path.join(rutaBase, _dirComprobantes, 'ventas', nombreArchivo),
            path.join(rutaBase, _dirComprobantes, 'rentas', nombreArchivo),

            // 6. Buscar en directorios alternativos (documentos vs assets/documentos)
            rutaBase.contains('assets/documentos')
                ? path.join(
                  rutaBase.replaceFirst('assets/documentos', 'documentos'),
                  rutaNormalizada,
                )
                : path.join(
                  rutaBase.replaceFirst('documentos', 'assets/documentos'),
                  rutaNormalizada,
                ),
          ].where((path) => path != null).map((path) => path!).toList();

      // Registrar para depuración con nivel detalle disminuido
      AppLogger.info(
        'Verificando archivo en múltiples ubicaciones: $nombreArchivo',
      );

      // Verificar cada ubicación
      for (final ubicacion in ubicaciones) {
        final archivo = File(ubicacion);
        if (await archivo.exists()) {
          AppLogger.info('Archivo encontrado en: $ubicacion');
          return true;
        }
      }

      AppLogger.warning(
        'No se pudo encontrar el archivo en ninguna ubicación: $rutaRelativa',
      );
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al verificar existencia de archivo',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Busca un archivo por su nombre en múltiples ubicaciones y devuelve la ruta completa
  static Future<String?> buscarArchivoPorNombre(String nombreArchivo) async {
    try {
      final String rutaBase = await _obtenerRutaBaseDocumentos();

      // Obtener ruta alternativa (con o sin prefijo 'assets/')
      String rutaBaseAlternativa = rutaBase;
      if (rutaBase.contains('assets/documentos')) {
        rutaBaseAlternativa = rutaBase.replaceFirst(
          'assets/documentos',
          'documentos',
        );
      } else if (rutaBase.contains('documentos')) {
        rutaBaseAlternativa = rutaBase.replaceFirst(
          'documentos',
          'assets/documentos',
        );
      }

      // Lista de posibles directorios donde buscar en ambas rutas base
      final directoriosBase = [rutaBase, rutaBaseAlternativa];
      final subDirs = [
        '',
        _dirComprobantes,
        _dirContratos,
        _dirTemp,
        '$_dirComprobantes/movimientos',
        '$_dirComprobantes/ventas',
        '$_dirComprobantes/rentas',
        '$_dirContratos/venta',
        '$_dirContratos/renta',
      ];

      // Generar todas las combinaciones de directorios posibles
      final directorios = <String>[];
      for (final base in directoriosBase) {
        for (final subDir in subDirs) {
          directorios.add(path.join(base, subDir));
        }
      }

      // Registrar para depuración
      AppLogger.debug(
        'Buscando archivo $nombreArchivo en ${directorios.length} ubicaciones',
      );

      // Buscar en todos los directorios
      for (final directorio in directorios) {
        final dir = Directory(directorio);
        if (!(await dir.exists())) continue;

        try {
          final archivos = await dir.list().toList();
          for (final archivo in archivos) {
            if (archivo is File &&
                path.basename(archivo.path) == nombreArchivo) {
              AppLogger.info(
                'Archivo $nombreArchivo encontrado en: ${archivo.path}',
              );
              return archivo.path;
            }
          }
        } catch (e) {
          // Ignorar errores al listar directorios individuales para continuar con otros
          AppLogger.debug('No se pudo listar el directorio $directorio: $e');
        }
      }

      AppLogger.warning(
        'No se encontró el archivo $nombreArchivo en ninguna ubicación',
      );
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Error al buscar archivo por nombre', e, stackTrace);
      return null;
    }
  }

  /// Guarda un archivo en una ubicación permanente y devuelve la ruta relativa normalizada
  static Future<String> guardarArchivoPermanente(
    File archivoTemporal,
    String nombreBase, {
    String? subDirectorio,
    String directorioPrincipal =
        _dirComprobantes, // Parámetro para especificar el directorio principal
  }) async {
    try {
      final String rutaBase = await _obtenerRutaBaseDocumentos();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(archivoTemporal.path).toLowerCase();

      // Nombre de archivo único con timestamp para evitar colisiones
      final nombreUnico = '${nombreBase}_$timestamp$extension';

      // Construir la ruta del directorio de destino
      String directorioDestino = path.join(rutaBase, directorioPrincipal);
      if (subDirectorio != null && subDirectorio.isNotEmpty) {
        directorioDestino = path.join(directorioDestino, subDirectorio);
      }

      // Crear directorio si no existe
      final directorio = Directory(directorioDestino);
      if (!await directorio.exists()) {
        await directorio.create(recursive: true);
      }

      // Ruta completa del archivo de destino
      final rutaDestino = path.join(directorioDestino, nombreUnico);

      AppLogger.info('Guardando archivo permanente en: $rutaDestino');

      // Copiar archivo con verificación
      await archivoTemporal.copy(rutaDestino);
      final archivoFinal = File(rutaDestino);

      if (!await archivoFinal.exists()) {
        throw Exception(
          'Error al guardar: el archivo no se copió correctamente',
        );
      }

      // Eliminar archivo temporal después de copiarlo exitosamente
      try {
        if (await archivoTemporal.exists()) {
          await archivoTemporal.delete();
          AppLogger.info('Archivo temporal eliminado: ${archivoTemporal.path}');
        }
      } catch (e) {
        // Solo registrar el error, pero no fallar el proceso completo
        AppLogger.warning('No se pudo eliminar el archivo temporal: $e');
      }

      // Calcular y retornar ruta relativa normalizada
      final rutaRelativa =
          '$directorioPrincipal/${subDirectorio != null ? "$subDirectorio/" : ""}$nombreUnico';
      AppLogger.info('Archivo guardado en ruta relativa: $rutaRelativa');
      return normalizarRuta(rutaRelativa);
    } catch (e, stack) {
      AppLogger.error('Error al guardar archivo permanente', e, stack);
      throw Exception('No se pudo guardar el archivo: $e');
    }
  }

  /// Verifica si el nombre de archivo es un PDF
  static bool esPDF(String rutaArchivo) {
    return path.extension(rutaArchivo).toLowerCase() == '.pdf';
  }

  /// Obtiene el tipo MIME basado en la extensión del archivo
  static String obtenerTipoMIME(String rutaArchivo) {
    final ext = path.extension(rutaArchivo).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  /// Crea los directorios necesarios para la aplicación
  static Future<bool> crearDirectoriosNecesarios() async {
    try {
      final String rutaBase = await _obtenerRutaBaseDocumentos();

      // Lista de directorios a crear
      final directorios = [
        path.join(rutaBase, _dirComprobantes),
        path.join(rutaBase, _dirComprobantes, 'movimientos'),
        path.join(rutaBase, _dirComprobantes, 'ventas'),
        path.join(rutaBase, _dirComprobantes, 'rentas'),
        path.join(rutaBase, _dirContratos),
        path.join(rutaBase, _dirContratos, 'venta'),
        path.join(rutaBase, _dirContratos, 'renta'),
        path.join(rutaBase, _dirTemp),
      ];

      // Crear cada directorio
      for (final dir in directorios) {
        final directorio = Directory(dir);
        if (!await directorio.exists()) {
          await directorio.create(recursive: true);
          AppLogger.info('Directorio creado: $dir');
        }
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error al crear directorios necesarios', e, stackTrace);
      return false;
    }
  }
}

import 'dart:io';
import '../utils/applogger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Servicio para verificar y gestionar directorios de almacenamiento de documentos
class DirectoryService {
  // Constantes para las rutas relativas (mantienen la estructura deseada)
  static const String contratosRentaDir = 'documentos/contratos/renta';
  static const String contratosVentaDir = 'documentos/contratos/venta';
  static const String comprobantesDir = 'documentos/comprobantes';

  // Cache para evitar llamadas repetidas a getApplicationDocumentsDirectory
  static String? _baseDirPath;
  static Map<String, String>? _resolvedDirs;

  /// Obtiene el directorio base de documentos de forma segura
  static Future<String> _getBaseDirectory() async {
    if (_baseDirPath != null) return _baseDirPath!;

    // En escritorio/development, usar la carpeta del proyecto como base dir
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        final projectRoot = Directory.current.path;
        _baseDirPath = projectRoot;
        AppLogger.info('⛳ Usando proyecto como base dir: $_baseDirPath');
        return _baseDirPath!;
      } catch (e, stack) {
        AppLogger.error(
          'Error crítico al obtener directorio del proyecto',
          e,
          stack,
        );
        // Lanzar excepción si no se puede obtener el directorio del proyecto
        throw Exception(
          'No se pudo determinar el directorio base del proyecto: $e',
        );
      }
    }

    // En móvil, usar getApplicationDocumentsDirectory
    try {
      final directory = await getApplicationDocumentsDirectory();
      _baseDirPath = directory.path;
      AppLogger.info('📄 Documents dir obtenido: $_baseDirPath');
      return _baseDirPath!;
    } catch (e, stack) {
      AppLogger.error(
        'Error crítico al obtener directorio de documentos',
        e,
        stack,
      );
      // Lanzar excepción si no se puede obtener el directorio de documentos
      throw Exception(
        'No se pudo determinar el directorio de documentos de la aplicación: $e',
      );
    }
    // Se elimina el fallback final a getTemporaryDirectory()
  }

  /// Asegura que todos los directorios necesarios existan y sean accesibles
  static Future<Map<String, String>> ensureDirectoriesExist() async {
    // Si ya resolvimos los directorios, retornarlos
    if (_resolvedDirs != null) {
      return _resolvedDirs!;
    }

    AppLogger.info('Asegurando existencia de directorios...');
    final baseDir = await _getBaseDirectory(); // Puede lanzar excepción ahora

    final Map<String, String> dirs = {
      'base': baseDir,
      'contratos_renta': path.join(baseDir, contratosRentaDir),
      'contratos_venta': path.join(baseDir, contratosVentaDir),
      'comprobantes': path.join(baseDir, comprobantesDir),
    };

    for (final entry in dirs.entries) {
      if (entry.key == 'base') continue;

      final dirPath = entry.value;
      AppLogger.info('Verificando directorio: ${entry.key} -> $dirPath');
      try {
        final dir = Directory(dirPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
          AppLogger.info('Directorio creado: $dirPath');
        } else {
          AppLogger.info('Directorio ya existe: $dirPath');
        }

        // Verificar permisos de escritura
        final testFilePath = path.join(dirPath, '.writetest');
        final testFile = File(testFilePath);
        await testFile.writeAsString('test', flush: true);
        await testFile.delete();
        AppLogger.info('Permisos de escritura confirmados para: $dirPath');
      } catch (e, stack) {
        // Ya NO hay fallback a temporal. Si falla, es un error real.
        AppLogger.error(
          'Error CRÍTICO al crear/verificar directorio: $dirPath',
          e,
          stack,
        );
        // Relanzar la excepción para detener el proceso si un directorio esencial falla
        throw Exception(
          'Fallo crítico al asegurar directorio ${entry.key} en $dirPath: $e',
        );
      }
    }

    _resolvedDirs = dirs;
    AppLogger.info('Directorios asegurados: $_resolvedDirs');
    return _resolvedDirs!;
  }

  /// Obtiene la ruta completa para un archivo en un directorio específico
  static Future<String> getFullPath(String fileName, String dirType) async {
    final dirs =
        await ensureDirectoriesExist(); // Asegura que los directorios estén listos
    final dirPath = dirs[dirType];

    if (dirPath == null) {
      AppLogger.error(
        'Tipo de directorio inválido solicitado: $dirType. Directorios disponibles: ${dirs.keys}',
      );
      throw Exception('Tipo de directorio inválido: $dirType');
    }

    final fullPath = path.join(dirPath, fileName);
    AppLogger.info(
      'Ruta completa calculada para $fileName en $dirType: $fullPath',
    );
    return fullPath;
  }

  /// Obtiene la ruta relativa basada en el directorio de documentos
  static String getRelativePath(String fullPath, String dirType) {
    switch (dirType) {
      case 'contratos_renta':
        return path.join(contratosRentaDir, path.basename(fullPath));
      case 'contratos_venta':
        return path.join(contratosVentaDir, path.basename(fullPath));
      case 'comprobantes':
        return path.join(comprobantesDir, path.basename(fullPath));
      default:
        AppLogger.warning(
          'No se pudo determinar la ruta relativa para dirType: $dirType',
        );
        // Devolver solo el nombre del archivo como fallback
        return path.basename(fullPath);
    }
  }
}

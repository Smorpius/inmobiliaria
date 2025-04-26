import 'dart:io';
import '../utils/applogger.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio para verificar y gestionar directorios de almacenamiento de documentos
class DirectoryService {
  /// Verifica que un directorio exista y tenga permisos de escritura
  static Future<bool> verificarDirectorio(String ruta) async {
    try {
      final directory = Directory(ruta);
      if (!await directory.exists()) {
        AppLogger.info('El directorio no existe, se intentará crear: $ruta');
        await directory.create(recursive: true);
        AppLogger.info('Directorio creado correctamente: $ruta');
      }
      final archivo = File('${directory.path}/test_permisos.tmp');
      await archivo.writeAsString('Test de permisos');
      await archivo.delete();
      AppLogger.info('Directorio verificado con permisos correctos: $ruta');
      return true;
    } catch (e, stack) {
      AppLogger.error('Error al verificar directorio: $ruta', e, stack);
      return false;
    }
  }

  /// Obtiene el directorio de documentos de la aplicación
  static Future<String?> obtenerDirectorioDocumentos() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = '${appDir.path}/documentos';
      if (await verificarDirectorio(docsDir)) {
        return docsDir;
      }
      if (await verificarDirectorio(appDir.path)) {
        return appDir.path;
      }
      return null;
    } catch (e, stack) {
      AppLogger.error('Error al obtener directorio de documentos', e, stack);
      return null;
    }
  }

  /// Crea una estructura de directorios por tipo de documento
  static Future<Map<String, String?>> crearEstructuraDirectorios() async {
    final baseDir = await obtenerDirectorioDocumentos();
    if (baseDir == null) {
      AppLogger.error('No se pudo obtener el directorio base para documentos');
      return {
        'base': null,
        'contratos_venta': null,
        'contratos_renta': null,
        'comprobantes': null,
      };
    }
    final dirs = <String, String?>{
      'base': baseDir,
      'contratos_venta': '$baseDir/contratos/venta',
      'contratos_renta': '$baseDir/contratos/renta',
      'comprobantes': '$baseDir/comprobantes',
    };
    for (final entry in dirs.entries) {
      if (entry.key != 'base') {
        final dirValido = await verificarDirectorio(entry.value!);
        if (!dirValido) {
          AppLogger.warning('No se pudo crear el directorio: ${entry.value}');
          dirs[entry.key] = baseDir;
        }
      }
    }
    return dirs;
  }

  /// Método auxiliar para garantizar que todos los directorios necesarios existan
  static Future<Map<String, String?>> ensureDirectoriesExist() async {
    final directorios = await crearEstructuraDirectorios();
    if (directorios['base'] == null) {
      AppLogger.error('No se pudo crear el directorio base para documentos');
      throw Exception('No se pudo acceder o crear los directorios necesarios');
    }
    return directorios;
  }
}

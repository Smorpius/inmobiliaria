import 'dart:io';
import 'package:uuid/uuid.dart';
import 'directory_service.dart';
import '../utils/applogger.dart';
import '../utils/archivo_utils.dart';
import 'package:path/path.dart' as path;
import '../models/documento_model.dart';

class DocumentoService {
  final _uuid = Uuid();

  // Obtener todos los documentos del sistema
  Future<List<Documento>> obtenerDocumentos() async {
    List<Documento> documentos = [];
    List<Documento> documentosValidos = [];

    try {
      // Buscar en todas las carpetas de documentos
      final directorios = await DirectoryService.ensureDirectoriesExist();
      if (directorios.isEmpty) return [];

      for (var entry in directorios.entries) {
        if (entry.key == 'base') continue;

        final categoria = _obtenerCategoria(entry.key);
        final tipoDocumento = _obtenerTipoDocumento(entry.key);

        await _escanearDirectorio(
          entry.value,
          documentos,
          categoria,
          tipoDocumento,
        );
      }

      // Verificar la existencia física de cada documento
      AppLogger.info(
        'Verificando existencia física de ${documentos.length} documentos...',
      );

      for (final documento in documentos) {
        try {
          final rutaCompleta = await ArchivoUtils.obtenerRutaCompleta(
            documento.rutaArchivo,
          );
          final archivo = File(rutaCompleta);

          if (await archivo.exists()) {
            documentosValidos.add(documento);
          } else {
            // Intentar buscar por nombre en caso de que la ruta haya cambiado
            final nombreArchivo = path.basename(documento.rutaArchivo);
            final rutaAlternativa = await ArchivoUtils.buscarArchivoPorNombre(
              nombreArchivo,
            );

            if (rutaAlternativa != null) {
              // Crear una copia del documento con la ruta actualizada
              final documentoActualizado = Documento(
                id: documento.id,
                nombre: documento.nombre,
                rutaArchivo: rutaAlternativa,
                tipoDocumento: documento.tipoDocumento,
                categoria: documento.categoria,
                fechaCreacion: documento.fechaCreacion,
                descripcion: documento.descripcion,
                esFavorito: documento.esFavorito,
              );
              documentosValidos.add(documentoActualizado);
            } else {
              AppLogger.warning(
                'Documento no encontrado físicamente: ${documento.rutaArchivo}',
              );
            }
          }
        } catch (e) {
          AppLogger.warning(
            'Error al verificar existencia de documento: ${documento.rutaArchivo}, $e',
          );
        }
      }

      AppLogger.info(
        'Documentos válidos encontrados: ${documentosValidos.length} de ${documentos.length}',
      );
    } catch (e, stack) {
      AppLogger.error('Error al obtener documentos', e, stack);
    }

    // Ordenar por fecha más reciente
    documentosValidos.sort(
      (a, b) => b.fechaCreacion.compareTo(a.fechaCreacion),
    );
    return documentosValidos;
  }

  // Subir un nuevo documento
  Future<Documento?> subirDocumento({
    required File archivo,
    required String tipoDocumento,
    required String categoria,
    String? descripcion,
    String? nombrePersonalizado,
  }) async {
    try {
      final nombreArchivo = nombrePersonalizado ?? path.basename(archivo.path);
      final extension = path.extension(nombreArchivo);

      // Determinar directorio destino
      String directorio = _obtenerDirectorio(tipoDocumento, categoria);

      // Obtener ruta del directorio
      final rutaDirectorio = await DirectoryService.getDirectoryPath(
        directorio,
      );
      if (rutaDirectorio == null) {
        throw Exception('No se pudo obtener el directorio $directorio');
      }

      // Generar nombre único
      final id = _uuid.v4();
      final nombreFinal =
          '${path.basenameWithoutExtension(nombreArchivo)}_$id$extension';
      final rutaDestino = path.join(rutaDirectorio, nombreFinal);

      // Copiar el archivo
      await archivo.copy(rutaDestino);

      // Crear objeto documento
      final rutaRelativa = path.join(directorio, nombreFinal);
      final documento = Documento(
        id: id,
        nombre:
            nombrePersonalizado ?? path.basenameWithoutExtension(nombreArchivo),
        rutaArchivo: rutaRelativa,
        tipoDocumento: tipoDocumento,
        categoria: categoria,
        fechaCreacion: DateTime.now(),
        descripcion: descripcion,
      );

      AppLogger.info('Documento subido: $rutaRelativa');
      return documento;
    } catch (e, stack) {
      AppLogger.error('Error al subir documento', e, stack);
      return null;
    }
  }

  // Eliminar documento
  Future<bool> eliminarDocumento(Documento documento) async {
    try {
      final rutaCompleta = await ArchivoUtils.obtenerRutaCompleta(
        documento.rutaArchivo,
      );
      final archivo = File(rutaCompleta);

      if (await archivo.exists()) {
        await archivo.delete();
        AppLogger.info('Documento eliminado: ${documento.rutaArchivo}');
        return true;
      }
      return false;
    } catch (e, stack) {
      AppLogger.error('Error al eliminar documento', e, stack);
      return false;
    }
  }

  // Escanear un directorio para encontrar documentos
  Future<void> _escanearDirectorio(
    String directorio,
    List<Documento> documentos,
    String categoria,
    String tipoDocumento,
  ) async {
    try {
      final dir = Directory(directorio);
      if (!await dir.exists()) return;

      await for (final entidad in dir.list(recursive: true)) {
        if (entidad is File) {
          final ext = path.extension(entidad.path).toLowerCase();
          if ([
            '.pdf',
            '.jpg',
            '.jpeg',
            '.png',
            '.doc',
            '.docx',
          ].contains(ext)) {
            final nombreArchivo = path.basename(entidad.path);
            final stat = await entidad.stat();

            // Obtener directorios para determinar la ruta relativa
            final dirs = await DirectoryService.ensureDirectoriesExist();
            final baseDir = dirs['base'];

            if (baseDir == null) {
              AppLogger.warning('No se pudo obtener el directorio base');
              continue;
            }

            // Obtener ruta relativa
            String rutaRelativa = entidad.path.replaceAll(
              baseDir + path.separator,
              '',
            );

            final documento = Documento(
              id: path.basenameWithoutExtension(entidad.path),
              nombre: path.basenameWithoutExtension(nombreArchivo),
              rutaArchivo: rutaRelativa,
              tipoDocumento: tipoDocumento,
              categoria: categoria,
              fechaCreacion: stat.modified,
            );

            documentos.add(documento);
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Error al escanear directorio: $directorio, $e');
    }
  }

  // Obtener categoría a partir del nombre del directorio
  String _obtenerCategoria(String nombreDirectorio) {
    if (nombreDirectorio.contains('venta')) return 'venta';
    if (nombreDirectorio.contains('renta')) return 'renta';
    if (nombreDirectorio.contains('movimientos')) return 'movimiento';
    if (nombreDirectorio.contains('estadisticas')) return 'estadística';
    return 'general';
  }

  // Obtener tipo de documento a partir del nombre del directorio
  String _obtenerTipoDocumento(String nombreDirectorio) {
    if (nombreDirectorio.contains('contratos')) return 'contrato';
    if (nombreDirectorio.contains('comprobantes')) return 'comprobante';
    if (nombreDirectorio.contains('reportes') ||
        nombreDirectorio.contains('estadisticas')) {
      return 'reporte';
    }
    return 'documento';
  }

  // Obtener directorio basado en tipo y categoría
  String _obtenerDirectorio(String tipoDocumento, String categoria) {
    if (tipoDocumento == 'contrato') {
      if (categoria == 'venta') return 'contratos_venta';
      if (categoria == 'renta') return 'contratos_renta';
    }

    if (tipoDocumento == 'comprobante') {
      if (categoria == 'movimiento') return 'comprobantes';
      if (categoria == 'venta') return 'comprobantes';
      if (categoria == 'renta') return 'comprobantes';
    }

    if (tipoDocumento == 'reporte') {
      return 'estadisticas';
    }

    return 'documentos';
  }
}

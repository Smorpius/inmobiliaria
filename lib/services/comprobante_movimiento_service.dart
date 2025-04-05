import '../utils/applogger.dart';
import '../models/comprobante_movimiento_model.dart';
import '../controllers/comprobante_movimiento_controller.dart';

/// Servicio para gestionar comprobantes de movimientos de renta
class ComprobanteMovimientoService {
  final ComprobanteMovimientoController _controller;

  ComprobanteMovimientoService({ComprobanteMovimientoController? controller})
    : _controller = controller ?? ComprobanteMovimientoController();

  /// Obtiene los comprobantes asociados a un movimiento específico
  Future<List<ComprobanteMovimiento>> obtenerComprobantesPorMovimiento(
    int idMovimiento,
  ) async {
    try {
      return await _controller.obtenerComprobantesPorMovimiento(idMovimiento);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al obtener comprobantes por movimiento',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Agrega un nuevo comprobante a un movimiento
  Future<int> agregarComprobante(ComprobanteMovimiento comprobante) async {
    try {
      return await _controller.agregarComprobante(comprobante);
    } catch (e, stackTrace) {
      AppLogger.error('Error al agregar comprobante', e, stackTrace);
      rethrow;
    }
  }

  /// Actualiza un comprobante existente
  Future<bool> actualizarComprobante(ComprobanteMovimiento comprobante) async {
    try {
      return await _controller.actualizarComprobante(comprobante);
    } catch (e, stackTrace) {
      AppLogger.error('Error al actualizar comprobante', e, stackTrace);
      rethrow;
    }
  }

  /// Elimina un comprobante
  Future<bool> eliminarComprobante(int idComprobante) async {
    try {
      return await _controller.eliminarComprobante(idComprobante);
    } catch (e, stackTrace) {
      AppLogger.error('Error al eliminar comprobante', e, stackTrace);
      rethrow;
    }
  }

  /// Busca comprobantes por tipo, fecha y otros criterios
  Future<List<ComprobanteMovimiento>> buscarComprobantes({
    required String tipoComprobante,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      return await _controller.buscarComprobantes(
        tipoComprobante: tipoComprobante,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al buscar comprobantes', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene comprobantes detallados para un movimiento con filtro por tipo
  Future<List<ComprobanteMovimiento>> obtenerComprobantesDetallados(
    int idMovimiento,
    String? tipoComprobante,
  ) async {
    try {
      return await _controller.obtenerComprobantesDetallados(
        idMovimiento,
        tipoComprobante,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al obtener comprobantes detallados',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Valida un comprobante fiscal (factura o recibo)
  Future<bool> validarComprobanteFiscal({
    required int idComprobante,
    required String estadoValidacion,
    required int usuarioValidacion,
    required String comentarioValidacion,
  }) async {
    try {
      return await _controller.validarComprobanteFiscal(
        idComprobante: idComprobante,
        estadoValidacion: estadoValidacion,
        usuarioValidacion: usuarioValidacion,
        comentarioValidacion: comentarioValidacion,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al validar comprobante fiscal', e, stackTrace);
      rethrow;
    }
  }

  /// Clona un comprobante de un movimiento a otro
  Future<int> clonarComprobante(
    int idComprobanteOriginal,
    int idMovimientoDestino,
  ) async {
    try {
      return await _controller.clonarComprobante(
        idComprobanteOriginal,
        idMovimientoDestino,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al clonar comprobante', e, stackTrace);
      rethrow;
    }
  }

  /// Registra un nuevo comprobante desde un archivo
  Future<int> registrarComprobanteDesdeArchivo({
    required int idMovimiento,
    required String rutaArchivo,
    String? descripcion,
    bool esPrincipal = false,
    String tipoComprobante = 'otro',
  }) async {
    try {
      // Extraer el tipo de archivo de la ruta
      String tipoArchivo = 'imagen';
      if (rutaArchivo.toLowerCase().endsWith('.pdf')) {
        tipoArchivo = 'pdf';
      }

      final comprobante = ComprobanteMovimiento(
        idMovimiento: idMovimiento,
        rutaArchivo: rutaArchivo,
        descripcion: descripcion,
        esPrincipal: esPrincipal,
        fechaCarga: DateTime.now(),
        tipoArchivo: tipoArchivo,
        tipoComprobante: tipoComprobante,
      );

      return await _controller.agregarComprobante(comprobante);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al registrar comprobante desde archivo',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Obtiene resumen de comprobantes por período
  Future<Map<String, dynamic>> obtenerResumenComprobantes({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      return await _controller.obtenerResumenComprobantes(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al obtener resumen de comprobantes',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Genera reporte de comprobantes por periodo
  Future<Map<String, dynamic>> generarReporteComprobantes({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    int? idInmueble,
  }) async {
    try {
      return await _controller.generarReporteComprobantes(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        idInmueble: idInmueble,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al generar reporte de comprobantes',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Obtiene comprobantes vencidos o con antigüedad superior a un límite
  Future<List<ComprobanteMovimiento>> obtenerComprobantesVencidos({
    int? diasAntiguedad,
  }) async {
    try {
      return await _controller.obtenerComprobantesVencidos(
        diasAntiguedad: diasAntiguedad,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener comprobantes vencidos', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene estadísticas de cumplimiento fiscal
  Future<Map<String, dynamic>> obtenerCumplimientoFiscal(int idInmueble) async {
    try {
      return await _controller.obtenerCumplimientoFiscal(idInmueble);
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener cumplimiento fiscal', e, stackTrace);
      rethrow;
    }
  }

  /// Libera recursos cuando el servicio ya no se necesita
  void dispose() {
    _controller.dispose();
  }
}

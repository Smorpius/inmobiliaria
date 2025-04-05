import '../utils/applogger.dart';
import '../models/comprobante_venta_model.dart';
import '../controllers/comprobante_venta_controller.dart';

/// Servicio para gestionar comprobantes de venta
class ComprobanteVentaService {
  final ComprobanteVentaController _controller;

  ComprobanteVentaService({ComprobanteVentaController? controller})
    : _controller = controller ?? ComprobanteVentaController();

  /// Obtiene los comprobantes asociados a una venta específica
  Future<List<ComprobanteVenta>> obtenerComprobantesPorVenta(
    int idVenta,
  ) async {
    try {
      return await _controller.obtenerComprobantesPorVenta(idVenta);
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener comprobantes de venta', e, stackTrace);
      rethrow;
    }
  }

  /// Registra un nuevo comprobante de venta
  Future<int> agregarComprobante(ComprobanteVenta comprobante) async {
    try {
      return await _controller.agregarComprobante(comprobante);
    } catch (e, stackTrace) {
      AppLogger.error('Error al agregar comprobante de venta', e, stackTrace);
      rethrow;
    }
  }

  /// Actualiza un comprobante de venta existente
  Future<bool> actualizarComprobante(ComprobanteVenta comprobante) async {
    try {
      return await _controller.actualizarComprobante(comprobante);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al actualizar comprobante de venta',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Elimina un comprobante de venta
  Future<bool> eliminarComprobante(int idComprobante) async {
    try {
      return await _controller.eliminarComprobante(idComprobante);
    } catch (e, stackTrace) {
      AppLogger.error('Error al eliminar comprobante de venta', e, stackTrace);
      rethrow;
    }
  }

  /// Registra un comprobante desde una ruta de archivo local y lo asocia a una venta
  Future<int> registrarComprobanteDesdeArchivo({
    required int idVenta,
    required String rutaArchivo,
    String? descripcion,
    bool esPrincipal = false,
  }) async {
    try {
      // Determinar el tipo de archivo basado en la extensión
      final extension = rutaArchivo.split('.').last.toLowerCase();
      String tipoArchivo;

      if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension)) {
        tipoArchivo = 'imagen';
      } else if (extension == 'pdf') {
        tipoArchivo = 'pdf';
      } else {
        tipoArchivo = 'documento';
      }

      final comprobante = ComprobanteVenta(
        idVenta: idVenta,
        rutaArchivo: rutaArchivo,
        tipoArchivo: tipoArchivo,
        descripcion: descripcion,
        esPrincipal: esPrincipal,
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

  /// Marca un comprobante como el principal para una venta
  Future<bool> marcarComoPrincipal(int idComprobante, int idVenta) async {
    try {
      // Primero obtener todos los comprobantes de esa venta
      final comprobantes = await _controller.obtenerComprobantesPorVenta(
        idVenta,
      );

      // Buscar el comprobante específico
      final comprobantePrincipal = comprobantes.firstWhere(
        (c) => c.id == idComprobante,
        orElse: () => throw Exception('Comprobante no encontrado'),
      );

      // Solo actualizar si no era ya el principal
      if (!comprobantePrincipal.esPrincipal) {
        // Modificarlo para que sea principal
        final actualizado = comprobantePrincipal.copyWith(esPrincipal: true);
        return await _controller.actualizarComprobante(actualizado);
      }

      return true; // Ya era el principal, no hace falta cambiar nada
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al marcar comprobante como principal',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Libera recursos cuando el servicio ya no se necesita
  void dispose() {
    _controller.dispose();
  }
}

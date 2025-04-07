import '../utils/applogger.dart';
import '../models/historial_transaccion_model.dart';
import '../controllers/historial_transaccion_controller.dart';

/// Servicio para gestionar el historial de cambios en transacciones
class HistorialTransaccionService {
  final HistorialTransaccionController _controller;

  HistorialTransaccionService({HistorialTransaccionController? controller})
    : _controller = controller ?? HistorialTransaccionController();

  /// Registra un cambio en el historial de transacciones
  Future<int> registrarCambio({
    required String tipoEntidadStr,
    required int idEntidad,
    required String campoModificado,
    String? valorAnterior,
    String? valorNuevo,
    int? idUsuario,
  }) async {
    try {
      final tipoEntidad = TipoEntidad.fromString(tipoEntidadStr);
      final historial = HistorialTransaccion(
        tipoEntidad: tipoEntidad,
        idEntidad: idEntidad,
        campoModificado: campoModificado,
        valorAnterior: valorAnterior,
        valorNuevo: valorNuevo,
        idUsuarioModificacion: idUsuario,
      );

      return await _controller.registrarCambio(historial);
    } catch (e, stackTrace) {
      AppLogger.error('Error al registrar cambio en historial', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene el historial de una entidad específica con filtros opcionales de fecha
  Future<List<HistorialTransaccion>> obtenerHistorialDeEntidad({
    required String tipoEntidadStr,
    required int idEntidad,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      return await _controller.obtenerHistorialPorEntidad(
        tipoEntidad: tipoEntidadStr,
        idEntidad: idEntidad,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener historial de entidad', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene resumen estadístico del historial
  Future<Map<String, dynamic>> obtenerResumenHistorial({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? idUsuario,
  }) async {
    try {
      return await _controller.obtenerResumenHistorial(
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        idUsuario: idUsuario,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener resumen del historial', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene estadísticas de actividad de usuarios
  Future<List<Map<String, dynamic>>> obtenerEstadisticasActividad({
    int? diasUltimos,
  }) async {
    try {
      return await _controller.obtenerEstadisticasActividad(dias: diasUltimos);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al obtener estadísticas de actividad',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Registra múltiples cambios en una sola transacción
  Future<List<int>> registrarCambiosMultiples(
    List<HistorialTransaccion> cambios,
  ) async {
    try {
      return await _controller.registrarCambiosMultiples(cambios);
    } catch (e, stackTrace) {
      AppLogger.error('Error al registrar múltiples cambios', e, stackTrace);
      rethrow;
    }
  }

  /// Elimina registros antiguos del historial
  Future<int> limpiarHistorialAntiguo({
    required int diasAntiguedad,
    String? tipoEntidad,
  }) async {
    try {
      return await _controller.eliminarHistorialAntiguo(
        diasAntiguedad: diasAntiguedad,
        tipoEntidad: tipoEntidad,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al limpiar historial antiguo', e, stackTrace);
      rethrow;
    }
  }

  /// Registra cambio comparando valores y determinando si hubo cambio real
  Future<int?> registrarCambioSiDiferente({
    required String tipoEntidadStr,
    required int idEntidad,
    required String campoModificado,
    required dynamic valorAnterior,
    required dynamic valorNuevo,
    int? idUsuario,
  }) async {
    try {
      // Convertir valores a string para comparación
      final anteriorStr = valorAnterior?.toString();
      final nuevoStr = valorNuevo?.toString();

      // Si los valores son iguales, no registrar cambio
      if (anteriorStr == nuevoStr) {
        return null;
      }

      final tipoEntidad = TipoEntidad.fromString(tipoEntidadStr);
      // Crear y registrar el historial
      final historial = HistorialTransaccion(
        tipoEntidad: tipoEntidad,
        idEntidad: idEntidad,
        campoModificado: campoModificado,
        valorAnterior: anteriorStr,
        valorNuevo: nuevoStr,
        idUsuarioModificacion: idUsuario,
      );

      return await _controller.registrarCambio(historial);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al registrar cambio condicionalmente',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Obtiene el historial de modificaciones de una venta
  Future<List<HistorialTransaccion>> obtenerHistorialVenta(int idVenta) async {
    try {
      return await _controller.obtenerHistorialPorEntidad(
        tipoEntidad: 'venta',
        idEntidad: idVenta,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener historial de venta', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene el historial de modificaciones de un movimiento de renta
  Future<List<HistorialTransaccion>> obtenerHistorialMovimiento(
    int idMovimiento,
  ) async {
    try {
      return await _controller.obtenerHistorialPorEntidad(
        tipoEntidad: 'movimiento_renta',
        idEntidad: idMovimiento,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al obtener historial de movimiento',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Obtiene el historial de modificaciones de un contrato de renta
  Future<List<HistorialTransaccion>> obtenerHistorialContratoRenta(
    int idContrato,
  ) async {
    try {
      return await _controller.obtenerHistorialPorEntidad(
        tipoEntidad: 'contrato_renta',
        idEntidad: idContrato,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al obtener historial de contrato de renta',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Registra un cambio de estado en una venta
  Future<int> registrarCambioEstadoVenta({
    required int idVenta,
    required String estadoAnterior,
    required String estadoNuevo,
    required int idUsuario,
  }) async {
    try {
      final historial = HistorialTransaccion(
        tipoEntidad: TipoEntidad.venta,
        idEntidad: idVenta,
        campoModificado: 'estado',
        valorAnterior: estadoAnterior,
        valorNuevo: estadoNuevo,
        idUsuarioModificacion: idUsuario,
      );

      return await _controller.registrarCambio(historial);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al registrar cambio de estado de venta',
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

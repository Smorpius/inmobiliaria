import 'dart:io';
import '../utils/applogger.dart';
import '../models/contrato_generado_model.dart';
import '../controllers/contrato_generado_controller.dart';

/// Servicio para gestionar contratos generados
class ContratoGeneradoService {
  final ContratoGeneradoController _controller;

  ContratoGeneradoService({ContratoGeneradoController? controller})
    : _controller = controller ?? ContratoGeneradoController();

  /// Registra un nuevo contrato generado
  Future<int> registrarContrato({
    required String tipoContrato,
    required int idReferencia,
    required String rutaArchivo,
    required int idUsuario,
  }) async {
    try {
      return await _controller.registrarContrato(
        tipoContrato: tipoContrato,
        idReferencia: idReferencia,
        rutaArchivo: rutaArchivo,
        idUsuario: idUsuario,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al registrar contrato generado', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene los contratos generados para una entidad específica (venta o contrato de renta)
  Future<List<ContratoGenerado>> obtenerContratosPorReferencia({
    required String tipoContrato,
    required int idReferencia,
  }) async {
    try {
      return await _controller.obtenerPorReferencia(
        tipoContrato: tipoContrato,
        idReferencia: idReferencia,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener contratos generados', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene todos los contratos generados de venta
  Future<List<ContratoGenerado>> obtenerContratosVenta(int idVenta) async {
    try {
      return await _controller.obtenerPorReferencia(
        tipoContrato: 'venta',
        idReferencia: idVenta,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener contratos de venta', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene todos los contratos generados de renta
  Future<List<ContratoGenerado>> obtenerContratosRenta(int idContrato) async {
    try {
      return await _controller.obtenerPorReferencia(
        tipoContrato: 'renta',
        idReferencia: idContrato,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener contratos de renta', e, stackTrace);
      rethrow;
    }
  }

  /// Elimina un contrato generado
  Future<bool> eliminarContrato(int idContratoGenerado) async {
    try {
      return await _controller.eliminarContrato(idContratoGenerado);
    } catch (e, stackTrace) {
      AppLogger.error('Error al eliminar contrato generado', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene datos necesarios para generar un contrato de venta
  Future<Map<String, dynamic>> obtenerDatosContratoVenta(int idVenta) async {
    try {
      return await _controller.obtenerDatosContratoVenta(idVenta);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al obtener datos para contrato de venta',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Obtiene datos necesarios para generar un contrato de renta
  Future<Map<String, dynamic>> obtenerDatosContratoRenta(int idContrato) async {
    try {
      return await _controller.obtenerDatosContratoRenta(idContrato);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al obtener datos para contrato de renta',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Registra un contrato desde un archivo y verifica que exista
  Future<int> registrarContratoDesdeArchivo({
    required String tipoContrato,
    required int idReferencia,
    required String rutaArchivo,
    required int idUsuario,
  }) async {
    try {
      // Verificar que el archivo exista
      final archivo = File(rutaArchivo);
      if (!await archivo.exists()) {
        throw Exception(
          'El archivo del contrato no existe en la ruta especificada',
        );
      }

      // Validar el tipo de contrato
      if (tipoContrato.toLowerCase() != 'venta' &&
          tipoContrato.toLowerCase() != 'renta') {
        throw Exception(
          'Tipo de contrato inválido. Debe ser "venta" o "renta"',
        );
      }

      // Registrar el contrato
      return await _controller.registrarContrato(
        tipoContrato: tipoContrato.toLowerCase(),
        idReferencia: idReferencia,
        rutaArchivo: rutaArchivo,
        idUsuario: idUsuario,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error al registrar contrato desde archivo',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Obtiene el contrato principal (última versión) para una entidad
  Future<ContratoGenerado?> obtenerContratoActual({
    required String tipoContrato,
    required int idReferencia,
  }) async {
    try {
      final contratos = await _controller.obtenerPorReferencia(
        tipoContrato: tipoContrato,
        idReferencia: idReferencia,
      );

      if (contratos.isEmpty) {
        return null;
      }

      // Ordenar por versión descendente y obtener el primero
      contratos.sort((a, b) => b.version.compareTo(a.version));
      return contratos.first;
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener contrato actual', e, stackTrace);
      rethrow;
    }
  }

  /// Libera recursos cuando el servicio ya no se necesita
  void dispose() {
    _controller.dispose();
  }
}

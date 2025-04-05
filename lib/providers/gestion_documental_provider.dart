import 'comprobantes_provider.dart';
import 'contratos_generados_provider.dart';
import 'historial_transaccion_provider.dart';
import '../models/comprobante_venta_model.dart';
import '../models/contrato_generado_model.dart';
import '../services/comprobante_venta_service.dart';
import '../services/contrato_generado_service.dart';
import '../models/historial_transaccion_model.dart';
import '../models/comprobante_movimiento_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/historial_transaccion_service.dart';
import '../services/comprobante_movimiento_service.dart';

/// Provider estado para la sección de gestión documental activa actual
final gestionDocumentalActivaProvider = StateProvider<String>(
  (ref) => 'comprobantes',
);

/// Provider de servicio unificado para gestión documental
final gestionDocumentalServiceProvider = Provider((ref) {
  return GestionDocumentalService(
    comprobanteVentaService: ref.watch(comprobanteVentaServiceProvider),
    comprobanteMovimientoService: ref.watch(
      comprobanteMovimientoServiceProvider,
    ),
    contratoGeneradoService: ref.watch(contratoGeneradoServiceProvider),
    historialTransaccionService: ref.watch(historialTransaccionServiceProvider),
  );
});

/// Clase que unifica los servicios relacionados con la gestión documental
class GestionDocumentalService {
  final ComprobanteVentaService comprobanteVentaService;
  final ComprobanteMovimientoService comprobanteMovimientoService;
  final ContratoGeneradoService contratoGeneradoService;
  final HistorialTransaccionService historialTransaccionService;

  GestionDocumentalService({
    required this.comprobanteVentaService,
    required this.comprobanteMovimientoService,
    required this.contratoGeneradoService,
    required this.historialTransaccionService,
  });

  /// MÉTODOS PARA COMPROBANTES DE VENTA

  Future<List<ComprobanteVenta>> obtenerComprobantesPorVenta(int idVenta) {
    return comprobanteVentaService.obtenerComprobantesPorVenta(idVenta);
  }

  Future<int> agregarComprobanteVenta(ComprobanteVenta comprobante) {
    return comprobanteVentaService.agregarComprobante(comprobante);
  }

  Future<int> registrarComprobanteVentaDesdeArchivo({
    required int idVenta,
    required String rutaArchivo,
    String? descripcion,
    bool esPrincipal = false,
  }) {
    return comprobanteVentaService.registrarComprobanteDesdeArchivo(
      idVenta: idVenta,
      rutaArchivo: rutaArchivo,
      descripcion: descripcion,
      esPrincipal: esPrincipal,
    );
  }

  Future<bool> eliminarComprobanteVenta(int idComprobante) {
    return comprobanteVentaService.eliminarComprobante(idComprobante);
  }

  /// MÉTODOS PARA COMPROBANTES DE MOVIMIENTO

  Future<List<ComprobanteMovimiento>> obtenerComprobantesPorMovimiento(
    int idMovimiento,
  ) {
    return comprobanteMovimientoService.obtenerComprobantesPorMovimiento(
      idMovimiento,
    );
  }

  Future<int> agregarComprobanteMovimiento(ComprobanteMovimiento comprobante) {
    return comprobanteMovimientoService.agregarComprobante(comprobante);
  }

  Future<int> registrarComprobanteMovimientoDesdeArchivo({
    required int idMovimiento,
    required String rutaArchivo,
    String? descripcion,
    bool esPrincipal = false,
    String tipoComprobante = 'otro',
  }) {
    return comprobanteMovimientoService.registrarComprobanteDesdeArchivo(
      idMovimiento: idMovimiento,
      rutaArchivo: rutaArchivo,
      descripcion: descripcion,
      esPrincipal: esPrincipal,
      tipoComprobante: tipoComprobante,
    );
  }

  Future<bool> eliminarComprobanteMovimiento(int idComprobante) {
    return comprobanteMovimientoService.eliminarComprobante(idComprobante);
  }

  Future<Map<String, dynamic>> obtenerCumplimientoFiscal(int idInmueble) {
    return comprobanteMovimientoService.obtenerCumplimientoFiscal(idInmueble);
  }

  Future<Map<String, dynamic>> generarReporteComprobantes({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    int? idInmueble,
  }) {
    return comprobanteMovimientoService.generarReporteComprobantes(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      idInmueble: idInmueble,
    );
  }

  /// MÉTODOS PARA CONTRATOS GENERADOS

  Future<List<ContratoGenerado>> obtenerContratosGeneradosVenta(int idVenta) {
    return contratoGeneradoService.obtenerContratosVenta(idVenta);
  }

  Future<List<ContratoGenerado>> obtenerContratosGeneradosRenta(
    int idContrato,
  ) {
    return contratoGeneradoService.obtenerContratosRenta(idContrato);
  }

  Future<int> registrarContratoGenerado({
    required String tipoContrato,
    required int idReferencia,
    required String rutaArchivo,
    required int idUsuario,
  }) {
    return contratoGeneradoService.registrarContrato(
      tipoContrato: tipoContrato,
      idReferencia: idReferencia,
      rutaArchivo: rutaArchivo,
      idUsuario: idUsuario,
    );
  }

  Future<bool> eliminarContratoGenerado(int idContratoGenerado) {
    return contratoGeneradoService.eliminarContrato(idContratoGenerado);
  }

  Future<ContratoGenerado?> obtenerContratoActual({
    required String tipoContrato,
    required int idReferencia,
  }) {
    return contratoGeneradoService.obtenerContratoActual(
      tipoContrato: tipoContrato,
      idReferencia: idReferencia,
    );
  }

  Future<Map<String, dynamic>> obtenerDatosContratoVenta(int idVenta) {
    return contratoGeneradoService.obtenerDatosContratoVenta(idVenta);
  }

  Future<Map<String, dynamic>> obtenerDatosContratoRenta(int idContrato) {
    return contratoGeneradoService.obtenerDatosContratoRenta(idContrato);
  }

  /// MÉTODOS PARA HISTORIAL DE TRANSACCIONES

  Future<List<HistorialTransaccion>> obtenerHistorialVenta(int idVenta) {
    return historialTransaccionService.obtenerHistorialVenta(idVenta);
  }

  Future<List<HistorialTransaccion>> obtenerHistorialMovimiento(
    int idMovimiento,
  ) {
    return historialTransaccionService.obtenerHistorialMovimiento(idMovimiento);
  }

  Future<List<HistorialTransaccion>> obtenerHistorialContrato(int idContrato) {
    return historialTransaccionService.obtenerHistorialContratoRenta(
      idContrato,
    );
  }

  Future<int> registrarCambioHistorial({
    required String tipoEntidad,
    required int idEntidad,
    required String campoModificado,
    String? valorAnterior,
    String? valorNuevo,
    int? idUsuario,
  }) {
    return historialTransaccionService.registrarCambio(
      tipoEntidad: tipoEntidad,
      idEntidad: idEntidad,
      campoModificado: campoModificado,
      valorAnterior: valorAnterior,
      valorNuevo: valorNuevo,
      idUsuario: idUsuario,
    );
  }

  Future<int?> registrarCambioSiDiferente({
    required String tipoEntidad,
    required int idEntidad,
    required String campoModificado,
    required dynamic valorAnterior,
    required dynamic valorNuevo,
    int? idUsuario,
  }) {
    return historialTransaccionService.registrarCambioSiDiferente(
      tipoEntidad: tipoEntidad,
      idEntidad: idEntidad,
      campoModificado: campoModificado,
      valorAnterior: valorAnterior,
      valorNuevo: valorNuevo,
      idUsuario: idUsuario,
    );
  }

  Future<Map<String, dynamic>> obtenerResumenHistorial({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? idUsuario,
  }) {
    return historialTransaccionService.obtenerResumenHistorial(
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      idUsuario: idUsuario,
    );
  }
}

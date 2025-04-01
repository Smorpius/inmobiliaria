import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../models/inmueble_model.dart';
import '../utils/inmueble_formatter.dart';
import '../vistas/inmuebles/components/detail_row.dart';

class InmuebleFinancieroInfo extends StatelessWidget {
  final Inmueble inmueble;
  final bool isInactivo;

  // Control para evitar logs duplicados
  static final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _intervaloMinimo = Duration(minutes: 5);
  static const int _maxErrorEntries =
      20; // Limitar tamaño para evitar memory leaks

  const InmuebleFinancieroInfo({
    super.key,
    required this.inmueble,
    required this.isInactivo,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              'Información Financiera',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isInactivo ? Colors.grey : Colors.indigo,
              ),
            ),
          ),

          _buildDetailRow(
            'Costo del Cliente',
            inmueble.costoCliente,
            Icons.person_outline,
          ),

          _buildDetailRow(
            'Costo de Servicios',
            inmueble.costoServicios,
            Icons.home_repair_service,
          ),

          _buildDetailRow(
            'Comisión de la Agencia (30%)',
            inmueble.comisionAgencia,
            Icons.business,
          ),

          _buildDetailRow(
            'Comisión del Agente (3%)',
            inmueble.comisionAgente,
            Icons.person,
          ),

          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isInactivo ? Colors.grey.shade200 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  'PRECIO DE VENTA FINAL',
                  inmueble.precioVentaFinal,
                  Icons.money,
                  destacado: true,
                ),

                // Margen de Utilidad con tooltip y manejo seguro
                Tooltip(
                  message:
                      'Porcentaje de ganancia calculado como proporción de comisiones respecto al precio final',
                  child: _buildDetailRow(
                    'MARGEN DE UTILIDAD',
                    null, // Pasamos null porque manejaremos un formato especial
                    Icons.trending_up,
                    valorEspecial: _formatearMargenUtilidad(),
                    destacado: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'error_financiero_${inmueble.id ?? 0}',
        'Error al construir información financiera del inmueble ID: ${inmueble.id ?? "nuevo"}',
        e,
        stackTrace,
      );

      // Widget de fallback para mostrar en caso de error
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            child: const Text(
              'Información Financiera',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(
            'No se pudo cargar la información financiera',
            style: TextStyle(color: Colors.red),
          ),
          Text(
            'ID Inmueble: ${inmueble.id ?? 'N/A'}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      );
    }
  }

  Widget _buildDetailRow(
    String label,
    double? valor,
    IconData icon, {
    bool destacado = false,
    String? valorEspecial,
  }) {
    try {
      return DetailRow(
        label: label,
        value: valorEspecial ?? _formatearValor(valor, label),
        icon: icon,
        isInactivo: isInactivo,
        valueColor: destacado && !isInactivo ? Colors.indigo : null,
      );
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'detail_row_${label.hashCode}',
        'Error al construir fila de detalle: $label',
        e,
        stackTrace,
      );

      // Retornar una versión simplificada en caso de error
      return DetailRow(
        label: label,
        value: 'Error al mostrar valor',
        icon: Icons.error_outline,
        isInactivo: true,
        valueColor: Colors.red,
      );
    }
  }

  /// Formatea un valor monetario con manejo seguro de nulos
  String _formatearValor(double? valor, String campo) {
    try {
      return InmuebleFormatter.formatMonto(valor ?? 0.0);
    } catch (e) {
      _registrarWarningSinDuplicados(
        'formato_${inmueble.id ?? 0}_$campo',
        'Error al formatear $campo del inmueble: ${inmueble.id ?? "nuevo"}',
        e,
      );
      return 'N/A';
    }
  }

  /// Formatea el margen de utilidad con manejo seguro de nulos
  String _formatearMargenUtilidad() {
    try {
      return '${(inmueble.margenUtilidad ?? 0).toStringAsFixed(2)}%';
    } catch (e) {
      _registrarWarningSinDuplicados(
        'margen_formato_${inmueble.id ?? 0}',
        'Error al formatear margen de utilidad del inmueble: ${inmueble.id ?? "nuevo"}',
        e,
      );
      return '0.00%';
    }
  }

  /// Registra errores evitando duplicados en intervalos cortos
  void _registrarErrorControlado(
    String codigo,
    String mensaje,
    dynamic error,
    StackTrace stackTrace,
  ) {
    final errorKey = codigo;
    final ahora = DateTime.now();

    _limpiarErroresAntiguos();

    // Evitar logs duplicados en intervalo corto
    if (!_ultimosErrores.containsKey(errorKey) ||
        ahora.difference(_ultimosErrores[errorKey]!) > _intervaloMinimo) {
      _ultimosErrores[errorKey] = ahora;
      AppLogger.error(mensaje, error, stackTrace);
    }
  }

  /// Registra advertencias evitando duplicados
  void _registrarWarningSinDuplicados(
    String codigo,
    String mensaje,
    dynamic error,
  ) {
    final warnKey = codigo;
    final ahora = DateTime.now();

    if (!_ultimosErrores.containsKey(warnKey) ||
        ahora.difference(_ultimosErrores[warnKey]!) > _intervaloMinimo) {
      _ultimosErrores[warnKey] = ahora;
      AppLogger.warning('$mensaje. Error: $error');
    }
  }

  /// Limpia errores antiguos para evitar memory leaks
  void _limpiarErroresAntiguos() {
    if (_ultimosErrores.length > _maxErrorEntries) {
      final keysToRemove =
          _ultimosErrores.entries
              .toList()
              .sublist(0, _ultimosErrores.length - _maxErrorEntries ~/ 2)
              .map((e) => e.key)
              .toList();

      for (var key in keysToRemove) {
        _ultimosErrores.remove(key);
      }
    }
  }
}

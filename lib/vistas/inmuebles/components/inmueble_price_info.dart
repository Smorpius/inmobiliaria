import 'detail_row.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/inmueble_model.dart';
import 'package:inmobiliaria/utils/inmueble_formatter.dart';

class InmueblePriceInfo extends StatelessWidget {
  final Inmueble inmueble;
  final bool isInactivo;

  // Control para evitar logs duplicados
  static final Map<int, DateTime> _ultimosErrores = {};
  static const Duration _intervaloMinimo = Duration(seconds: 5);

  const InmueblePriceInfo({
    super.key,
    required this.inmueble,
    required this.isInactivo,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Column(
        children: [
          DetailRow(
            label: 'Monto total',
            value: _formatearValor(inmueble.montoTotal, 'monto total'),
            icon: Icons.attach_money,
            isInactivo: isInactivo,
          ),
          if (_mostrarPrecioVenta(inmueble.tipoOperacion))
            DetailRow(
              label: 'Precio de venta',
              value: _formatearValor(inmueble.precioVenta, 'precio de venta'),
              icon: Icons.monetization_on,
              isInactivo: isInactivo,
            ),
          if (_mostrarPrecioRenta(inmueble.tipoOperacion))
            DetailRow(
              label: 'Precio de renta',
              value: _formatearValor(inmueble.precioRenta, 'precio de renta'),
              icon: Icons.payments,
              isInactivo: isInactivo,
            ),
          // Añadir margen de utilidad si está disponible y es una venta
          if (_mostrarPrecioVenta(inmueble.tipoOperacion) &&
              inmueble.margenUtilidad != null)
            DetailRow(
              label: 'Margen',
              value: '${inmueble.margenUtilidad?.toStringAsFixed(2) ?? 'N/A'}%',
              icon: Icons.trending_up,
              isInactivo: isInactivo,
            ),
        ],
      );
    } catch (e, stackTrace) {
      // Evitar mostrar errores duplicados en la consola
      _registrarErrorSinDuplicados(
        'error_ui_precios',
        'Error al mostrar información de precios',
        e,
        stackTrace,
      );
      return const Column(
        children: [
          Text(
            'No se pudo mostrar la información de precios',
            style: TextStyle(color: Colors.red),
          ),
        ],
      );
    }
  }

  /// Determina si debe mostrar el precio de venta según el tipo de operación
  bool _mostrarPrecioVenta(String? tipoOperacion) {
    return tipoOperacion == 'venta' || tipoOperacion == 'ambos';
  }

  /// Determina si debe mostrar el precio de renta según el tipo de operación
  bool _mostrarPrecioRenta(String? tipoOperacion) {
    return tipoOperacion == 'renta' || tipoOperacion == 'ambos';
  }

  /// Formatea un valor monetario con manejo seguro de nulos
  String _formatearValor(double? valor, String campo) {
    try {
      if (valor == null) return 'N/A';
      return InmuebleFormatter.formatMonto(valor);
    } catch (e) {
      // Usar warning en lugar de error para eventos menos críticos
      _registrarWarningSinDuplicados(
        'formato_${inmueble.id ?? 0}_$campo',
        'Error al formatear $campo del inmueble: ${inmueble.id ?? "nuevo"}',
        e,
      );
      return 'N/A';
    }
  }

  /// Registra errores evitando duplicados en intervalos cortos
  void _registrarErrorSinDuplicados(
    String codigo,
    String mensaje,
    dynamic error,
    StackTrace stackTrace,
  ) {
    final hashCode = codigo.hashCode;
    final ahora = DateTime.now();

    if (!_ultimosErrores.containsKey(hashCode) ||
        ahora.difference(_ultimosErrores[hashCode]!) > _intervaloMinimo) {
      _ultimosErrores[hashCode] = ahora;
      AppLogger.error(mensaje, error, stackTrace);
    }
  }

  /// Registra warnings evitando duplicados en intervalos cortos
  void _registrarWarningSinDuplicados(
    String codigo,
    String mensaje,
    dynamic error,
  ) {
    final hashCode = codigo.hashCode;
    final ahora = DateTime.now();

    if (!_ultimosErrores.containsKey(hashCode) ||
        ahora.difference(_ultimosErrores[hashCode]!) > _intervaloMinimo) {
      _ultimosErrores[hashCode] = ahora;
      AppLogger.warning('$mensaje. Error: $error');
    }
  }
}

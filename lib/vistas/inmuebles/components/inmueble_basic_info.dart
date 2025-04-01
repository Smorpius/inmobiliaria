import 'detail_row.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/inmueble_model.dart';
import 'package:inmobiliaria/utils/inmueble_formatter.dart';

class InmuebleBasicInfo extends StatelessWidget {
  final Inmueble inmueble;
  final bool isInactivo;

  // Control para evitar logs duplicados con un mecanismo más eficiente
  static final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _intervaloMinimo = Duration(minutes: 5);

  const InmuebleBasicInfo({
    super.key,
    required this.inmueble,
    required this.isInactivo,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Obtener información del estado del inmueble utilizando el formatter
      final estadoInmueble = InmuebleFormatter.obtenerEstadoInmueble(
        inmueble.idEstado,
      );

      // Determinar color según el estado
      final estadoColor = _obtenerColorEstado(inmueble.idEstado);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailRow(
            label: 'Tipo de inmueble',
            value: InmuebleFormatter.formatTipoInmueble(inmueble.tipoInmueble),
            icon: Icons.home,
            isInactivo: isInactivo,
          ),
          DetailRow(
            label: 'Tipo de operación',
            value: InmuebleFormatter.formatTipoOperacion(
              inmueble.tipoOperacion,
            ),
            icon: Icons.sell,
            isInactivo: isInactivo,
          ),
          DetailRow(
            label: 'Estado',
            value: estadoInmueble,
            icon: Icons.info_outline,
            isInactivo: isInactivo,
            valueColor: estadoColor,
          ),
          // Características adicionales
          if (inmueble.caracteristicas != null &&
              inmueble.caracteristicas!.isNotEmpty)
            DetailRow(
              label: 'Características',
              value: inmueble.caracteristicas!,
              icon: Icons.list_alt,
              isInactivo: isInactivo,
            ),
          // Fecha de registro - Mejorado con formateo seguro
          if (inmueble.fechaRegistro != null)
            DetailRow(
              label: 'Fecha de registro',
              value: _formatearFechaSeguro(inmueble.fechaRegistro),
              icon: Icons.calendar_today,
              isInactivo: isInactivo,
            ),
        ],
      );
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'error_inmueble_basic_info_${inmueble.id ?? 0}',
        'Error al construir información básica del inmueble ID: ${inmueble.id ?? "nuevo"}',
        e,
        stackTrace,
      );

      // Widget de fallback para mostrar en caso de error
      return Column(
        children: [
          const DetailRow(
            label: 'Error',
            value: 'No se pudo cargar la información del inmueble',
            icon: Icons.error_outline,
            isInactivo: false,
            valueColor: Colors.red,
          ),
        ],
      );
    }
  }

  /// Obtiene el color según el estado del inmueble
  Color _obtenerColorEstado(int? idEstado) {
    switch (idEstado) {
      case 2: return Colors.red;      // No disponible
      case 3: return Colors.green;    // Disponible
      case 4: return Colors.blue;     // Vendido
      case 5: return Colors.purple;   // Rentado
      case 6: return Colors.orange;   // En negociación
      default: return Colors.grey;    // Estado desconocido o nulo
    }
  }

  /// Formatea la fecha de manera segura usando intl
  String _formatearFechaSeguro(DateTime? fecha) {
    if (fecha == null) return 'N/A';
    
    try {
      return DateFormat('yyyy-MM-dd').format(fecha);
    } catch (e) {
      _registrarErrorControlado(
        'formato_fecha_${inmueble.id ?? 0}',
        'Error al formatear fecha del inmueble: ${inmueble.id ?? "nuevo"}',
        e,
        StackTrace.current,
      );
      // Método alternativo más seguro si falla el formateo con intl
      try {
        return fecha.toString().split(' ')[0];
      } catch (_) {
        return 'N/A';
      }
    }
  }

  /// Registra errores evitando duplicados con un mecanismo mejorado
  void _registrarErrorControlado(
    String codigo,
    String mensaje,
    dynamic error,
    StackTrace stackTrace,
  ) {
    final ahora = DateTime.now();
    
    // Evitar log duplicado en intervalo corto
    if (!_ultimosErrores.containsKey(codigo) ||
        ahora.difference(_ultimosErrores[codigo]!) > _intervaloMinimo) {
      
      _ultimosErrores[codigo] = ahora;
      
      // Preservar la excepción original
      final errorString = error.toString();
      
      // Limitar la cantidad de errores almacenados para evitar memory leaks
      if (_ultimosErrores.length > 50) {
        final keysToRemove = _ultimosErrores.keys
            .toList()
            .sublist(0, _ultimosErrores.length - 30);
        for (var key in keysToRemove) {
          _ultimosErrores.remove(key);
        }
      }
      
      AppLogger.error('$mensaje: $errorString', error, stackTrace);
    }
  }
}
import 'detail_row.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/inmueble_model.dart';

class InmuebleAddressInfo extends StatelessWidget {
  final Inmueble inmueble;
  final bool isInactivo;

  // Control para evitar logs duplicados con límite máximo de entradas
  static final Map<String, DateTime> _ultimosLogs = {};
  static const Duration _intervaloMinimo = Duration(minutes: 5);
  static const int _maxLogEntries =
      50; // Limitar tamaño del mapa para evitar fugas de memoria

  const InmuebleAddressInfo({
    super.key,
    required this.inmueble,
    required this.isInactivo,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Verificar si hay suficientes datos para mostrar
      if (inmueble.id == null) {
        return const SizedBox.shrink(); // No mostrar nada si no hay ID
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dirección completa con manejo seguro
          DetailRow(
            label: 'Dirección completa',
            value: _obtenerDireccionCompleta(),
            icon: Icons.location_on,
            isInactivo: isInactivo,
          ),

          // Componentes individuales de la dirección
          // Solo mostrar campos que realmente tienen valor
          if (_mostrarCampo(inmueble.calle))
            DetailRow(
              label: 'Calle',
              value: inmueble.calle!,
              icon: Icons.signpost,
              isInactivo: isInactivo,
            ),
          if (_mostrarCampo(inmueble.numero))
            DetailRow(
              label: 'Número',
              value: inmueble.numero!,
              icon: Icons.confirmation_number,
              isInactivo: isInactivo,
            ),
          if (_mostrarCampo(inmueble.colonia))
            DetailRow(
              label: 'Colonia',
              value: inmueble.colonia!,
              icon: Icons.holiday_village,
              isInactivo: isInactivo,
            ),
          if (_mostrarCampo(inmueble.ciudad))
            DetailRow(
              label: 'Ciudad',
              value: inmueble.ciudad!,
              icon: Icons.location_city,
              isInactivo: isInactivo,
            ),
          if (_mostrarCampo(inmueble.estadoGeografico))
            DetailRow(
              label: 'Estado',
              value: inmueble.estadoGeografico!,
              icon: Icons.map,
              isInactivo: isInactivo,
            ),
          if (_mostrarCampo(inmueble.codigoPostal))
            DetailRow(
              label: 'Código Postal',
              value: inmueble.codigoPostal!,
              icon: Icons.markunread_mailbox,
              isInactivo: isInactivo,
            ),
          if (_mostrarCampo(inmueble.referencias))
            DetailRow(
              label: 'Referencias',
              value: inmueble.referencias!,
              icon: Icons.place,
              isInactivo: isInactivo,
            ),
        ],
      );
    } catch (e, stack) {
      _registrarErrorControlado(
        'error_direccion_render',
        'Error al renderizar información de dirección',
        e,
        stack,
      );

      // Retornar un fallback más informativo en caso de error
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No se pudo mostrar la información de dirección',
            style: TextStyle(color: Colors.grey),
          ),
          Text(
            'ID Inmueble: ${inmueble.id ?? 'N/A'}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      );
    }
  }

  /// Obtiene la dirección completa con manejo seguro para evitar errores
  String _obtenerDireccionCompleta() {
    try {
      // Si ya está disponible la dirección completa, usarla
      if (inmueble.direccionCompleta.isNotEmpty) {
        return inmueble.direccionCompleta;
      }

      // Si no, intentar construirla con los componentes disponibles
      final List<String> componentes = [];
      if (_mostrarCampo(inmueble.calle)) {
        componentes.add('${inmueble.calle}');
        if (_mostrarCampo(inmueble.numero)) {
          componentes.add('No. ${inmueble.numero}');
        }
      }

      if (_mostrarCampo(inmueble.colonia)) {
        componentes.add('Col. ${inmueble.colonia}');
      }

      if (_mostrarCampo(inmueble.ciudad)) {
        componentes.add(inmueble.ciudad!);

        if (_mostrarCampo(inmueble.estadoGeografico)) {
          componentes.add(inmueble.estadoGeografico!);
        }
      }

      if (_mostrarCampo(inmueble.codigoPostal)) {
        componentes.add('CP. ${inmueble.codigoPostal}');
      }

      return componentes.isEmpty
          ? 'Sin dirección disponible'
          : componentes.join(', ');
    } catch (e) {
      // Evitar llenar la consola con errores de formato de dirección
      _registrarWarning(
        'formato_direccion_${inmueble.id ?? 0}',
        'Error al formatear dirección completa: $e',
      );
      return 'Dirección no disponible';
    }
  }

  /// Método para determinar si un campo debe mostrarse
  bool _mostrarCampo(String? valor) {
    return valor != null && valor.trim().isNotEmpty;
  }

  /// Registra errores controladamente para evitar duplicados
  void _registrarErrorControlado(
    String codigo,
    String mensaje,
    dynamic error,
    StackTrace stackTrace,
  ) {
    final errorHash = '${codigo}_${inmueble.id ?? 0}';
    final ahora = DateTime.now();

    _limpiarLogsAntiguos();

    if (!_ultimosLogs.containsKey(errorHash) ||
        ahora.difference(_ultimosLogs[errorHash]!) > _intervaloMinimo) {
      _ultimosLogs[errorHash] = ahora;
      AppLogger.error(mensaje, error, stackTrace);
    }
  }

  /// Registra advertencias controladamente
  void _registrarWarning(String codigo, String mensaje) {
    final warningHash = '${codigo}_${inmueble.id ?? 0}';
    final ahora = DateTime.now();

    _limpiarLogsAntiguos();

    if (!_ultimosLogs.containsKey(warningHash) ||
        ahora.difference(_ultimosLogs[warningHash]!) > _intervaloMinimo) {
      _ultimosLogs[warningHash] = ahora;
      AppLogger.warning(mensaje);
    }
  }

  /// Limpia logs antiguos para evitar crecimiento excesivo de memoria
  static void _limpiarLogsAntiguos() {
    if (_ultimosLogs.length > _maxLogEntries) {
      // Encontrar las entradas más antiguas
      final entradas =
          _ultimosLogs.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));

      // Eliminar el 20% más antiguo
      final eliminar = (_ultimosLogs.length * 0.2).ceil();
      for (var i = 0; i < eliminar && i < entradas.length; i++) {
        _ultimosLogs.remove(entradas[i].key);
      }
    }
  }
}

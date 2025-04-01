import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';

class InmuebleErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final bool isConnectionError;

  // Control para evitar logs duplicados
  static final Map<String, DateTime> _ultimosLogsErrores = {};
  static const Duration _minTiempoEntreLogsErrores = Duration(minutes: 5);

  const InmuebleErrorState({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.isConnectionError = false,
  });

  @override
  Widget build(BuildContext context) {
    // Registrar el error sin duplicados
    _registrarErrorControlado(errorMessage);

    // Determinar si es un error de conexión basado en el mensaje o la bandera
    final bool esErrorConexion =
        isConnectionError || _esErrorDeConexion(errorMessage);

    // Determinar si es un error específico de la base de datos
    final bool esErrorBaseDatos = _esErrorBaseDeDatos(errorMessage);

    // Determinar mensaje e icono apropiados
    final String titulo;
    final IconData iconoError;
    final Color colorError;

    if (esErrorConexion) {
      titulo = 'Error de Conexión';
      iconoError = Icons.cloud_off;
      colorError = Colors.orange;
    } else if (esErrorBaseDatos) {
      titulo = 'Error de Base de Datos';
      iconoError = Icons.storage_outlined;
      colorError = Colors.amber.shade800;
    } else {
      titulo = 'Error';
      iconoError = Icons.error_outline;
      colorError = Colors.red;
    }

    // Formatear el mensaje para mejor visualización
    final String mensajeMostrado = _formatearMensajeError(errorMessage);

    // Mostrar un mensaje adicional según el tipo de error
    final String mensajeAdicional = _obtenerMensajeAdicional(
      esErrorConexion,
      esErrorBaseDatos,
    );

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconoError, size: 48, color: colorError),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorError,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensajeMostrado,
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            if (mensajeAdicional.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  mensajeAdicional,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Log cuando el usuario reintenta
                AppLogger.info(
                  'Usuario reintentando después de error: $errorMessage',
                );
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Registra el error pero evitando duplicados en el tiempo
  void _registrarErrorControlado(String mensaje) {
    final errorHash = mensaje.hashCode.toString();
    final ahora = DateTime.now();

    if (!_ultimosLogsErrores.containsKey(errorHash) ||
        ahora.difference(_ultimosLogsErrores[errorHash]!) >
            _minTiempoEntreLogsErrores) {
      _ultimosLogsErrores[errorHash] = ahora;
      AppLogger.warning('Error mostrado en UI de inmuebles: $mensaje');
    }
  }

  /// Verifica si el error es relacionado con la conexión
  bool _esErrorDeConexion(String mensaje) {
    final mensajeLower = mensaje.toLowerCase();
    return mensajeLower.contains('conexión') ||
        mensajeLower.contains('connection') ||
        mensajeLower.contains('timeout') ||
        mensajeLower.contains('socket') ||
        mensajeLower.contains('network');
  }

  /// Verifica si es un error específico de base de datos
  bool _esErrorBaseDeDatos(String mensaje) {
    final mensajeLower = mensaje.toLowerCase();
    return mensajeLower.contains('mysql') ||
        mensajeLower.contains('database') ||
        mensajeLower.contains('base de datos') ||
        mensajeLower.contains('sql') ||
        mensajeLower.contains('procedure') ||
        mensajeLower.contains('procedimiento');
  }

  /// Formatea el mensaje de error para mejor visualización
  String _formatearMensajeError(String mensaje) {
    // Si es un error de base de datos específico, hacerlo más amigable
    if (_esErrorBaseDeDatos(mensaje)) {
      if (mensaje.contains('SQLSTATE')) {
        return 'Ha ocurrido un error en la base de datos';
      }
      if (mensaje.contains('transaction')) {
        return 'Error en la transacción de datos';
      }
    }

    // Si es un error con detalles técnicos, extraer la parte más relevante
    if (mensaje.contains(': ')) {
      final partes = mensaje.split(': ');
      if (partes.length > 1) {
        return '${partes[0]}: ${partes[1]}';
      }
    }

    // Si el mensaje es muy largo, cortar a un tamaño razonable
    if (mensaje.length > 100) {
      return '${mensaje.substring(0, 97)}...';
    }

    return mensaje;
  }

  /// Obtiene un mensaje adicional según el tipo de error
  String _obtenerMensajeAdicional(bool esErrorConexion, bool esErrorBaseDatos) {
    if (esErrorConexion) {
      return 'Verifique su conexión a internet o que el servidor esté disponible.';
    }

    if (esErrorBaseDatos) {
      return 'Se ha detectado un problema con la base de datos. Intente nuevamente en unos momentos.';
    }

    return '';
  }
}

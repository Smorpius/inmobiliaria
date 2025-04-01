import '../utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/widgets/inmueble_imagenes_section.dart';

class ErrorDisplayWidget extends ConsumerWidget {
  final String errorMessage;
  final dynamic originalError;
  final VoidCallback onRetry;
  final bool showRetryButton;

  const ErrorDisplayWidget({
    super.key,
    required this.errorMessage,
    this.originalError,
    required this.onRetry,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esErrorConexion = _esErrorDeConexion(
      originalError?.toString() ?? errorMessage,
    );
    final esErrorDatabase = _esErrorBaseDatos(
      originalError?.toString() ?? errorMessage,
    );

    final mensajeAmigable = ErrorHandler.obtenerMensajeAmigable(
      originalError ?? errorMessage,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              esErrorConexion
                  ? Icons.wifi_off
                  : esErrorDatabase
                  ? Icons.storage
                  : Icons.error_outline,
              size: 64,
              color:
                  esErrorConexion || esErrorDatabase
                      ? Colors.orange
                      : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              mensajeAmigable,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (_obtenerMensajeAdicional(
              esErrorConexion,
              esErrorDatabase,
            ).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _obtenerMensajeAdicional(esErrorConexion, esErrorDatabase),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            if (showRetryButton)
              ElevatedButton.icon(
                onPressed: () {
                  // Si es un error de MySQL, intentar reiniciar la conexión
                  if (esErrorDatabase) {
                    ref.read(dbServiceProvider).reiniciarConexion().then((_) {
                      onRetry();
                    });
                  } else {
                    onRetry();
                  }
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

  bool _esErrorDeConexion(String mensaje) {
    final mensajeLower = mensaje.toLowerCase();
    return mensajeLower.contains('conexión') ||
        mensajeLower.contains('connection') ||
        mensajeLower.contains('timeout') ||
        mensajeLower.contains('socket') ||
        mensajeLower.contains('network');
  }

  bool _esErrorBaseDatos(String mensaje) {
    final mensajeLower = mensaje.toLowerCase();
    return mensajeLower.contains('mysql') ||
        mensajeLower.contains('database') ||
        mensajeLower.contains('base de datos') ||
        mensajeLower.contains('sql');
  }

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

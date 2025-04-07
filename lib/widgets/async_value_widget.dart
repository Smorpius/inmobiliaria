import '../utils/applogger.dart';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget optimizado para mostrar estados asíncronos de Riverpod.
///
/// Gestiona automáticamente estados de carga, error y datos,
/// con optimizaciones para prevenir congelamientos y mejorar la experiencia.
class AsyncValueWidget<T> extends StatelessWidget {
  static final Logger _logger = Logger('AsyncValueWidget');

  /// El valor asíncrono a mostrar
  final AsyncValue<T> value;

  /// Constructor de widget para el estado de datos
  final Widget Function(T) data;

  /// Widget opcional a mostrar durante la carga
  final Widget? loadingWidget;

  /// Constructor opcional de widget para errores personalizados
  final Widget Function(Object, StackTrace?)? errorWidget;

  /// Callback para reintentar la operación
  final VoidCallback? onRetry;

  /// Controla si se muestra el botón de reintentar
  final bool showRetryButton;

  /// Mensaje para cuando los datos están vacíos
  final String? emptyMessage;

  /// Widget opcional para mostrar cuando los datos están vacíos
  final Widget? emptyWidget;

  /// Función para verificar si los datos se consideran "vacíos"
  final bool Function(T)? isEmpty;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loadingWidget,
    this.errorWidget,
    this.onRetry,
    this.showRetryButton = true,
    this.emptyMessage,
    this.emptyWidget,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true, // Evita parpadeos durante refrescos
      data: (dataValue) {
        // Verificar datos vacíos usando función personalizada o lógica predeterminada
        final bool empty = isEmpty?.call(dataValue) ?? _isDataEmpty(dataValue);

        if (empty) {
          return emptyWidget ??
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    emptyMessage ?? 'No hay datos disponibles',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
        }

        // Si hay datos, llamar al constructor de datos
        return data(dataValue);
      },

      // Estado de carga optimizado
      loading:
          () =>
              loadingWidget ??
              Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              ),

      // Estado de error mejorado
      error: (error, stackTrace) {
        // Registrar el error con AppLogger
        try {
          AppLogger.error('Error en AsyncValueWidget', error, stackTrace);
        } catch (_) {
          // Si AppLogger no está disponible, usar el logger
          _logger.severe(
            'Error en AsyncValueWidget: $error',
            error,
            stackTrace,
          );
        }

        // Usar el widget de error personalizado si existe
        if (errorWidget != null) {
          return errorWidget!.call(error, stackTrace);
        }

        // Widget de error predeterminado con estilo adaptativo
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          _formatErrorMessage(error),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (showRetryButton && onRetry != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Determina si los datos se consideran vacíos según su tipo
  bool _isDataEmpty(T? data) {
    if (data == null) return true;
    if (data is List) return data.isEmpty;
    if (data is Map) return data.isEmpty;
    if (data is String) return data.isEmpty;
    if (data is Iterable) return data.isEmpty;
    return false;
  }

  /// Formatea el mensaje de error para hacerlo más amigable
  String _formatErrorMessage(Object error) {
    String message = error.toString();

    // Mensajes personalizados para errores comunes de base de datos
    if (message.contains('DatabaseException')) {
      if (message.contains('connection') || message.contains('timeout')) {
        return 'Error de conexión a la base de datos. Por favor, verifica tu conexión e inténtalo nuevamente.';
      }
      return 'Error en la base de datos. Por favor, inténtalo de nuevo.';
    }

    // Mensajes personalizados para errores de red
    if (message.contains('SocketException') ||
        message.contains('TimeoutException')) {
      return 'Error de conexión. Verifica tu conexión a Internet e inténtalo de nuevo.';
    }

    // Truncar mensajes demasiado largos
    if (message.length > 200) {
      message = '${message.substring(0, 197)}...';
    }

    // Limpiar prefijos técnicos
    message =
        message.replaceAll('Exception:', '').replaceAll('Error:', '').trim();

    return message.isEmpty ? 'Se produjo un error inesperado' : message;
  }
}

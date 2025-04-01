import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';

/// Widget que muestra los botones de acciones de edición para un inmueble.
///
/// Proporciona un botón de actualizar y otro de eliminar con sus respectivas
/// funciones callback que serán invocadas al presionarlos.
class InmuebleEditActions extends StatelessWidget {
  /// Callback ejecutado al presionar el botón de actualizar
  final VoidCallback onActualizar;

  /// Callback ejecutado al presionar el botón de eliminar
  final VoidCallback onEliminar;

  /// Indica si actualmente hay una operación en progreso
  final bool isLoading;

  /// Color personalizado para el botón de actualizar (opcional)
  final Color? colorActualizar;

  /// Color personalizado para el botón de eliminar (opcional)
  final Color? colorEliminar;

  const InmuebleEditActions({
    super.key,
    required this.onActualizar,
    required this.onEliminar,
    this.isLoading = false,
    this.colorActualizar,
    this.colorEliminar,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Column(
        children: [
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed:
                  isLoading
                      ? null
                      : () {
                        AppLogger.info(
                          'Iniciando operación de actualización de inmueble',
                        );
                        onActualizar();
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorActualizar ?? Colors.blue,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'ACTUALIZAR',
                        style: TextStyle(fontSize: 16),
                      ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed:
                  isLoading
                      ? null
                      : () {
                        AppLogger.info(
                          'Iniciando operación de eliminación de inmueble',
                        );
                        onEliminar();
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorEliminar ?? Colors.red,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('ELIMINAR', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      );
    } catch (e, stackTrace) {
      // Registrar errores inesperados (muy improbable en este componente)
      AppLogger.error(
        'Error al construir botones de edición de inmueble',
        e,
        stackTrace,
      );

      // Mostrar un fallback en caso de error
      return const Column(
        children: [Text('Error al cargar acciones de edición')],
      );
    }
  }
}

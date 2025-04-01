import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';

/// Widget que muestra los botones de acción para un inmueble.
///
/// Incluye botones para editar, cambiar estado (activar/inactivar) y
/// opcionalmente añadir un cliente interesado.
class InmuebleActionButtons extends StatefulWidget {
  /// Función a ejecutar cuando se presiona el botón de editar.
  final VoidCallback onEdit;

  /// Función a ejecutar cuando se presiona el botón de cambiar estado.
  final VoidCallback onDelete;

  /// Función opcional a ejecutar cuando se presiona el botón de agregar cliente interesado.
  final VoidCallback? onAddClienteInteresado;

  /// Indica si el inmueble está inactivo para ajustar la apariencia de los botones.
  final bool isInactivo;

  /// Indica si se debe mostrar el botón de agregar cliente interesado.
  final bool showAddClienteInteresado;

  /// Texto personalizado para el botón de cambiar estado.
  /// Si es null, se usará un texto predeterminado según [isInactivo].
  final String? deleteButtonText;

  /// Color personalizado para el botón de cambiar estado.
  /// Si es null, se usará verde para activar y rojo para inactivar.
  final Color? deleteButtonColor;

  const InmuebleActionButtons({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.onAddClienteInteresado,
    this.isInactivo = false,
    this.showAddClienteInteresado = false,
    this.deleteButtonText,
    this.deleteButtonColor,
  });

  @override
  State<InmuebleActionButtons> createState() => _InmuebleActionButtonsState();
}

class _InmuebleActionButtonsState extends State<InmuebleActionButtons> {
  // Control para evitar clics múltiples - ahora por instancia, no estático
  final Map<String, bool> _operacionesEnProceso = {
    'editar': false,
    'activar': false,
    'inactivar': false,
    'agregar_interesado': false,
  };

  // Para evitar errores repetidos
  String? _ultimoErrorRegistrado;
  DateTime? _ultimoTiempoError;
  static const _tiempoMinimoEntreErrores = Duration(seconds: 10);

  @override
  Widget build(BuildContext context) {
    try {
      // Determinar el texto del botón usando el valor proporcionado o un valor predeterminado
      final textoBoton =
          widget.deleteButtonText ??
          (widget.isInactivo
              ? 'Marcar como Disponible'
              : 'Marcar como No Disponible');

      // Determinar el color del botón usando el valor proporcionado o un valor predeterminado
      final colorBoton =
          widget.deleteButtonColor ??
          (widget.isInactivo ? Colors.green : Colors.red);

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botón de editar
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  _operacionesEnProceso['editar'] == true
                      ? null
                      : () => _ejecutarOperacionSegura('editar', widget.onEdit),
              icon: const Icon(Icons.edit),
              label: const Text('Editar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Botón de inactivar/reactivar
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  _operacionesEnProceso[widget.isInactivo
                              ? 'activar'
                              : 'inactivar'] ==
                          true
                      ? null
                      : () => _ejecutarOperacionSegura(
                        widget.isInactivo ? 'activar' : 'inactivar',
                        widget.onDelete,
                      ),
              icon: Icon(
                widget.isInactivo ? Icons.check_circle : Icons.remove_circle,
              ),
              label: Text(textoBoton),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorBoton,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          // Botón opcional para agregar cliente interesado
          if (widget.showAddClienteInteresado &&
              widget.onAddClienteInteresado != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _operacionesEnProceso['agregar_interesado'] == true
                        ? null
                        : () => _ejecutarOperacionSegura(
                          'agregar_interesado',
                          widget.onAddClienteInteresado!,
                        ),
                icon: const Icon(Icons.person_add),
                label: const Text('Agregar Interesado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      );
    } catch (e, stackTrace) {
      // Registrar error inesperado (muy improbable en este componente de UI)
      _registrarErrorControlado(
        'Error al construir botones de acción',
        e,
        stackTrace,
      );

      // Devolver un widget mínimo en caso de error
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Error al cargar botones de acción',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }

  /// Método para prevenir operaciones duplicadas causadas por clics múltiples
  void _ejecutarOperacionSegura(String tipoOperacion, VoidCallback operacion) {
    // Si ya hay una operación en proceso, evitar ejecutar otra
    if (_operacionesEnProceso[tipoOperacion] == true) {
      AppLogger.info(
        'Operación $tipoOperacion en proceso, ignorando clic adicional',
      );
      return;
    }

    if (!mounted) return;

    try {
      setState(() {
        _operacionesEnProceso[tipoOperacion] = true;
      });

      // Registrar la acción para diagnóstico
      AppLogger.info('Ejecutando acción de inmueble: $tipoOperacion');

      // Ejecutar la operación
      operacion();
    } catch (e, stackTrace) {
      // Registrar error y mostrar mensaje al usuario
      _registrarErrorControlado(
        'Error al ejecutar acción: $tipoOperacion',
        e,
        stackTrace,
      );

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al procesar la operación: ${e.toString().split('\n').first}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Asegurar que siempre se libere el bloqueo después de un breve retraso
      // para evitar clics múltiples accidentales
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _operacionesEnProceso[tipoOperacion] = false;
          });
        }
      });
    }
  }

  /// Registra errores con control para evitar duplicados en poco tiempo
  void _registrarErrorControlado(
    String mensaje,
    Object error,
    StackTrace stackTrace,
  ) {
    final errorHash = '${mensaje}_${error.hashCode}';
    final ahora = DateTime.now();

    // Evitar registrar el mismo error muchas veces en poco tiempo
    if (_ultimoErrorRegistrado != errorHash ||
        _ultimoTiempoError == null ||
        ahora.difference(_ultimoTiempoError!) > _tiempoMinimoEntreErrores) {
      _ultimoErrorRegistrado = errorHash;
      _ultimoTiempoError = ahora;

      AppLogger.error(mensaje, error, stackTrace);
    }
  }

  @override
  void dispose() {
    // Limpiar recursos
    _operacionesEnProceso.clear();
    super.dispose();
  }
}

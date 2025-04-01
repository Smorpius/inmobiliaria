import 'inmueble_card.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/inmueble_model.dart';
import '../../../models/inmueble_imagen.dart';

/// Widget que muestra una cuadrícula de tarjetas de inmuebles.
///
/// Permite personalizar las acciones al tocar, editar o cambiar el estado
/// de los inmuebles, así como la apariencia del botón de estado.
class InmuebleGridView extends StatelessWidget {
  // Constantes para estados de inmueble alineadas con los procedimientos almacenados
  static const int estadoNoDisponible = 2;
  static const int estadoDisponible = 3;
  static const int estadoVendido = 4;
  static const int estadoRentado = 5;
  static const int estadoEnNegociacion = 6;

  /// Lista de inmuebles a mostrar
  final List<Inmueble> inmuebles;

  /// Mapa de imágenes principales asociadas a cada inmueble por su ID
  final Map<int, InmuebleImagen?> imagenesPrincipales;

  /// Mapa de rutas de imágenes principales asociadas a cada inmueble por su ID
  final Map<int, String?> rutasImagenesPrincipales;

  /// Callback llamado cuando se toca una tarjeta de inmueble
  final Function(Inmueble) onTapInmueble;

  /// Callback llamado cuando se presiona el botón de editar de un inmueble
  final Function(Inmueble) onEditInmueble;

  /// Callback llamado cuando se presiona el botón de cambiar estado de un inmueble
  final Function(Inmueble) onInactivateInmueble;

  /// Callback opcional para renderizar un botón de estado personalizado
  final Widget Function(Inmueble, VoidCallback)? renderizarBotonEstado;

  // Control para evitar logs duplicados
  static final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _minimoTiempoEntreErrores = Duration(minutes: 1);

  const InmuebleGridView({
    super.key,
    required this.inmuebles,
    required this.imagenesPrincipales,
    required this.rutasImagenesPrincipales,
    required this.onTapInmueble,
    required this.onEditInmueble,
    required this.onInactivateInmueble,
    this.renderizarBotonEstado,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final crossAxisCount = _calculateCrossAxisCount(context);

      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio:
              0.85, // Modificado para dar más altura a las tarjetas
        ),
        itemCount: inmuebles.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          try {
            final inmueble = inmuebles[index];
            final bool isInactivo = inmueble.idEstado == estadoNoDisponible;

            // Crear botón de estado personalizado si se proporciona el callback
            Widget? customStateButton;
            if (renderizarBotonEstado != null) {
              customStateButton = renderizarBotonEstado!(
                inmueble,
                () => onInactivateInmueble(inmueble),
              );
            }

            // Verificar y asignar la ruta de imagen de manera segura
            String? rutaImagen;
            if (inmueble.id != null &&
                rutasImagenesPrincipales.containsKey(inmueble.id!)) {
              rutaImagen = rutasImagenesPrincipales[inmueble.id!];
            }

            return InmuebleCard(
              inmueble: inmueble,
              imagenPrincipal:
                  inmueble.id != null
                      ? imagenesPrincipales[inmueble.id!]
                      : null,
              rutaImagen: rutaImagen,
              onTap: () => onTapInmueble(inmueble),
              onEdit: () => onEditInmueble(inmueble),
              onInactivate: () => onInactivateInmueble(inmueble),
              isInactivo: isInactivo,
              inactivateButtonText: isInactivo ? 'Activar' : 'Desactivar',
              inactivateButtonColor: isInactivo ? Colors.green : Colors.red,
              customStateButton: customStateButton,
            );
          } catch (e, stackTrace) {
            _registrarErrorControlado(
              'Error al renderizar tarjeta de inmueble en posición $index',
              e,
              stackTrace,
            );

            // Devolver un widget de fallback en caso de error
            return Card(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error al cargar inmueble',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'Error crítico al construir grid de inmuebles',
        e,
        stackTrace,
      );

      // Widget de fallback en caso de error crítico
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('No se pudieron cargar los inmuebles'),
            const SizedBox(height: 8),
            Text(
              e.toString().split('\n').first,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
  }

  /// Calcula el número de columnas según el ancho de la pantalla
  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Ajuste más fino para diferentes tamaños de pantalla
    if (width < 500) return 1; // Dispositivos móviles en vertical
    if (width < 800) return 2; // Tabletas pequeñas o móviles en horizontal
    if (width < 1200) return 3; // Tabletas grandes o pantallas pequeñas
    if (width < 1500) return 4; // Pantallas medianas
    return 5; // Pantallas grandes
  }

  /// Registra errores de forma controlada evitando saturación de logs
  void _registrarErrorControlado(
    String mensaje,
    Object error,
    StackTrace stackTrace,
  ) {
    final errorHash = '${error.hashCode}_${mensaje.hashCode}';
    final ahora = DateTime.now();

    // Evitar logs duplicados en intervalo corto de tiempo
    if (!_ultimosErrores.containsKey(errorHash) ||
        ahora.difference(_ultimosErrores[errorHash]!) >
            _minimoTiempoEntreErrores) {
      _ultimosErrores[errorHash] = ahora;

      // Limitar el mapa para evitar fugas de memoria
      if (_ultimosErrores.length > 25) {
        final keysToRemove = _ultimosErrores.entries
            .toList()
            .sublist(0, 10)
            .map((e) => e.key);
        for (var key in keysToRemove) {
          _ultimosErrores.remove(key);
        }
      }

      AppLogger.error(mensaje, error, stackTrace);
    }
  }
}

import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import '../models/comprobante_venta_model.dart';
import '../providers/comprobantes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_colors.dart'; // Ruta de importación corregida

/// Widget para mostrar los comprobantes de una venta específica
class ComprobantesVentaWidget extends ConsumerWidget {
  static final Logger _logger = Logger('ComprobantesVentaWidget');

  final int idVenta;
  final bool esSoloLectura;
  final void Function(ComprobanteVenta)? onComprobanteSelected;

  const ComprobantesVentaWidget({
    super.key,
    required this.idVenta,
    this.esSoloLectura = false,
    this.onComprobanteSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comprobantesAsyncValue = ref.watch(
      comprobantesPorVentaProvider(idVenta),
    );

    return comprobantesAsyncValue.when(
      data: (comprobantes) {
        if (comprobantes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: AppColors.grisClaro,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay comprobantes registrados',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.oscuro.withAlpha((0.6 * 255).round()),
                  ),
                ),
                if (!esSoloLectura)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Comprobante'),
                      onPressed: () => _agregarComprobante(context, ref),
                    ),
                  ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: comprobantes.length,
                itemBuilder: (context, index) {
                  final comprobante = comprobantes[index];
                  return _ComprobanteVentaCard(
                    comprobante: comprobante,
                    onTap: () {
                      if (onComprobanteSelected != null) {
                        onComprobanteSelected!(comprobante);
                      } else {
                        _mostrarComprobanteDetalle(context, comprobante, ref);
                      }
                    },
                    onDelete:
                        esSoloLectura
                            ? null
                            : () =>
                                _eliminarComprobante(context, ref, comprobante),
                  );
                },
              ),
            ),
            if (!esSoloLectura)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Comprobante'),
                  onPressed: () => _agregarComprobante(context, ref),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar comprobantes: $error',
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Store the refresh result in a variable to avoid the unused result warning
                    final refreshResult = ref.refresh(
                      comprobantesPorVentaProvider(idVenta),
                    );
                    _logger.info(
                      'Refreshed comprobantes: ${refreshResult.hashCode}',
                    );
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
    );
  }

  void _agregarComprobante(BuildContext context, WidgetRef ref) async {
    // Implementar lógica para seleccionar archivo y agregar comprobante
    // Este método deberá integrarse con un selector de archivos

    // Ejemplo de implementación básica (se deberá adaptar según las necesidades)
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Aquí se integraría la selección de archivo y subida del mismo
    // Por ahora solo mostramos una notificación de ejemplo
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Funcionalidad de agregar comprobante se implementará según los requerimientos específicos',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _eliminarComprobante(
    BuildContext context,
    WidgetRef ref,
    ComprobanteVenta comprobante,
  ) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar comprobante'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este comprobante? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );

    if (confirmacion == true) {
      final service = ref.read(comprobanteVentaServiceProvider);

      try {
        // Ensure we handle null id case
        final int comprobanteId = comprobante.id ?? 0;
        if (comprobanteId <= 0) {
          throw Exception('ID de comprobante inválido');
        }

        final eliminado = await service.eliminarComprobante(comprobanteId);

        // No usar context después de una operación asíncrona sin verificar que esté montado
        if (!context.mounted) return;

        if (eliminado) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comprobante eliminado correctamente'),
            ),
          );
          // Refrescar la lista de comprobantes
          final refreshResult = ref.refresh(
            comprobantesPorVentaProvider(idVenta),
          );
          _logger.info('Comprobantes actualizados: ${refreshResult.hashCode}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo eliminar el comprobante'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar comprobante: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _mostrarComprobanteDetalle(
    BuildContext context,
    ComprobanteVenta comprobante,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(
                    comprobante.descripcion ?? 'Comprobante de Venta',
                  ),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    if (!esSoloLectura)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _eliminarComprobante(context, ref, comprobante);
                        },
                      ),
                  ],
                ),
                Flexible(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child:
                        comprobante.rutaArchivo.toLowerCase().endsWith('.pdf')
                            ? const Center(
                              child: Text('Vista previa de PDF no disponible'),
                            )
                            : Image.network(
                              comprobante.rutaArchivo,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.broken_image,
                                        size: 64,
                                        color: AppColors.grisClaro,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No se pudo cargar la imagen',
                                        style: TextStyle(
                                          color: AppColors.oscuro.withAlpha(
                                            (0.6 * 255).round(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                  ),
                                );
                              },
                            ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (comprobante.descripcion != null &&
                          comprobante.descripcion!.isNotEmpty)
                        Text(
                          'Descripción: ${comprobante.descripcion}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 8),
                      Text('Fecha de registro: ${comprobante.fechaRegistro}'),
                      if (comprobante.esPrincipal)
                        Chip(
                          label: const Text('Principal'),
                          backgroundColor: AppColors.primario,
                          labelStyle: const TextStyle(color: AppColors.claro),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

/// Card para mostrar un comprobante de venta
class _ComprobanteVentaCard extends StatelessWidget {
  final ComprobanteVenta comprobante;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ComprobanteVentaCard({
    required this.comprobante,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen o indicador de PDF
          _buildPreview(),

          // Overlay para descripción
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.oscuro.withAlpha(153),
              padding: const EdgeInsets.all(8),
              child: Text(
                comprobante.descripcion ?? 'Sin descripción',
                style: const TextStyle(color: AppColors.claro),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Indicador para comprobante principal
          if (comprobante.esPrincipal)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primario.withAlpha((0.8 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Principal',
                  style: TextStyle(
                    color: AppColors.claro,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // Botón eliminar
          if (onDelete != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.claro,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  iconSize: 20,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                ),
              ),
            ),

          // Área tactil
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: AppColors.claro.withAlpha(77),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (comprobante.rutaArchivo.toLowerCase().endsWith('.pdf')) {
      return Container(
        color: AppColors.grisClaro.withAlpha((0.5 * 255).round()),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 8),
              Text(
                'Documento PDF',
                style: TextStyle(
                  color: AppColors.oscuro.withAlpha((0.6 * 255).round()),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Image.network(
        comprobante.rutaArchivo,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image,
                  size: 48,
                  color: AppColors.grisClaro,
                ),
                const SizedBox(height: 8),
                Text(
                  'Error al cargar',
                  style: TextStyle(
                    color: AppColors.oscuro.withAlpha((0.6 * 255).round()),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }
}

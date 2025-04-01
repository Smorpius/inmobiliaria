import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/inmueble_renta_provider.dart';
import '../../../models/comprobante_movimiento_model.dart';

class GaleriaComprobantes extends ConsumerStatefulWidget {
  final Inmueble inmueble;

  const GaleriaComprobantes({super.key, required this.inmueble});

  @override
  ConsumerState<GaleriaComprobantes> createState() =>
      _GaleriaComprobantesState();
}

class _GaleriaComprobantesState extends ConsumerState<GaleriaComprobantes> {
  int? _movimientoSeleccionado;

  @override
  Widget build(BuildContext context) {
    final movimientosAsyncValue = ref.watch(
      movimientosPorInmuebleProvider(widget.inmueble.id!),
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de movimiento
          movimientosAsyncValue.when(
            data: (movimientos) {
              if (movimientos.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No hay movimientos registrados',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }

              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selecciona un movimiento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Movimiento',
                          border: OutlineInputBorder(),
                        ),
                        value: _movimientoSeleccionado,
                        items:
                            movimientos.map((movimiento) {
                              final icono =
                                  movimiento.tipoMovimiento == 'ingreso'
                                      ? Icons.arrow_circle_up
                                      : Icons.arrow_circle_down;
                              final color =
                                  movimiento.tipoMovimiento == 'ingreso'
                                      ? Colors.green
                                      : Colors.red;

                              return DropdownMenuItem<int>(
                                value: movimiento.id,
                                child: Row(
                                  children: [
                                    Icon(icono, color: color),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${movimiento.fechaFormateada} - ${movimiento.concepto}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      movimiento.montoFormateado,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _movimientoSeleccionado = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, _) =>
                    Center(child: Text('Error al cargar movimientos: $error')),
          ),

          const SizedBox(height: 16),

          // Comprobantes del movimiento seleccionado
          if (_movimientoSeleccionado != null)
            Expanded(child: _buildComprobantes(_movimientoSeleccionado!)),
        ],
      ),
    );
  }

  Widget _buildComprobantes(int idMovimiento) {
    final comprobantesAsyncValue = ref.watch(
      comprobantesPorMovimientoProvider(idMovimiento),
    );

    return comprobantesAsyncValue.when(
      data: (comprobantes) {
        if (comprobantes.isEmpty) {
          return const Center(
            child: Text(
              'No hay comprobantes para este movimiento',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: comprobantes.length,
          itemBuilder: (context, index) {
            final comprobante = comprobantes[index];
            return _buildComprobanteCard(comprobante);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) =>
              Center(child: Text('Error al cargar comprobantes: $error')),
    );
  }

  Widget _buildComprobanteCard(ComprobanteMovimiento comprobante) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen
          Image.network(
            comprobante.rutaImagen,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
              );
            },
          ),

          // Indicador para comprobante principal
          if (comprobante.esPrincipal)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(204), // 0.8 * 255 = 204
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Principal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // Overlay para descripción
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withAlpha(153), // 0.6 * 255 = 153
              padding: const EdgeInsets.all(8),
              child: Text(
                comprobante.descripcion ?? 'Sin descripción',
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Botón para ver a pantalla completa
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _verComprobanteCompleto(comprobante),
              splashColor: Colors.white.withAlpha(77), // 0.3 * 255 = ~77
            ),
          ),
        ],
      ),
    );
  }

  void _verComprobanteCompleto(ComprobanteMovimiento comprobante) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: const Text('Comprobante'),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      comprobante.rutaImagen,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (comprobante.descripcion != null &&
                    comprobante.descripcion!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      comprobante.descripcion!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}

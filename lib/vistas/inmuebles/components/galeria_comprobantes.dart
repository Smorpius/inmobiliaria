import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../utils/archivo_utils.dart';
import '../../../models/inmueble_model.dart';
import '../../../models/movimiento_renta_model.dart';
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
  // Variables para el filtro de período
  DateTime _periodoSeleccionado = DateTime.now();
  bool _filtrarPorPeriodo = false;

  @override
  Widget build(BuildContext context) {
    final movimientosAsyncValue = ref.watch(
      movimientosPorInmuebleProvider(widget.inmueble.id!),
    );

    // Envolver el contenido con Scaffold y agregar AppBar
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería de Comprobantes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Botón para mostrar el selector de período
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Filtrar por período',
            onPressed: _mostrarSelectorPeriodo,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de filtro activo
            if (_filtrarPorPeriodo)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Chip(
                  avatar: const Icon(Icons.filter_alt, size: 18),
                  label: Text(
                    'Período: ${_periodoSeleccionado.month}/${_periodoSeleccionado.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () {
                    setState(() {
                      _filtrarPorPeriodo = false;
                      _movimientoSeleccionado = null;
                    });
                  },
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                ),
              ),

            // Selector de movimiento
            movimientosAsyncValue.when(
              data: (movimientos) {
                // Filtrar los movimientos por período si el filtro está activo
                final movimientosFiltrados =
                    _filtrarPorPeriodo
                        ? _filtrarMovimientosPorPeriodo(movimientos)
                        : movimientos;

                if (movimientosFiltrados.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _filtrarPorPeriodo
                            ? 'No hay movimientos en el período seleccionado'
                            : 'No hay movimientos registrados',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
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
                              movimientosFiltrados.map((movimiento) {
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
                                    // Cambiar esto
                                    mainAxisSize:
                                        MainAxisSize
                                            .min, // Añade esta línea para limitar el ancho del Row
                                    children: [
                                      Icon(icono, color: color),
                                      const SizedBox(width: 8),
                                      // Cambiar Expanded por Flexible para evitar el problema de layout
                                      Flexible(
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
                  (error, _) => Center(
                    child: Text('Error al cargar movimientos: $error'),
                  ),
            ),

            const SizedBox(height: 16),

            // Comprobantes del movimiento seleccionado
            if (_movimientoSeleccionado != null)
              Expanded(child: _buildComprobantes(_movimientoSeleccionado!)),
          ],
        ),
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
          FutureBuilder<String>(
            future: ArchivoUtils.obtenerRutaCompleta(comprobante.rutaArchivo),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final rutaAbsoluta = snapshot.data!;
              final existe = File(rutaAbsoluta).existsSync();
              AppLogger.info(
                'Ruta comprobante: $rutaAbsoluta, ¿Existe?: $existe',
              );
              return Image.file(
                File(rutaAbsoluta),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      'No se encontró la imagen\n$rutaAbsoluta',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                },
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

  void _verComprobanteCompleto(ComprobanteMovimiento comprobante) async {
    final rutaAbsoluta = await ArchivoUtils.obtenerRutaCompleta(
      comprobante.rutaArchivo,
    );

    // Check if widget is still mounted before using context
    if (!mounted) return;

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
                    child: Image.file(
                      File(rutaAbsoluta),
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

  List<MovimientoRenta> _filtrarMovimientosPorPeriodo(
    List<MovimientoRenta> movimientos,
  ) {
    return movimientos.where((movimiento) {
      // Como fechaMovimiento no es nulo según la definición de la clase MovimientoRenta,
      // simplemente filtramos por año y mes sin verificación de nulidad
      return movimiento.fechaMovimiento.year == _periodoSeleccionado.year &&
          movimiento.fechaMovimiento.month == _periodoSeleccionado.month;
    }).toList();
  }

  void _mostrarSelectorPeriodo() {
    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: const Text('Seleccionar período'),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mes:'),
                          DropdownButton<int>(
                            value: _periodoSeleccionado.month,
                            items: List.generate(12, (index) {
                              final mes = index + 1;
                              return DropdownMenuItem(
                                value: mes,
                                child: Text(meses[index]),
                              );
                            }),
                            onChanged: (mes) {
                              if (mes != null) {
                                setState(() {
                                  _periodoSeleccionado = DateTime(
                                    _periodoSeleccionado.year,
                                    mes,
                                  );
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Año:'),
                          DropdownButton<int>(
                            value: _periodoSeleccionado.year,
                            items: List.generate(10, (index) {
                              final anio = DateTime.now().year - index;
                              return DropdownMenuItem(
                                value: anio,
                                child: Text(anio.toString()),
                              );
                            }),
                            onChanged: (anio) {
                              if (anio != null) {
                                setState(() {
                                  _periodoSeleccionado = DateTime(
                                    anio,
                                    _periodoSeleccionado.month,
                                  );
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filtrarPorPeriodo = true;
                            _movimientoSeleccionado = null;
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('Aplicar filtro'),
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

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/proveedor.dart';
import '../../../providers/proveedor_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/inmueble_proveedor_servicio.dart';
import '../../../providers/inmueble_proveedores_provider.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/inmueble_detalle_notifier.dart';

class InmuebleProveedoresSection extends ConsumerWidget {
  final int idInmueble;
  final bool isInactivo;

  // Constantes para mejorar la claridad del código
  static const double _espacioVertical = 12.0;
  static const double _espacioEntreElementos = 16.0;

  const InmuebleProveedoresSection({
    super.key,
    required this.idInmueble,
    this.isInactivo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviciosAsyncValue = ref.watch(
      inmuebleProveedoresNotifierProvider(idInmueble),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, ref),
            const SizedBox(height: _espacioVertical),
            serviciosAsyncValue.when(
              data: (servicios) => _buildServiciosList(context, ref, servicios),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error, stack),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir el encabezado de sección con botón de asignación
  Widget _buildSectionHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Servicios de Proveedores',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (!isInactivo)
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Asignar Proveedor'),
            onPressed: () => _mostrarDialogoAsignarProveedor(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  // Método para construir la lista de servicios
  Widget _buildServiciosList(
    BuildContext context,
    WidgetRef ref,
    List<InmuebleProveedorServicio> servicios,
  ) {
    if (servicios.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No hay servicios de proveedores asignados a este inmueble',
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: servicios.length,
      itemBuilder: (context, index) {
        final servicio = servicios[index];
        return _buildServicioProveedorItem(context, ref, servicio);
      },
    );
  }

  // Método para construir el widget de error
  Widget _buildErrorWidget(Object error, StackTrace? stack) {
    // Registramos el error pero evitamos duplicar registros
    AppLogger.warning('Error al cargar servicios de proveedores: $error');

    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(
            'Error al cargar servicios: ${_formatErrorMessage(error)}',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Método para formatear mensajes de error para la UI
  String _formatErrorMessage(Object error) {
    final message = error.toString();
    // Limitamos la longitud del mensaje para la UI
    return message.length > 100 ? '${message.substring(0, 100)}...' : message;
  }

  // Widget para cada servicio de proveedor
  Widget _buildServicioProveedorItem(
    BuildContext context,
    WidgetRef ref,
    InmuebleProveedorServicio servicio,
  ) {
    final formatter = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final costoFormateado = formatter.format(servicio.costo);
    final comisionFormateada = formatter.format(servicio.comision);
    final fechaFormateada = DateFormat(
      'dd/MM/yyyy',
    ).format(servicio.fechaAsignacion);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${servicio.nombreProveedor} - ${servicio.tipoServicio}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalle: ${servicio.servicioDetalle}'),
            Text(
              'Costo: $costoFormateado - Comisión (30%): $comisionFormateada',
            ),
            Text('Fecha de asignación: $fechaFormateada'),
            if (servicio.fechaServicio != null)
              Text(
                'Fecha del servicio: ${DateFormat('dd/MM/yyyy').format(servicio.fechaServicio!)}',
              ),
          ],
        ),
        trailing:
            !isInactivo
                ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed:
                      () => _confirmarEliminarServicio(context, ref, servicio),
                  tooltip: 'Eliminar servicio',
                )
                : null,
      ),
    );
  }

  // Mostrar diálogo para asignar nuevo proveedor
  Future<void> _mostrarDialogoAsignarProveedor(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // Obtenemos los proveedores disponibles
      final proveedoresState = ref.watch(proveedoresProvider);
      final proveedores = proveedoresState.proveedoresFiltrados;

      if (proveedores.isEmpty) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay proveedores disponibles'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Controladores para los campos del formulario
      Proveedor? proveedorSeleccionado;
      final servicioController = TextEditingController();
      final costoController = TextEditingController();
      final fechaServicioController = TextEditingController();
      DateTime fechaAsignacion = DateTime.now();
      DateTime? fechaServicio;

      // Variable para controlar operaciones en proceso
      bool procesandoOperacion = false;

      // Mostrar el diálogo con el formulario
      await showDialog(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Asignar Proveedor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Proveedor>(
                      decoration: const InputDecoration(
                        labelText: 'Proveedor',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          proveedores
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    '${p.nombre} - ${p.tipoServicio}',
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        proveedorSeleccionado = value;
                      },
                    ),
                    const SizedBox(height: _espacioEntreElementos),
                    TextField(
                      controller: servicioController,
                      decoration: const InputDecoration(
                        labelText: 'Detalle del Servicio',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: _espacioEntreElementos),
                    TextField(
                      controller: costoController,
                      decoration: const InputDecoration(
                        labelText: 'Costo',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: _espacioEntreElementos),
                    InkWell(
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: dialogContext,
                          initialDate: fechaAsignacion,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (fecha != null) fechaAsignacion = fecha;
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Asignación',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(fechaAsignacion),
                        ),
                      ),
                    ),
                    const SizedBox(height: _espacioEntreElementos),
                    InkWell(
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: dialogContext,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (fecha != null) {
                          fechaServicio = fecha;
                          fechaServicioController.text = DateFormat(
                            'dd/MM/yyyy',
                          ).format(fecha);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha del Servicio (Opcional)',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          fechaServicioController.text.isEmpty
                              ? 'Seleccionar fecha'
                              : fechaServicioController.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Prevenir operaciones duplicadas
                    if (procesandoOperacion) return;
                    procesandoOperacion = true;

                    // Validar campos requeridos
                    if (proveedorSeleccionado == null ||
                        servicioController.text.isEmpty ||
                        costoController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Todos los campos son obligatorios'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      procesandoOperacion = false;
                      return;
                    }

                    try {
                      // Validar que el costo sea un número válido
                      final costo = double.tryParse(costoController.text);
                      if (costo == null || costo <= 0) {
                        throw Exception('El costo debe ser un número positivo');
                      }

                      // Crear objeto de servicio
                      final servicio = InmuebleProveedorServicio(
                        idInmueble: idInmueble,
                        idProveedor: proveedorSeleccionado!.idProveedor!,
                        servicioDetalle: servicioController.text,
                        costo: costo,
                        comision: costo * 0.30,
                        fechaAsignacion: fechaAsignacion,
                        fechaServicio: fechaServicio,
                        nombreProveedor: proveedorSeleccionado!.nombre,
                        tipoServicio: proveedorSeleccionado!.tipoServicio,
                      );

                      // Cerrar diálogo y devolver servicio
                      Navigator.of(dialogContext).pop(servicio);
                    } catch (e) {
                      // Log del error
                      AppLogger.error(
                        'Error al procesar datos del servicio',
                        e,
                        StackTrace.current,
                      );

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${_formatErrorMessage(e)}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      procesandoOperacion = false;
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
      ).then((servicio) async {
        if (servicio != null && servicio is InmuebleProveedorServicio) {
          try {
            // Mostrar indicador de progreso
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Procesando asignación...'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            }

            final notifier = ref.read(
              inmuebleProveedoresNotifierProvider(idInmueble).notifier,
            );
            final success = await notifier.asignarProveedor(servicio);

            if (!context.mounted) return;

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Proveedor asignado correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
              ref.invalidate(inmuebleDetalleProvider(idInmueble));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al asignar proveedor'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            AppLogger.error(
              'Error al asignar proveedor',
              e,
              StackTrace.current,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${_formatErrorMessage(e)}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      });
    } catch (e) {
      AppLogger.error(
        'Error al mostrar diálogo de asignación',
        e,
        StackTrace.current,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_formatErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Confirmar eliminación de un servicio
  Future<void> _confirmarEliminarServicio(
    BuildContext context,
    WidgetRef ref,
    InmuebleProveedorServicio servicio,
  ) async {
    if (servicio.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar un servicio sin ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Variable para prevenir doble procesamiento
    bool procesandoEliminacion = false;

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar Asignación'),
            content: Text(
              '¿Está seguro que desea eliminar el servicio "${servicio.servicioDetalle}" '
              'proporcionado por ${servicio.nombreProveedor}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmar == true && servicio.id != null && !procesandoEliminacion) {
      try {
        procesandoEliminacion = true;

        // Mostrar indicador de progreso
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Eliminando servicio...'),
              duration: Duration(milliseconds: 800),
            ),
          );
        }

        final notifier = ref.read(
          inmuebleProveedoresNotifierProvider(idInmueble).notifier,
        );
        final success = await notifier.eliminarAsignacion(servicio.id!);

        if (!context.mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Servicio eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          // Refrescar datos del inmueble
          ref.invalidate(inmuebleDetalleProvider(idInmueble));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar servicio'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        AppLogger.error(
          'Error al eliminar servicio de proveedor',
          e,
          StackTrace.current,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${_formatErrorMessage(e)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        procesandoEliminacion = false;
      }
    }
  }
}

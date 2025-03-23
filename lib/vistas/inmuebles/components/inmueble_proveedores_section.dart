import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../models/proveedor.dart';
import '../../../providers/proveedor_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/inmueble_proveedor_servicio.dart';
import '../../../providers/inmueble_proveedores_provider.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/inmueble_detalle_notifier.dart';

class InmuebleProveedoresSection extends ConsumerWidget {
  final int idInmueble;
  final bool isInactivo;

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
            Row(
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
                    onPressed:
                        () => _mostrarDialogoAsignarProveedor(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            serviciosAsyncValue.when(
              data: (servicios) {
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
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) =>
                      Center(child: Text('Error al cargar servicios: $error')),
            ),
          ],
        ),
      ),
    );
  }

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
                )
                : null,
      ),
    );
  }

  Future<void> _mostrarDialogoAsignarProveedor(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Aquí está la corrección principal: acceder a los proveedores directamente
    final proveedoresState = ref.watch(proveedoresProvider);
    // Asumiendo que proveedoresState tiene una propiedad proveedoresFiltrados
    final proveedores = proveedoresState.proveedoresFiltrados;

    if (proveedores.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay proveedores disponibles')),
      );
      return;
    }

    Proveedor? proveedorSeleccionado;
    final servicioController = TextEditingController();
    final costoController = TextEditingController();
    final fechaServicioController = TextEditingController();
    DateTime fechaAsignacion = DateTime.now();
    DateTime? fechaServicio;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                                child: Text('${p.nombre} - ${p.tipoServicio}'),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      proveedorSeleccionado = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: servicioController,
                    decoration: const InputDecoration(
                      labelText: 'Detalle del Servicio',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: costoController,
                    decoration: const InputDecoration(
                      labelText: 'Costo',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
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
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (proveedorSeleccionado == null ||
                      servicioController.text.isEmpty ||
                      costoController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Todos los campos son obligatorios'),
                      ),
                    );
                    return;
                  }
                  try {
                    final costo = double.parse(costoController.text);
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
                    Navigator.of(context).pop(servicio);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al procesar los datos: $e'),
                      ),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    ).then((servicio) async {
      if (servicio != null && servicio is InmuebleProveedorServicio) {
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
      }
    });
  }

  Future<void> _confirmarEliminarServicio(
    BuildContext context,
    WidgetRef ref,
    InmuebleProveedorServicio servicio,
  ) async {
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

    if (confirmar == true && servicio.id != null) {
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
        ref.invalidate(inmuebleDetalleProvider(idInmueble));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar servicio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

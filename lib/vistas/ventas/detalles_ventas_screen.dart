import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/venta_model.dart';
import '../../providers/venta_providers.dart';
import 'package:inmobiliaria/models/estados_venta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/historial_transaccion_provider.dart';
import '../../providers/inmuebles_disponibles_provider.dart';

class DetallesVentaScreen extends ConsumerWidget {
  final int idVenta;

  const DetallesVentaScreen({super.key, required this.idVenta});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventaAsyncValue = ref.watch(ventaDetalleProvider(idVenta));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de Venta')),
      body: ventaAsyncValue.when(
        data: (venta) {
          if (venta == null) {
            return const Center(
              child: Text('No se encontró información para esta venta'),
            );
          }
          return _construirDetallesVenta(context, ref, venta);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error al cargar venta: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed:
                          () => ref.refresh(ventaDetalleProvider(idVenta)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _construirDetallesVenta(
    BuildContext context,
    WidgetRef ref,
    Venta venta,
  ) {
    final formatter = NumberFormat.currency(symbol: '\$', locale: 'es_MX');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _construirCabeceraVenta(venta, formatter),
          _construirCardDetallesInmueble(venta, formatter),
          _construirCardDetallesCliente(venta),
          _construirCardDetallesFinancieros(venta, formatter, ref, context),

          // Sección de acciones
          if (venta.idEstado == EstadosVenta.enProceso) // Si está en proceso
            _construirBotonesAccion(context, ref, venta),
        ],
      ),
    );
  }

  Widget _construirCabeceraVenta(Venta venta, NumberFormat formatter) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.sell, size: 48, color: Colors.teal),
            const SizedBox(height: 8),
            Text(
              venta.nombreInmueble ?? 'Venta #${venta.id}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _obtenerColorEstado(venta.idEstado),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _obtenerNombreEstado(venta.idEstado),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ingreso: ${formatter.format(venta.ingreso)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(venta.fechaVenta)}',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCardDetallesInmueble(Venta venta, NumberFormat formatter) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.home, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Información del Inmueble',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            _construirFilaInfo(
              'Nombre',
              venta.nombreInmueble ?? 'No disponible',
            ),
            _construirFilaInfo(
              'Tipo',
              _capitalizarPalabra(venta.tipoInmueble ?? 'No disponible'),
            ),
            _construirFilaInfo(
              'Operación',
              _capitalizarPalabra(venta.tipoOperacion ?? 'No disponible'),
            ),
            if (venta.precioOriginalInmueble != null)
              _construirFilaInfo(
                'Precio Original',
                formatter.format(venta.precioOriginalInmueble!),
              ),
            if (venta.margenGanancia != null)
              _construirFilaInfo(
                'Margen de Ganancia',
                '${venta.margenGanancia!.toStringAsFixed(2)}%',
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirCardDetallesCliente(Venta venta) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Información del Cliente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            _construirFilaInfo(
              'Cliente',
              '${venta.nombreCliente ?? ''} ${venta.apellidoCliente ?? ''}',
            ),
            _construirFilaInfo('ID Cliente', venta.idCliente.toString()),
          ],
        ),
      ),
    );
  }

  Widget _construirCardDetallesFinancieros(
    Venta venta,
    NumberFormat formatter,
    WidgetRef ref,
    BuildContext context,
  ) {
    // Calcular gastos adicionales como la diferencia entre utilidad bruta y neta
    final gastosAdicionales = venta.utilidadBruta - venta.utilidadNeta;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      'Detalles Financieros',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (venta.idEstado ==
                    EstadosVenta.enProceso) // Solo si está en proceso
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed:
                        () => _mostrarDialogoEditarGastos(context, ref, venta),
                    tooltip: 'Editar gastos',
                  ),
              ],
            ),
            const Divider(),
            _construirFilaInfo(
              'Ingreso Total',
              formatter.format(venta.ingreso),
            ),
            _construirFilaInfo(
              'Comisión Proveedores',
              formatter.format(venta.comisionProveedores),
            ),
            _construirFilaInfo(
              'Utilidad Bruta',
              formatter.format(venta.utilidadBruta),
            ),
            _construirFilaInfo(
              'Gastos Adicionales',
              formatter.format(gastosAdicionales),
            ),
            const Divider(),
            _construirFilaInfo(
              'Utilidad Neta',
              formatter.format(venta.utilidadNeta),
              destacado: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBotonesAccion(
    BuildContext context,
    WidgetRef ref,
    Venta venta,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed:
                () => _confirmarCambioEstado(
                  context,
                  ref,
                  venta.id!,
                  EstadosVenta.completada,
                  'completar esta venta',
                ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.check_circle),
            label: const Text('COMPLETAR VENTA'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
                () => _confirmarCambioEstado(
                  context,
                  ref,
                  venta.id!,
                  EstadosVenta.cancelada,
                  'cancelar esta venta',
                ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.cancel),
            label: const Text('CANCELAR VENTA'),
          ),
        ],
      ),
    );
  }

  Widget _construirFilaInfo(
    String label,
    String value, {
    bool destacado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
              fontSize: destacado ? 18 : 16,
              color: destacado ? Colors.green.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditarGastos(
    BuildContext context,
    WidgetRef ref,
    Venta venta,
  ) {
    // Calcular gastos adicionales como la diferencia entre utilidad bruta y neta
    final gastosAdicionales = venta.utilidadBruta - venta.utilidadNeta;
    final gastosController = TextEditingController(
      text: gastosAdicionales.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar Gastos Adicionales'),
            content: TextField(
              controller: gastosController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Gastos adicionales',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final gastosNuevos = double.tryParse(gastosController.text);

                    // Verificar si el formato es correcto
                    if (gastosNuevos == null) {
                      throw FormatException('Ingrese un valor numérico válido');
                    }

                    if (gastosNuevos < 0) {
                      throw Exception('Los gastos no pueden ser negativos');
                    }

                    // Validación adicional: los gastos no deben superar la utilidad bruta
                    if (gastosNuevos > venta.utilidadBruta) {
                      throw Exception(
                        'Los gastos no pueden superar la utilidad bruta (${venta.utilidadBruta})',
                      );
                    }

                    // Calcular la nueva utilidad neta correctamente
                    final nuevaUtilidadNeta =
                        venta.utilidadBruta - gastosNuevos;

                    Navigator.pop(context);
                    final success = await ref
                        .read(ventasStateProvider.notifier)
                        .actualizarUtilidadNeta(venta.id!, nuevaUtilidadNeta);

                    if (context.mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gastos actualizados correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        final _ = ref.refresh(ventaDetalleProvider(idVenta));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al actualizar los gastos'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      // Mensaje de error específico según el tipo de excepción
                      String mensaje;
                      if (e is FormatException) {
                        mensaje = 'Error de formato: ${e.message}';
                      } else {
                        mensaje = 'Error: $e';
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(mensaje),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _confirmarCambioEstado(
    BuildContext context,
    WidgetRef ref,
    int idVenta,
    int nuevoEstado,
    String accionTexto,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmación'),
            content: Text('¿Está seguro que desea $accionTexto?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await ref
                      .read(ventasStateProvider.notifier)
                      .cambiarEstadoVenta(idVenta, nuevoEstado);

                  if (context.mounted) {
                    if (success) {
                      // Mostrar mensaje de éxito
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Estado actualizado correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Actualizar los providers relacionados para notificar a otras partes de la app

                      // Actualizar los detalles de esta venta específica
                      final _ = ref.refresh(ventaDetalleProvider(idVenta));

                      // Actualizar la lista general de ventas para reflejar el cambio
                      ref.invalidate(ventasProvider);

                      // Actualizar el estado global de las ventas
                      ref.read(ventasStateProvider.notifier).cargarVentas();

                      // Actualizar las estadísticas de ventas
                      final _ = ref.refresh(ventasEstadisticasGeneralProvider);

                      // Si se canceló la venta, también debemos refrescar los inmuebles disponibles
                      if (nuevoEstado == EstadosVenta.cancelada) {
                        ref.invalidate(inmueblesDisponiblesProvider);
                      }

                      // También refrescar el historial de transacciones para esta venta
                      if (nuevoEstado == EstadosVenta.completada) {
                        ref.invalidate(historialVentaProvider(idVenta));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al actualizar el estado'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      nuevoEstado == EstadosVenta.completada
                          ? Colors.green
                          : Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  nuevoEstado == EstadosVenta.completada
                      ? 'Completar'
                      : 'Cancelar',
                ),
              ),
            ],
          ),
    );
  }

  String _obtenerNombreEstado(int idEstado) {
    return EstadosVenta.obtenerNombre(idEstado.toString());
  }

  Color _obtenerColorEstado(int idEstado) {
    return EstadosVenta.obtenerColor(idEstado);
  }

  String _capitalizarPalabra(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }
}

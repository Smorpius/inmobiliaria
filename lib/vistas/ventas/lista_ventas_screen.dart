import 'package:intl/intl.dart';
import 'detalles_ventas_screen.dart';
import 'package:flutter/material.dart';
import '../../models/venta_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../models/estados_venta.dart';
import 'registrar_nueva_venta_screen.dart';
import '../../providers/venta_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ventas_state.dart'; // Importación correcta del modelo

class ListaVentasScreen extends ConsumerWidget {
  const ListaVentasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventasState = ref.watch(ventasStateProvider);

    return AppScaffold(
      title: 'Ventas',
      currentRoute: '/ventas',
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filtrar ventas',
          onPressed: () => _mostrarDialogoFiltros(context, ref),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart),
          tooltip: 'Ver reportes',
          onPressed: () => Navigator.pushNamed(context, '/ventas/reportes'),
        ),
      ],
      body: Column(
        children: [
          // Resumen de estadísticas
          _construirResumenEstadisticas(ref),

          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar ventas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed:
                      () => ref
                          .read(ventasStateProvider.notifier)
                          .actualizarBusqueda(''),
                ),
              ),
              onChanged:
                  (value) => ref
                      .read(ventasStateProvider.notifier)
                      .actualizarBusqueda(value),
            ),
          ),

          // Filtros aplicados
          if (ventasState.filtroFechas != null ||
              ventasState.filtroEstado != null)
            _construirChipsFiltros(context, ref, ventasState),

          // Lista de ventas
          Expanded(
            child:
                ventasState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ventasState.errorMessage != null
                    ? Center(child: Text('Error: ${ventasState.errorMessage}'))
                    : ventasState.ventasFiltradas.isEmpty
                    ? const Center(child: Text('No hay ventas disponibles'))
                    : _construirListaVentas(
                      context,
                      ref,
                      ventasState.ventasFiltradas,
                    ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        alignment: Alignment.centerRight,
        child: FloatingActionButton(
          onPressed: () => _navegarARegistrarVenta(context, ref),
          backgroundColor: Colors.teal,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _construirResumenEstadisticas(WidgetRef ref) {
    final estadisticasAsyncValue = ref.watch(ventasEstadisticasGeneralProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: estadisticasAsyncValue.when(
          data:
              (estadisticas) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Total Ventas',
                    estadisticas.totalVentas.toString(),
                    Icons.sell,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Ingresos',
                    '\$${NumberFormat('#,##0.00', 'es_MX').format(estadisticas.ingresoTotal)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Utilidad',
                    '\$${NumberFormat('#,##0.00', 'es_MX').format(estadisticas.utilidadTotal)}',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ],
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _construirChipsFiltros(
    BuildContext context,
    WidgetRef ref,
    VentasState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (state.filtroFechas != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(
                  '${DateFormat('dd/MM/yyyy').format(state.filtroFechas!.start)} - '
                  '${DateFormat('dd/MM/yyyy').format(state.filtroFechas!.end)}',
                ),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted:
                    () => ref
                        .read(ventasStateProvider.notifier)
                        .aplicarFiltroFechas(null),
                backgroundColor: Colors.blue.shade100,
              ),
            ),
          if (state.filtroEstado != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(_obtenerNombreEstado(state.filtroEstado!)),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted:
                    () => ref
                        .read(ventasStateProvider.notifier)
                        .aplicarFiltroEstado(null),
                backgroundColor: Colors.green.shade100,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: const Text('Limpiar filtros'),
              onPressed:
                  () => ref.read(ventasStateProvider.notifier).limpiarFiltros(),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirListaVentas(
    BuildContext context,
    WidgetRef ref,
    List<Venta> ventas,
  ) {
    return ListView.builder(
      itemCount: ventas.length,
      itemBuilder: (context, index) {
        final venta = ventas[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            title: Text(venta.nombreInmueble ?? 'Inmueble'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente: ${venta.nombreCliente ?? ''} ${venta.apellidoCliente ?? ''}',
                ),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy').format(venta.fechaVenta)}',
                ),
                Text(
                  'Ingreso: \$${NumberFormat('#,##0.00', 'es_MX').format(venta.ingreso)}',
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _obtenerColorEstado(venta.idEstado),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _obtenerNombreEstado(venta.idEstado.toString()),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            onTap: () => _navegarADetalleVenta(context, venta.id!),
          ),
        );
      },
    );
  }

  void _mostrarDialogoFiltros(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filtrar ventas'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.date_range),
                    title: const Text('Filtrar por fechas'),
                    onTap: () async {
                      Navigator.pop(context);
                      final fechaActual = DateTime.now();

                      // Usar el contexto dentro del mismo método async
                      if (context.mounted) {
                        final fechas = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: fechaActual,
                          initialDateRange: DateTimeRange(
                            start: fechaActual.subtract(
                              const Duration(days: 30),
                            ),
                            end: fechaActual,
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.teal,
                                  onPrimary: Colors.white,
                                  surface: Colors.teal.shade50,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (fechas != null && context.mounted) {
                          ref
                              .read(ventasStateProvider.notifier)
                              .aplicarFiltroFechas(fechas);
                        }
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.filter_list),
                    title: const Text('Filtrar por estado'),
                    onTap: () {
                      Navigator.pop(context);
                      _mostrarDialogoFiltroEstados(context, ref);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  void _mostrarDialogoFiltroEstados(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleccionar estado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.pending, color: Colors.orange),
                  title: const Text('En proceso'),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(ventasStateProvider.notifier)
                        .aplicarFiltroEstado('7');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Completada'),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(ventasStateProvider.notifier)
                        .aplicarFiltroEstado('8');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: const Text('Cancelada'),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(ventasStateProvider.notifier)
                        .aplicarFiltroEstado('9');
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  void _navegarADetalleVenta(BuildContext context, int idVenta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetallesVentaScreen(idVenta: idVenta),
      ),
    );
  }

  void _navegarARegistrarVenta(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistrarNuevaVentaScreen(),
      ),
    ).then((value) {
      // Si retornamos true, significa que se registró una venta correctamente
      if (value == true) {
        // Usar el operador "discard" para indicar explícitamente que ignoramos el resultado
        final _ = ref.refresh(ventasProvider);
      }
    });
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: Colors.grey.shade700)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
      ],
    );
  }

  String _obtenerNombreEstado(String idEstado) {
    return EstadosVenta.obtenerNombre(idEstado);
  }

  Color _obtenerColorEstado(int idEstado) {
    return EstadosVenta.obtenerColor(idEstado);
  }
}

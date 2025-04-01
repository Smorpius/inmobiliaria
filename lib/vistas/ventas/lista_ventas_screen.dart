import 'package:intl/intl.dart';
import '../../utils/applogger.dart';
import 'detalles_ventas_screen.dart';
import 'package:flutter/material.dart';
import '../../models/venta_model.dart';
import '../../models/ventas_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../models/estados_venta.dart';
import 'registrar_nueva_venta_screen.dart';
import '../../providers/venta_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListaVentasScreen extends ConsumerStatefulWidget {
  const ListaVentasScreen({super.key});

  @override
  ConsumerState<ListaVentasScreen> createState() => _ListaVentasScreenState();
}

class _ListaVentasScreenState extends ConsumerState<ListaVentasScreen> {
  // Mapa para control de errores y evitar duplicados
  final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _intervaloMinimoErrores = Duration(minutes: 1);

  @override
  Widget build(BuildContext context) {
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
          _construirBarraBusqueda(context, ref, ventasState),

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
                    ? const _EstadoVacio()
                    : _construirListaVentas(
                      context,
                      ref,
                      ventasState.ventasFiltradas,
                    ),
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => _navegarARegistrarVenta(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text(
                  'Registrar Nueva Venta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirBarraBusqueda(
    BuildContext context,
    WidgetRef ref,
    VentasState ventasState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar ventas...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed:
                () => ref
                    .read(ventasStateProvider.notifier)
                    .actualizarBusqueda(''),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged:
            (value) => ref
                .read(ventasStateProvider.notifier)
                .actualizarBusqueda(value),
      ),
    );
  }

  Widget _construirListaVentas(
    BuildContext context,
    WidgetRef ref,
    List<Venta> ventas,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: ventas.length,
      itemBuilder: (context, index) {
        final venta = ventas[index];
        return _VentaTarjeta(
          venta: venta,
          onTap: () => _navegarADetalleVenta(context, venta.id!),
        );
      },
    );
  }

  Widget _construirResumenEstadisticas(WidgetRef ref) {
    final estadisticasAsyncValue = ref.watch(ventasEstadisticasGeneralProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          error: (error, stackTrace) {
            // Registrar el error con AppLogger
            _registrarErrorControlado(
              'estadisticas_error',
              'Error al cargar estadísticas generales',
              error,
              stackTrace,
            );
            return Text('Error al cargar estadísticas: $error');
          },
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
                child: const Text('Cancelar'),
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

  // Registrar error controlando duplicados
  void _registrarErrorControlado(
    String codigo,
    String mensaje,
    dynamic error,
    StackTrace stackTrace,
  ) {
    final errorKey = codigo;
    final ahora = DateTime.now();

    // Evitar errores duplicados en corto periodo
    if (_ultimosErrores.containsKey(errorKey) &&
        ahora.difference(_ultimosErrores[errorKey]!) <
            _intervaloMinimoErrores) {
      return;
    }

    // Registrar error
    _ultimosErrores[errorKey] = ahora;

    // Limitar tamaño del mapa para evitar fugas de memoria
    if (_ultimosErrores.length > 10) {
      final entradaAntigua =
          _ultimosErrores.entries
              .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
              .key;
      _ultimosErrores.remove(entradaAntigua);
    }

    AppLogger.error('$mensaje: ${error.toString()}', error, stackTrace);
  }

  @override
  void dispose() {
    // Limpiar recursos
    _ultimosErrores.clear();
    super.dispose();
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No hay ventas disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra tu primera venta con el botón +',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _VentaTarjeta extends StatelessWidget {
  final Venta venta;
  final VoidCallback onTap;

  const _VentaTarjeta({required this.venta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTipoOperacionBadge(venta.tipoOperacion ?? 'venta'),
                  _buildEstadoBadge(venta.idEstado),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                venta.nombreInmueble ?? 'Inmueble sin nombre',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Cliente: ${venta.nombreCliente ?? ''} ${venta.apellidoCliente ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatCurrency.format(venta.ingreso),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatDate.format(venta.fechaVenta),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoOperacionBadge(String tipo) {
    bool esVenta = tipo.toLowerCase() == 'venta';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: esVenta ? Colors.blue[100] : Colors.amber[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tipo.toUpperCase(),
        style: TextStyle(
          color: esVenta ? Colors.blue[800] : Colors.amber[800],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(int idEstado) {
    Color backgroundColor;
    Color textColor;
    String estado = EstadosVenta.obtenerNombre(idEstado.toString());

    switch (idEstado) {
      case 7: // en_proceso
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 8: // completada
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 9: // cancelada
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

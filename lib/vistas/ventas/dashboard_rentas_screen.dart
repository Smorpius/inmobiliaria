import 'package:intl/intl.dart';
import '../../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/async_value_widget.dart';
import '../../providers/providers_global.dart';
import '../../models/movimiento_renta_model.dart';
import '../../widgets/filtro_periodo_widget.dart';
import '../../services/movimientos_renta_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para el servicio de movimientos
final movimientosServiceProvider = Provider<MovimientosRentaService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return MovimientosRentaService(dbService);
});

// Provider para el tipo de período seleccionado
final tipoPeriodoActualProvider = StateProvider<TipoPeriodo>((ref) {
  return TipoPeriodo.mes; // Inicializar con mes por defecto
});

// Provider para el rango de fechas seleccionado
final rangoFechasProvider = StateProvider<DateTimeRange>((ref) {
  final tipoInicial = ref.watch(tipoPeriodoActualProvider);
  return FiltroPeriodoWidget.calcularRangoPorTipoEstatico(tipoInicial);
});

// Provider para obtener la lista de movimientos del periodo seleccionado
final movimientosDelPeriodoProvider = FutureProvider.autoDispose<
  List<MovimientoRenta>
>((ref) async {
  final movimientosService = ref.watch(movimientosServiceProvider);
  final rango = ref.watch(rangoFechasProvider);

  try {
    final periodoStr = DateFormat('yyyy-MM').format(rango.start);
    AppLogger.info(
      'Cargando movimientos para el periodo aproximado: $periodoStr (basado en inicio de rango)',
    );
    return await movimientosService.obtenerMovimientosPorPeriodo(periodoStr);
  } catch (e, stack) {
    AppLogger.error('Error al obtener movimientos para el dashboard', e, stack);
    rethrow;
  }
});

class DashboardRentasScreen extends ConsumerWidget {
  const DashboardRentasScreen({super.key});

  void _actualizarPeriodo(
    WidgetRef ref,
    TipoPeriodo tipo,
    DateTimeRange rango,
  ) {
    ref.read(tipoPeriodoActualProvider.notifier).state = tipo;
    ref.read(rangoFechasProvider.notifier).state = rango;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipoPeriodo = ref.watch(tipoPeriodoActualProvider);
    final rangoFechas = ref.watch(rangoFechasProvider);
    final movimientosAsync = ref.watch(movimientosDelPeriodoProvider);
    final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
    final formatFechaCorta = DateFormat('dd/MM/yy');

    return AppScaffold(
      title: 'Dashboard de Rentas',
      currentRoute: '/dashboard_rentas',
      actions: const [],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(movimientosDelPeriodoProvider);
          await ref.read(movimientosDelPeriodoProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FiltroPeriodoWidget(
                  initialPeriodo: tipoPeriodo,
                  initialStartDate: rangoFechas.start,
                  initialEndDate: rangoFechas.end,
                  onPeriodoChanged:
                      (tipo, rango) => _actualizarPeriodo(ref, tipo, rango),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AsyncValueWidget<List<MovimientoRenta>>(
              value: movimientosAsync,
              data: (movimientos) {
                double totalIngresos = 0;
                double totalEgresos = 0;
                for (var mov in movimientos) {
                  if (mov.tipoMovimiento == 'ingreso') {
                    totalIngresos += mov.monto;
                  } else {
                    totalEgresos += mov.monto;
                  }
                }
                final balance = totalIngresos - totalEgresos;

                return Column(
                  children: [
                    _buildResumenCard(
                      context,
                      'Ingresos del Periodo',
                      totalIngresos,
                      Icons.arrow_downward,
                      Colors.green,
                      formatCurrency,
                    ),
                    const SizedBox(height: 16),
                    _buildResumenCard(
                      context,
                      'Egresos del Periodo',
                      totalEgresos,
                      Icons.arrow_upward,
                      Colors.red,
                      formatCurrency,
                    ),
                    const SizedBox(height: 16),
                    _buildResumenCard(
                      context,
                      'Balance del Periodo',
                      balance,
                      Icons.account_balance_wallet,
                      balance >= 0 ? Colors.blue : Colors.orange,
                      formatCurrency,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Movimientos del Periodo (${movimientos.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildListaMovimientos(
                      context,
                      movimientos,
                      formatCurrency,
                      formatFechaCorta,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard(
    BuildContext context,
    String titulo,
    double valor,
    IconData icono,
    Color color,
    NumberFormat formatCurrency,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icono, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency.format(valor),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaMovimientos(
    BuildContext context,
    List<MovimientoRenta> movimientos,
    NumberFormat formatCurrency,
    DateFormat formatFecha,
  ) {
    if (movimientos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: Text('No hay movimientos en este periodo.'),
        ),
      );
    }

    movimientos.sort((a, b) => b.fechaMovimiento.compareTo(a.fechaMovimiento));
    final movimientosAMostrar = movimientos;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movimientosAMostrar.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final movimiento = movimientosAMostrar[index];
        final esIngreso = movimiento.tipoMovimiento == 'ingreso';
        final color = esIngreso ? Colors.green : Colors.red;
        final icono = esIngreso ? Icons.arrow_downward : Icons.arrow_upward;

        return ListTile(
          leading: Icon(icono, color: color),
          title: Text(
            movimiento.concepto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${movimiento.nombreInmueble ?? 'Inmueble ID: ${movimiento.idInmueble}'} - ${formatFecha.format(movimiento.fechaMovimiento)}',
          ),
          trailing: Text(
            formatCurrency.format(movimiento.monto),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

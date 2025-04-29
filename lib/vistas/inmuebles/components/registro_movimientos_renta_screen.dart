import 'package:intl/intl.dart';
import 'galeria_comprobantes.dart';
import 'formulario_movimiento.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/cliente_model.dart';
import '../../../models/inmueble_model.dart';
import '../../../providers/cliente_providers.dart';
import '../../../models/movimiento_renta_model.dart';
import '../../../widgets/filtro_periodo_widget.dart';
import '../../../controllers/inmueble_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/inmueble_renta_provider.dart';
import '../../../providers/contrato_renta_provider.dart';
import 'package:inmobiliaria/providers/venta_providers.dart';
import 'package:inmobiliaria/vistas/ventas/reportes_movimientos_screen.dart';

// Provider para obtener detalles de un cliente específico
final clienteDetalleProvider = FutureProvider.family<Cliente?, int>((
  ref,
  idCliente,
) async {
  try {
    final controller = ref.read(clienteControllerProvider);
    return await controller.getClientePorId(idCliente);
  } catch (e, stackTrace) {
    AppLogger.error('Error al cargar cliente', e, stackTrace);
    return null;
  }
});

// Provider para obtener el cliente asociado a un inmueble (prioriza cliente de ventas sobre cliente de inmueble)
final clientePorInmuebleProvider = FutureProvider.family<Cliente?, int>((
  ref,
  idInmueble,
) async {
  try {
    // 1. Primero verificar si hay una venta asociada al inmueble
    final ventasController = ref.read(ventaControllerProvider);
    final ventas = await ventasController.obtenerVentas();
    final ventasInmueble =
        ventas.where((v) => v.idInmueble == idInmueble).toList();

    // Si hay ventas, usar el cliente de la más reciente
    if (ventasInmueble.isNotEmpty) {
      // Ordenar por fecha de venta (más reciente primero)
      ventasInmueble.sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));

      if (ventasInmueble.first.idCliente > 0) {
        AppLogger.info(
          'Cliente encontrado en venta: ${ventasInmueble.first.idCliente}',
        );
        final clienteController = ref.read(clienteControllerProvider);
        return await clienteController.getClientePorId(
          ventasInmueble.first.idCliente,
        );
      }
    }

    // 2. Si no hay ventas, buscar en contratos activos
    final contratos = await ref.read(contratosRentaProvider.future);
    final contratoActivo =
        contratos
            .where((c) => c.idInmueble == idInmueble && c.idEstado == 1)
            .firstOrNull;

    if (contratoActivo != null && contratoActivo.idCliente > 0) {
      AppLogger.info(
        'Cliente encontrado en contrato: ${contratoActivo.idCliente}',
      );
      final clienteController = ref.read(clienteControllerProvider);
      return await clienteController.getClientePorId(contratoActivo.idCliente);
    }

    // 3. Finalmente verificar el cliente asociado directamente al inmueble
    final controller = InmuebleController();
    final inmuebles = await controller.getInmuebles();
    final inmueble = inmuebles.where((i) => i.id == idInmueble).firstOrNull;

    if (inmueble?.idCliente != null && inmueble!.idCliente! > 0) {
      AppLogger.info('Cliente encontrado en inmueble: ${inmueble.idCliente}');
      final clienteController = ref.read(clienteControllerProvider);
      return await clienteController.getClientePorId(inmueble.idCliente!);
    }

    // 4. No se encontró ningún cliente
    AppLogger.info('No se encontró cliente para el inmueble: $idInmueble');
    return null;
  } catch (e, stackTrace) {
    AppLogger.error('Error al cargar cliente del inmueble', e, stackTrace);
    return null;
  }
});

class RegistroMovimientosRentaScreen extends ConsumerStatefulWidget {
  final Inmueble inmueble;

  const RegistroMovimientosRentaScreen({super.key, required this.inmueble});

  @override
  ConsumerState<RegistroMovimientosRentaScreen> createState() =>
      _RegistroMovimientosRentaScreenState();
}

class _RegistroMovimientosRentaScreenState
    extends ConsumerState<RegistroMovimientosRentaScreen> {
  final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
  final formatDate = DateFormat('dd/MM/yyyy');

  // Variables de estado para el filtro de período
  TipoPeriodo _tipoPeriodoActual = TipoPeriodo.mes;
  DateTimeRange _periodoParlamento =
      FiltroPeriodoWidget.calcularRangoPorTipoEstatico(TipoPeriodo.mes);
  bool _mostrarPersonalizado = false;

  @override
  void initState() {
    super.initState();
  }

  // Método para manejar cambios desde el FiltroPeriodoWidget
  void _onPeriodoChanged(TipoPeriodo nuevoPeriodo, DateTimeRange nuevoRango) {
    setState(() {
      _tipoPeriodoActual = nuevoPeriodo;
      _periodoParlamento = nuevoRango;
      _mostrarPersonalizado = nuevoPeriodo == TipoPeriodo.personalizado;

      // Invalidar los providers para forzar una recarga
      ref.invalidate(movimientosPorInmuebleProvider(widget.inmueble.id!));
    });
    AppLogger.info('Período cambiado a: $nuevoPeriodo, Rango: $nuevoRango');
  }

  @override
  Widget build(BuildContext context) {
    final clienteAsync = ref.watch(
      clientePorInmuebleProvider(widget.inmueble.id!),
    );

    // Usar el nuevo provider para filtrar por período
    final movimientosFiltrados = ref.watch(
      movimientosFiltradosPorPeriodoProvider((
        idInmueble: widget.inmueble.id!,
        periodo: _periodoParlamento,
      )),
    );

    // Calcular balance del período seleccionado
    final balancePeriodo = ref.watch(
      balancePeriodoProvider(movimientosFiltrados),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Movimientos: ${widget.inmueble.nombre}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed:
                () => _generarReporteMovimientos(context, _periodoParlamento),
            tooltip: 'Generar reporte PDF',
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Ver Comprobantes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          GaleriaComprobantes(inmueble: widget.inmueble),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(movimientosPorInmuebleProvider(widget.inmueble.id!));
          ref.invalidate(clientePorInmuebleProvider(widget.inmueble.id!));
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoSection(clienteAsync, const AsyncValue.data(null)),
              const SizedBox(height: 16),

              // Selector de período con los botones de filtro
              _buildPeriodSelector(),

              // Mostrar el período seleccionado
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Período: ${_formatPeriodo(_tipoPeriodoActual, _periodoParlamento)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),

              // Mostrar el balance del período
              _buildBalanceCard(balancePeriodo),

              // Lista de movimientos filtrados
              _buildMovimientosList(movimientosFiltrados),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Registrar Nuevo Movimiento'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _mostrarFormularioMovimiento(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para mostrar el balance en una tarjeta
  Widget _buildBalanceCard(Map<String, double> balance) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance del Período',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBalanceItem(
                    'Ingresos',
                    balance['ingresos'] ?? 0,
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                  _buildBalanceItem(
                    'Egresos',
                    balance['egresos'] ?? 0,
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildBalanceItem(
                'Total',
                balance['balance'] ?? 0,
                Icons.account_balance,
                (balance['balance'] ?? 0) >= 0 ? Colors.green : Colors.red,
                isTotal: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceItem(
    String label,
    double value,
    IconData icon,
    Color color, {
    bool isTotal = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: isTotal ? 36 : 24),
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          formatCurrency.format(value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 24 : 18,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPeriodButton(TipoPeriodo.dia, 'Día'),
                _buildPeriodButton(TipoPeriodo.semana, 'Semana'),
                _buildPeriodButton(TipoPeriodo.mes, 'Mes'),
                _buildPeriodButton(TipoPeriodo.bimestre, 'Bimestre'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPeriodButton(TipoPeriodo.trimestre, 'Trimestre'),
                _buildPeriodButton(TipoPeriodo.semestre, 'Semestre'),
                _buildPeriodButton(TipoPeriodo.anio, 'Año'),
                _buildPeriodButton(TipoPeriodo.personalizado, 'Personalizado'),
              ],
            ),
            if (_mostrarPersonalizado)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: FiltroPeriodoWidget(
                  initialPeriodo: TipoPeriodo.personalizado,
                  onPeriodoChanged: _onPeriodoChanged,
                  initialStartDate: _periodoParlamento.start,
                  initialEndDate: _periodoParlamento.end,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(TipoPeriodo tipo, String label) {
    final isSelected = _tipoPeriodoActual == tipo;

    return ElevatedButton(
      onPressed: () {
        final nuevoPeriodo = FiltroPeriodoWidget.calcularRangoPorTipoEstatico(
          tipo,
        );
        _onPeriodoChanged(tipo, nuevoPeriodo);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
      child: Text(label),
    );
  }

  String _formatPeriodo(TipoPeriodo tipo, DateTimeRange periodo) {
    final formatter = DateFormat('dd/MM/yyyy');
    final inicio = formatter.format(periodo.start);
    final fin = formatter.format(periodo.end);

    switch (tipo) {
      case TipoPeriodo.dia:
        return 'Día $inicio';
      case TipoPeriodo.semana:
        return 'Semana del $inicio al $fin';
      case TipoPeriodo.mes:
        return 'Mes ${DateFormat('MMMM yyyy', 'es_ES').format(periodo.start)}';
      case TipoPeriodo.bimestre:
        return 'Bimestre ${periodo.start.month}-${periodo.start.month + 1} ${periodo.start.year}';
      case TipoPeriodo.trimestre:
        return 'Trimestre ${((periodo.start.month - 1) ~/ 3) + 1} del ${periodo.start.year}';
      case TipoPeriodo.semestre:
        return 'Semestre ${periodo.start.month <= 6 ? 1 : 2} del ${periodo.start.year}';
      case TipoPeriodo.anio:
        return 'Año ${periodo.start.year}';
      case TipoPeriodo.personalizado:
        return '$inicio - $fin';
    }
  }

  // Método para construir la lista de movimientos filtrados
  Widget _buildMovimientosList(movimientosFiltrados) {
    if (movimientosFiltrados is AsyncValue<List<MovimientoRenta>>) {
      // Si recibimos un AsyncValue, usamos el patrón when
      return movimientosFiltrados.when(
        data: (movimientos) {
          if (movimientos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No hay movimientos en el período seleccionado',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: movimientos.length,
            itemBuilder: (context, index) {
              final movimiento = movimientos[index];
              final isIngreso = movimiento.tipoMovimiento == 'ingreso';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    isIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isIngreso ? Colors.green : Colors.red,
                  ),
                  title: Text(movimiento.concepto),
                  subtitle: Text(formatDate.format(movimiento.fechaMovimiento)),
                  trailing: Text(
                    formatCurrency.format(movimiento.monto),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIngreso ? Colors.green : Colors.red,
                    ),
                  ),
                  onTap: () {
                    // Aquí podría implementarse la lógica para ver detalles del movimiento
                  },
                ),
              );
            },
          );
        },
        loading:
            () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
        error:
            (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error al cargar los movimientos: ${error.toString()}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
      );
    } else if (movimientosFiltrados is List<MovimientoRenta>) {
      // Si recibimos una lista directamente, la procesamos
      final movimientos = movimientosFiltrados;

      if (movimientos.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'No hay movimientos en el período seleccionado',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: movimientos.length,
        itemBuilder: (context, index) {
          final movimiento = movimientos[index];
          final isIngreso = movimiento.tipoMovimiento == 'ingreso';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Icon(
                isIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                color: isIngreso ? Colors.green : Colors.red,
              ),
              title: Text(movimiento.concepto),
              subtitle: Text(formatDate.format(movimiento.fechaMovimiento)),
              trailing: Text(
                formatCurrency.format(movimiento.monto),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIngreso ? Colors.green : Colors.red,
                ),
              ),
              onTap: () {
                // Aquí podría implementarse la lógica para ver detalles del movimiento
              },
            ),
          );
        },
      );
    } else {
      // Caso fallback para otros tipos
      return const Center(child: Text('Formato de datos no reconocido'));
    }
  }

  // Método para generar reporte de movimientos en PDF
  void _generarReporteMovimientos(BuildContext context, DateTimeRange periodo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReportesMovimientosScreen(
              idInmueble: widget.inmueble.id!,
              nombreInmueble: widget.inmueble.nombre,
              periodoInicial: periodo,
            ),
      ),
    );
  }

  // Método para mostrar el formulario de registro de movimiento
  void _mostrarFormularioMovimiento(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: FormularioMovimiento(
              inmueble: widget.inmueble,
              onSuccess: () {
                ref.invalidate(
                  movimientosPorInmuebleProvider(widget.inmueble.id!),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Movimiento registrado correctamente.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
    );
  }

  // Método para construir la sección de información
  Widget _buildInfoSection(
    AsyncValue<Cliente?> clienteAsync,
    AsyncValue<dynamic> contratoAsync,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.inmueble.nombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            clienteAsync.when(
              data:
                  (cliente) =>
                      cliente != null
                          ? _buildInfoRow(
                            Icons.person,
                            'Cliente Asociado',
                            '${cliente.nombre} ${cliente.apellidoPaterno}',
                          )
                          : _buildInfoRow(
                            Icons.person_off,
                            'Cliente Asociado',
                            'No asignado',
                            color: Colors.orange,
                          ),
              loading:
                  () => const Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Cargando cliente...'),
                      SizedBox(width: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
              error:
                  (e, _) => _buildInfoRow(
                    Icons.error,
                    'Cliente Asociado',
                    'Error al cargar',
                    color: Colors.red,
                  ),
            ),
            const SizedBox(height: 8),
            contratoAsync.when(
              data: (contrato) {
                if (contrato != null) {
                  return _buildInfoRow(
                    Icons.description,
                    'Detalles contrato',
                    'Disponible',
                  );
                }
                return _buildInfoRow(
                  Icons.description_outlined,
                  'Operación',
                  'Sin contrato/venta activa',
                  color: Colors.grey,
                );
              },
              loading:
                  () => const Row(
                    children: [
                      Icon(Icons.description, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Cargando operación...'),
                      SizedBox(width: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
              error:
                  (e, _) => _buildInfoRow(
                    Icons.error,
                    'Operación',
                    'Error al cargar',
                    color: Colors.red,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[700]),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color ?? Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

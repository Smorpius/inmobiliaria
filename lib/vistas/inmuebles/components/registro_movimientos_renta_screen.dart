import 'package:intl/intl.dart';
import 'resumen_financiero.dart';
import 'galeria_comprobantes.dart';
import 'formulario_movimiento.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/venta_model.dart';
import '../../../models/cliente_model.dart';
import '../../../models/inmueble_model.dart';
import '../../../models/contrato_renta_model.dart';
import '../../../providers/cliente_providers.dart';
import '../../../widgets/filtro_periodo_widget.dart';
import '../../../controllers/inmueble_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/inmueble_renta_provider.dart';
import '../../../providers/contrato_renta_provider.dart';
import 'package:inmobiliaria/providers/venta_providers.dart';

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
  DateTime _fechaInicio = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    // El widget FiltroPeriodoWidget notificará el período inicial por callback
  }

  // Método para manejar cambios desde el FiltroPeriodoWidget
  void _onPeriodoChanged(TipoPeriodo nuevoPeriodo, DateTimeRange nuevoRango) {
    // Validación básica del año
    if (nuevoRango.start.year < 2000 || nuevoRango.start.year > 2100) {
      AppLogger.warning(
        'Rango de fechas inválido recibido: $nuevoRango. No se actualizará el estado.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar el rango de fechas seleccionado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _tipoPeriodoActual = nuevoPeriodo;
      _fechaInicio =
          nuevoRango.start; // Actualizar la fecha de inicio localmente

      // Invalidar el provider del resumen con los parámetros correctos
      final params = ResumenRentaParams(
        idInmueble: widget.inmueble.id!,
        anio: nuevoRango.start.year, // Usar el año del nuevo rango
        mes: nuevoRango.start.month, // Usar el mes del nuevo rango
      );
      ref.invalidate(resumenRentaPorMesProvider(params));

      // Puedes mantener o quitar la invalidación del otro provider según sea necesario
      // ref.invalidate(movimientosPorInmuebleProvider(widget.inmueble.id!));
    });
    AppLogger.info('Período cambiado a: $nuevoPeriodo, Rango: $nuevoRango');
  }

  @override
  Widget build(BuildContext context) {
    final clienteAsync = ref.watch(
      clientePorInmuebleProvider(widget.inmueble.id!),
    );
    final contratoAsync = const AsyncValue.data(null); // Ajuste temporal

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Movimientos: ${widget.inmueble.nombre}'),
        actions: [
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
              _buildInfoSection(clienteAsync, contratoAsync),
              const SizedBox(height: 16),
              FiltroPeriodoWidget(
                initialPeriodo: _tipoPeriodoActual,
                onPeriodoChanged: _onPeriodoChanged,
              ),
              const SizedBox(height: 16),
              ResumenFinanciero(
                inmueble: widget.inmueble,
                anio: _fechaInicio.year, // Se pasa el año actualizado
                mes: _fechaInicio.month, // Se pasa el mes actualizado
              ),
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

  Widget _buildInfoSection(
    AsyncValue<Cliente?> clienteAsync,
    AsyncValue<dynamic> contratoAsync, // Puede ser ContratoRenta o Venta
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
                  if (contrato is ContratoRenta) {
                    return _buildInfoRow(
                      Icons.description,
                      'Contrato Renta',
                      'Activo hasta ${formatDate.format(contrato.fechaFin)}',
                    );
                  } else if (contrato is Venta) {
                    return _buildInfoRow(
                      Icons.sell,
                      'Venta',
                      'Realizada el ${formatDate.format(contrato.fechaVenta)}',
                    );
                  }
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
}

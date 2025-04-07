import 'package:intl/intl.dart';
import '../../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../../models/inmueble_model.dart';
import '../../models/contrato_renta_model.dart';
import '../ventas/movimientos_renta_screen.dart';
import '../inmuebles/inmueble_detalle_screen.dart';
import '../../controllers/inmueble_controller.dart';
import '../../providers/inmueble_renta_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/contrato_renta_controller.dart';
import '../inmuebles/components/contrato_generator_screen.dart';
import '../inmuebles/components/registro_movimientos_renta_screen.dart';

// Constantes para estados de contrato
class EstadosContrato {
  static const int estadoActivo = 1;
  static const int estadoFinalizado = 2;
}

// Provider para el controlador de contratos
final contratoControllerProvider = Provider((ref) => ContratoRentaController());

// Provider para obtener detalles de un contrato específico
final contratoDetalleProvider = FutureProvider.family<ContratoRenta?, int>((
  ref,
  idContrato,
) async {
  final controller = ref.read(contratoControllerProvider);
  try {
    // Usar el método específico para obtener el contrato por ID
    return await controller.obtenerContratoPorId(idContrato);
  } catch (e) {
    AppLogger.error('Error al cargar contrato', e, StackTrace.current);
    return null;
  }
});

// Provider para obtener detalles de un inmueble específico
final inmuebleDetalleProvider = FutureProvider.family<Inmueble?, int>((
  ref,
  idInmueble,
) async {
  try {
    // Crear una instancia del controlador
    final controller = InmuebleController();

    // Obtener todos los inmuebles y filtrar por ID
    // Ya que no hay un método específico para obtener un inmueble por ID
    final inmuebles = await controller.getInmuebles();

    // Filtrar el inmueble con el ID correcto
    final inmueble = inmuebles.where((i) => i.id == idInmueble).firstOrNull;

    // Liberar recursos
    controller.dispose();

    return inmueble;
  } catch (e) {
    AppLogger.error('Error al cargar inmueble', e, StackTrace.current);
    return null;
  }
});

// Provider para el estado de procesamiento de finalización de contratos
final finalizandoContratoProvider = StateProvider.family<bool, int>(
  (ref, idContrato) => false,
);

class DetalleContratoScreen extends ConsumerStatefulWidget {
  final int idContrato;

  const DetalleContratoScreen({super.key, required this.idContrato});

  @override
  ConsumerState<DetalleContratoScreen> createState() =>
      _DetalleContratoScreenState();
}

class _DetalleContratoScreenState extends ConsumerState<DetalleContratoScreen> {
  final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
  final formatDate = DateFormat('dd/MM/yyyy');
  // La variable _isProcessing se reemplaza por el provider de Riverpod

  // Método para determinar si un contrato está vigente
  bool _estaContratoVigente(ContratoRenta contrato) {
    // Mejorar el cálculo de días restantes para manejar fechas sin hora
    final hoy = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final fechaFin = DateTime(
      contrato.fechaFin.year,
      contrato.fechaFin.month,
      contrato.fechaFin.day,
    );
    final diasRestantes = fechaFin.difference(hoy).inDays;

    return diasRestantes >= 0 &&
        contrato.idEstado == EstadosContrato.estadoActivo;
  }

  // Método para calcular los días restantes del contrato
  int _calcularDiasRestantes(DateTime fechaFin) {
    final hoy = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final fechaFinSinHora = DateTime(
      fechaFin.year,
      fechaFin.month,
      fechaFin.day,
    );
    return fechaFinSinHora.difference(hoy).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final contratoAsyncValue = ref.watch(
      contratoDetalleProvider(widget.idContrato),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Contrato')),
      body: contratoAsyncValue.when(
        data: (contrato) {
          if (contrato == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No se encontró información para este contrato'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }
          return _buildDetalleContrato(contrato);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error al cargar contrato: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Refrescar el provider y usar el resultado para evitar warning
                        final _ = ref.refresh(
                          contratoDetalleProvider(widget.idContrato),
                        );
                      },
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

  Widget _buildDetalleContrato(ContratoRenta contrato) {
    final diasRestantes = _calcularDiasRestantes(contrato.fechaFin);
    final bool vigente = _estaContratoVigente(contrato);
    final isProcessing = ref.watch(finalizandoContratoProvider(contrato.id!));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de información básica
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.home_work, size: 48, color: Colors.indigo),
                  const SizedBox(height: 8),
                  Text(
                    'Contrato de Renta #${contrato.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: vigente ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      vigente ? 'ACTIVO' : 'FINALIZADO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Monto mensual: ${formatCurrency.format(contrato.montoMensual)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vigente
                        ? '$diasRestantes días restantes'
                        : 'Contrato finalizado',
                    style: TextStyle(
                      fontSize: 16,
                      color: vigente ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Detalles del inmueble
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalles del Inmueble',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow('ID Inmueble', contrato.idInmueble.toString()),

                  // Sección para mostrar el tipo de inmueble si está disponible
                  _buildInfoRow('Tipo de Operación', 'Renta'),

                  // Obtener la duración total del contrato en meses
                  _buildInfoRow(
                    'Duración Total',
                    '${contrato.duracionMeses} meses',
                  ),

                  // Mostrar el monto total del contrato
                  _buildInfoRow(
                    'Monto Total Contrato',
                    formatCurrency.format(contrato.montoTotalContrato),
                  ),

                  // Mostrar porcentaje de avance si el contrato está vigente
                  if (vigente)
                    _buildInfoRow(
                      'Avance del Contrato',
                      '${contrato.porcentajeAvance.toStringAsFixed(1)}%',
                    ),

                  // Agregar botón para ver detalles completos del inmueble
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed:
                          () =>
                              _verDetalleInmueble(context, contrato.idInmueble),
                      icon: const Icon(Icons.home_work),
                      label: const Text('VER INMUEBLE COMPLETO'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Información del cliente
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información del Cliente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Cliente',
                    contrato.clienteNombreCompleto ?? 'No disponible',
                  ),
                  _buildInfoRow('ID Cliente', contrato.idCliente.toString()),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Detalles del contrato
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalles del Contrato',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Fecha de Inicio',
                    formatDate.format(contrato.fechaInicio),
                  ),
                  _buildInfoRow(
                    'Fecha de Fin',
                    formatDate.format(contrato.fechaFin),
                  ),
                  _buildInfoRow(
                    'Duración',
                    '${contrato.fechaFin.difference(contrato.fechaInicio).inDays} días',
                  ),
                  if (contrato.condicionesAdicionales != null &&
                      contrato.condicionesAdicionales!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const Text(
                          'Condiciones Adicionales:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(contrato.condicionesAdicionales!),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Historial de Transacciones
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Historial de Transacciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildTransactionHistory(contrato.idInmueble),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botones de acción
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (vigente)
                ElevatedButton.icon(
                  onPressed:
                      isProcessing
                          ? null
                          : () => _confirmarFinalizarContrato(contrato.id!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.cancel),
                  label:
                      isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('FINALIZAR CONTRATO'),
                ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: () async {
                  // Primero obtenemos el inmueble para tener su nombre real
                  try {
                    // Mostrar indicador de carga
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cargando información del inmueble...'),
                        duration: Duration(milliseconds: 500),
                      ),
                    );

                    // Obtener detalles del inmueble usando el provider
                    final inmuebleInfo = await ref.read(
                      inmuebleDetalleProvider(contrato.idInmueble).future,
                    );

                    // Si no estamos montados después de la operación asíncrona, salir
                    if (!mounted) return;

                    // Usar el nombre real del inmueble si está disponible
                    final nombreInmuebleReal =
                        inmuebleInfo?.nombre ?? 'Casa/Departamento';

                    // Navegar a la pantalla de movimientos
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MovimientosRentaScreen(
                              idInmueble: contrato.idInmueble,
                              nombreInmueble: nombreInmuebleReal,
                              idCliente: contrato.idCliente,
                              nombreCliente:
                                  contrato.clienteNombreCompleto ??
                                  'Cliente ID: ${contrato.idCliente}',
                            ),
                      ),
                    );
                  } catch (e) {
                    // En caso de error, usar el formato anterior como fallback
                    if (mounted) {
                      AppLogger.error(
                        'Error al obtener detalles del inmueble',
                        e,
                        StackTrace.current,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => MovimientosRentaScreen(
                                idInmueble: contrato.idInmueble,
                                nombreInmueble: 'Inmueble',
                                idCliente: contrato.idCliente,
                                nombreCliente:
                                    contrato.clienteNombreCompleto ??
                                    'Cliente ID: ${contrato.idCliente}',
                              ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('VER MOVIMIENTOS'),
              ),

              const SizedBox(height: 12),

              // Botón para registro de renta (más destacado)
              ElevatedButton.icon(
                icon: const Icon(Icons.add_card),
                label: const Text('REGISTRO DE RENTA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    // Obtener el inmueble para pasarlo a la pantalla de registro
                    final inmuebleInfo = await ref.read(
                      inmuebleDetalleProvider(contrato.idInmueble).future,
                    );

                    if (!mounted) return;

                    if (inmuebleInfo != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => RegistroMovimientosRentaScreen(
                                inmueble: inmuebleInfo,
                              ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se pudo cargar el inmueble asociado al contrato',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      AppLogger.error(
                        'Error al cargar inmueble',
                        e,
                        StackTrace.current,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: ${e.toString().split('\n').first}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),

              const SizedBox(height: 12),

              // Botón para generar contrato
              ElevatedButton.icon(
                icon: const Icon(Icons.description),
                label: const Text('GENERAR CONTRATO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    // Obtener el inmueble para pasarlo a la pantalla de generación de contrato
                    final inmuebleInfo = await ref.read(
                      inmuebleDetalleProvider(contrato.idInmueble).future,
                    );

                    if (!mounted) return;

                    if (inmuebleInfo != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ContratoGeneratorScreen(
                                inmueble: inmuebleInfo,
                                tipoContrato: 'renta',
                              ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se pudo cargar el inmueble para generar el contrato',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      AppLogger.error(
                        'Error al preparar generación de contrato',
                        e,
                        StackTrace.current,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: ${e.toString().split('\n').first}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _confirmarFinalizarContrato(int idContrato) async {
    ref.read(finalizandoContratoProvider(idContrato).notifier).state = true;

    try {
      final confirmacion = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Finalizar Contrato'),
            content: const Text(
              '¿Está seguro que desea finalizar este contrato de renta? '
              'Esta acción liberará el inmueble para nuevas operaciones.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCELAR'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('FINALIZAR'),
              ),
            ],
          );
        },
      );

      if (confirmacion == true) {
        // Usar el controlador del provider en lugar de crear uno nuevo
        final controller = ref.read(contratoControllerProvider);
        final result = await controller.cambiarEstadoContrato(
          idContrato,
          EstadosContrato.estadoFinalizado,
        );

        if (result && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contrato finalizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          // Actualizar la UI asignando el resultado a una variable
          final _ = ref.refresh(contratoDetalleProvider(idContrato));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al finalizar contrato: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      AppLogger.error('Error al finalizar contrato', e, StackTrace.current);
    } finally {
      if (mounted) {
        ref.read(finalizandoContratoProvider(idContrato).notifier).state =
            false;
      }
    }
  }

  // Método para ver el detalle del inmueble asociado al contrato
  void _verDetalleInmueble(BuildContext context, int idInmueble) async {
    // Capturar el contexto antes de la operación asíncrona
    final localContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(localContext);

    try {
      // Mostrar indicador de carga
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Cargando detalles del inmueble...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Obtener el inmueble utilizando el provider
      final inmuebleAsyncValue = await ref.read(
        inmuebleDetalleProvider(idInmueble).future,
      );

      // Verificar si el widget está montado antes de continuar
      if (!mounted) return;

      if (inmuebleAsyncValue != null) {
        // Verificar si el contexto local sigue siendo válido antes de navegar
        if (!localContext.mounted) return;
        // Navegar a la pantalla de detalles del inmueble con la información completa
        Navigator.push(
          localContext,
          MaterialPageRoute(
            builder:
                (builderContext) => InmuebleDetailScreen(
                  inmuebleInicial: inmuebleAsyncValue,
                  onEdit:
                      () {}, // Función vacía ya que no permitiremos editar desde aquí
                  onDelete:
                      () {}, // Función vacía ya que no permitiremos eliminar desde aquí
                ),
          ),
        );
      } else {
        // Mostrar mensaje de error si no se pudo obtener el inmueble
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo cargar la información del inmueble'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Manejar cualquier error
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error al cargar detalles del inmueble: $e'),
          backgroundColor: Colors.red,
        ),
      );
      AppLogger.error(
        'Error al cargar detalles del inmueble',
        e,
        StackTrace.current,
      );
    }
  }

  // Método para mostrar el historial de transacciones
  Widget _buildTransactionHistory(int idInmueble) {
    // Usar el proveedor que devuelve las transacciones/movimientos para este inmueble
    final movimientosProvider = ref.watch(
      movimientosPorInmuebleProvider(idInmueble),
    );

    return movimientosProvider.when(
      data: (movimientos) {
        if (movimientos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'No hay transacciones registradas',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movimientos.length > 5 ? 5 : movimientos.length,
              itemBuilder: (context, index) {
                final movimiento = movimientos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          movimiento.tipoMovimiento == 'ingreso'
                              ? Colors.green.withAlpha(26)
                              : Colors.red.withAlpha(26),
                      child: Icon(
                        // Usar icono específico para pagos de renta
                        movimiento.concepto.startsWith('Pago de renta:')
                            ? Icons.home
                            : (movimiento.tipoMovimiento == 'ingreso'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward),
                        color:
                            movimiento.tipoMovimiento == 'ingreso'
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            movimiento.concepto,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (movimiento.concepto.startsWith('Pago de renta:'))
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Renta',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      formatDate.format(movimiento.fechaMovimiento),
                    ),
                    trailing: Text(
                      formatCurrency.format(movimiento.monto),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            movimiento.tipoMovimiento == 'ingreso'
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                    onTap: () => _mostrarDetalleMovimiento(context, movimiento),
                  ),
                );
              },
            ),
            if (movimientos.length > 5)
              TextButton.icon(
                onPressed: () async {
                  try {
                    // Obtener el inmueble para pasarlo a la pantalla de registro
                    final inmuebleInfo = await ref.read(
                      inmuebleDetalleProvider(idInmueble).future,
                    );

                    if (!mounted) return;

                    if (inmuebleInfo != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => RegistroMovimientosRentaScreen(
                                inmueble: inmuebleInfo,
                              ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se pudo cargar el inmueble asociado al contrato',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      AppLogger.error(
                        'Error al cargar inmueble',
                        e,
                        StackTrace.current,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: ${e.toString().split('\n').first}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.history),
                label: const Text('Ver historial completo'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
          ],
        );
      },
      loading:
          () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
      error:
          (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  Text('Error al cargar transacciones: ${error.toString()}'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.invalidate(
                        movimientosPorInmuebleProvider(idInmueble),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Método para mostrar detalles de un movimiento
  void _mostrarDetalleMovimiento(BuildContext context, dynamic movimiento) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  movimiento.tipoMovimiento == 'ingreso'
                      ? Icons.arrow_circle_down
                      : Icons.arrow_circle_up,
                  color:
                      movimiento.tipoMovimiento == 'ingreso'
                          ? Colors.green
                          : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    movimiento.concepto,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetalleMovimientoRow(
                  'Monto',
                  formatCurrency.format(movimiento.monto),
                ),
                _buildDetalleMovimientoRow(
                  'Fecha',
                  formatDate.format(movimiento.fechaMovimiento),
                ),
                _buildDetalleMovimientoRow(
                  'Tipo',
                  movimiento.tipoMovimiento == 'ingreso' ? 'Ingreso' : 'Egreso',
                ),
                if (movimiento.mesCorrespondiente != null &&
                    movimiento.mesCorrespondiente.isNotEmpty)
                  _buildDetalleMovimientoRow(
                    'Mes correspondiente',
                    _formatMesCorrespondiente(movimiento.mesCorrespondiente),
                  ),
                if (movimiento.comentarios != null &&
                    movimiento.comentarios.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Comentarios:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(movimiento.comentarios),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  // Método auxiliar para construir filas en el detalle de movimiento
  Widget _buildDetalleMovimientoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  // Método para formatear el mes correspondiente de YYYY-MM a un formato legible
  String _formatMesCorrespondiente(String mesCorrespondiente) {
    try {
      final parts = mesCorrespondiente.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateFormat('MMMM yyyy', 'es_ES').format(DateTime(year, month));
      }
      return mesCorrespondiente;
    } catch (e) {
      return mesCorrespondiente;
    }
  }
}

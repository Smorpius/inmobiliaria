import 'package:intl/intl.dart';
import '../../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../../models/contrato_renta_model.dart';
import '../ventas/movimientos_renta_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/contrato_renta_controller.dart';

// Provider para obtener detalles de un contrato específico
final contratoDetalleProvider = FutureProvider.family<ContratoRenta?, int>((
  ref,
  idContrato,
) async {
  final controller = ContratoRentaController();
  try {
    // Obtener contrato específico desde la base de datos
    final contratos = await controller.obtenerContratos();

    // Método seguro que maneja correctamente el caso de no encontrar el contrato
    final contratosFiltrados =
        contratos.where((c) => c.id == idContrato).toList();
    if (contratosFiltrados.isNotEmpty) {
      return contratosFiltrados.first;
    } else {
      return null;
    }
  } catch (e) {
    AppLogger.error('Error al cargar contrato', e, StackTrace.current);
    return null;
  } finally {
    controller.dispose();
  }
});

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
  bool _isProcessing = false;

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
            return const Center(
              child: Text('No se encontró información para este contrato'),
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
                      onPressed:
                          () => ref.refresh(
                            contratoDetalleProvider(widget.idContrato),
                          ),
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
    final diasRestantes = contrato.fechaFin.difference(DateTime.now()).inDays;
    final bool vigente = diasRestantes > 0 && contrato.idEstado == 1;

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

          const SizedBox(height: 24),

          // Botones de acción
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (vigente)
                ElevatedButton.icon(
                  onPressed:
                      _isProcessing
                          ? null
                          : () => _confirmarFinalizarContrato(contrato.id!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.cancel),
                  label:
                      _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('FINALIZAR CONTRATO'),
                ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MovimientosRentaScreen(
                              idInmueble: contrato.idInmueble,
                              nombreInmueble:
                                  'Inmueble ID: ${contrato.idInmueble}',
                              idCliente: contrato.idCliente,
                              nombreCliente:
                                  contrato.clienteNombreCompleto ??
                                  'Cliente ID: ${contrato.idCliente}',
                            ),
                      ),
                    ),
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('VER MOVIMIENTOS'),
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
    setState(() {
      _isProcessing = true;
    });

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
        final controller = ContratoRentaController();
        try {
          final result = await controller.cambiarEstadoContrato(
            idContrato,
            2,
          ); // 2 = finalizado

          if (result && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contrato finalizado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
            // Actualizar la UI
            final _ = ref.refresh(contratoDetalleProvider(idContrato));
          }
        } finally {
          controller.dispose();
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
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

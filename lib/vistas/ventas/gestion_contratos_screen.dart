import 'package:intl/intl.dart';
import '../../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../../models/contrato_renta_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/contrato_renta_controller.dart';
import 'package:inmobiliaria/vistas/ventas/detalle_contrato_screen.dart';
import 'package:inmobiliaria/vistas/ventas/registrar_contrato_screen.dart';

final contratosProvider = FutureProvider<List<ContratoRenta>>((ref) async {
  final controller = ContratoRentaController();
  try {
    return await controller.obtenerContratos();
  } catch (e) {
    AppLogger.error('Error al cargar contratos', e, StackTrace.current);
    throw Exception('Error al cargar contratos: $e');
  } finally {
    controller.dispose();
  }
});

class GestionContratosScreen extends ConsumerStatefulWidget {
  const GestionContratosScreen({super.key});

  @override
  ConsumerState<GestionContratosScreen> createState() =>
      _GestionContratosScreenState();
}

class _GestionContratosScreenState extends ConsumerState<GestionContratosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
  final formatDate = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Contratos de Renta'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Contratos Activos'), Tab(text: 'Histórico')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final _ = ref.refresh(contratosProvider);
              // Alternatively: await ref.refresh(contratosProvider.future);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContratosList(true), // Activos
          _buildContratosList(false), // Históricos
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegistrarContratoScreen(),
            ),
          );
          if (result == true && mounted) {
            final _ = ref.refresh(contratosProvider);
          }
        },
        label: const Text('Nuevo Contrato'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContratosList(bool activos) {
    final contratosAsync = ref.watch(contratosProvider);

    return contratosAsync.when(
      data: (contratos) {
        final filteredContratos =
            contratos
                .where((contrato) => contrato.idEstado == (activos ? 1 : 2))
                .toList();

        if (filteredContratos.isEmpty) {
          return Center(
            child: Text(
              activos
                  ? 'No hay contratos activos'
                  : 'No hay contratos finalizados',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredContratos.length,
          itemBuilder: (context, index) {
            final contrato = filteredContratos[index];
            return _buildContratoCard(contrato);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: Text(
              'Error al cargar contratos: ${error.toString()}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
    );
  }

  Widget _buildContratoCard(ContratoRenta contrato) {
    final diasRestantes = contrato.fechaFin.difference(DateTime.now()).inDays;
    final bool vigente = diasRestantes > 0 && contrato.idEstado == 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DetalleContratoScreen(idContrato: contrato.id!),
            ),
          );
          if (result == true) {
            final _ = ref.refresh(contratosProvider);
            // Alternatively: await ref.refresh(contratosProvider.future);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Inmueble: ${contrato.idInmueble}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: vigente ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vigente ? 'ACTIVO' : 'FINALIZADO',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Cliente: ${contrato.nombreCliente ?? ''} ${contrato.apellidoCliente ?? ''}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Renta mensual: ${formatCurrency.format(contrato.montoMensual)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    vigente ? '$diasRestantes días restantes' : 'Finalizado',
                    style: TextStyle(
                      color: vigente ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Periodo: ${formatDate.format(contrato.fechaInicio)} - ${formatDate.format(contrato.fechaFin)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

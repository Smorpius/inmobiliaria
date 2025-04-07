import 'package:intl/intl.dart';
import 'resumen_financiero.dart';
import 'galeria_comprobantes.dart';
import 'formulario_movimiento.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/cliente_model.dart';
import '../../../models/inmueble_model.dart';
import '../../../providers/cliente_providers.dart';
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
    extends ConsumerState<RegistroMovimientosRentaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _anioSeleccionado = DateTime.now().year;
  int _mesSeleccionado = DateTime.now().month;
  final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // En lugar de llamar directamente, usamos Future.microtask para programar
    // la carga después de que se complete la construcción del widget
    Future.microtask(() => _cargarDatos());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      if (widget.inmueble.id != null) {
        // Retrasamos la actualización del estado para evitar conflictos
        // con la construcción del árbol de widgets
        Future.microtask(() {
          ref
              .read(movimientosRentaStateProvider(widget.inmueble.id!).notifier)
              .cargarMovimientos(widget.inmueble.id!);
        });
      }
    } catch (e, stack) {
      AppLogger.error('Error al cargar movimientos', e, stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;
    // Obtener el cliente asociado al inmueble usando el nuevo provider
    final clienteAsync = ref.watch(
      clientePorInmuebleProvider(widget.inmueble.id!),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          esPantallaPequena
              ? widget.inmueble.nombre.length > 15
                  ? '${widget.inmueble.nombre.substring(0, 15)}...'
                  : widget.inmueble.nombre
              : 'Registro de Renta: ${widget.inmueble.nombre}',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_box), text: 'Registrar'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Resumen'),
            Tab(icon: Icon(Icons.image), text: 'Comprobantes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Pestaña 1: Formulario de registro con información del cliente
          SingleChildScrollView(
            child: Column(
              children: [
                // Widget de información del cliente sólo en la primera pestaña
                _construirInfoGeneral(clienteAsync),
                // Formulario de registro
                FormularioMovimiento(
                  inmueble: widget.inmueble,
                  onSuccess: () {
                    // Después de un registro exitoso, cambiamos a la pestaña de resumen
                    _tabController.animateTo(1);
                    // Refrescamos los datos
                    _cargarDatos();
                  },
                ),
              ],
            ),
          ),

          // Pestaña 2: Resumen financiero (sin información del cliente)
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _construirSelectorMes(),
                  const SizedBox(height: 16),
                  ResumenFinanciero(
                    inmueble: widget.inmueble,
                    anio: _anioSeleccionado,
                    mes: _mesSeleccionado,
                  ),
                ],
              ),
            ),
          ),

          // Pestaña 3: Galería de comprobantes (sin información del cliente)
          GaleriaComprobantes(inmueble: widget.inmueble),
        ],
      ),
    );
  }

  Widget _construirSelectorMes() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona periodo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                      border: OutlineInputBorder(),
                    ),
                    value: _mesSeleccionado,
                    items: List.generate(12, (index) {
                      final mes = index + 1;
                      return DropdownMenuItem(
                        value: mes,
                        child: Text(_obtenerNombreMes(mes)),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _mesSeleccionado = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(),
                    ),
                    value: _anioSeleccionado,
                    items: List.generate(5, (index) {
                      final anio = DateTime.now().year - 2 + index;
                      return DropdownMenuItem(
                        value: anio,
                        child: Text(anio.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _anioSeleccionado = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _obtenerNombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return meses[mes - 1];
  }

  String _obtenerNombreEstado(int estado) {
    const estados = {
      2: 'No Disponible',
      3: 'Disponible',
      4: 'Vendido',
      5: 'Rentado',
      6: 'En Negociación',
    };
    return estados[estado] ?? 'Desconocido';
  }

  Widget _construirInfoGeneral(AsyncValue<Cliente?> clienteAsync) {
    // Verificar el estado del inmueble antes de mostrar cualquier información
    final inmuebleEstado = widget.inmueble.idEstado;
    final esRentado = inmuebleEstado == 5; // 5 = estado rentado

    if (!esRentado) {
      // Si el inmueble no está rentado, mostrar una advertencia
      return Card(
        elevation: 2,
        margin: const EdgeInsets.all(16.0),
        color: Colors.orange.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Advertencia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Este inmueble no está actualmente en estado "Rentado".',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Estado actual: ${_obtenerNombreEstado(inmuebleEstado ?? 0)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.done),
                label: const Text("Verificar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    }

    return clienteAsync.when(
      data: (cliente) {
        if (cliente == null) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.all(16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Información del Cliente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Reemplazar el texto simple con una presentación más informativa
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Este inmueble no tiene un cliente asignado o un contrato activo.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Asignar Cliente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            // Navegar a pantalla de asignación de cliente
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Funcionalidad de asignar cliente próximamente',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.description),
                          label: const Text('Crear Contrato'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            // Navegar a pantalla de creación de contrato
                            Navigator.pushNamed(context, '/registrar_contrato');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Formatear nombre completo con apellidos
        final nombreCompleto =
            '${cliente.nombre} ${cliente.apellidoPaterno} ${cliente.apellidoMaterno ?? ''}';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade100, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Información del Cliente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _construirFilaInfo(
                        'Nombre',
                        nombreCompleto.trim(),
                        Icons.person_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _construirFilaInfo(
                        'Teléfono',
                        cliente.telefono ?? 'No disponible',
                        Icons.phone,
                      ),
                    ),
                    Expanded(
                      child: _construirFilaInfo(
                        'Correo',
                        cliente.correo ?? 'No disponible',
                        Icons.email,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _construirFilaInfo(
                        'RFC',
                        cliente.rfc ?? 'No disponible',
                        Icons.badge,
                      ),
                    ),
                    Expanded(
                      child: _construirFilaInfo(
                        'CURP',
                        cliente.curp ?? 'No disponible',
                        Icons.account_balance_wallet,
                        isBold: true,
                      ),
                    ),
                  ],
                ),
                if (cliente.direccionCompleta != 'Dirección no disponible')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _construirFilaInfo(
                      'Dirección',
                      cliente.direccionCompleta,
                      Icons.home,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Cargando información del cliente...'),
                ],
              ),
            ),
          ),
      error:
          (error, stack) => Card(
            elevation: 2,
            margin: const EdgeInsets.all(16.0),
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Error al cargar información del cliente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('No se pudo cargar la información del cliente'),
                ],
              ),
            ),
          ),
    );
  }

  // Widget auxiliar para mostrar filas de información
  Widget _construirFilaInfo(
    String label,
    String value,
    IconData icon, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    fontSize: isBold ? 15 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

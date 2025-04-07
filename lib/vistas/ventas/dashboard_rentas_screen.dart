import 'package:intl/intl.dart';
import '../../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../../models/contrato_renta_model.dart';
import '../ventas/gestion_contratos_screen.dart';
import '../ventas/movimientos_renta_screen.dart';
import '../../providers/contrato_renta_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vistas/ventas/registrar_contrato_screen.dart';
import '../../vistas/ventas/registrar_pago_renta_screen.dart';
import 'package:inmobiliaria/providers/inmueble_renta_provider.dart';
import 'package:inmobiliaria/vistas/ventas/detalle_contrato_screen.dart';

/// Dashboard principal del módulo de Rentas
class DashboardRentasScreen extends ConsumerStatefulWidget {
  const DashboardRentasScreen({super.key});

  @override
  ConsumerState<DashboardRentasScreen> createState() =>
      _DashboardRentasScreenState();
}

class _DashboardRentasScreenState extends ConsumerState<DashboardRentasScreen> {
  final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
  final formatDate = DateFormat('dd/MM/yyyy');

  int _contratosProximosVencer = 0;
  int _contratosTotales = 0;
  double _ingresosMes = 0.0;
  bool _isLoading = true;
  String? _errorMsg;

  // Variables para memorización de contratos
  List<ContratoRenta>? _cachedContratosPorVencer;
  List<ContratoRenta>? _lastContratos;

  @override
  void initState() {
    super.initState();
    _cargarResumenDashboard();
  }

  /// Carga los datos del dashboard desde los providers
  Future<void> _cargarResumenDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });

      final contratosAsyncValue = ref.watch(contratosRentaProvider);

      contratosAsyncValue.when(
        data: (contratos) {
          _procesarDatosContratos(contratos);
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        error: (error, stack) {
          AppLogger.error('Error al cargar contratos', error, stack);
          if (mounted) {
            setState(() {
              _errorMsg = 'No se pudieron cargar los contratos: $error';
              _isLoading = false;
            });
          }
        },
        loading: () {}, // No cambiar el estado de carga
      );

      return Future.delayed(Duration.zero); // Garantiza retorno de Future
    } catch (e, stack) {
      AppLogger.error('Error al cargar dashboard de rentas', e, stack);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg =
              'No se pudieron cargar los datos. Por favor, intenta de nuevo.';
        });
      }
      return Future.delayed(Duration.zero);
    }
  }

  /// Procesa los datos de contratos obtenidos para actualizar las métricas del dashboard
  void _procesarDatosContratos(List<ContratoRenta> contratos) {
    final contratosActivos = contratos.where((c) => c.idEstado == 1).toList();
    _contratosTotales = contratosActivos.length;

    final ahora = DateTime.now();
    final limite = ahora.add(const Duration(days: 30));

    _contratosProximosVencer =
        contratosActivos
            .where(
              (c) => c.fechaFin.isAfter(ahora) && c.fechaFin.isBefore(limite),
            )
            .length;

    _calcularIngresosMes(contratosActivos);
  }

  /// Calcula los ingresos del mes actual basados en contratos activos
  void _calcularIngresosMes(List<ContratoRenta> contratos) {
    final ahora = DateTime.now();
    final mesActual = DateTime(ahora.year, ahora.month);
    _ingresosMes = contratos
        .where(
          (c) => c.fechaInicio.isBefore(ahora) && c.fechaFin.isAfter(mesActual),
        )
        .fold(0.0, (sum, contrato) => sum + contrato.montoMensual);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Rentas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarResumenDashboard,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMsg != null
              ? _buildErrorView()
              : _buildDashboardContent(),
    );
  }

  /// Vista para mostrar errores con opción de reintentar
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMsg!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarResumenDashboard,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Contenido principal del dashboard
  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _cargarResumenDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumenTarjetas(),
            const SizedBox(height: 24),
            _buildAccionesRapidas(),
            const SizedBox(height: 24),
            _buildModulosPrincipales(),
            if (_contratosProximosVencer > 0) ...[
              const SizedBox(height: 24),
              _buildContratosProximosVencer(),
            ],
          ],
        ),
      ),
    );
  }

  /// Tarjetas de resumen con información clave
  Widget _buildResumenTarjetas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen del día',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildTarjeta(
              titulo: 'Contratos Activos',
              valor: '$_contratosTotales',
              icono: Icons.description,
              color: Colors.blue.shade800,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GestionContratosScreen(),
                    ),
                  ),
            ),
            const SizedBox(width: 16),
            _buildTarjeta(
              titulo: 'A vencer (30 días)',
              valor: _contratosProximosVencer.toString(),
              icono: Icons.timer,
              color: Colors.orange.shade800,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GestionContratosScreen(),
                    ),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildTarjeta(
              titulo: 'Ingresos del Mes',
              valor: formatCurrency.format(_ingresosMes),
              icono: Icons.attach_money,
              color: Colors.green.shade700,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reportes de ingresos próximamente'),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Widget para construir cada tarjeta de resumen
  Widget _buildTarjeta({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha((255 * 0.1).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha((255 * 0.5).round())),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                titulo,
                style: TextStyle(
                  color: color.withAlpha((255 * 0.8).round()),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sección de acciones rápidas
  Widget _buildAccionesRapidas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones rápidas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildAccionRapida(
                texto: 'Nuevo Contrato',
                icono: Icons.add_circle,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrarContratoScreen(),
                    ),
                  ).then((_) => _cargarResumenDashboard());
                },
              ),
              _buildAccionRapida(
                texto: 'Registrar Pago',
                icono: Icons.payments,
                color: Colors.blue,
                onTap: () => _mostrarDialogoSeleccionContrato(context),
              ),
              _buildAccionRapida(
                texto: 'Renovar Contrato',
                icono: Icons.autorenew,
                color: Colors.purple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Renovación de contratos próximamente'),
                    ),
                  );
                },
              ),
              _buildAccionRapida(
                texto: 'Reportes',
                icono: Icons.bar_chart,
                color: Colors.amber.shade800,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reportes detallados próximamente'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget para construir cada acción rápida
  Widget _buildAccionRapida({
    required String texto,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha((255 * 0.2).round()),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icono, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                texto,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sección de módulos principales
  Widget _buildModulosPrincipales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Módulos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildModuloCard(
              titulo: 'Contratos',
              descripcion: 'Gestionar contratos activos e históricos',
              icono: Icons.description,
              color: Colors.indigo,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GestionContratosScreen(),
                    ),
                  ),
            ),
            _buildModuloCard(
              titulo: 'Movimientos',
              descripcion: 'Registrar pagos y gastos',
              icono: Icons.account_balance_wallet,
              color: Colors.green,
              onTap: () => _mostrarDialogoSeleccionInmueble(context),
            ),
            _buildModuloCard(
              titulo: 'Calendario',
              descripcion: 'Calendario de pagos y vencimientos',
              icono: Icons.calendar_today,
              color: Colors.amber.shade700,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calendario de pagos próximamente'),
                  ),
                );
              },
            ),
            _buildModuloCard(
              titulo: 'Reportes',
              descripcion: 'Estadísticas y análisis',
              icono: Icons.bar_chart,
              color: Colors.purple,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reportes avanzados próximamente'),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Widget para construir cada tarjeta de módulo
  Widget _buildModuloCard({
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icono, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                descripcion,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sección de contratos próximos a vencer
  Widget _buildContratosProximosVencer() {
    return Consumer(
      builder: (context, ref, child) {
        final contratosAsync = ref.watch(contratosRentaProvider);
        return contratosAsync.when(
          data: (contratos) {
            // Usar cache si los contratos no han cambiado
            if (_lastContratos == contratos &&
                _cachedContratosPorVencer != null) {
              final contratosPorVencer = _cachedContratosPorVencer!;
              if (contratosPorVencer.isEmpty) return const SizedBox.shrink();
              return _buildContratosPorVencerContent(contratosPorVencer);
            }

            final ahora = DateTime.now();
            final limite = ahora.add(const Duration(days: 30));
            final contratosPorVencer =
                contratos
                    .where(
                      (c) =>
                          c.idEstado == 1 &&
                          c.fechaFin.isAfter(ahora) &&
                          c.fechaFin.isBefore(limite),
                    )
                    .toList();

            // Guardar en cache
            _lastContratos = contratos;
            _cachedContratosPorVencer = contratosPorVencer;

            if (contratosPorVencer.isEmpty) return const SizedBox.shrink();
            return _buildContratosPorVencerContent(contratosPorVencer);
          },
          error: (error, stack) {
            AppLogger.error(
              'Error al cargar contratos próximos a vencer',
              error,
              stack,
            );
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Error al cargar contratos próximos a vencer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(error.toString()),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          final _ = ref.refresh(contratosRentaProvider);
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  /// Método auxiliar para construir el contenido de contratos por vencer
  Widget _buildContratosPorVencerContent(
    List<ContratoRenta> contratosPorVencer,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Contratos próximos a vencer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GestionContratosScreen(),
                  ),
                );
              },
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...contratosPorVencer.take(3).map((contrato) {
          return _buildContratoProximoVencer(contrato);
        }),
      ],
    );
  }

  /// Construye la tarjeta para un contrato próximo a vencer
  Widget _buildContratoProximoVencer(ContratoRenta contrato) {
    final diasRestantes = contrato.fechaFin.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Inmueble ID: ${contrato.idInmueble}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    diasRestantes < 10
                        ? Colors.red.shade100
                        : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      diasRestantes < 10
                          ? Colors.red.shade300
                          : Colors.orange.shade300,
                ),
              ),
              child: Text(
                '$diasRestantes días',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:
                      diasRestantes < 10
                          ? Colors.red.shade700
                          : Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Cliente: ${contrato.clienteNombreCompleto ?? 'Cliente ID: ${contrato.idCliente}'}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              'Vence: ${formatDate.format(contrato.fechaFin)}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: diasRestantes < 10 ? Colors.red : Colors.black87,
              ),
            ),
            Text(
              'Renta: ${formatCurrency.format(contrato.montoMensual)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        onTap: () {
          if (contrato.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        DetalleContratoScreen(idContrato: contrato.id!),
              ),
            ).then((_) => _cargarResumenDashboard());
          } else {
            // Mostrar mensaje de error si el ID del contrato es nulo
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Error: No se puede abrir el contrato (ID no válido)',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _mostrarDialogoSeleccionInmueble(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Inmueble'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Consumer(
              builder: (context, ref, child) {
                final inmueblesAsync = ref.watch(inmueblesRentadosProvider);

                return inmueblesAsync.when(
                  data: (inmuebles) {
                    if (inmuebles.isEmpty) {
                      return const Center(
                        child: Text('No hay inmuebles rentados actualmente'),
                      );
                    }

                    return ListView.builder(
                      itemCount: inmuebles.length,
                      itemBuilder: (context, index) {
                        final inmueble = inmuebles[index];
                        return ListTile(
                          title: Text('Inmueble ID: ${inmueble.id}'),
                          subtitle: Text(
                            inmueble.idDireccion?.toString() ?? 'Sin dirección',
                          ),
                          leading: const Icon(Icons.home),
                          onTap: () async {
                            // Cerrar el diálogo
                            Navigator.pop(context);

                            // Buscar el contrato activo asociado a este inmueble
                            final contratosAsync = ref.read(
                              contratosRentaProvider,
                            );

                            // Mostrar indicador de carga mientras buscamos el contrato
                            final snackBar = ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text('Cargando información...'),
                                duration: Duration(seconds: 2),
                              ),
                            );

                            // Obtener el contrato y la información del cliente
                            contratosAsync.whenData((contratos) {
                              // Cerrar el SnackBar manualmente si aún está visible
                              snackBar.close();

                              // Filtrar el contrato activo para este inmueble
                              final contratoActivo = contratos.firstWhere(
                                (c) =>
                                    c.idInmueble == inmueble.id &&
                                    c.idEstado == 1,
                                orElse:
                                    () => ContratoRenta(
                                      idInmueble: inmueble.id!,
                                      idCliente: 0,
                                      fechaInicio: DateTime.now(),
                                      fechaFin: DateTime.now(),
                                      montoMensual: 0,
                                      idEstado: 1,
                                    ),
                              );

                              // Navegar a la pantalla de movimientos con la información correcta
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MovimientosRentaScreen(
                                          idInmueble: inmueble.id!,
                                          nombreInmueble:
                                              inmueble.nombre.isNotEmpty
                                                  ? inmueble.nombre
                                                  : 'Inmueble ${inmueble.id}',
                                          idCliente: contratoActivo.idCliente,
                                          nombreCliente:
                                              contratoActivo
                                                  .clienteNombreCompleto ??
                                              (contratoActivo.idCliente > 0
                                                  ? 'Cliente ID: ${contratoActivo.idCliente}'
                                                  : 'Cliente no especificado'),
                                        ),
                                  ),
                                );
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stack) =>
                          Center(child: Text('Error: ${error.toString()}')),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
          ],
        );
      },
    );
  }

  /// Diálogo para seleccionar un contrato y registrar un pago
  void _mostrarDialogoSeleccionContrato(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Contrato para Registrar Pago'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Consumer(
              builder: (context, ref, child) {
                final contratosAsync = ref.watch(contratosRentaProvider);

                return contratosAsync.when(
                  data: (contratos) {
                    final contratosActivos =
                        contratos.where((c) => c.idEstado == 1).toList();

                    if (contratosActivos.isEmpty) {
                      return const Center(
                        child: Text('No hay contratos activos'),
                      );
                    }

                    return ListView.builder(
                      itemCount: contratosActivos.length,
                      itemBuilder: (context, index) {
                        final contrato = contratosActivos[index];
                        return ListTile(
                          title: Text('Contrato ID: ${contrato.id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cliente: ${contrato.clienteNombreCompleto ?? 'Cliente ID: ${contrato.idCliente}'}',
                              ),
                              Text(
                                'Monto: ${formatCurrency.format(contrato.montoMensual)}',
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          leading: const Icon(Icons.description),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => RegistrarPagoRentaScreen(
                                      idContrato: contrato.id!,
                                    ),
                              ),
                            ).then((_) => _cargarResumenDashboard());
                          },
                        );
                      },
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stack) =>
                          Center(child: Text('Error: ${error.toString()}')),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
          ],
        );
      },
    );
  }
}

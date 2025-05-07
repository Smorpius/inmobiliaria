import 'dart:async';
import 'package:intl/intl.dart';
import 'components/detail_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'components/inmueble_header.dart';
import 'components/inmueble_basic_info.dart';
import 'components/inmueble_price_info.dart';
import 'components/inmueble_address_info.dart';
import 'components/cliente_asociado_info.dart';
import 'components/inmueble_action_buttons.dart';
import 'package:inmobiliaria/utils/applogger.dart';
import 'components/inmueble_detalle_notifier.dart';
import 'components/inmueble_operation_buttons.dart';
import 'components/inmueble_proveedores_section.dart';
import 'components/clientes_interesados_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/models/inmueble_model.dart';
import 'package:inmobiliaria/widgets/async_value_widget.dart';
import '../../../utils/app_colors.dart'; // Importar AppColors
import 'package:inmobiliaria/providers/cliente_providers.dart';
import 'package:inmobiliaria/models/inmueble_imagenes_state.dart';
import 'package:inmobiliaria/widgets/inmueble_financiero_info.dart';
import 'package:inmobiliaria/widgets/inmueble_imagenes_section.dart';
import 'package:inmobiliaria/models/clientes_interesados_state.dart';
import 'package:inmobiliaria/providers/inmueble_renta_provider.dart';
import 'package:inmobiliaria/vistas/ventas/registrar_operacion_screen.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/contrato_generator_screen.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/registro_movimientos_renta_screen.dart'
    as movimientos_renta;

class InmuebleDetailScreen extends ConsumerStatefulWidget {
  // Constantes para los estados del inmueble usando lowerCamelCase
  static const int estadoNoDisponible = 2;
  static const int estadoDisponible = 3;
  static const int estadoVendido = 4;
  static const int estadoRentado = 5;
  static const int estadoEnNegociacion = 6;

  // Mapeo de estados a nombres para facilitar acceso
  static const Map<int, String> nombresEstados = {
    estadoNoDisponible: 'No Disponible',
    estadoDisponible: 'Disponible',
    estadoVendido: 'Vendido',
    estadoRentado: 'Rentado',
    estadoEnNegociacion: 'En Negociación',
  };

  // Mapeo de estados a colores
  static const Map<int, Color> coloresEstados = {
    estadoNoDisponible: AppColors.error,
    estadoDisponible: AppColors.exito,
    estadoVendido: AppColors.info,
    estadoRentado: AppColors.advertencia,
    estadoEnNegociacion: AppColors.acento,
  };

  final Inmueble inmuebleInicial;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isInactivo;
  final String? botonEstadoTexto;
  final Color? botonEstadoColor;

  const InmuebleDetailScreen({
    super.key,
    required this.inmuebleInicial,
    required this.onEdit,
    required this.onDelete,
    this.isInactivo = false,
    this.botonEstadoTexto,
    this.botonEstadoColor,
  });

  @override
  ConsumerState<InmuebleDetailScreen> createState() =>
      _InmuebleDetailScreenState();
}

class _InmuebleDetailScreenState extends ConsumerState<InmuebleDetailScreen> {
  // Controlador para evitar múltiples peticiones
  bool _isOperationInProgress = false;

  // Clientes disponibles en caché para evitar recargas
  List<dynamic> _cachedClientes = [];
  bool _clientesLoading = false;

  @override
  void initState() {
    super.initState();
    // Precarga de datos en segundo plano
    if (widget.inmuebleInicial.id != null) {
      _precargarDatos();
    }
  }

  // Método para precargar datos en segundo plano
  Future<void> _precargarDatos() async {
    Future.microtask(() {
      try {
        if (_cachedClientes.isEmpty && !_clientesLoading) {
          setState(() {
            _clientesLoading = true;
          });

          final clientesAsync = ref.read(clientesProvider);
          if (clientesAsync is AsyncData) {
            setState(() {
              _cachedClientes = clientesAsync.value ?? [];
              _clientesLoading = false;
            });
          }
        }
      } catch (e, stackTrace) {
        AppLogger.error('Error en precarga de datos', e, stackTrace);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inmuebleAsync =
        widget.inmuebleInicial.id != null
            ? ref.watch(inmuebleDetalleProvider(widget.inmuebleInicial.id!))
            : AsyncValue.data(widget.inmuebleInicial);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inmuebleInicial.nombre),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isOperationInProgress)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar información',
              onPressed: () {
                if (widget.inmuebleInicial.id != null) {
                  ref.invalidate(
                    inmuebleDetalleProvider(widget.inmuebleInicial.id!),
                  );
                }
              },
            ),
        ],
      ),
      body: AsyncValueWidget<Inmueble>(
        value: inmuebleAsync,
        loadingWidget: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando detalles del inmueble...'),
            ],
          ),
        ),
        errorWidget: (error, stackTrace) => _buildErrorWidget(error),
        data: (inmueble) => _buildContent(inmueble),
      ),
    );
  }

  // Widget separado para el manejo de errores
  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error al cargar detalles: ${error.toString().split('\n').first}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.inmuebleInicial.id != null) {
                ref.invalidate(
                  inmuebleDetalleProvider(widget.inmuebleInicial.id!),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // Contenido principal optimizado
  Widget _buildContent(Inmueble inmueble) {
    final currentIsInactivo =
        inmueble.idEstado == InmuebleDetailScreen.estadoNoDisponible ||
        widget.isInactivo;
    final isInNegotiation =
        inmueble.idEstado == InmuebleDetailScreen.estadoEnNegociacion;

    final textoBotonEstado =
        widget.botonEstadoTexto ??
        (currentIsInactivo ? 'Marcar Disponible' : 'Marcar No Disponible');

    final colorBotonEstado =
        widget.botonEstadoColor ??
        (currentIsInactivo ? Colors.green : Colors.red);

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.all(16.0),
        elevation: 4,
        color: currentIsInactivo ? Colors.grey.shade50 : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InmuebleHeader(
                      key: ValueKey('header_${inmueble.id ?? "nuevo"}'),
                      inmueble: inmueble,
                      isInactivo: currentIsInactivo,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildOptimizedImageSection(
                  inmueble.id,
                  currentIsInactivo,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Divider(height: 16),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InmuebleBasicInfo(
                      key: ValueKey('basic_${inmueble.id ?? "nuevo"}'),
                      inmueble: inmueble,
                      isInactivo: currentIsInactivo,
                    ),
                    const SizedBox(height: 16),
                    InmueblePriceInfo(
                      key: ValueKey('price_${inmueble.id ?? "nuevo"}'),
                      inmueble: inmueble,
                      isInactivo: currentIsInactivo,
                    ),
                    if (inmueble.costoCliente > 0 ||
                        inmueble.costoServicios > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: InmuebleFinancieroInfo(
                          key: ValueKey('financiero_${inmueble.id ?? "nuevo"}'),
                          inmueble: inmueble,
                          isInactivo: currentIsInactivo,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: _buildOptimizedProveedoresSection(
                  inmueble.id,
                  currentIsInactivo,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Divider(height: 16),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InmuebleAddressInfo(
                      key: ValueKey('address_${inmueble.id ?? "nuevo"}'),
                      inmueble: inmueble,
                      isInactivo: currentIsInactivo,
                    ),
                    if (inmueble.caracteristicas != null &&
                        inmueble.caracteristicas!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: DetailRow(
                          label: 'Características',
                          value: inmueble.caracteristicas!,
                          icon: Icons.list_alt,
                          isInactivo: currentIsInactivo,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Divider(height: 16),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (inmueble.idCliente != null && inmueble.id != null)
                      ClienteAsociadoInfo(
                        key: ValueKey('cliente_${inmueble.idCliente}'),
                        idInmueble: inmueble.id!,
                        idCliente: inmueble.idCliente!,
                        isInactivo: currentIsInactivo,
                        onClienteDesasociado: () {
                          final inmuebleId = inmueble.id;
                          if (inmuebleId != null) {
                            ref.invalidate(inmuebleDetalleProvider(inmuebleId));
                          }
                        },
                      ),
                    if (inmueble.idEmpleado != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: DetailRow(
                          label: 'Empleado responsable',
                          value: 'ID: ${inmueble.idEmpleado}',
                          icon: Icons.person,
                          isInactivo: currentIsInactivo,
                        ),
                      ),
                    if (inmueble.id != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ClientesInteresadosSection(
                          key: ValueKey('interesados_${inmueble.id}'),
                          idInmueble: inmueble.id!,
                          isInactivo: currentIsInactivo,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (inmueble.id != null && !currentIsInactivo)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 24.0,
                    left: 24.0,
                    right: 24.0,
                  ),
                  child: InmuebleOperationButtons(
                    key: const ValueKey('operation_buttons'),
                    inmueble: inmueble,
                    isInNegotiation: isInNegotiation,
                    onOperationSelected:
                        (operationType) => _ejecutarOperacionSegura(
                          () => _iniciarOperacion(
                            context,
                            inmueble,
                            operationType,
                          ),
                        ),
                    onFinishProcess:
                        isInNegotiation
                            ? () => _ejecutarOperacionSegura(
                              () => _finalizarProceso(context, inmueble),
                            )
                            : null,
                  ),
                ),
              ),

            if (inmueble.idEstado == InmuebleDetailScreen.estadoRentado)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 16.0,
                    left: 24.0,
                    right: 24.0,
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Registro de Renta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    movimientos_renta.RegistroMovimientosRentaScreen(
                                      inmueble: inmueble,
                                    ),
                          ),
                        ),
                  ),
                ),
              ),

            if (inmueble.idEstado == InmuebleDetailScreen.estadoEnNegociacion ||
                inmueble.idEstado == InmuebleDetailScreen.estadoRentado ||
                inmueble.idEstado == InmuebleDetailScreen.estadoVendido)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 16.0,
                    left: 24.0,
                    right: 24.0,
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.description),
                    label: const Text('Generar Contrato'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (inmueble.idCliente == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'El inmueble no tiene un cliente asociado. Asigne un cliente antes de generar el contrato.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      String tipoContrato = 'renta';
                      if (inmueble.idEstado ==
                              InmuebleDetailScreen.estadoVendido ||
                          (inmueble.tipoOperacion == 'venta' ||
                              inmueble.tipoOperacion == 'ambos')) {
                        tipoContrato = 'venta';
                      } else if (inmueble.tipoOperacion == 'renta') {
                        tipoContrato = 'renta';
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ContratoGeneratorScreen(
                                inmueble: inmueble,
                                tipoContrato: tipoContrato,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: InmuebleActionButtons(
                  key: const ValueKey('action_buttons'),
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                  isInactivo: currentIsInactivo,
                  deleteButtonText: textoBotonEstado,
                  deleteButtonColor: colorBotonEstado,
                  showAddClienteInteresado:
                      !currentIsInactivo && inmueble.id != null,
                  onAddClienteInteresado:
                      inmueble.id != null
                          ? () => _ejecutarOperacionSegura(
                            () => _mostrarDialogoAgregarClienteInteresado(
                              context,
                              inmueble.id!,
                            ),
                          )
                          : null,
                ),
              ),
            ),

            if (inmueble.idEstado == InmuebleDetailScreen.estadoVendido ||
                inmueble.idEstado == InmuebleDetailScreen.estadoRentado)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 32),
                      const Text(
                        'Historial de Transacciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTransactionHistory(inmueble),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(Inmueble inmueble) {
    if (inmueble.id == null) {
      return const Center(
        child: Text('No se puede cargar el historial: ID no disponible'),
      );
    }

    // Usar el proveedor adecuado que devuelve un AsyncValue
    final movimientosProvider = ref.watch(
      movimientosPorInmuebleProvider(inmueble.id!),
    );

    return movimientosProvider.when(
      data: (movimientos) {
        if (movimientos.isEmpty) {
          return const Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No hay transacciones registradas',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movimientos.length > 5 ? 5 : movimientos.length,
              itemBuilder: (context, index) {
                final movimiento = movimientos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    leading: Icon(
                      movimiento.tipoMovimiento == 'ingreso'
                          ? Icons.arrow_circle_down
                          : Icons.arrow_circle_up,
                      color:
                          movimiento.tipoMovimiento == 'ingreso'
                              ? Colors.green
                              : Colors.orange,
                      size: 36,
                    ),
                    title: Text(
                      movimiento.concepto,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(movimiento.fechaMovimiento),
                    ),
                    trailing: Text(
                      '\$${movimiento.monto.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            movimiento.tipoMovimiento == 'ingreso'
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                      ),
                    ),
                    onTap: () {
                      _mostrarDetallesMovimiento(context, movimiento);
                    },
                  ),
                );
              },
            ),
            if (movimientos.length > 5)
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              movimientos_renta.RegistroMovimientosRentaScreen(
                                inmueble: inmueble,
                              ),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('Ver historial completo'),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: Text(
              'Error al cargar transacciones: ${error.toString().split('\n').first}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
    );
  }

  void _mostrarDetallesMovimiento(BuildContext context, dynamic movimiento) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Detalles: ${movimiento.concepto}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DetailRow(
                    label: 'Tipo',
                    value:
                        movimiento.tipoMovimiento == 'ingreso'
                            ? 'Ingreso'
                            : 'Egreso',
                    icon: Icons.category,
                    isInactivo: false,
                  ),
                  const SizedBox(height: 8),
                  DetailRow(
                    label: 'Monto',
                    value: '\$${movimiento.monto.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    isInactivo: false,
                  ),
                  const SizedBox(height: 8),
                  DetailRow(
                    label: 'Fecha',
                    value: DateFormat(
                      'dd/MM/yyyy',
                    ).format(movimiento.fechaMovimiento),
                    icon: Icons.calendar_today,
                    isInactivo: false,
                  ),
                  if (movimiento.comentarios != null &&
                      movimiento.comentarios!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DetailRow(
                      label: 'Comentarios',
                      value: movimiento.comentarios!,
                      icon: Icons.comment,
                      isInactivo: false,
                    ),
                  ],
                ],
              ),
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

  // Método optimizado para la sección de imágenes
  Widget _buildOptimizedImageSection(int? inmuebleId, bool isInactivo) {
    if (inmuebleId == null) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                "No se pudieron cargar las imágenes: ID de inmueble no disponible",
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<void>(
      future: Future.delayed(const Duration(milliseconds: 5)),
      builder: (context, snapshot) {
        try {
          return InmuebleImagenesSection(
            key: ValueKey('inmueble_imgs_$inmuebleId'),
            inmuebleId: inmuebleId,
            isInactivo: isInactivo,
          );
        } catch (e, stackTrace) {
          AppLogger.error(
            'Error al construir la sección de imágenes',
            e,
            stackTrace,
          );
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No se pudieron cargar las imágenes: ${e.toString().contains('RangeError') ? 'Error de formato' : e.toString().split('\n').first}",
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.invalidate(inmuebleImagenesStateProvider(inmuebleId));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar cargar imágenes'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  // Método optimizado para la sección de proveedores
  Widget _buildOptimizedProveedoresSection(int? inmuebleId, bool isInactivo) {
    if (inmuebleId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          "No se pudo cargar la información de proveedores: ID de inmueble no disponible",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return FutureBuilder<void>(
      future: Future.delayed(const Duration(milliseconds: 5)),
      builder: (context, snapshot) {
        try {
          return InmuebleProveedoresSection(
            key: ValueKey('prov_section_$inmuebleId'),
            idInmueble: inmuebleId,
            isInactivo: isInactivo,
          );
        } catch (e, stackTrace) {
          AppLogger.error(
            'Error al construir la sección de proveedores',
            e,
            stackTrace,
          );
          return Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              "No se pudo cargar la información de proveedores: ${e.toString().split('\n').first}",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }
      },
    );
  }

  // Método para evitar múltiples operaciones simultáneas
  Future<void> _ejecutarOperacionSegura(
    Future<void> Function() operacion,
  ) async {
    if (_isOperationInProgress) return;

    setState(() {
      _isOperationInProgress = true;
    });

    try {
      await operacion().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('La operación tardó demasiado tiempo');
        },
      );
    } catch (e, stackTrace) {
      if (mounted) {
        AppLogger.error('Error en operación segura', e, stackTrace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOperationInProgress = false;
        });
      }
    }
  }

  // Método para verificar si una transición de estado es válida
  bool _esTransicionValida(int estadoActual, int nuevoEstado) {
    final Map<int, List<int>> transicionesValidas = {
      InmuebleDetailScreen.estadoDisponible: [
        InmuebleDetailScreen.estadoNoDisponible,
        InmuebleDetailScreen.estadoEnNegociacion,
      ],
      InmuebleDetailScreen.estadoNoDisponible: [
        InmuebleDetailScreen.estadoDisponible,
      ],
      InmuebleDetailScreen.estadoEnNegociacion: [
        InmuebleDetailScreen.estadoDisponible,
        InmuebleDetailScreen.estadoVendido,
        InmuebleDetailScreen.estadoRentado,
      ],
      InmuebleDetailScreen.estadoVendido: [
        InmuebleDetailScreen.estadoDisponible,
      ],
      InmuebleDetailScreen.estadoRentado: [
        InmuebleDetailScreen.estadoDisponible,
      ],
    };

    return transicionesValidas.containsKey(estadoActual) &&
        transicionesValidas[estadoActual]!.contains(nuevoEstado);
  }

  // Función optimizada para mostrar diálogo de cliente interesado
  Future<void> _mostrarDialogoAgregarClienteInteresado(
    BuildContext context,
    int idInmueble,
  ) async {
    List<dynamic> clientes = _cachedClientes;

    if (clientes.isEmpty) {
      final clientesAsyncValue = ref.read(clientesProvider);

      if (clientesAsyncValue is AsyncLoading) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cargando lista de clientes...'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (clientesAsyncValue is AsyncError) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar clientes: ${clientesAsyncValue.error.toString().split('\n').first}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      clientes = clientesAsyncValue.value ?? [];

      if (mounted && clientes.isNotEmpty) {
        setState(() {
          _cachedClientes = clientes;
        });
      }
    }

    if (clientes.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay clientes disponibles para agregar como interesados',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int? clienteSeleccionado;
    final comentariosController = TextEditingController();

    if (!context.mounted) return;

    final dropdownItems = await compute(_buildDropdownItems, clientes);

    if (!context.mounted) return;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar Cliente Interesado'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Seleccione un cliente:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: clienteSeleccionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      hint: const Text('Seleccionar cliente'),
                      items: dropdownItems,
                      onChanged: (value) {
                        setState(() {
                          clienteSeleccionado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Comentarios (opcional):'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: comentariosController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'Agregar comentarios sobre el interés del cliente...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      clienteSeleccionado == null
                          ? null
                          : () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado == true && clienteSeleccionado != null) {
      if (!context.mounted) return;

      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrando cliente interesado...'),
            duration: Duration(seconds: 1),
          ),
        );

        final notifier = ref.read(
          clientesInteresadosStateProvider(idInmueble).notifier,
        );

        final success = await notifier
            .registrarClienteInteresado(
              clienteSeleccionado!,
              comentariosController.text.isEmpty
                  ? null
                  : comentariosController.text,
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('La operación tardó demasiado tiempo');
              },
            );

        if (!context.mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente agregado como interesado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo agregar el cliente como interesado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e, stackTrace) {
        if (!context.mounted) return;

        AppLogger.error('Error al agregar cliente interesado', e, stackTrace);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al agregar cliente interesado: ${e.toString().split('\n').first}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    comentariosController.dispose();
  }

  // Método para iniciar operación (venta, renta, servicio)
  Future<void> _iniciarOperacion(
    BuildContext context,
    Inmueble inmueble,
    String operationType,
  ) async {
    if (inmueble.id == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se puede realizar esta operación: ID de inmueble no disponible',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (inmueble.idEstado == InmuebleDetailScreen.estadoEnNegociacion) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El inmueble ya está en negociación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_esTransicionValida(
      inmueble.idEstado ?? InmuebleDetailScreen.estadoDisponible,
      InmuebleDetailScreen.estadoEnNegociacion,
    )) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se puede iniciar $operationType desde el estado actual: ${InmuebleDetailScreen.nombresEstados[inmueble.idEstado]}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!context.mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        String operationTitle = '';
        String operationMessage = '';

        switch (operationType) {
          case 'venta':
            operationTitle = 'Iniciar venta';
            operationMessage =
                '¿Desea iniciar el proceso de venta para este inmueble? El inmueble pasará a estado "En negociación".';
            break;
          case 'renta':
            operationTitle = 'Iniciar renta';
            operationMessage =
                '¿Desea iniciar el proceso de renta para este inmueble? El inmueble pasará a estado "En negociación".';
            break;
          case 'servicio':
            operationTitle = 'Agregar servicio';
            operationMessage =
                '¿Desea agregar un servicio para este inmueble? El inmueble pasará a estado "En negociación".';
            break;
          default:
            operationTitle = 'Iniciar operación';
            operationMessage =
                '¿Confirma que desea iniciar esta operación? El inmueble pasará a estado "En negociación".';
        }

        return AlertDialog(
          title: Text(operationTitle),
          content: Text(operationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !context.mounted) return;

    try {
      final idInmueble = inmueble.id!;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Procesando solicitud...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      final notifier = ref.read(inmuebleDetalleProvider(idInmueble).notifier);
      await notifier
          .actualizarEstado(InmuebleDetailScreen.estadoEnNegociacion)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('La operación tardó demasiado tiempo');
            },
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Inmueble en proceso de ${operationType == 'servicio' ? 'servicio' : operationType}',
          ),
          backgroundColor: Colors.blue,
        ),
      );

      if (operationType == 'venta') {
        if (!context.mounted) return;

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrarOperacionScreen(inmueble: inmueble),
          ),
        );

        if (result == true && context.mounted) {
          ref.invalidate(inmuebleDetalleProvider(idInmueble));
        }
      }
    } catch (e, stackTrace) {
      if (!context.mounted) return;

      AppLogger.error(
        'Error al iniciar operación $operationType',
        e,
        stackTrace,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al iniciar operación $operationType: ${e.toString().split('\n').first}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para finalizar proceso
  Future<void> _finalizarProceso(
    BuildContext context,
    Inmueble inmueble,
  ) async {
    if (inmueble.id == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se puede finalizar el proceso: ID de inmueble no disponible',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (inmueble.idEstado != InmuebleDetailScreen.estadoEnNegociacion) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo se puede finalizar el proceso cuando el inmueble está en negociación',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<int> estadosFinalesPermitidos = [
      InmuebleDetailScreen.estadoDisponible,
    ];

    String tipoOperacion = inmueble.tipoOperacion;

    if (tipoOperacion == 'venta' || tipoOperacion == 'ambos') {
      estadosFinalesPermitidos.add(InmuebleDetailScreen.estadoVendido);
    }

    if (tipoOperacion == 'renta' || tipoOperacion == 'ambos') {
      estadosFinalesPermitidos.add(InmuebleDetailScreen.estadoRentado);
    }

    if (!context.mounted) return;

    final estadoFinal = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Finalizar proceso'),
          content: const Text('Seleccione el estado final del inmueble:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            if (estadosFinalesPermitidos.contains(
              InmuebleDetailScreen.estadoVendido,
            ))
              ElevatedButton.icon(
                icon: const Icon(Icons.sell, size: 18),
                label: const Text('Vendido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pop(InmuebleDetailScreen.estadoVendido),
              ),
            if (estadosFinalesPermitidos.contains(
              InmuebleDetailScreen.estadoRentado,
            ))
              ElevatedButton.icon(
                icon: const Icon(Icons.home, size: 18),
                label: const Text('Rentado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pop(InmuebleDetailScreen.estadoRentado),
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Disponible'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  () => Navigator.of(
                    context,
                  ).pop(InmuebleDetailScreen.estadoDisponible),
            ),
          ],
        );
      },
    );

    if (estadoFinal == null || !context.mounted) return;

    if (!estadosFinalesPermitidos.contains(estadoFinal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: No se puede cambiar a ${InmuebleDetailScreen.nombresEstados[estadoFinal]} con tipo de operación "$tipoOperacion"',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final idInmueble = inmueble.id!;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Actualizando estado...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      final notifier = ref.read(inmuebleDetalleProvider(idInmueble).notifier);
      await notifier
          .actualizarEstado(estadoFinal)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('La operación tardó demasiado tiempo');
            },
          );

      if (!context.mounted) return;

      String mensaje;
      switch (estadoFinal) {
        case InmuebleDetailScreen.estadoVendido:
          mensaje = 'Inmueble marcado como Vendido';
          break;
        case InmuebleDetailScreen.estadoRentado:
          mensaje = 'Inmueble marcado como Rentado';
          break;
        case InmuebleDetailScreen.estadoDisponible:
          mensaje = 'Inmueble marcado como Disponible';
          break;
        default:
          mensaje = 'Estado del inmueble actualizado';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor:
              InmuebleDetailScreen.coloresEstados[estadoFinal] ?? Colors.blue,
        ),
      );
    } catch (e, stackTrace) {
      if (!context.mounted) return;

      AppLogger.error('Error al finalizar proceso', e, stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al finalizar proceso: ${e.toString().split('\n').first}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Función para procesar clientes en segundo plano usando compute
List<DropdownMenuItem<int>> _buildDropdownItems(List<dynamic> clientes) {
  return clientes.map((cliente) {
    final nombreCompleto =
        '${cliente.nombre} ${cliente.apellidoPaterno} ${cliente.apellidoMaterno ?? ''}';
    return DropdownMenuItem<int>(
      value: cliente.id,
      child: Text(nombreCompleto.trim()),
    );
  }).toList();
}

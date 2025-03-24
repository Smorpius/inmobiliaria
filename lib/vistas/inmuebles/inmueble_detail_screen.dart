import 'dart:async';
import 'components/detail_row.dart';
import 'package:flutter/material.dart';
import 'components/inmueble_header.dart';
import 'package:flutter/foundation.dart';
import 'components/inmueble_basic_info.dart';
import 'components/inmueble_price_info.dart';
import 'components/inmueble_address_info.dart';
import 'components/cliente_asociado_info.dart';
import 'components/inmueble_action_buttons.dart';
import 'components/inmueble_detalle_notifier.dart';
import 'components/inmueble_operation_buttons.dart';
import 'components/inmueble_proveedores_section.dart';
import 'components/clientes_interesados_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/models/inmueble_model.dart';
import 'package:inmobiliaria/widgets/async_value_widget.dart';
import 'package:inmobiliaria/providers/cliente_providers.dart';
import 'package:inmobiliaria/widgets/inmueble_financiero_info.dart';
import 'package:inmobiliaria/models/clientes_interesados_state.dart';
import 'package:inmobiliaria/widgets/inmueble_imagenes_section.dart';
import 'package:inmobiliaria/vistas/ventas/registrar_venta_screen.dart';
import 'package:inmobiliaria/models/inmueble_imagenes_state.dart'; // Corrección: importación adecuada

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
    estadoNoDisponible: Colors.red,
    estadoDisponible: Colors.green,
    estadoVendido: Colors.blue,
    estadoRentado: Colors.orange,
    estadoEnNegociacion: Colors.purple,
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
    // Programar la carga para después de que la UI esté completamente construida
    Future.microtask(() {
      try {
        // Precargar clientes para mejorar la respuesta del diálogo
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
      } catch (e) {
        debugPrint('Error en precarga: $e');
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

    // Usar RepaintBoundary para evitar repintados innecesarios del contenido
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.all(16.0),
        elevation: 4,
        color: currentIsInactivo ? Colors.grey.shade50 : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Usar SliverToBoxAdapter para cada sección ayuda al rendimiento
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado con nombre del inmueble
                    InmuebleHeader(
                      key: ValueKey('header_${inmueble.id}'),
                      inmueble: inmueble,
                      isInactivo: currentIsInactivo,
                    ),
                  ],
                ),
              ),
            ),

            // Sección de imágenes optimizada
            if (inmueble.id != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildOptimizedImageSection(
                    inmueble.id!,
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

            // Información principal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Secciones de información básica
                    InmuebleBasicInfo(
                      key: ValueKey('basic_${inmueble.id}'),
                      inmueble: inmueble,
                      isInactivo: currentIsInactivo,
                    ),

                    const SizedBox(height: 16),

                    InmueblePriceInfo(
                      key: ValueKey('price_${inmueble.id}'),
                      inmueble: inmueble,
                      isInactivo: currentIsInactivo,
                    ),

                    if (inmueble.costoCliente > 0 ||
                        inmueble.costoServicios > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: InmuebleFinancieroInfo(
                          key: ValueKey('financiero_${inmueble.id}'),
                          inmueble: inmueble,
                          isInactivo: currentIsInactivo,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Sección de proveedores
            if (inmueble.id != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: _buildOptimizedProveedoresSection(
                    inmueble.id!,
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

            // Información de dirección y características
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InmuebleAddressInfo(
                      key: ValueKey('address_${inmueble.id}'),
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

            // Información de cliente, empleado e interesados
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
                          if (inmueble.id != null) {
                            ref.invalidate(
                              inmuebleDetalleProvider(inmueble.id!),
                            );
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

            // Botones de operación
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

            // Botones de acción
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
          ],
        ),
      ),
    );
  }

  // Método optimizado para la sección de imágenes
  Widget _buildOptimizedImageSection(int inmuebleId, bool isInactivo) {
    return FutureBuilder<void>(
      // Usar delay mínimo para permitir que la UI se construya primero
      future: Future.delayed(const Duration(milliseconds: 5)),
      builder: (context, snapshot) {
        try {
          return InmuebleImagenesSection(
            key: ValueKey('inmueble_imgs_$inmuebleId'),
            inmuebleId: inmuebleId,
            isInactivo: isInactivo,
          );
        } catch (e) {
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
                      // Corregido: Usar el provider correcto
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
  Widget _buildOptimizedProveedoresSection(int inmuebleId, bool isInactivo) {
    return FutureBuilder<void>(
      future: Future.delayed(const Duration(milliseconds: 5)),
      builder: (context, snapshot) {
        try {
          return InmuebleProveedoresSection(
            key: ValueKey('prov_section_$inmuebleId'),
            idInmueble: inmuebleId,
            isInactivo: isInactivo,
          );
        } catch (e) {
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
      await operacion();
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

    // Si no tenemos clientes en caché, los cargamos
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

      // Guardar en caché para futuros usos
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

    // Usar compute para procesar la lista de clientes en otro hilo
    final dropdownItems = await compute(_buildDropdownItems, clientes);

    if (!context.mounted) return; // Verificación adicional

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
        // Mostrar indicador de carga
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrando cliente interesado...'),
            duration: Duration(seconds: 1),
          ),
        );

        final notifier = ref.read(
          clientesInteresadosStateProvider(idInmueble).notifier,
        );

        // Corrección: Asegurar que clienteSeleccionado no es null
        final success = await notifier.registrarClienteInteresado(
          clienteSeleccionado!, // Usamos el operador de aserción no nula
          comentariosController.text.isEmpty
              ? null
              : comentariosController.text,
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
      } catch (e) {
        if (!context.mounted) return;

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
    if (inmueble.id == null) return;

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
      if (inmueble.id != null) {
        // Mostrar indicador de progreso
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

        final notifier = ref.read(
          inmuebleDetalleProvider(inmueble.id!).notifier,
        );
        await notifier.actualizarEstado(
          InmuebleDetailScreen.estadoEnNegociacion,
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
              builder: (context) => RegistrarVentaScreen(inmueble: inmueble),
            ),
          );

          if (result == true && inmueble.id != null && context.mounted) {
            ref.invalidate(inmuebleDetalleProvider(inmueble.id!));
          }
        }
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cambiar estado de ${inmueble.nombre} a $operationType: ${e.toString().split('\n').first}',
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
    if (inmueble.id == null) return;

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
      if (inmueble.id != null) {
        // Mostrar indicador de progreso
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

        final notifier = ref.read(
          inmuebleDetalleProvider(inmueble.id!).notifier,
        );
        await notifier.actualizarEstado(estadoFinal);

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
      }
    } catch (e) {
      if (!context.mounted) return;

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

import 'package:intl/intl.dart';
import '../../utils/applogger.dart';
import 'detalles_ventas_screen.dart';
import 'detalle_contrato_screen.dart';
import 'package:flutter/material.dart';
import '../../models/venta_model.dart';
import '../../models/ventas_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../models/estados_venta.dart';
import 'registrar_nueva_venta_screen.dart';
import '../../providers/venta_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Añadida importación de AppColors

class ListaVentasScreen extends ConsumerStatefulWidget {
  const ListaVentasScreen({super.key});

  @override
  ConsumerState<ListaVentasScreen> createState() => _ListaVentasScreenState();
}

class _ListaVentasScreenState extends ConsumerState<ListaVentasScreen> {
  // Mapa para control de errores y evitar duplicados
  final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _intervaloMinimoErrores = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    // Cargar ventas al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(ventasStateProvider.notifier).cargarVentas();
      } catch (e, stackTrace) {
        if (mounted) {
          _registrarErrorControlado(
            'carga_inicial_error',
            'Error al cargar las ventas inicialmente',
            e,
            stackTrace,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ventasState = ref.watch(ventasStateProvider);

    return AppScaffold(
      title: 'Ventas',
      currentRoute: '/ventas',
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filtrar ventas',
          onPressed: () => _mostrarDialogoFiltros(context, ref),
        ),
        // IconButton(
        //   icon: const Icon(Icons.bar_chart),
        //   tooltip: 'Ver reportes',
        //   onPressed: () => Navigator.pushNamed(context, '/ventas/reportes'),
        // ),
      ],
      body: Column(
        children: [
          // Barra de búsqueda
          _construirBarraBusqueda(context, ref, ventasState),

          // Filtros aplicados
          if (ventasState.filtroFechas != null ||
              ventasState.filtroEstado != null)
            _construirChipsFiltros(context, ref, ventasState),

          // Lista de ventas
          Expanded(child: _construirContenidoVentas(context, ref, ventasState)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarARegistrarVenta(context, ref),
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: 'Registrar Nueva Venta', // Tooltip para accesibilidad
        child: const Icon(Icons.add),
      ),
    );
  }

  // Nuevo método para manejar los diferentes estados de la lista de ventas
  Widget _construirContenidoVentas(
    BuildContext context,
    WidgetRef ref,
    VentasState ventasState,
  ) {
    if (ventasState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ventasState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: ${ventasState.errorMessage}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  () => ref.read(ventasStateProvider.notifier).cargarVentas(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (ventasState.ventasFiltradas.isEmpty) {
      return const _EstadoVacio();
    }

    return _construirListaVentas(context, ref, ventasState.ventasFiltradas);
  }

  Widget _construirBarraBusqueda(
    BuildContext context,
    WidgetRef ref,
    VentasState ventasState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar ventas...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed:
                () => ref
                    .read(ventasStateProvider.notifier)
                    .actualizarBusqueda(''),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged:
            (value) => ref
                .read(ventasStateProvider.notifier)
                .actualizarBusqueda(value),
      ),
    );
  }

  Widget _construirListaVentas(
    BuildContext context,
    WidgetRef ref,
    List<Venta> ventas,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: ventas.length,
      itemBuilder: (context, index) {
        final venta = ventas[index];
        return _VentaTarjeta(
          venta: venta,
          onTap: () => _navegarADetalleVenta(context, venta.id!),
        );
      },
    );
  }

  Widget _construirChipsFiltros(
    BuildContext context,
    WidgetRef ref,
    VentasState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (state.filtroFechas != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(
                  '${DateFormat('dd/MM/yyyy').format(state.filtroFechas!.start)} - '
                  '${DateFormat('dd/MM/yyyy').format(state.filtroFechas!.end)}',
                ),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted:
                    () => ref
                        .read(ventasStateProvider.notifier)
                        .aplicarFiltroFechas(null),
                backgroundColor: Colors.blue.shade100,
              ),
            ),
          if (state.filtroEstado != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(_obtenerNombreEstado(state.filtroEstado!)),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted:
                    () => ref
                        .read(ventasStateProvider.notifier)
                        .aplicarFiltroEstado(null),
                backgroundColor: Colors.green.shade100,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: const Text('Limpiar filtros'),
              onPressed:
                  () => ref.read(ventasStateProvider.notifier).limpiarFiltros(),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoFiltros(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filtrar ventas'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.date_range),
                    title: const Text('Filtrar por fechas'),
                    onTap: () async {
                      Navigator.pop(context);
                      final fechaActual = DateTime.now();

                      // Guardar el contexto en una variable local o cerrar el diálogo antes
                      // de iniciar una operación asíncrona
                      if (!mounted) return; // Verificar mounted antes de async

                      final fechas = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: fechaActual,
                        initialDateRange: DateTimeRange(
                          start: fechaActual.subtract(const Duration(days: 30)),
                          end: fechaActual,
                        ),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Colors.teal,
                                onPrimary: Colors.white,
                                surface: Colors.teal.shade50,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      // Verificar que el widget siga montado después de la operación async
                      if (fechas != null && mounted) {
                        ref
                            .read(ventasStateProvider.notifier)
                            .aplicarFiltroFechas(fechas);
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.filter_list),
                    title: const Text('Filtrar por estado'),
                    onTap: () {
                      Navigator.pop(context);
                      _mostrarDialogoFiltroEstados(context, ref);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  void _mostrarDialogoFiltroEstados(BuildContext context, WidgetRef ref) {
    // Comprobar que el widget sigue montado antes de mostrar el diálogo
    if (!mounted) return;

    final contextLocal = context; // Guardar el contexto en una variable local

    showDialog(
      context: contextLocal,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Seleccionar estado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.pending, color: Colors.orange),
                  title: const Text('En proceso'),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    // Usar el contexto del diálogo o verificar mounted
                    if (mounted) {
                      ref
                          .read(ventasStateProvider.notifier)
                          .aplicarFiltroEstado('7');
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Completada'),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    // Usar el contexto del diálogo o verificar mounted
                    if (mounted) {
                      ref
                          .read(ventasStateProvider.notifier)
                          .aplicarFiltroEstado('8');
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: const Text('Cancelada'),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    // Usar el contexto del diálogo o verificar mounted
                    if (mounted) {
                      ref
                          .read(ventasStateProvider.notifier)
                          .aplicarFiltroEstado('9');
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  void _navegarADetalleVenta(BuildContext context, int idVenta) {
    // Primero, obtenemos la venta para determinar el tipo de operación
    final ventasState = ref.read(ventasStateProvider);
    final venta = ventasState.ventasFiltradas.firstWhere(
      (v) => v.id == idVenta,
      orElse:
          () => Venta(
            idCliente: 0,
            idInmueble: 0,
            fechaVenta: DateTime.now(),
            ingreso: 0,
            comisionProveedores: 0,
            utilidadBruta: 0,
            utilidadNeta: 0,
            idEstado: 0,
          ),
    );

    // Si es de tipo renta, navegamos a la pantalla de detalles de contrato
    if (venta.tipoOperacion?.toLowerCase() == 'renta') {
      // ¡IMPORTANTE! Usamos el ID original del contrato, no el ID de la venta
      final idContratoReal = venta.contratoRentaId;

      if (idContratoReal != null) {
        AppLogger.info('Navegando a detalle de contrato ID: $idContratoReal');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => DetalleContratoScreen(idContrato: idContratoReal),
          ),
        ).then((value) {
          // Actualizar datos cuando regresemos
          if (mounted && value == true) {
            ref.read(ventasStateProvider.notifier).cargarVentas();
          }
        });
      } else {
        // Mostrar mensaje de error si no se puede obtener el ID del contrato
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: No se puede abrir este contrato. ID no encontrado.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Si es una venta normal, seguimos el comportamiento anterior
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetallesVentaScreen(idVenta: idVenta),
        ),
      ).then((value) {
        // Actualizar datos cuando regresemos
        if (mounted && value == true) {
          ref.read(ventasStateProvider.notifier).cargarVentas();
        }
      });
    }
  }

  void _navegarARegistrarVenta(BuildContext context, WidgetRef ref) {
    // Creamos un método local que capture el BuildContext actual
    void mostrarMensajeExito() {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Operación registrada exitosamente. Actualizando lista...',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistrarNuevaVentaScreen(),
      ),
    ).then((value) {
      // Verificar que el widget siga montado después de la navegación
      if (!mounted) return;

      // Si retornamos true, significa que se registró una venta correctamente
      if (value == true) {
        // Primero invalidamos los providers para forzar una recarga completa
        ref.invalidate(ventasProvider);
        ref.invalidate(ventasEstadisticasGeneralProvider);

        // Luego, realizamos una recarga controlada de las ventas
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Cargar ventas explícitamente para evitar estado de carga infinita
            ref.read(ventasStateProvider.notifier).cargarVentas();
          }
        });

        // Mostrar confirmación visual al usuario
        mostrarMensajeExito();
      }
    });
  }

  String _obtenerNombreEstado(String idEstado) {
    return EstadosVenta.obtenerNombre(idEstado);
  }

  // Registrar error controlando duplicados
  void _registrarErrorControlado(
    String codigo,
    String mensaje,
    dynamic error,
    StackTrace stackTrace,
  ) {
    final errorKey = codigo;
    final ahora = DateTime.now();

    // Evitar errores duplicados en corto periodo
    if (_ultimosErrores.containsKey(errorKey) &&
        ahora.difference(_ultimosErrores[errorKey]!) <
            _intervaloMinimoErrores) {
      return;
    }

    // Registrar error
    _ultimosErrores[errorKey] = ahora;

    // Limitar tamaño del mapa para evitar fugas de memoria
    if (_ultimosErrores.length > 10) {
      final entradaAntigua =
          _ultimosErrores.entries
              .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
              .key;
      _ultimosErrores.remove(entradaAntigua);
    }

    AppLogger.error('$mensaje: ${error.toString()}', error, stackTrace);
  }

  @override
  void dispose() {
    // Limpiar recursos y memoria
    _ultimosErrores.clear();

    // Consideración: invalidar providers específicos de esta pantalla
    // cuando ya no sean necesarios para liberar recursos
    if (mounted) {
      // Solo invalidamos providers que son específicos de esta pantalla
      // y que no se necesitarán inmediatamente después
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Esto se ejecuta después de que el widget se ha desmontado
        // para evitar errores de "setState() called after dispose()"
        try {
          ref.invalidate(ventasEstadisticasGeneralProvider);
        } catch (e) {
          // Ignoramos errores aquí ya que estamos en dispose
        }
      });
    }

    super.dispose();
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No hay ventas disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra tu primera venta con el botón +',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _VentaTarjeta extends StatelessWidget {
  final Venta venta;
  final VoidCallback onTap;

  const _VentaTarjeta({required this.venta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTipoOperacionBadge(venta.tipoOperacion ?? 'venta'),
                  _buildEstadoBadge(venta.idEstado),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                venta.nombreInmueble ?? 'Inmueble sin nombre',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Cliente: ${venta.nombreCliente ?? ''} ${venta.apellidoCliente ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatCurrency.format(venta.ingreso),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatDate.format(venta.fechaVenta),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoOperacionBadge(String tipo) {
    bool esVenta = tipo.toLowerCase() == 'venta';
    bool esRenta = tipo.toLowerCase() == 'renta';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            esVenta
                ? Colors.blue[100]
                : esRenta
                ? Colors.amber[100]
                : Colors.purple[100], // Por si hay algún otro tipo
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tipo.toUpperCase(),
        style: TextStyle(
          color:
              esVenta
                  ? Colors.blue[800]
                  : esRenta
                  ? Colors.amber[800]
                  : Colors.purple[800],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(int idEstado) {
    Color backgroundColor;
    Color textColor;
    String estado = EstadosVenta.obtenerNombre(idEstado.toString());

    switch (idEstado) {
      case 7: // EN_PROCESO
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 8: // COMPLETADA
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 9: // CANCELADA
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

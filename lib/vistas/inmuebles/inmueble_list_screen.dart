import 'add_inmueble_screen.dart';
import 'inmueble_edit_screen.dart';
import '../../utils/applogger.dart';
import 'inmueble_detalle_screen.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import '../../models/inmueble_model.dart';
import 'components/inmueble_grid_view.dart';
import 'components/inmueble_error_state.dart';
import 'components/inmueble_empty_state.dart';
import '../../providers/inmueble_providers.dart';
import '../../widgets/inmueble_filtro_avanzado.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/app_colors.dart'; // Importar AppColors

// Provider para controlar la visibilidad de los filtros avanzados
final filtrosAvanzadosVisiblesProvider = StateProvider<bool>((ref) => false);

class InmuebleListScreen extends ConsumerWidget {
  const InmuebleListScreen({super.key});

  // Constantes para los estados del inmueble
  static const int estadoNoDisponible = 2;
  static const int estadoDisponible = 3;
  static const int estadoVendido = 4;
  static const int estadoRentado = 5;
  static const int estadoEnNegociacion = 6;

  // Mapeo de estados a nombres para UI
  static const Map<int, String> estadosInmueble = {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mostrarInactivos = ref.watch(mostrarInactivosProvider);

    return AppScaffold(
      title: 'Inmuebles',
      currentRoute: '/inmuebles',
      actions: _buildAppBarActions(context, ref, mostrarInactivos),
      body: Stack(
        children: [
          Column(
            children: [
              // Header con FilterChips para tipo de operación
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 12.0,
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final filtros = ref.watch(filtrosInmuebleProvider);
                    final notifier = ref.read(filtrosInmuebleProvider.notifier);
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildOperacionFilterChip(
                            label: 'Todos',
                            targetOperacion: null,
                            currentOperacion: filtros.operacion,
                            notifier: notifier,
                          ),
                          _buildOperacionFilterChip(
                            label: 'Renta',
                            targetOperacion: 'renta',
                            currentOperacion: filtros.operacion,
                            notifier: notifier,
                          ),
                          _buildOperacionFilterChip(
                            label: 'Venta',
                            targetOperacion: 'venta',
                            currentOperacion: filtros.operacion,
                            notifier: notifier,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Sección de Filtros Avanzados
              Consumer(
                builder: (context, ref, child) {
                  final esVisible = ref.watch(filtrosAvanzadosVisiblesProvider);
                  if (!esVisible) {
                    return const SizedBox.shrink();
                  }
                  return Card(
                    // Envolver en una Card para mejor separación visual
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        8.0,
                      ), // Reducir padding interno
                      child: InmuebleFiltroAvanzado(
                        onFiltrar: ({
                          String? tipo,
                          String? operacion,
                          double? precioMin,
                          double? precioMax,
                          String? ciudad,
                          int? idEstado,
                          double? margenMin,
                        }) {
                          ref
                              .read(filtrosInmuebleProvider.notifier)
                              .actualizarFiltro(
                                tipo: tipo,
                                operacion: operacion,
                                precioMin: precioMin,
                                precioMax: precioMax,
                                ciudad: ciudad,
                                idEstado: idEstado,
                                margenMin: margenMin,
                              );
                        },
                        onLimpiar: () {
                          ref
                              .read(filtrosInmuebleProvider.notifier)
                              .limpiarFiltros();
                        },
                      ),
                    ),
                  );
                },
              ),
              // Indicador de estado
              _buildEstadoIndicator(mostrarInactivos),
              // Lista de inmuebles
              Expanded(child: _buildListado(context, ref)),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: _buildFabButton(context, ref),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    WidgetRef ref,
    bool mostrarInactivos,
  ) {
    return [
      // Botón para mostrar/ocultar filtros avanzados
      IconButton(
        icon: Icon(
          ref.watch(filtrosAvanzadosVisiblesProvider)
              ? Icons.filter_alt_off_outlined
              : Icons.filter_alt_outlined,
        ),
        tooltip: 'Filtros avanzados',
        onPressed: () {
          ref.read(filtrosAvanzadosVisiblesProvider.notifier).state =
              !ref.read(filtrosAvanzadosVisiblesProvider);
        },
      ),
      // Botón para alternar entre activos e inactivos
      IconButton(
        icon: Icon(
          mostrarInactivos
              ? Icons.person
              : Icons.person_off, // Icono actualizado
          color:
              mostrarInactivos ? AppColors.acento : null, // Color actualizado
        ),
        tooltip: mostrarInactivos ? 'Mostrar activos' : 'Mostrar inactivos',
        onPressed: () {
          ref.read(mostrarInactivosProvider.notifier).state = !mostrarInactivos;
        },
      ),
      // Botón para refrescar datos
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Actualizar',
        onPressed: () => _recargarDatosCompletos(ref),
      ),
    ];
  }

  // Nuevo método para recargar datos e imágenes completamente
  void _recargarDatosCompletos(WidgetRef ref) {
    AppLogger.info('Recargando datos completos de inmuebles');
    // Invalidar primero las imágenes para que se recarguen
    ref.invalidate(imagenesPrincipalesProvider);
    ref.invalidate(rutasImagenesPrincipalesProvider);
    // Luego invalidar los datos de inmuebles
    ref.invalidate(inmueblesProvider);
    ref.invalidate(inmueblesBusquedaStateProvider);
  }

  Widget _buildEstadoIndicator(bool mostrarInactivos) {
    // Se devuelve un Container vacío para ocultar el indicador
    return const SizedBox.shrink();
  }

  Widget _buildFabButton(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      backgroundColor: Theme.of(context).primaryColor,
      tooltip: 'Agregar inmueble',
      onPressed: () => _navegarAgregarInmueble(context, ref),
      child: const Icon(Icons.add),
    );
  }

  Widget _buildListado(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingProvider);
    final errorMessage = ref.watch(errorMessageProvider);
    final inmuebles = ref.watch(inmueblesBuscadosProvider);

    // Cargar imágenes principales inmediatamente cuando tenemos inmuebles
    if (!isLoading && inmuebles.isNotEmpty) {
      // Uso un delay mínimo para asegurar que se ejecute después de que el frame actual esté listo
      Future.microtask(() => _cargarImagenesPrincipales(ref, inmuebles));
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      AppLogger.error(
        'Error al cargar inmuebles',
        errorMessage,
        StackTrace.current,
      );
      return InmuebleErrorState(
        errorMessage: errorMessage,
        onRetry: () => _recargarDatosCompletos(ref),
      );
    }

    if (inmuebles.isEmpty) {
      return InmuebleEmptyState(
        isFiltering: ref.read(filtrosInmuebleProvider).hayFiltrosAplicados,
        onLimpiarFiltros: () {
          ref.read(filtrosInmuebleProvider.notifier).limpiarFiltros();
        },
      );
    }

    final imagenesPrincipales = ref.watch(imagenesPrincipalesProvider);
    final rutasImagenes = ref.watch(rutasImagenesPrincipalesProvider);

    return InmuebleGridView(
      inmuebles: inmuebles,
      imagenesPrincipales: imagenesPrincipales,
      rutasImagenesPrincipales: rutasImagenes,
      onTapInmueble:
          (inmueble) => _navegarDetalleInmueble(context, ref, inmueble),
      onEditInmueble:
          (inmueble) => _navegarEditarInmueble(context, ref, inmueble),
      onInactivateInmueble:
          (inmueble) => _cambiarEstadoInmueble(context, ref, inmueble),
      renderizarBotonEstado: _renderizarBotonEstado,
    );
  }

  Future<void> _cargarImagenesPrincipales(
    WidgetRef ref,
    List<Inmueble> inmuebles,
  ) async {
    try {
      AppLogger.info(
        'Cargando imágenes principales para ${inmuebles.length} inmuebles',
      );

      // Cargar las imágenes principales
      await ref
          .read(imagenesPrincipalesProvider.notifier)
          .cargarImagenesPrincipales(inmuebles);

      // Cargar las rutas de las imágenes
      await ref
          .read(rutasImagenesPrincipalesProvider.notifier)
          .cargarRutasImagenes(ref.read(imagenesPrincipalesProvider));

      AppLogger.info('Imágenes principales cargadas exitosamente');
    } catch (e, stack) {
      AppLogger.error('Error al cargar imágenes principales', e, stack);
    }
  }

  Widget _renderizarBotonEstado(Inmueble inmueble, VoidCallback onPressed) {
    final estadoActual = inmueble.idEstado;
    final nombreEstado = estadosInmueble[estadoActual] ?? 'Desconocido';
    final colorEstado = coloresEstados[estadoActual] ?? Colors.grey;

    return Tooltip(
      message: 'Cambiar estado del inmueble',
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.change_circle, color: Colors.white),
        label: Text(
          'Estado: $nombreEstado',
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(backgroundColor: colorEstado),
      ),
    );
  }

  Future<void> _navegarAgregarInmueble(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AgregarInmuebleScreen()),
      );

      if (result == true) {
        _recargarDatosCompletos(ref);
      }
    } catch (e, stack) {
      AppLogger.error(
        'Error al navegar a pantalla de agregar inmueble',
        e,
        stack,
      );
      if (context.mounted) {
        _mostrarSnackbarError(context, 'Error al abrir formulario: $e');
      }
    }
  }

  Future<void> _navegarDetalleInmueble(
    BuildContext context,
    WidgetRef ref,
    Inmueble inmueble,
  ) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => InmuebleDetailScreen(
                inmuebleInicial: inmueble,
                onEdit: () => _navegarEditarInmueble(context, ref, inmueble),
                onDelete: () => _cambiarEstadoInmueble(context, ref, inmueble),
              ),
        ),
      );

      if (result == true) {
        _recargarDatosCompletos(ref);
      }
    } catch (e, stack) {
      AppLogger.error('Error al navegar a detalles de inmueble', e, stack);
      if (context.mounted) {
        _mostrarSnackbarError(context, 'Error al abrir detalles: $e');
      }
    }
  }

  Future<void> _navegarEditarInmueble(
    BuildContext context,
    WidgetRef ref,
    Inmueble inmueble,
  ) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InmuebleEditScreen(inmueble: inmueble),
        ),
      );

      if (result == true && context.mounted) {
        _recargarDatosCompletos(ref);
      }
    } catch (e, stack) {
      AppLogger.error('Error al navegar a edición de inmueble', e, stack);
      if (context.mounted) {
        _mostrarSnackbarError(context, 'Error al abrir editor: $e');
      }
    }
  }

  Future<void> _cambiarEstadoInmueble(
    BuildContext context,
    WidgetRef ref,
    Inmueble inmueble,
  ) async {
    if (inmueble.id == null) {
      _mostrarSnackbarError(context, 'El inmueble no tiene ID válido');
      return;
    }

    try {
      AppLogger.info('Cambiando estado del inmueble ID: ${inmueble.id}');

      final nuevoEstado = await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Seleccionar nuevo estado'),
            children:
                estadosInmueble.entries.map((entry) {
                  return SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, entry.key);
                    },
                    child: Text(entry.value),
                  );
                }).toList(),
          );
        },
      );

      if (nuevoEstado == null || !context.mounted) return;

      final inmuebleActualizado = Inmueble(
        id: inmueble.id,
        nombre: inmueble.nombre,
        idDireccion: inmueble.idDireccion,
        montoTotal: inmueble.montoTotal,
        idEstado: nuevoEstado,
        idCliente: inmueble.idCliente,
        idEmpleado: inmueble.idEmpleado,
        tipoInmueble: inmueble.tipoInmueble,
        tipoOperacion: inmueble.tipoOperacion,
        precioVenta: inmueble.precioVenta,
        precioRenta: inmueble.precioRenta,
        caracteristicas: inmueble.caracteristicas,
        calle: inmueble.calle,
        numero: inmueble.numero,
        colonia: inmueble.colonia,
        ciudad: inmueble.ciudad,
        estadoGeografico: inmueble.estadoGeografico,
        codigoPostal: inmueble.codigoPostal,
        referencias: inmueble.referencias,
        fechaRegistro: inmueble.fechaRegistro,
        costoCliente: inmueble.costoCliente,
        costoServicios: inmueble.costoServicios,
        comisionAgencia: inmueble.comisionAgencia,
        comisionAgente: inmueble.comisionAgente,
        margenUtilidad: inmueble.margenUtilidad,
      );

      final inmuebleController = ref.read(inmuebleControllerProvider);
      await inmuebleController.updateInmueble(inmuebleActualizado);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Inmueble actualizado a ${estadosInmueble[nuevoEstado]}',
            ),
            backgroundColor: coloresEstados[nuevoEstado] ?? Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _recargarDatosCompletos(ref);
    } catch (e, stack) {
      AppLogger.error('Error al cambiar estado del inmueble', e, stack);
      if (context.mounted) {
        _mostrarSnackbarError(context, 'Error al cambiar estado: $e');
      }
    }
  }

  void _mostrarSnackbarError(BuildContext context, String mensaje) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildOperacionFilterChip({
    required String label,
    required String? targetOperacion,
    required String? currentOperacion,
    required FiltrosInmuebleNotifier notifier,
  }) {
    final isSelected = currentOperacion == targetOperacion;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool value) {
          // Si el chip se está seleccionando (value es true), actualiza la operación.
          // Si el chip se está deseleccionando (value es false),
          // la operación vuelve a null (Todos).
          notifier.actualizarFiltro(operacion: value ? targetOperacion : null);
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor:
            Colors
                .teal
                .shade300, // Usando un color similar al de RegistrarNuevaVentaScreen
        checkmarkColor: isSelected ? Colors.white : Colors.black,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
    );
  }
}

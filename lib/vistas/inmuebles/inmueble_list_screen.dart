import 'package:flutter/material.dart';
import 'package:inmobiliaria/widgets/app_scaffold.dart';
import 'package:inmobiliaria/models/inmueble_model.dart';
import 'package:inmobiliaria/controllers/inmueble_controller.dart';
import 'package:inmobiliaria/models/inmueble_list_view_model.dart';
import 'package:inmobiliaria/widgets/inmueble_filtro_avanzado.dart';
import 'package:inmobiliaria/vistas/inmuebles/add_inmueble_screen.dart';
import 'package:inmobiliaria/vistas/inmuebles/inmueble_edit_screen.dart';
import 'package:inmobiliaria/vistas/inmuebles/inmueble_detail_screen.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/inmueble_grid_view.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/inmueble_empty_state.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/inmueble_error_state.dart';
import 'package:inmobiliaria/services/image_service.dart'; // Cambiado a la ruta correcta

class InmuebleListScreen extends StatefulWidget {
  const InmuebleListScreen({super.key});

  @override
  State<InmuebleListScreen> createState() => _InmuebleListScreenState();
}

class _InmuebleListScreenState extends State<InmuebleListScreen> {
  late final InmuebleListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = InmuebleListViewModel(
      inmuebleController: InmuebleController(),
      imageService: ImageService(),
    );
    _viewModel.cargarInmuebles();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Inmuebles',
      currentRoute: '/inmuebles',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _viewModel.cargarInmuebles,
          tooltip: 'Actualizar',
        ),
      ],
      body: Column(
        children: [
          // Widget de filtros avanzados
          InmuebleFiltroAvanzado(
            onFiltrar: _viewModel.filtrarInmuebles,
            onLimpiar: _viewModel.limpiarFiltros,
          ),

          // Indicador de filtros activos
          ValueListenableBuilder(
            valueListenable: _viewModel.isFilteringNotifier,
            builder: (context, isFiltering, _) {
              if (isFiltering && !_viewModel.isLoadingNotifier.value) {
                return Container(
                  color: Colors.amber.shade100,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Text(
                        'Filtros aplicados',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${_viewModel.inmueblesFiltradosNotifier.value.length} resultados',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Contenido principal
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _viewModel.cargarInmuebles,
                  child: _buildBody(),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: () => _navegarAgregarInmueble(context),
                    tooltip: 'Agregar inmueble',
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return ValueListenableBuilder(
      valueListenable: _viewModel.isLoadingNotifier,
      builder: (context, isLoading, _) {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ValueListenableBuilder(
          valueListenable: _viewModel.errorMessageNotifier,
          builder: (context, errorMessage, _) {
            if (errorMessage != null) {
              return InmuebleErrorState(
                errorMessage: errorMessage,
                onRetry: _viewModel.cargarInmuebles,
              );
            }

            return ValueListenableBuilder(
              valueListenable: _viewModel.inmueblesFiltradosNotifier,
              builder: (context, inmueblesFiltrados, _) {
                if (inmueblesFiltrados.isEmpty) {
                  return ValueListenableBuilder(
                    valueListenable: _viewModel.isFilteringNotifier,
                    builder: (context, isFiltering, _) {
                      return InmuebleEmptyState(
                        isFiltering: isFiltering,
                        onLimpiarFiltros: _viewModel.limpiarFiltros,
                      );
                    },
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InmuebleGridView(
                    inmuebles: inmueblesFiltrados,
                    imagenesPrincipales:
                        _viewModel.imagenesPrincipalesNotifier.value,
                    rutasImagenesPrincipales:
                        _viewModel.rutasImagenesPrincipalesNotifier.value,
                    onTapInmueble:
                        (inmueble) =>
                            _navegarDetalleInmueble(context, inmueble),
                    onEditInmueble:
                        (inmueble) => _navegarEditarInmueble(context, inmueble),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _navegarAgregarInmueble(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AgregarInmuebleScreen()),
    );

    if (!mounted) return;
    if (result == true) {
      _viewModel.cargarInmuebles();
    }
  }

  Future<void> _navegarDetalleInmueble(
    BuildContext context,
    Inmueble inmueble,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => InmuebleDetailScreen(
              inmueble: inmueble,
              onEdit: () {
                Navigator.pop(context);
                _navegarEditarInmueble(context, inmueble);
              },
              onDelete: () async {
                final contextCurrent = context;
                final bool success = await _viewModel.cambiarEstadoInmueble(
                  inmueble,
                  context,
                );
                if (success && contextCurrent.mounted) {
                  Navigator.pop(contextCurrent, true);
                }
              },
            ),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      _viewModel.cargarInmuebles();
    }
  }

  Future<void> _navegarEditarInmueble(
    BuildContext context,
    Inmueble inmueble,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InmuebleEditScreen(inmueble: inmueble),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      _viewModel.cargarInmuebles();
    }
  }
}

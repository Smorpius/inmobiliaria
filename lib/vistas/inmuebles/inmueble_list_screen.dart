import 'package:flutter/material.dart';
import 'package:inmobiliaria/widgets/app_scaffold.dart';
import 'package:inmobiliaria/models/inmueble_model.dart';
import 'package:inmobiliaria/services/image_service.dart';
import 'package:inmobiliaria/controllers/inmueble_controller.dart';
import 'package:inmobiliaria/models/inmueble_list_view_model.dart';
import 'package:inmobiliaria/widgets/inmueble_filtro_avanzado.dart';
import 'package:inmobiliaria/vistas/inmuebles/add_inmueble_screen.dart';
import 'package:inmobiliaria/vistas/inmuebles/inmueble_edit_screen.dart';
import 'package:inmobiliaria/vistas/inmuebles/inmueble_detail_screen.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/inmueble_grid_view.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/inmueble_empty_state.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/inmueble_error_state.dart';

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
        // Nuevo botón para mostrar inmuebles inactivos
        ValueListenableBuilder(
          valueListenable: _viewModel.mostrarInactivosNotifier,
          builder: (context, mostrarInactivos, child) {
            return IconButton(
              icon: Icon(
                mostrarInactivos ? Icons.visibility_off : Icons.visibility,
                color: mostrarInactivos ? Colors.red : null,
              ),
              onPressed: _viewModel.toggleMostrarInactivos,
              tooltip: mostrarInactivos ? 'Mostrar todos' : 'Mostrar inactivos',
            );
          },
        ),
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

          // Indicador de filtros activos o modo inactivos
          ValueListenableBuilder(
            valueListenable: _viewModel.isFilteringNotifier,
            builder: (context, isFiltering, _) {
              // Mostrar banner de inmuebles inactivos si está activado ese modo
              return ValueListenableBuilder(
                valueListenable: _viewModel.mostrarInactivosNotifier,
                builder: (context, mostrarInactivos, _) {
                  if (mostrarInactivos) {
                    return Container(
                      color: Colors.red.shade100,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.visibility_off, color: Colors.red[800]),
                          const SizedBox(width: 8),
                          Text(
                            'INMUEBLES INACTIVOS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[800],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_viewModel.inmueblesFiltradosNotifier.value.length} resultados',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    );
                  } else if (isFiltering &&
                      !_viewModel.isLoadingNotifier.value) {
                    // Si hay filtros activos pero no es modo inactivos
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
                  return const SizedBox.shrink(); // Sin filtros ni modo inactivos
                },
              );
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
                  // Personalizar mensaje de vacío para modo de inactivos
                  return ValueListenableBuilder(
                    valueListenable: _viewModel.mostrarInactivosNotifier,
                    builder: (context, mostrarInactivos, _) {
                      if (mostrarInactivos) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_off,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hay inmuebles inactivos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Todos los inmuebles están disponibles actualmente.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Estado vacío normal
                      return ValueListenableBuilder(
                        valueListenable: _viewModel.isFilteringNotifier,
                        builder: (context, isFiltering, _) {
                          return InmuebleEmptyState(
                            isFiltering: isFiltering,
                            onLimpiarFiltros: _viewModel.limpiarFiltros,
                          );
                        },
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
                    onInactivateInmueble:
                        (inmueble) => _inactivarInmueble(inmueble),
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

  // Método para manejar la inactivación de inmuebles
  void _inactivarInmueble(Inmueble inmueble) async {
    final success = await _viewModel.cambiarEstadoInmueble(inmueble, context);

    // Si fue exitoso, recargar la lista para reflejar los cambios
    if (success && mounted) {
      _viewModel.cargarInmuebles();
    }
  }
}

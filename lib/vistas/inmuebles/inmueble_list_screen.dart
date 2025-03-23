import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/models/inmueble_model.dart';
import 'package:inmobiliaria/providers/inmueble_providers.dart';
import 'package:inmobiliaria/widgets/inmueble_filtro_avanzado.dart';
import 'package:inmobiliaria/vistas/inmuebles/add_inmueble_screen.dart';
import 'package:inmobiliaria/vistas/inmuebles/inmueble_edit_screen.dart';
import 'package:inmobiliaria/vistas/inmuebles/inmueble_detail_screen.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/inmueble_grid_view.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/inmueble_error_state.dart';
import 'package:inmobiliaria/vistas/inmuebles/components/inmueble_empty_state.dart';

class InmuebleListScreen extends ConsumerWidget {
  const InmuebleListScreen({super.key});

  // Constantes para los estados del inmueble usando lowerCamelCase
  static const int estadoNoDisponible = 2;
  static const int estadoDisponible = 3;
  static const int estadoVendido = 4;
  static const int estadoRentado = 5;
  static const int estadoEnNegociacion = 6;

  // Mapeo de estados a nombres para UI
  static const Map<int, String> estadosInmueble = {
    estadoNoDisponible: 'No disponible',
    estadoDisponible: 'Disponible',
    estadoVendido: 'Vendido',
    estadoRentado: 'Rentado',
    estadoEnNegociacion: 'En negociación',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mostrarInactivos = ref.watch(mostrarInactivosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inmuebles'),
        actions: [
          // Botón de filtros avanzados
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtros avanzados',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return InmuebleFiltroAvanzado(
                    onFiltrar: ({
                      String? tipo,
                      String? operacion,
                      double? precioMin,
                      double? precioMax,
                      String? ciudad,
                      int? idEstado,
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
                          );
                      Navigator.pop(context);
                    },
                    onLimpiar: () {
                      ref
                          .read(filtrosInmuebleProvider.notifier)
                          .limpiarFiltros();
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
          // Botón para alternar entre activos e inactivos
          IconButton(
            icon: Icon(
              mostrarInactivos ? Icons.visibility_off : Icons.visibility,
              color: mostrarInactivos ? Colors.red : Colors.green,
            ),
            tooltip: mostrarInactivos ? 'Mostrar activos' : 'Mostrar inactivos',
            onPressed: () {
              ref.read(mostrarInactivosProvider.notifier).state =
                  !mostrarInactivos;
            },
          ),
          // Botón para refrescar datos
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(inmueblesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de modo de visualización
          Container(
            color:
                mostrarInactivos ? Colors.red.shade100 : Colors.green.shade100,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  mostrarInactivos ? Icons.visibility_off : Icons.visibility,
                  color: mostrarInactivos ? Colors.red[800] : Colors.green[800],
                ),
                const SizedBox(width: 8),
                Text(
                  mostrarInactivos
                      ? 'INMUEBLES INACTIVOS'
                      : 'INMUEBLES ACTIVOS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        mostrarInactivos ? Colors.red[800] : Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          // Lista de inmuebles
          Expanded(child: _buildListado(context, ref)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: 'Agregar inmueble',
        onPressed: () => _navegarAgregarInmueble(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListado(BuildContext context, WidgetRef ref) {
    final inmueblesFiltrados = ref.watch(inmueblesBuscadosProvider);

    return inmueblesFiltrados.when(
      data: (inmuebles) {
        if (inmuebles.isEmpty) {
          return InmuebleEmptyState(
            isFiltering: true,
            onLimpiarFiltros: () {
              ref.read(filtrosInmuebleProvider.notifier).limpiarFiltros();
            },
          );
        }

        final imagenesPrincipales = ref.watch(imagenesPrincipalesProvider);
        final rutasImagenes = ref.watch(rutasImagenesPrincipalesProvider);

        // Asegurar que se carguen las imágenes principales
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(imagenesPrincipalesProvider.notifier)
              .cargarImagenesPrincipales(inmuebles);
          ref
              .read(rutasImagenesPrincipalesProvider.notifier)
              .cargarRutasImagenes(imagenesPrincipales);
        });

        return InmuebleGridView(
          inmuebles: inmuebles,
          imagenesPrincipales: imagenesPrincipales,
          rutasImagenesPrincipales: rutasImagenes,
          onTapInmueble:
              (inmueble) => _navegarDetalleInmueble(context, ref, inmueble),
          onEditInmueble:
              (inmueble) => _navegarEditarInmueble(context, ref, inmueble),
          onInactivateInmueble:
              (inmueble) => _inactivarInmueble(context, ref, inmueble),
          // Personalización del botón de estado
          renderizarBotonEstado: (inmueble, onPressed) {
            final isInactivo = inmueble.idEstado == estadoNoDisponible;
            return ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(isInactivo ? Icons.check_circle : Icons.remove_circle),
              label: Text(isInactivo ? 'Activar' : 'Desactivar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isInactivo ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => InmuebleErrorState(
            errorMessage: error.toString(),
            onRetry: () => ref.invalidate(inmueblesProvider),
          ),
    );
  }

  /// Navega a la pantalla para agregar un nuevo inmueble
  Future<void> _navegarAgregarInmueble(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AgregarInmuebleScreen()),
    );

    if (result == true) {
      ref.invalidate(inmueblesProvider);
    }
  }

  /// Navega a la pantalla de detalles del inmueble
  Future<void> _navegarDetalleInmueble(
    BuildContext context,
    WidgetRef ref,
    Inmueble inmueble,
  ) async {
    final bool isInactivo = inmueble.idEstado == estadoNoDisponible;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => InmuebleDetailScreen(
              inmuebleInicial: inmueble,
              isInactivo: isInactivo,
              onEdit: () => _navegarEditarInmueble(context, ref, inmueble),
              onDelete: () => _inactivarInmueble(context, ref, inmueble),
              botonEstadoTexto:
                  isInactivo
                      ? 'Marcar como Disponible'
                      : 'Marcar como No Disponible',
              botonEstadoColor: isInactivo ? Colors.green : Colors.red,
            ),
      ),
    );

    if (result == true) {
      ref.invalidate(inmueblesProvider);
    }
  }

  /// Navega a la pantalla de edición del inmueble
  Future<void> _navegarEditarInmueble(
    BuildContext context,
    WidgetRef ref,
    Inmueble inmueble,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InmuebleEditScreen(inmueble: inmueble),
      ),
    );

    if (result == true) {
      ref.invalidate(inmueblesProvider);
    }
  }

  /// Cambia el estado de un inmueble entre activo/inactivo
  Future<void> _inactivarInmueble(
    BuildContext context,
    WidgetRef ref,
    Inmueble inmueble,
  ) async {
    try {
      // Determinar el nuevo estado basado en el estado actual
      int nuevoEstado;
      String mensaje;
      Color colorMensaje;

      if (inmueble.idEstado == estadoNoDisponible) {
        // Si está inactivo, marcar como disponible
        nuevoEstado = estadoDisponible;
        mensaje = 'Inmueble marcado como Disponible';
        colorMensaje = Colors.green;
      } else {
        // Si está en otro estado, marcar como no disponible
        nuevoEstado = estadoNoDisponible;
        mensaje = 'Inmueble marcado como No Disponible';
        colorMensaje = Colors.red;
      }

      // Crear inmueble actualizado con el nuevo estado
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
        // Preservar otros campos que puedan existir
        costoCliente: inmueble.costoCliente,
        costoServicios: inmueble.costoServicios,
        comisionAgencia: inmueble.comisionAgencia,
        comisionAgente: inmueble.comisionAgente,
      );

      // Actualizar en la base de datos
      final inmuebleController = ref.read(inmuebleControllerProvider);
      await inmuebleController.updateInmueble(inmuebleActualizado);

      // Mostrar mensaje y refrescar la lista
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: colorMensaje,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      ref.invalidate(inmueblesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

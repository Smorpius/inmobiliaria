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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar el estado de mostrar inmuebles inactivos
    final mostrarInactivos = ref.watch(mostrarInactivosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inmuebles'),
        actions: [
          // Botón para mostrar activos/inactivos
          IconButton(
            icon: Icon(
              mostrarInactivos ? Icons.visibility_off : Icons.visibility,
              color: mostrarInactivos ? Colors.red : Colors.green,
            ),
            onPressed:
                () =>
                    ref.read(mostrarInactivosProvider.notifier).state =
                        !mostrarInactivos,
            tooltip: mostrarInactivos ? 'Mostrar activos' : 'Mostrar inactivos',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(inmueblesProvider),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Widget de filtros avanzados
          InmuebleFiltroAvanzado(
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
            },
            onLimpiar:
                () =>
                    ref.read(filtrosInmuebleProvider.notifier).limpiarFiltros(),
          ),

          // Indicador de filtros activos o modo inactivos
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

          // Listado de inmuebles
          Expanded(child: _buildListado(context, ref)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _navegarAgregarInmueble(context, ref),
      ),
    );
  }

  Widget _buildListado(BuildContext context, WidgetRef ref) {
    // Observar el estado de los inmuebles filtrados
    final inmueblesFiltrados = ref.watch(inmueblesBuscadosProvider);

    return inmueblesFiltrados.when(
      data: (inmuebles) {
        if (inmuebles.isEmpty) {
          return InmuebleEmptyState(
            isFiltering: true,
            onLimpiarFiltros:
                () =>
                    ref.read(filtrosInmuebleProvider.notifier).limpiarFiltros(),
          );
        }

        // Cargar las imágenes principales
        final imagenesPrincipales = ref.watch(imagenesPrincipalesProvider);
        final rutasImagenes = ref.watch(rutasImagenesPrincipalesProvider);

        // Cuando se tienen datos, asegurarse de que se carguen las imágenes principales
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

  Future<void> _navegarDetalleInmueble(
    BuildContext context,
    WidgetRef ref,
    Inmueble inmueble,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => InmuebleDetailScreen(
              inmuebleInicial:
                  inmueble, // Corregido: cambiado inmueble a inmuebleInicial
              onEdit: () => _navegarEditarInmueble(context, ref, inmueble),
              onDelete: () => _inactivarInmueble(context, ref, inmueble),
              isInactivo: inmueble.idEstado == 2,
            ),
      ),
    );

    if (result == true) {
      ref.invalidate(inmueblesProvider);
    }
  }

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

  // Método para manejar la inactivación de inmuebles
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

      if (inmueble.idEstado == 2) {
        // Si está inactivo
        nuevoEstado = 3; // Marcar como disponible
        mensaje = 'Inmueble marcado como Disponible';
        colorMensaje = Colors.green;
      } else {
        // Si está disponible u otro estado
        nuevoEstado = 2; // Marcar como no disponible
        mensaje = 'Inmueble marcado como No Disponible';
        colorMensaje = Colors.red;
      }

      // Crear una copia actualizada del inmueble con el nuevo estado
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
      );

      // Actualizar el inmueble
      final inmuebleController = ref.read(inmuebleControllerProvider);
      await inmuebleController.updateInmueble(inmuebleActualizado);

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: colorMensaje,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Refrescar la lista de inmuebles
      ref.invalidate(inmueblesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

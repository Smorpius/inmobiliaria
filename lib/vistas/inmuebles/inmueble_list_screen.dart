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

  // Mapa de estados para mostrar mensajes consistentes
  static const Map<int, String> estadosInmueble = {
    2: 'No disponible',
    3: 'Disponible',
    4: 'Vendido',
    5: 'Rentado',
    6: 'En negociación', // Corregido de 'En oferta' a 'En negociación'
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar el estado de mostrar inmuebles inactivos
    final mostrarInactivos = ref.watch(mostrarInactivosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inmuebles'),
        actions: [
          // Botón para filtros avanzados
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
                      // Actualizar filtros
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
          // Botón para mostrar/ocultar inmuebles inactivos
          IconButton(
            icon: Icon(
              mostrarInactivos ? Icons.visibility_off : Icons.visibility,
            ),
            tooltip:
                mostrarInactivos
                    ? 'Ocultar inmuebles inactivos'
                    : 'Mostrar inmuebles inactivos',
            onPressed: () {
              ref.read(mostrarInactivosProvider.notifier).state =
                  !mostrarInactivos;
            },
          ),
        ],
      ),
      body: Column(children: [Expanded(child: _buildListado(context, ref))]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
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
            onLimpiarFiltros: () {
              ref.read(filtrosInmuebleProvider.notifier).limpiarFiltros();
            },
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
          // Renderizador de botón corregido con "Marcar Disponible"
          renderizarBotonEstado: (inmueble, onPressed) {
            final isInactivo = inmueble.idEstado == 2;
            return ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(isInactivo ? Icons.check_circle : Icons.remove_circle),
              label: Text(isInactivo ? 'Marcar Disponible' : 'Desactivar'),
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
    // Determinar si el inmueble está inactivo
    final bool isInactivo = inmueble.idEstado == 2;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => InmuebleDetailScreen(
              inmuebleInicial: inmueble,
              isInactivo: isInactivo,
              onEdit: () => _navegarEditarInmueble(context, ref, inmueble),
              onDelete: () => _inactivarInmueble(context, ref, inmueble),
              // Texto corregido del botón de estado
              botonEstadoTexto:
                  isInactivo
                      ? 'Marcar Disponible'
                      : 'Marcar como No Disponible',
              botonEstadoColor: isInactivo ? Colors.green : Colors.red,
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

  // Método para manejar la inactivación/activación de inmuebles
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
        // Si está inactivo, marcar como disponible
        nuevoEstado = 3; // Disponible
        mensaje = 'Inmueble marcado como Disponible';
        colorMensaje = Colors.green;
      } else {
        // Si está disponible u otro estado, marcar como inactivo
        nuevoEstado = 2; // No disponible
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
            behavior: SnackBarBehavior.floating,
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

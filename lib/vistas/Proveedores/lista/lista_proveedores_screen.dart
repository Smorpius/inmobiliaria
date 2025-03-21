import 'dart:async';
import 'proveedores_filtro.dart';
import 'proveedores_busqueda.dart';
import 'proveedores_list_view.dart';
import 'dart:developer' as developer;
import 'proveedores_empty_view.dart';
import 'proveedores_error_view.dart';
import 'package:flutter/material.dart';
import '../nuevo_proveedor_screen.dart';
import '../../../models/proveedor.dart';
import '../../../utils/dialog_helper.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../providers/proveedor_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListaProveedoresScreen extends ConsumerStatefulWidget {
  const ListaProveedoresScreen({super.key});

  @override
  ConsumerState<ListaProveedoresScreen> createState() =>
      _ListaProveedoresScreenState();
}

class _ListaProveedoresScreenState
    extends ConsumerState<ListaProveedoresScreen> {
  // Timer para actualización automática
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    developer.log(
      '[Proveedores] Inicializando ListaProveedoresScreen con Riverpod',
    );

    // Inicialización después de montar el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Iniciar actualización automática cada 30 segundos
      _iniciarActualizacionAutomatica();
    });
  }

  void _iniciarActualizacionAutomatica() {
    developer.log('[Proveedores] Configurando actualización automática (30s)');

    // Cancelar timer existente si hay uno
    _autoRefreshTimer?.cancel();

    // Crear nuevo timer que se ejecuta cada 30 segundos
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final estado = ref.read(proveedoresProvider);

      if (mounted && !estado.buscando) {
        // No actualizar automáticamente durante búsqueda
        developer.log('[Proveedores] Ejecutando actualización automática');
        ref.read(proveedoresProvider.notifier).cargarProveedores();
      }
    });
  }

  @override
  void dispose() {
    developer.log('[Proveedores] Destruyendo ListaProveedoresScreen');
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _navegarANuevoProveedor() {
    developer.log('[Proveedores] Navegando a pantalla de nuevo proveedor');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NuevoProveedorScreen()),
    ).then((_) {
      developer.log(
        '[Proveedores] Regresando de nuevo proveedor, recargando datos',
      );
      ref.read(proveedoresProvider.notifier).cargarProveedores();
    });
  }

  void _manejarError(String mensaje) {
    if (!mounted) return;

    DialogHelper.mostrarMensajeError(context, 'Error', mensaje);
  }

  @override
  Widget build(BuildContext context) {
    // Consumir el estado de Riverpod
    final estado = ref.watch(proveedoresProvider);
    final notifier = ref.read(proveedoresProvider.notifier);

    return Stack(
      children: [
        AppScaffold(
          title: 'Gestión de Proveedores',
          currentRoute: '/proveedores',
          actions: [
            ProveedoresFiltro(
              mostrarInactivos: estado.mostrarInactivos,
              onChanged: notifier.cambiarFiltroInactivos,
              isLoading: estado.isLoading,
              onRefresh: () => notifier.cargarProveedores(),
            ),
          ],
          body: Column(
            children: [
              // Componente de búsqueda
              ProveedoresBusqueda(
                onSearch: (termino) => notifier.buscarProveedores(termino),
                isLoading: estado.isLoading,
              ),

              // Indicador de búsqueda activa
              if (estado.buscando && estado.terminoBusqueda.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_list,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Resultados para: "${estado.terminoBusqueda}"',
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed:
                            estado.isLoading
                                ? null
                                : () => notifier.buscarProveedores(''),
                        child: const Text('Limpiar filtro'),
                      ),
                    ],
                  ),
                ),

              // El resto del contenido en un Expanded para que ocupe el espacio restante
              Expanded(child: _buildBody(estado, notifier)),
            ],
          ),
          // Se eliminó el bottomNavigationBar
        ),

        // Botón flotante
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: estado.isLoading ? null : _navegarANuevoProveedor,
            backgroundColor: Theme.of(context).primaryColor,
            tooltip: 'Agregar proveedor',
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ProveedoresState estado, ProveedoresNotifier notifier) {
    // Vista de carga
    if (estado.isLoading) {
      developer.log('[Proveedores] Renderizando vista de carga');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando proveedores...'),
          ],
        ),
      );
    }

    // Vista de error
    if (estado.errorMessage != null) {
      developer.log(
        '[Proveedores] Renderizando vista de error: ${estado.errorMessage}',
      );
      return ProveedoresErrorView(
        errorMessage: estado.errorMessage!,
        onRetry: () => notifier.cargarProveedores(),
      );
    }

    final proveedoresFiltrados = estado.proveedoresFiltrados;

    // Vista sin datos
    if (proveedoresFiltrados.isEmpty) {
      developer.log('[Proveedores] No hay datos o lista vacía');
      return ProveedoresEmptyView(
        mostrandoInactivos: estado.mostrarInactivos,
        onNuevoProveedor: _navegarANuevoProveedor,
        terminoBusqueda: estado.buscando ? estado.terminoBusqueda : null,
        onClearSearch:
            estado.buscando ? () => notifier.buscarProveedores('') : null,
      );
    }

    // Vista con datos
    return ProveedoresListView(
      proveedores: proveedoresFiltrados,
      onItemTap: (proveedor) => _modificarProveedor(proveedor),
      onAgregarProveedor: _navegarANuevoProveedor,
      onEliminar: (proveedor) => _inactivarProveedor(proveedor),
      onReactivar: (proveedor) => _reactivarProveedor(proveedor),
      onModificar: (proveedor) => _modificarProveedor(proveedor),
    );
  }

  Future<void> _modificarProveedor(Proveedor proveedor) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevoProveedorScreen(proveedorEditar: proveedor),
      ),
    );

    if (result == true) {
      ref.read(proveedoresProvider.notifier).cargarProveedores();
    }
  }

  Future<void> _inactivarProveedor(Proveedor proveedor) async {
    final confirmar = await DialogHelper.confirmarAccion(
      context,
      '¿Desea eliminar este proveedor?',
      'Esta acción cambiará el estado del proveedor a inactivo.',
      'Eliminar',
      const TextStyle(color: Colors.red),
    );

    if (confirmar) {
      try {
        final exito = await ref
            .read(proveedoresProvider.notifier)
            .inactivarProveedor(proveedor.idProveedor!);

        if (exito && mounted) {
          DialogHelper.mostrarMensajeExito(
            context,
            'Proveedor inactivado correctamente',
          );
        }
      } catch (e) {
        _manejarError('Error al inactivar el proveedor: ${e.toString()}');
      }
    }
  }

  Future<void> _reactivarProveedor(Proveedor proveedor) async {
    final confirmar = await DialogHelper.confirmarAccion(
      context,
      '¿Desea reactivar este proveedor?',
      'Esta acción cambiará el estado del proveedor a activo.',
      'Reactivar',
      const TextStyle(color: Colors.green),
    );

    if (confirmar) {
      try {
        final exito = await ref
            .read(proveedoresProvider.notifier)
            .reactivarProveedor(proveedor.idProveedor!);

        if (exito && mounted) {
          DialogHelper.mostrarMensajeExito(
            context,
            'Proveedor reactivado correctamente',
          );
        }
      } catch (e) {
        _manejarError('Error al reactivar el proveedor: ${e.toString()}');
      }
    }
  }
}

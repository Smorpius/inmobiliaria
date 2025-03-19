import 'dart:async';
import 'proveedores_estado.dart';
import 'proveedores_filtro.dart';
import 'proveedores_acciones.dart';
import 'proveedores_list_view.dart';
import 'proveedores_empty_view.dart';
import 'proveedores_error_view.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'proveedores_error_handler.dart';
import '../nuevo_proveedor_screen.dart';
import '../../../models/proveedor.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../controllers/proveedor_controller.dart';
import 'proveedores_busqueda.dart'; // Nuevo componente importado

class ListaProveedoresScreen extends StatefulWidget {
  final ProveedorController controller;

  const ListaProveedoresScreen({super.key, required this.controller});

  @override
  State<ListaProveedoresScreen> createState() => _ListaProveedoresScreenState();
}

class _ListaProveedoresScreenState extends State<ListaProveedoresScreen>
    with ProveedoresErrorHandler, ProveedoresAcciones {
  late final ProveedoresEstado estado;

  // Timer para actualización automática
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    developer.log('[Proveedores] Inicializando ListaProveedoresScreen');

    estado = ProveedoresEstado();
    inicializarErrorHandler(context);
    inicializarAcciones(widget.controller, context, setState);

    // Inicialización después de montar el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('[Proveedores] Widget montado, iniciando carga inicial');

      if (!widget.controller.isInitialized) {
        developer.log(
          '[Proveedores] Controlador no inicializado, inicializando...',
        );
        widget.controller
            .inicializar()
            .then((_) {
              developer.log(
                '[Proveedores] Controlador inicializado exitosamente',
              );
              if (mounted) setState(() {});
            })
            .catchError((e) {
              developer.log(
                '[Proveedores] Error al inicializar controlador: $e',
                error: e,
              );
              if (mounted) manejarError(e);
            });
      } else {
        // Siempre cargar proveedores incluso si ya está inicializado
        cargarProveedores();
      }

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
      if (mounted && !estado.buscando) {
        // No actualizar automáticamente durante búsqueda
        developer.log('[Proveedores] Ejecutando actualización automática');
        cargarProveedores();
      }
    });
  }

  @override
  void dispose() {
    developer.log('[Proveedores] Destruyendo ListaProveedoresScreen');
    _autoRefreshTimer?.cancel();
    // Llamada correcta para limpiar recursos del mixin
    super.dispose();
  }

  Future<void> cargarProveedores() async {
    if (estado.isLoading) {
      developer.log(
        '[Proveedores] Ignorando solicitud de carga, ya hay una carga en progreso',
      );
      return;
    }

    try {
      developer.log('[Proveedores] Iniciando carga de proveedores');
      setState(() {
        estado.isLoading = true;
        estado.tieneError = false;
        estado.mensajeError = null;
      });

      await widget.controller.cargarProveedores();
      developer.log('[Proveedores] Proveedores cargados exitosamente');

      if (mounted) {
        setState(() {
          estado.isLoading = false;
          // Limpiamos la búsqueda si estamos recargando
          if (!estado.buscando) {
            estado.terminoBusqueda = '';
          }
          developer.log(
            '[Proveedores] Vista actualizada después de carga exitosa',
          );
        });
      }
    } catch (e, stackTrace) {
      developer.log(
        '[Proveedores] Error al cargar proveedores: $e',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          estado.isLoading = false;
          estado.tieneError = true;
          estado.mensajeError = e.toString();
          estado.stackTrace = stackTrace;
        });
        manejarError(e);
      }
    }
  }

  // Método para manejar la búsqueda (NUEVO)
  Future<void> buscarProveedores(String termino) async {
    if (estado.isLoading) return;

    developer.log('[Proveedores] Iniciando búsqueda con término: "$termino"');

    try {
      setState(() {
        estado.isLoading = true;
        estado.terminoBusqueda = termino;
        estado.buscando = termino.isNotEmpty;
      });

      if (termino.isEmpty) {
        await widget.controller.cargarProveedores();
      } else {
        await widget.controller.filtrarProveedores(termino);
      }

      setState(() {
        estado.isLoading = false;
      });

      developer.log('[Proveedores] Búsqueda completada');
    } catch (e, stackTrace) {
      developer.log(
        '[Proveedores] Error en búsqueda: $e',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          estado.isLoading = false;
          estado.tieneError = true;
          estado.mensajeError = e.toString();
          estado.stackTrace = stackTrace;
        });
        manejarError(e);
      }
    }
  }

  void _navegarANuevoProveedor() {
    developer.log('[Proveedores] Navegando a pantalla de nuevo proveedor');
    // Navegar a la pantalla de nuevo proveedor
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NuevoProveedorScreen(controller: widget.controller),
      ),
    ).then((_) {
      developer.log(
        '[Proveedores] Regresando de pantalla de nuevo proveedor, recargando datos',
      );
      cargarProveedores();
    });
  }

  // CORREGIDO: No regenerar clave del streamBuilder al cambiar filtro
  void cambiarFiltroInactivos(bool mostrarInactivos) {
    if (estado.mostrarInactivos != mostrarInactivos) {
      developer.log(
        '[Proveedores] Cambiando filtro de inactivos: $mostrarInactivos',
      );
      setState(() {
        estado.mostrarInactivos = mostrarInactivos;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppScaffold(
          title: 'Gestión de Proveedores',
          currentRoute: '/proveedores',
          actions: [
            ProveedoresFiltro(
              mostrarInactivos: estado.mostrarInactivos,
              onChanged: cambiarFiltroInactivos,
              isLoading: estado.isLoading,
              onRefresh: cargarProveedores,
            ),
          ],
          body: Column(
            children: [
              // Añadir componente de búsqueda
              ProveedoresBusqueda(
                onSearch: buscarProveedores,
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
                                : () => buscarProveedores(''),
                        child: const Text('Limpiar filtro'),
                      ),
                    ],
                  ),
                ),

              // El resto del contenido en un Expanded para que ocupe el espacio restante
              Expanded(child: _buildBody()),
            ],
          ),
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

  Widget _buildBody() {
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

    if (estado.tieneError) {
      developer.log(
        '[Proveedores] Renderizando vista de error: ${estado.mensajeError}',
      );
      return ProveedoresErrorView(
        errorMessage: estado.mensajeError!,
        stackTrace: estado.stackTrace,
        onRetry: cargarProveedores,
      );
    }

    developer.log('[Proveedores] Configurando StreamBuilder para proveedores');

    return StreamBuilder<List<Proveedor>>(
      key: estado.streamKey, // Usamos una clave constante
      stream: widget.controller.proveedores,
      builder: (context, snapshot) {
        // MEJORA IMPLEMENTADA: Log adicional para depurar el estado del snapshot
        developer.log(
          '[StreamBuilder] Estado: hasData=${snapshot.hasData}, '
          'connectionState=${snapshot.connectionState}, '
          'error=${snapshot.error}, '
          '${snapshot.hasData ? 'items=${snapshot.data!.length}' : 'no data'}',
        );

        // CORREGIDO: Solo mostrar carga si no hay datos previos
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          developer.log('[Proveedores] Error en stream: ${snapshot.error}');
          return ProveedoresErrorView(
            errorMessage: snapshot.error.toString(),
            onRetry: cargarProveedores,
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          developer.log('[Proveedores] No hay datos o lista vacía');
          return ProveedoresEmptyView(
            mostrandoInactivos: estado.mostrarInactivos,
            onNuevoProveedor: _navegarANuevoProveedor,
            terminoBusqueda: estado.buscando ? estado.terminoBusqueda : null,
            onClearSearch: estado.buscando ? () => buscarProveedores('') : null,
          );
        }

        final proveedores = snapshot.data!;

        // MEJORA IMPLEMENTADA: Conteo para logs de depuración
        final activosCount = proveedores.where((p) => p.idEstado == 1).length;
        final inactivosCount = proveedores.where((p) => p.idEstado != 1).length;

        // Filtrado de proveedores según el estado del switch
        final proveedoresFiltrados =
            estado.mostrarInactivos
                ? proveedores
                : proveedores.where((p) => p.idEstado == 1).toList();

        // MEJORA IMPLEMENTADA: Log específico para el filtrado
        developer.log(
          '[Proveedores] Filtrado: total=${proveedores.length}, '
          'activos=$activosCount, inactivos=$inactivosCount, '
          'mostrados=${proveedoresFiltrados.length} '
          '(mostrarInactivos: ${estado.mostrarInactivos})',
        );

        if (proveedoresFiltrados.isEmpty) {
          developer.log('[Proveedores] Lista filtrada vacía');
          return ProveedoresEmptyView(
            mostrandoInactivos: estado.mostrarInactivos,
            onNuevoProveedor: _navegarANuevoProveedor,
            terminoBusqueda: estado.buscando ? estado.terminoBusqueda : null,
            onClearSearch: estado.buscando ? () => buscarProveedores('') : null,
          );
        }

        // MEJORA IMPLEMENTADA: Usar el componente ProveedoresListView
        developer.log(
          '[Proveedores] Renderizando ProveedoresListView con ${proveedoresFiltrados.length} items',
        );
        return ProveedoresListView(
          proveedores: proveedoresFiltrados,
          onItemTap: (proveedor) {
            developer.log(
              '[Proveedores] Tap en proveedor: ${proveedor.nombre} (ID: ${proveedor.idProveedor})',
            );
            modificarProveedor(proveedor, onSuccess: cargarProveedores);
          },
          onAgregarProveedor: _navegarANuevoProveedor,
          onEliminar: (proveedor) {
            developer.log(
              '[Proveedores] Eliminando proveedor: ${proveedor.nombre} (ID: ${proveedor.idProveedor})',
            );
            inactivarProveedor(proveedor, onSuccess: cargarProveedores);
          },
          onReactivar: (proveedor) {
            developer.log(
              '[Proveedores] Reactivando proveedor: ${proveedor.nombre} (ID: ${proveedor.idProveedor})',
            );
            reactivarProveedor(proveedor, onSuccess: cargarProveedores);
          },
          onModificar: (proveedor) {
            developer.log(
              '[Proveedores] Modificando proveedor: ${proveedor.nombre} (ID: ${proveedor.idProveedor})',
            );
            modificarProveedor(proveedor, onSuccess: cargarProveedores);
          },
        );
      },
    );
  }
}

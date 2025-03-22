import 'dart:async';
import 'empleados_estado.dart';
import 'empleados_filtro.dart';
import 'empleados_acciones.dart';
import 'empleados_list_view.dart';
import 'empleados_empty_view.dart';
import 'empleados_error_view.dart';
import 'dart:developer' as developer;
import 'empleados_error_handler.dart';
import 'package:flutter/material.dart';
import '../nuevo_empleado_screen.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../models/usuario_empleado.dart';
import '../../../providers/empleado_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers_global.dart'
    hide empleadoControllerProvider;

// Provider para manejar la actualización automática
final empleadosAutoRefreshProvider = Provider.autoDispose<void>((ref) {
  // Timer para actualización automática cada 30 segundos
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    developer.log('Ejecutando actualización automática de empleados');
    final controller = ref.read(usuarioEmpleadoControllerProvider);

    // Verificar conexión y actualizar silenciosamente
    controller
        .verificarConexion()
        .then((conexionExitosa) {
          if (conexionExitosa) {
            controller.cargarEmpleadosConRefresco();
          }
        })
        .catchError((e) {
          developer.log('Error en actualización automática: $e', error: e);
        });
  });

  // Cancelar el timer cuando se dispone el provider
  ref.onDispose(() {
    timer.cancel();
  });
});

// Provider para manejar el estado de carga
final empleadosLoadingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

// Provider para manejar errores
final empleadosErrorProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

class ListaEmpleadosScreen extends ConsumerStatefulWidget {
  const ListaEmpleadosScreen({super.key});

  @override
  ConsumerState<ListaEmpleadosScreen> createState() =>
      _ListaEmpleadosScreenState();
}

class _ListaEmpleadosScreenState extends ConsumerState<ListaEmpleadosScreen>
    with EmpleadosErrorHandler, EmpleadosAcciones {
  // Usaremos esto para manejar estados adicionales y el streamKey
  late final EmpleadosEstado estado;

  @override
  void initState() {
    super.initState();
    estado = EmpleadosEstado();
    inicializarErrorHandler(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Inicializar el controlador
      final usuarioEmpleadoController = ref.read(
        usuarioEmpleadoControllerProvider,
      );
      inicializarAcciones(usuarioEmpleadoController, context);

      if (!usuarioEmpleadoController.isInitialized) {
        usuarioEmpleadoController
            .inicializar()
            .then((_) => cargarEmpleados())
            .catchError((e) {
              if (mounted) manejarError(e);
            });
      } else {
        cargarEmpleados();
      }

      // Activar el provider de actualización automática
      ref.read(empleadosAutoRefreshProvider);
    });
  }

  Future<void> cargarEmpleados() async {
    if (!mounted) return;

    // Actualizar estado global de carga
    ref.read(empleadosLoadingProvider.notifier).state = true;
    // Actualizar estado local
    setState(() => estado.iniciarCarga());

    try {
      final usuarioEmpleadoController = ref.read(
        usuarioEmpleadoControllerProvider,
      );
      final conexionExitosa =
          await usuarioEmpleadoController.verificarConexion();

      if (!conexionExitosa) {
        throw Exception("No se pudo establecer conexión con la base de datos");
      }

      await usuarioEmpleadoController.cargarEmpleadosConReintentos(2);

      // Limpiar error si existía
      ref.read(empleadosErrorProvider.notifier).state = null;
      if (mounted) setState(() => estado.finalizarCarga());
    } catch (e, stackTrace) {
      // Manejar error en ambos estados (global y local)
      ref.read(empleadosErrorProvider.notifier).state = e.toString();
      if (mounted) manejarError(e, stackTrace);
    } finally {
      // Finalizar estado de carga global
      ref.read(empleadosLoadingProvider.notifier).state = false;
    }
  }

  void cambiarFiltroInactivos(bool value) {
    ref.read(mostrarEmpleadosInactivosProvider.notifier).state = value;
  }

  void _navegarANuevoEmpleado() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => NuevoEmpleadoScreen(
                  usuarioEmpleadoController: ref.read(
                    usuarioEmpleadoControllerProvider,
                  ),
                ),
          ),
        )
        .then((_) => cargarEmpleados());
  }

  @override
  Widget build(BuildContext context) {
    // Observar estados de Riverpod
    final mostrarInactivos = ref.watch(mostrarEmpleadosInactivosProvider);
    final isLoading = ref.watch(empleadosLoadingProvider);
    final errorMessage = ref.watch(empleadosErrorProvider);

    // Actualizar estado local si hay cambio en providers globales
    if (estado.isLoading != isLoading) {
      estado.isLoading = isLoading;
    }

    if (errorMessage != null && errorMessage != estado.mensajeError) {
      estado.mensajeError = errorMessage;
    }

    return Stack(
      children: [
        AppScaffold(
          title: 'Gestión de Empleados',
          currentRoute: '/empleados',
          actions: [
            EmpleadosFiltro(
              mostrarInactivos: mostrarInactivos,
              onChanged: cambiarFiltroInactivos,
              isLoading: estado.isLoading,
              onRefresh: cargarEmpleados,
            ),
          ],
          body: _buildBody(mostrarInactivos),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: estado.isLoading ? null : _navegarANuevoEmpleado,
            backgroundColor: Theme.of(context).primaryColor,
            tooltip: 'Agregar empleado',
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(bool mostrarInactivos) {
    if (estado.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando empleados...'),
          ],
        ),
      );
    }

    if (estado.tieneError) {
      return EmpleadosErrorView(
        errorMessage: estado.mensajeError!,
        stackTrace: estado.stackTrace,
        onRetry: cargarEmpleados,
      );
    }

    return StreamBuilder<List<UsuarioEmpleado>>(
      key: estado.streamKey,
      stream: ref.read(usuarioEmpleadoControllerProvider).empleados,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return EmpleadosErrorView(
            errorMessage: snapshot.error.toString(),
            onRetry: cargarEmpleados,
          );
        }

        if (!snapshot.hasData && !estado.isLoading) {
          return EmpleadosEmptyView(
            mostrandoInactivos: mostrarInactivos,
            onNuevoEmpleado: _navegarANuevoEmpleado,
          );
        }

        if (snapshot.hasData) {
          final empleados = snapshot.data!;
          final empleadosFiltrados =
              mostrarInactivos
                  ? empleados
                  : empleados.where((e) => e.empleado.idEstado == 1).toList();

          if (empleadosFiltrados.isEmpty) {
            return EmpleadosEmptyView(
              mostrandoInactivos: mostrarInactivos,
              onNuevoEmpleado: _navegarANuevoEmpleado,
            );
          }

          return RefreshIndicator(
            onRefresh: cargarEmpleados,
            child: EmpleadosListView(
              empleados: empleadosFiltrados,
              onItemTap:
                  (empleado) =>
                      modificarEmpleado(empleado, onSuccess: cargarEmpleados),
              onAgregarEmpleado: _navegarANuevoEmpleado,
              onEliminar:
                  (empleado) =>
                      inactivarEmpleado(empleado, onSuccess: cargarEmpleados),
              onReactivar:
                  (empleado) =>
                      reactivarEmpleado(empleado, onSuccess: cargarEmpleados),
              onModificar:
                  (empleado) =>
                      modificarEmpleado(empleado, onSuccess: cargarEmpleados),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

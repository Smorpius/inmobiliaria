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
import '../../../providers/providers_global.dart';

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
  late final EmpleadosEstado estado;
  // Guardar la instancia del stream para el StreamBuilder
  late final Stream<List<UsuarioEmpleado>> _empleadosStream;

  @override
  void initState() {
    super.initState();
    estado = EmpleadosEstado();
    inicializarErrorHandler(context);

    // Obtener la instancia del controlador y el stream una vez
    final usuarioEmpleadoController = ref.read(usuarioEmpleadoControllerProvider);
    _empleadosStream = usuarioEmpleadoController.empleados;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      inicializarAcciones(usuarioEmpleadoController, context);

      if (!usuarioEmpleadoController.isInitialized) {
        usuarioEmpleadoController
            .inicializar()
            .then((_) {
              // Forzar una carga completa con refresco
              return usuarioEmpleadoController.cargarEmpleadosConRefresco();
            })
            .then((_) {
              if (mounted) setState(() {});
            })
            .catchError((e) {
              if (mounted) manejarError(e);
            });
      } else {
        // Forzar carga con refresco incluso si está inicializado
        usuarioEmpleadoController.cargarEmpleadosConRefresco()
            .then((_) {
              if (mounted) setState(() {});
            })
            .catchError((e) {
              if (mounted) manejarError(e);
            });
      }
      ref.read(empleadosAutoRefreshProvider);
    });
  }

  Future<void> cargarEmpleados() async {
    developer.log('[Screen] Iniciando cargarEmpleados (forzando refresco)...');
    if (!mounted) {
       developer.log('[Screen] cargarEmpleados abortado: Widget no montado.');
       return;
    }

    // Usar el provider de carga global
    ref.read(empleadosLoadingProvider.notifier).state = true;

    try {
      // Siempre llamar al método que fuerza el refresco desde el servicio
      await ref.read(usuarioEmpleadoControllerProvider).cargarEmpleadosConRefresco();
      developer.log('[Screen] cargarEmpleados completado exitosamente.');

      // Limpiar error global si existía
      ref.read(empleadosErrorProvider.notifier).state = null;

    } catch (e, stackTrace) {
      developer.log('[Screen] Error en cargarEmpleados: $e');
      // Manejar error global
      ref.read(empleadosErrorProvider.notifier).state = e.toString();
      // Usar el manejador de errores mixin si es necesario mostrar diálogos
      if (mounted) manejarError(e, stackTrace);
    } finally {
      // Finalizar estado de carga global
      if (mounted) {
         ref.read(empleadosLoadingProvider.notifier).state = false;
      }
       developer.log('[Screen] cargarEmpleados finalizado.');
    }
  }

  void cambiarFiltroInactivos(bool value) {
    ref.read(mostrarEmpleadosInactivosProvider.notifier).state = value;
  }

  void _navegarANuevoEmpleado() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => NuevoEmpleadoScreen(
              usuarioEmpleadoController: ref.read(usuarioEmpleadoControllerProvider),
            ),
          ),
        )
        .then((result) {
          if (result == true) {
            // Llamar a cargarEmpleados primero y luego forzar la reconstrucción del widget
            setState(() {});
            cargarEmpleados();
          }
        });
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
    // Observar estados globales directamente
    final isLoadingGlobal = ref.watch(empleadosLoadingProvider);
    final errorMessageGlobal = ref.watch(empleadosErrorProvider);

    developer.log('[Screen] _buildBody rebuild: isLoadingGlobal=$isLoadingGlobal, errorMessageGlobal=$errorMessageGlobal');

    // Obtener directamente la lista de empleados del controlador
    final controller = ref.read(usuarioEmpleadoControllerProvider);

    // Mostrar indicador de carga global si está activo
    if (isLoadingGlobal) {
      developer.log('[Screen] _buildBody: Mostrando indicador de carga global.');
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

    // Mostrar vista de error global si existe
    if (errorMessageGlobal != null) {
      developer.log('[Screen] _buildBody: Mostrando vista de error global: $errorMessageGlobal');
      return EmpleadosErrorView(
        errorMessage: errorMessageGlobal,
        onRetry: cargarEmpleados,
      );
    }

    // CAMBIO IMPORTANTE: Usar un ValueListenableBuilder como intermediario
    // que siempre mostrará los datos más recientes del stream o de la propiedad
    return StreamBuilder<List<UsuarioEmpleado>>(
      stream: _empleadosStream,
      builder: (context, snapshot) {
        developer.log(
          '[Screen] StreamBuilder rebuild: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}, dataLength=${snapshot.data?.length}',
        );

        // Manejar error del stream
        if (snapshot.hasError) {
          developer.log('[Screen] StreamBuilder: Error recibido: ${snapshot.error}');
          return EmpleadosErrorView(
            errorMessage: snapshot.error.toString(),
            onRetry: cargarEmpleados,
          );
        }

        // NUEVA LÓGICA: Si estamos en ConnectionState.waiting después de una actualización, 
        // usar los datos almacenados en el controlador en vez de mostrar un indicador
        if (snapshot.connectionState == ConnectionState.waiting) {
          developer.log('[Screen] StreamBuilder: Esperando datos (ConnectionState.waiting).');
          
          // Verificar si tenemos datos disponibles en el controlador
          final empleadosActuales = controller.empleadosActuales;
          if (empleadosActuales.isNotEmpty) {
            developer.log('[Screen] Usando datos del controlador mientras esperamos stream: ${empleadosActuales.length} empleados');
            return _buildEmpleadosList(empleadosActuales, mostrarInactivos);
          }
          
          // Si no hay datos en el controlador, mostrar indicador
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        // Si no hay datos después de esperar (y no hay error) -> Lista vacía
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          developer.log('[Screen] StreamBuilder: No hay datos o lista vacía. Mostrando EmpleadosEmptyView.');
          return EmpleadosEmptyView(
            mostrandoInactivos: mostrarInactivos,
            onNuevoEmpleado: _navegarANuevoEmpleado,
          );
        }

        // Si hay datos en el snapshot, usarlos
        return _buildEmpleadosList(snapshot.data!, mostrarInactivos);
      },
    );
  }
  
  // Método extraído para construir la lista de empleados
  Widget _buildEmpleadosList(List<UsuarioEmpleado> empleados, bool mostrarInactivos) {
    developer.log('[Screen] Construyendo lista filtrada de ${empleados.length} empleados totales.');
    
    // Corregimos la lógica del filtrado: Si mostrarInactivos es true, solo mostramos los inactivos
    final empleadosFiltrados = mostrarInactivos
        ? empleados.where((e) => e.empleado.idEstado != 1).toList()  // SOLO inactivos (idEstado != 1)
        : empleados.where((e) => e.empleado.idEstado == 1).toList();  // SOLO activos (idEstado == 1)
    
    developer.log('[Screen] Empleados filtrados (${mostrarInactivos ? "inactivos" : "activos"} solamente): ${empleadosFiltrados.length}');
    
    if (empleadosFiltrados.isEmpty) {
      developer.log('[Screen] Lista filtrada vacía. Mostrando EmpleadosEmptyView.');
      return EmpleadosEmptyView(
        mostrandoInactivos: mostrarInactivos,
        onNuevoEmpleado: _navegarANuevoEmpleado,
      );
    }
    
    developer.log('[Screen] Mostrando EmpleadosListView con ${empleadosFiltrados.length} empleados.');
    return RefreshIndicator(
      onRefresh: cargarEmpleados,
      child: EmpleadosListView(
        empleados: empleadosFiltrados,
        onItemTap: (empleado) => modificarEmpleado(empleado, onSuccess: cargarEmpleados),
        onAgregarEmpleado: _navegarANuevoEmpleado,
        onEliminar: (empleado) => inactivarEmpleado(empleado, onSuccess: cargarEmpleados),
        onReactivar: (empleado) => reactivarEmpleado(empleado, onSuccess: cargarEmpleados),
        onModificar: (empleado) => modificarEmpleado(empleado, onSuccess: cargarEmpleados),
      ),
    );
  }
}

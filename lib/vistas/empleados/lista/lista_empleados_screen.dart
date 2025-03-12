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
import '../../../controllers/usuario_empleado_controller.dart';

class ListaEmpleadosScreen extends StatefulWidget {
  final UsuarioEmpleadoController controller;

  const ListaEmpleadosScreen({super.key, required this.controller});

  @override
  State<ListaEmpleadosScreen> createState() => _ListaEmpleadosScreenState();
}

class _ListaEmpleadosScreenState extends State<ListaEmpleadosScreen>
    with EmpleadosErrorHandler, EmpleadosAcciones {
  late final EmpleadosEstado estado;
  
  // Timer para actualización automática
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    estado = EmpleadosEstado();
    inicializarErrorHandler(context);
    inicializarAcciones(widget.controller, context);

    // Inicialización después de montar el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.controller.isInitialized) {
        widget.controller
            .inicializar()
            .then((_) {
              if (mounted) setState(() {});
            })
            .catchError((e) {
              if (mounted) manejarError(e);
            });
      }
      cargarEmpleados();
      
      // Iniciar actualización automática cada 30 segundos
      _iniciarActualizacionAutomatica();
    });
  }
  
  void _iniciarActualizacionAutomatica() {
    // Cancelar timer existente si hay uno
    _autoRefreshTimer?.cancel();
    
    // Crear nuevo timer que se ejecuta cada 30 segundos
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          developer.log('Ejecutando actualización automática de empleados');
          // Cargar datos sin mostrar indicador de carga para no interrumpir al usuario
          _cargarEmpleadosSilenciosamente();
        }
      },
    );
  }

  // Cargar datos sin mostrar indicador de carga
  Future<void> _cargarEmpleadosSilenciosamente() async {
    try {
      final conexionExitosa = await widget.controller.verificarConexion();
      if (conexionExitosa) {
        await widget.controller.cargarEmpleadosConRefresco();
      }
    } catch (e) {
      developer.log('Error en actualización automática: $e');
      // No mostrar errores al usuario para actualizaciones en segundo plano
    }
  }

  Future<void> cargarEmpleados() async {
    if (!mounted) return;

    setState(() {
      estado.iniciarCarga();
    });

    try {
      final conexionExitosa = await widget.controller.verificarConexion();

      if (!conexionExitosa) {
        throw Exception("No se pudo establecer conexión con la base de datos");
      }

      await widget.controller.cargarEmpleadosConReintentos(2);

      if (mounted) setState(() => estado.finalizarCarga());
    } catch (e, stackTrace) {
      if (mounted) manejarError(e, stackTrace);
    }
  }

  void cambiarFiltroInactivos(bool value) {
    setState(() => estado.mostrarInactivos = value);
  }

  void _navegarANuevoEmpleado() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NuevoEmpleadoScreen(
          usuarioEmpleadoController: widget.controller,
        ),
      ),
    ).then((_) => cargarEmpleados());
  }
  
  @override
  void dispose() {
    // Cancelar el timer de actualización automática
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppScaffold(
          title: 'Gestión de Empleados',
          currentRoute: '/empleados',
          actions: [
            EmpleadosFiltro(
              mostrarInactivos: estado.mostrarInactivos,
              onChanged: cambiarFiltroInactivos,
              isLoading: estado.isLoading,
              onRefresh: cargarEmpleados,
            ),
          ],
          body: _buildBody(),
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

  Widget _buildBody() {
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
      stream: widget.controller.empleados,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return EmpleadosErrorView(
            errorMessage: snapshot.error.toString(),
            onRetry: cargarEmpleados,
          );
        }

        if (!snapshot.hasData && !estado.isLoading) {
          return EmpleadosEmptyView(
            mostrandoInactivos: estado.mostrarInactivos,
            onNuevoEmpleado: _navegarANuevoEmpleado,
          );
        }

        if (snapshot.hasData) {
          final empleados = snapshot.data!;
          final empleadosFiltrados =
              estado.mostrarInactivos
                  ? empleados
                  : empleados.where((e) => e.empleado.idEstado == 1).toList();

          if (empleadosFiltrados.isEmpty) {
            return EmpleadosEmptyView(
              mostrandoInactivos: estado.mostrarInactivos,
              onNuevoEmpleado: _navegarANuevoEmpleado,
            );
          }

          return RefreshIndicator(
            onRefresh: cargarEmpleados,
            child: EmpleadosListView(
              empleados: empleadosFiltrados,
              onItemTap: (empleado) => 
                  modificarEmpleado(empleado, onSuccess: cargarEmpleados),
              onAgregarEmpleado: _navegarANuevoEmpleado,
              onEliminar: (empleado) => 
                  inactivarEmpleado(empleado, onSuccess: cargarEmpleados),
              onReactivar: (empleado) => 
                  reactivarEmpleado(empleado, onSuccess: cargarEmpleados),
              onModificar: (empleado) => 
                  modificarEmpleado(empleado, onSuccess: cargarEmpleados),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
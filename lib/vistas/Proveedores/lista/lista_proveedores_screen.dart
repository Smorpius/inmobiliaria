import 'dart:async';
import 'proveedores_estado.dart';
import 'proveedores_filtro.dart';
import 'proveedores_acciones.dart';
import 'proveedores_list_view.dart';
import 'proveedores_empty_view.dart';
import 'proveedores_error_view.dart';
import 'dart:developer' as developer;
import 'proveedores_error_handler.dart';
import 'package:flutter/material.dart';
import '../nuevo_proveedor_screen.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../models/proveedor.dart';
import '../../../controllers/proveedor_controller.dart';

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
    estado = ProveedoresEstado();
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
      cargarProveedores();
      
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
          cargarProveedores();
        }
      },
    );
  }
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> cargarProveedores() async {
    if (estado.isLoading) return;
    
    try {
      setState(() {
        estado.isLoading = true;
        estado.tieneError = false;
        estado.mensajeError = null;
      });

      await widget.controller.cargarProveedores();
      
      if (mounted) {
        setState(() {
          estado.isLoading = false;
          // Actualizar la clave del stream para forzar reconstrucción
          estado.regenerarStreamKey();
        });
      }
    } catch (e, stackTrace) {
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
    // Navegar a la pantalla de nuevo proveedor
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevoProveedorScreen(
          controller: widget.controller,
        ),
      ),
    ).then((_) => cargarProveedores());
  }

  void cambiarFiltroInactivos(bool mostrarInactivos) {
    if (estado.mostrarInactivos != mostrarInactivos) {
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
          body: _buildBody(),
        ),
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
      return ProveedoresErrorView(
        errorMessage: estado.mensajeError!,
        stackTrace: estado.stackTrace,
        onRetry: cargarProveedores,
      );
    }

    return StreamBuilder<List<Proveedor>>(
      key: estado.streamKey,
      stream: widget.controller.proveedores,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ProveedoresErrorView(
            errorMessage: snapshot.error.toString(),
            onRetry: cargarProveedores,
          );
        }

        if (!snapshot.hasData && !estado.isLoading) {
          return ProveedoresEmptyView(
            mostrandoInactivos: estado.mostrarInactivos,
            onNuevoProveedor: _navegarANuevoProveedor,
          );
        }

        if (snapshot.hasData) {
          final proveedores = snapshot.data!;
          final proveedoresFiltrados =
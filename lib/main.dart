import 'vistas/vista_user.dart';
import 'vistas/vista_menu.dart';
import 'dart:developer' as developer;
import 'vistas/inmuebles/index.dart';
import 'package:flutter/material.dart';
import 'providers/providers_global.dart';
import 'vistas/clientes/vista_clientes.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vistas/empleados/lista/lista_empleados_screen.dart';
import 'vistas/Proveedores/lista/lista_proveedores_screen.dart';
import 'package:inmobiliaria/vistas/ventas/lista_ventas_screen.dart';
import 'package:inmobiliaria/vistas/ventas/reportes_ventas_screen.dart';

// Nueva importación

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar datos de fecha para español
  await initializeDateFormatting('es_ES', null);
  developer.log('Inicialización de formato de fecha completada');

  // Ejecutar la aplicación con ProviderScope sin overrides
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar errores globales
    final errorGlobal = ref.watch(errorGlobalProvider);

    // Usar el provider de inicialización centralizado
    final appInit = ref.watch(appInitializationProvider);

    return MaterialApp(
      title: 'Inmobiliaria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // Mostrar errores globales
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            if (errorGlobal != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            errorGlobal,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed:
                              () =>
                                  ref
                                      .read(errorGlobalProvider.notifier)
                                      .clearError(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      // Usar el estado de inicialización para mostrar la pantalla adecuada
      home: appInit.when(
        data: (_) => const HomePage(),
        loading:
            () => const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Inicializando aplicación...'),
                  ],
                ),
              ),
            ),
        error:
            (error, stack) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error al inicializar la aplicación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(error.toString()),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(appInitializationProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
      ),
      // Rutas de la aplicación
      routes: {
        '/usuario': (context) => const UsuarioPageWrapper(),
        '/clientes': (context) => const VistaClientes(),
        '/inmuebles': (context) => const InmuebleListScreen(),
        '/empleados': (context) => const EmpleadosScreenWrapper(),
        '/proveedores': (context) => const ListaProveedoresScreen(),
        '/ventas': (context) => const ListaVentasScreen(),
        '/ventas/reportes':
            (context) => const ReportesVentasScreen(), // Agregada ruta
      },
    );
  }
}

// Wrappers para pantallas que necesitan acceso a providers
class UsuarioPageWrapper extends ConsumerWidget {
  const UsuarioPageWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioController = ref.watch(usuarioControllerProvider);
    return UsuarioPage(usuarioController: usuarioController);
  }
}

// Versión corregida - Ya no pasa explícitamente el controller
class EmpleadosScreenWrapper extends ConsumerWidget {
  const EmpleadosScreenWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ya no necesitamos pasar el controller explícitamente
    return const ListaEmpleadosScreen();
  }
}

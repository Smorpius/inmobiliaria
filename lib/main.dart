import 'vistas/vista_menu.dart';
import 'vistas/inmuebles/index.dart';
import 'package:flutter/material.dart';
import 'vistas/usuario/vista_user.dart';
import 'providers/providers_global.dart';
import 'vistas/clientes/vista_clientes.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/applogger.dart'; // Importación del AppLogger
import 'vistas/empleados/lista/lista_empleados_screen.dart';
import 'vistas/Proveedores/lista/lista_proveedores_screen.dart';
import 'utils/archivo_utils.dart'; // Importación de ArchivoUtils
import 'utils/app_colors.dart'; // Importar nuestra clase de colores
import 'utils/pdf_font_helper.dart'; // Importación de PdfFontHelper
import 'package:inmobiliaria/vistas/ventas/lista_ventas_screen.dart';
import 'package:inmobiliaria/vistas/ventas/reportes_ventas_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Importar
import 'vistas/documentos/documentos_screen.dart'; // Importar la nueva pantalla
import 'vistas/estadisticas/estadisticas_dashboard_screen.dart'; // Importar pantalla de estadísticas
import 'vistas/estadisticas/ventas/reporte_ventas_screen.dart'; // Importar pantalla de reporte de ventas
import 'vistas/estadisticas/rentas/reporte_rentas_screen.dart'; // Importar pantalla de reporte de rentas

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.init(
      level: LogLevel.error,
    ); // Cambiado a "info" para mostrar solo información importante

    // Inicializar y precargar fuentes para PDFs con timeout
    try {
      await PdfFontHelper.init();
      AppLogger.info('Sistema de fuentes para PDFs inicializado correctamente');
    } catch (e) {
      AppLogger.error(
        'Error al inicializar sistema de fuentes para PDFs',
        e,
        StackTrace.current,
      );
    }

    // Crear estructura de directorios necesarios para la aplicación
    try {
      final directoriosCreados =
          await ArchivoUtils.crearDirectoriosNecesarios();
      if (directoriosCreados) {
        AppLogger.info('Estructura de directorios inicializada correctamente');
      } else {
        AppLogger.warning(
          'No se pudieron crear todos los directorios necesarios',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error al crear estructura de directorios',
        e,
        StackTrace.current,
      );
    }

    // Inicializar datos de fecha para español
    await initializeDateFormatting('es_ES', null);
    AppLogger.info('Inicialización de formato de fecha completada');

    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stack) {
    AppLogger.error('ERROR CRÍTICO DE INICIALIZACIÓN', e, stack);
  }
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
        primaryColor: AppColors.primario,
        primarySwatch:
            Colors
                .teal, // Esto debería cambiarse por un MaterialColor personalizado
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primario,
          primary: AppColors.primario,
          secondary: AppColors.acento,
          surface: AppColors.claro,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.claro,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.claro,
          foregroundColor: AppColors.primario,
          elevation: 2,
        ),
        useMaterial3: true,
      ),
      // Añadir configuración de localización
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español de España
        Locale('es', 'MX'), // Español de México (si lo necesitas)
        Locale('en', ''), // Inglés (opcional)
        // ... otros locales que necesites
      ],
      locale: const Locale(
        'es',
        'ES',
      ), // Establecer español como idioma por defecto
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
        error: (error, stack) {
          // Registrar el error mediante AppLogger
          AppLogger.error(
            'Error de inicialización de la aplicación',
            error,
            stack,
          );

          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error al inicializar la aplicación',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          );
        },
      ),
      // Rutas de la aplicación
      routes: {
        '/usuario': (context) => const UsuarioPageWrapper(),
        '/clientes': (context) => const VistaClientes(),
        '/inmuebles': (context) => const InmuebleListScreen(),
        '/empleados': (context) => const EmpleadosScreenWrapper(),
        '/proveedores': (context) => const ListaProveedoresScreen(),
        '/ventas': (context) => const ListaVentasScreen(),
        '/ventas/reportes': (context) => const ReportesVentasScreen(),
        '/documentos': (context) => const DocumentosScreen(),
        '/estadisticas': (context) => const EstadisticasDashboardScreen(),
        '/estadisticas/ventas':
            (context) => ReporteVentasScreen(
              periodoInicial: DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 30)),
                end: DateTime.now(),
              ),
            ),
        '/estadisticas/rentas':
            (context) => ReporteRentasScreen(
              periodoInicial: DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 30)),
                end: DateTime.now(),
              ),
            ),
      },
      // Manejador para rutas desconocidas
      onUnknownRoute: (settings) {
        AppLogger.warning(
          'Intento de acceder a ruta desconocida: ${settings.name}',
        );
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Página no encontrada'),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'La página solicitada no existe',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No se pudo encontrar la ruta: ${settings.name}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed:
                            () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (route) => false,
                            ),
                        child: const Text('Volver al inicio'),
                      ),
                    ],
                  ),
                ),
              ),
        );
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
    return const ListaEmpleadosScreen();
  }
}

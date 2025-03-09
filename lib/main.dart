import 'vistas/vista_user.dart';
import 'vistas/vista_menu.dart';
import 'services/mysql_helper.dart';
import 'services/auth_service.dart';
import 'vistas/vista_inmuebles.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'controllers/usuario_controller.dart';
import 'services/usuario_empleado_service.dart';
import 'controllers/usuario_empleado_controller.dart';
import 'vistas/empleados/lista/lista_empleados_screen.dart';
import 'vistas/clientes/vista_clientes.dart';  // Importación correcta
import 'package:intl/date_symbol_data_local.dart'; // Para inicializar los datos de fecha local
import 'services/image_service.dart'; // Mantenemos el import original (que ahora es una fachada)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar datos de fecha para español
  await initializeDateFormatting('es_ES', null);

  // Inicializar servicio de caché de imágenes
  final imageService = ImageService(); // Esta instancia ahora usa la fachada
  imageService.scheduleCacheCleanup(); // Programar limpieza periódica de caché
  developer.log('Servicio de caché de imágenes inicializado');

  // Inicialización de servicios
  final dbService = DatabaseService();
  await dbService.connection;

  // Controladores existentes
  final usuarioController = UsuarioController(dbService: dbService);
  final authService = AuthService(usuarioController);

  // Nuevo servicio y controlador para Usuario-Empleado
  final usuarioEmpleadoService = UsuarioEmpleadoService(dbService);
  final usuarioEmpleadoController = UsuarioEmpleadoController(
    usuarioEmpleadoService,
  );

  // Inicializar el controlador de empleados en segundo plano
  // para tener los datos disponibles cuando se abra la pantalla
  usuarioEmpleadoController
      .inicializar()
      .then((_) {
        developer.log('Controlador de empleados inicializado correctamente');
      })
      .catchError((e) {
        developer.log(
          'Error al pre-inicializar el controlador de empleados: $e',
          error: e,
        );
        // No bloqueamos la UI con este error, se manejará en la pantalla si es necesario
      });

  runApp(
    MyApp(
      usuarioController: usuarioController,
      authService: authService,
      usuarioEmpleadoController: usuarioEmpleadoController,
    ),
  );
}

class MyApp extends StatelessWidget {
  final UsuarioController usuarioController;
  final AuthService authService;
  final UsuarioEmpleadoController usuarioEmpleadoController;

  const MyApp({
    super.key,
    required this.usuarioController,
    required this.authService,
    required this.usuarioEmpleadoController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inmobiliaria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
      routes: {
        '/usuario':
            (context) => UsuarioPage(usuarioController: usuarioController),
        '/clientes': (context) => const VistaClientes(), // CORREGIDO: ClientesScreen -> VistaClientes
        '/inmuebles': (context) => const HomeScreen(),
        '/empleados':
            (context) =>
                ListaEmpleadosScreen(controller: usuarioEmpleadoController),
      },
    );
  }
}
import 'vistas/vista_user.dart';
import 'vistas/vista_menu.dart';
import 'vistas/vista_clientes.dart';
import 'services/mysql_helper.dart';
import 'services/auth_service.dart';
import 'vistas/vista_inmuebles.dart';
import 'package:flutter/material.dart';
import 'controllers/usuario_controller.dart';
import 'vistas/lista_empleados_screen.dart'; // Nueva importación
import 'services/usuario_empleado_service.dart'; // Nueva importación
import 'controllers/usuario_empleado_controller.dart'; // Nueva importación

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización de servicios
  final dbService = DatabaseService();
  await dbService.connection;
  
  // Controladores existentes
  final usuarioController = UsuarioController(dbService: dbService);
  final authService = AuthService(usuarioController);
  
  // Nuevo servicio y controlador para Usuario-Empleado
  final usuarioEmpleadoService = UsuarioEmpleadoService(dbService);
  final usuarioEmpleadoController = UsuarioEmpleadoController(usuarioEmpleadoService);

  runApp(
    MyApp(
      usuarioController: usuarioController,
      authService: authService,
      usuarioEmpleadoController: usuarioEmpleadoController, // Nuevo controlador
    ),
  );
}

class MyApp extends StatelessWidget {
  final UsuarioController usuarioController;
  final AuthService authService;
  final UsuarioEmpleadoController usuarioEmpleadoController; // Nuevo controlador

  const MyApp({
    super.key,
    required this.usuarioController,
    required this.authService,
    required this.usuarioEmpleadoController, // Agregar al constructor
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
        '/usuario': (context) => UsuarioPage(usuarioController: usuarioController),
        '/clientes': (context) => const ClientesScreen(),
        '/inmuebles': (context) => const HomeScreen(),
        '/empleados': (context) => ListaEmpleadosScreen(
          controller: usuarioEmpleadoController
        ), // Nueva ruta para la vista de empleados
      },
    );
  }
}
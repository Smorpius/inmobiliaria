import 'vistas/usuario.dart';
import 'vistas/clientes.dart';
import 'services/mysql_helper.dart';
import 'services/auth_service.dart';
import 'package:flutter/material.dart';
import 'controllers/usuario_controller.dart';
import 'package:inmobiliaria/vistas/menu.dart';
import 'vistas/inmuebles.dart'; // Añade esta importación

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegura la inicialización
  final dbService = DatabaseService();
  await dbService.connection; // Espera la conexión a la base de datos
  final usuarioController = UsuarioController(dbService: dbService);
  final authService = AuthService(usuarioController);

  runApp(MyApp(usuarioController: usuarioController, authService: authService));
}

class MyApp extends StatelessWidget {
  final UsuarioController usuarioController;
  final AuthService authService;

  const MyApp({
    super.key,
    required this.usuarioController,
    required this.authService,
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
        '/inmuebles': (context) => const HomeScreen(), // Añade esta ruta
      },
    );
  }
}
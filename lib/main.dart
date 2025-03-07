import 'vistas/vista_user.dart';
import 'vistas/vista_menu.dart';
import 'vistas/vista_clientes.dart';
import 'services/mysql_helper.dart';
import 'services/auth_service.dart';
import 'package:flutter/material.dart';
import 'controllers/usuario_controller.dart';
import 'vistas/vista_inmuebles.dart'; // Import para la pantalla de Inmuebles

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = DatabaseService();
  await dbService.connection; 
  final usuarioController = UsuarioController(dbService: dbService);
  final authService = AuthService(usuarioController);

  runApp(
    MyApp(
      usuarioController: usuarioController,
      authService: authService,
    ),
  );
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
        '/inmuebles': (context) => const HomeScreen(),
      },
    );
  }
}
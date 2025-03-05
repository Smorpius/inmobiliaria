import 'vistas/usuario.dart';
import 'vistas/clientes.dart';
import 'services/mysql_helper.dart';
import 'services/auth_service.dart';
import 'package:flutter/material.dart';
import 'controllers/usuario_controller.dart';
import 'package:inmobiliaria/vistas/menu.dart';

Future<void> main() async {
  // Use dependency injection
  final dbService = DatabaseService();
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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomePage(),
      routes: {
        '/usuario':
            (context) => UsuarioPage(usuarioController: usuarioController),
        '/clientes': (context) => ClientesScreen(),
      },
    );
  }
}

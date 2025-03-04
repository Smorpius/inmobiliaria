import 'package:flutter/material.dart';
import 'package:inmobiliaria/vistas/menu.dart';
import 'vistas/usuario.dart'; // Importa la clase UsuarioPage
import 'vistas/Clientes.dart'; // Importa la clase ClientesScreen
import 'services/mysql_helper.dart'; // Importa la clase MySqlHelper
import 'controllers/usuario_controller.dart'; // Importa la clase UsuarioController

Future<void> main() async {
  // Initialize MySQL connection
  final mysqlHelper = MySqlHelper();
  final connection = await mysqlHelper.connection;

  // Pass the connection to controllers
  final usuarioController = UsuarioController(connection);

  runApp(MyApp(usuarioController: usuarioController));
}

class MyApp extends StatelessWidget {
  final UsuarioController usuarioController;

  const MyApp({super.key, required this.usuarioController});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomePage(), // Cambia la clase inicial a InicioUsuario
      routes: {
        '/usuario':
            (context) => UsuarioPage(
              usuarioController: usuarioController,
            ), // Define la ruta
        '/clientes':
            (context) => ClientesScreen(), // Define la ruta para Clientes
      },
    );
  }
}

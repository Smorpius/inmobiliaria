import 'package:flutter/material.dart';
import 'package:inmobiliaria/vistas/menu.dart';
import 'vistas/usuario.dart'; // Importa la clase UsuarioPage
import 'vistas/Clientes.dart'; // Importa la clase ClientesScreen
import 'vistas/Inicio_Usuario.dart'; // Importa la clase InicioUsuario

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomePage(), // Cambia la clase inicial a InicioUsuario
      routes: {
        '/usuario': (context) => const UsuarioPage(), // Define la ruta
        '/clientes':
            (context) => ClientesScreen(), // Define la ruta para Clientes
      },
    );
  }
}

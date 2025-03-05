import 'usuario.dart';
import 'clientes.dart';
import 'package:flutter/material.dart';
import '../services/mysql_helper.dart';
import '../controllers/usuario_controller.dart';
import '../services/connection_test.dart'; // Importación para el test de conexión

void main() async {
  final mysqlHelper = DatabaseService();
  await mysqlHelper.connection; // Establece la conexión
  final usuarioController = UsuarioController(dbService: mysqlHelper);

  runApp(MyApp(usuarioController: usuarioController));
}

class MyApp extends StatelessWidget {
  final UsuarioController usuarioController;

  const MyApp({super.key, required this.usuarioController});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      routes: {
        '/usuario':
            (context) => UsuarioPage(usuarioController: usuarioController),
        '/clientes': (context) => const ClientesScreen(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("Usuario"),
              accountEmail: Text("correo@example.com"),
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.person, size: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Acción para Ventas
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text("Ventas"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Acción para Inicio
                },
                icon: const Icon(Icons.home),
                label: const Text("Inicio"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/usuario');
                },
                icon: const Icon(Icons.people),
                label: const Text("Usuarios"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/clientes');
                },
                icon: const Icon(Icons.person),
                label: const Text("Clientes"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Acción para Documentos
                },
                icon: const Icon(Icons.article),
                label: const Text("Documentos"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Acción para Estadísticas
                },
                icon: const Icon(Icons.show_chart),
                label: const Text("Estadísticas"),
              ),
            ),
            // Nuevo botón para probar la conexión a la base de datos
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Mostrar indicador de carga
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Comprobando conexión a la base de datos...',
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  // Comprobar conexión a la base de datos
                  final result = await DatabaseConnectionTest.testConnection();

                  if (!context.mounted) return;

                  // Mostrar resultado
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result
                            ? '✅ Conexión exitosa a la base de datos'
                            : '❌ Error al conectar a la base de datos',
                      ),
                      backgroundColor: result ? Colors.green : Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.storage,
                ), // Cambiado de database a storage
                label: const Text("Probar Conexión BD"),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("VENTAS", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "FAVORITOS",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.center,
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    Image.asset('assets/logo.png', height: 100),
                    const SizedBox(height: 10),
                    const Text(
                      "CASITAS REAL ESTATE",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

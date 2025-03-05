import 'usuario.dart';
import 'clientes.dart';
import 'package:flutter/material.dart';
import '../services/mysql_helper.dart';
import '../controllers/usuario_controller.dart';
import 'inmuebles.dart'; // Importamos la vista de inmuebles
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
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ),
      home: const HomePage(),
      routes: {
        '/usuario':
            (context) => UsuarioPage(usuarioController: usuarioController),
        '/clientes': (context) => const ClientesScreen(),
        '/inmuebles':
            (context) => const HomeScreen(), // Añadiendo ruta para inmuebles
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
        width: 280,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.teal.shade50, Colors.white],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.teal.shade700, Colors.teal.shade500],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 36,
                      child: Icon(Icons.person, size: 50, color: Colors.teal),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Usuario",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "correo@example.com",
                      style: TextStyle(
                        color: Colors.grey.shade100,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildDrawerButton(
                icon: Icons.home,
                label: "Inicio",
                onPressed: () {
                  Navigator.pop(context); // Solo cierra el drawer
                },
                context: context,
              ),
              _buildDrawerButton(
                icon: Icons.people,
                label: "Usuarios",
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/usuario');
                },
                context: context,
              ),
              _buildDrawerButton(
                icon: Icons.person,
                label: "Clientes",
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/clientes');
                },
                context: context,
              ),
              _buildDrawerButton(
                icon: Icons.home_work,
                label: "Inmobiliaria",
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/inmuebles');
                },
                context: context,
                highlighted: true,
              ),
              _buildDrawerButton(
                icon: Icons.shopping_cart,
                label: "Ventas",
                onPressed: () {
                  // Acción para Ventas
                  Navigator.pop(context);
                },
                context: context,
              ),
              _buildDrawerButton(
                icon: Icons.article,
                label: "Documentos",
                onPressed: () {
                  // Acción para Documentos
                  Navigator.pop(context);
                },
                context: context,
              ),
              _buildDrawerButton(
                icon: Icons.show_chart,
                label: "Estadísticas",
                onPressed: () {
                  // Acción para Estadísticas
                  Navigator.pop(context);
                },
                context: context,
              ),
              const Divider(),
              _buildDrawerButton(
                icon: Icons.storage,
                label: "Probar Conexión BD",
                onPressed: () async {
                  Navigator.pop(context);

                  // Mostrar indicador de carga
                  if (!context.mounted) return;
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
                context: context,
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text(
          "VENTAS",
          style: TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        iconTheme: const IconThemeData(color: Colors.teal),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // Acción para notificaciones
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade50, Colors.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Buscar...",
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                  suffixIcon: const Icon(Icons.mic, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "FAVORITOS",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16.0),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildFeatureCard(
                    context,
                    "Inmuebles",
                    Icons.home_work,
                    Colors.teal,
                    () {
                      Navigator.pushNamed(context, '/inmuebles');
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    "Clientes",
                    Icons.people,
                    Colors.blue,
                    () {
                      Navigator.pushNamed(context, '/clientes');
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    "Ventas",
                    Icons.shopping_cart,
                    Colors.orange,
                    () {
                      // Acción para sección de ventas
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    "Reportes",
                    Icons.bar_chart,
                    Colors.purple,
                    () {
                      // Acción para sección de reportes
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    Image.asset('assets/logo.png', height: 60),
                    const SizedBox(height: 8),
                    const Text(
                      "CASITAS REAL ESTATE",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método auxiliar para crear botones del drawer
  Widget _buildDrawerButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required BuildContext context,
    bool highlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Material(
        color: highlighted ? Colors.teal.withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: highlighted ? Colors.teal : Colors.grey.shade700,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: highlighted ? Colors.teal : Colors.black87,
                    fontWeight:
                        highlighted ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Método auxiliar para crear tarjetas de características
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    // Crear un color más oscuro para el texto
    final textColor = color is MaterialColor ? color.shade700 : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shadowColor: color.withAlpha(76), // 0.3 como alpha ≈ 76
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25), // 0.1 como alpha ≈ 25
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

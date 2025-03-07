import 'package:flutter/material.dart';
import '../services/connection_test.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget body;
  final List<Widget>? actions;
  final bool showDrawer;

  const AppScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.body,
    this.actions,
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Solo mostrar el drawer en las vistas internas, no en el menú principal
      drawer: showDrawer ? _buildDrawer(context) : null,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        iconTheme: const IconThemeData(color: Colors.teal),
        actions:
            actions ??
            [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  // Acción para notificaciones
                },
              ),
              const SizedBox(width: 8),
            ],
      ),
      body: body,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
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
                    style: TextStyle(color: Colors.grey.shade100, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildDrawerButton(
              icon: Icons.home,
              label: "Inicio",
              route: '/',
              currentRoute: currentRoute,
              context: context,
            ),
            _buildDrawerButton(
              icon: Icons.people,
              label: "Usuarios",
              route: '/usuario',
              currentRoute: currentRoute,
              context: context,
            ),
            _buildDrawerButton(
              icon: Icons.person,
              label: "Clientes",
              route: '/clientes',
              currentRoute: currentRoute,
              context: context,
            ),
            _buildDrawerButton(
              icon: Icons.home_work,
              label: "Inmobiliaria",
              route: '/inmuebles',
              currentRoute: currentRoute,
              context: context,
            ),
            _buildDrawerButton(
              icon: Icons.shopping_cart,
              label: "Ventas",
              route: '/ventas',
              currentRoute: currentRoute,
              context: context,
            ),
            _buildDrawerButton(
              icon: Icons.article,
              label: "Documentos",
              route: '/documentos',
              currentRoute: currentRoute,
              context: context,
            ),
            _buildDrawerButton(
              icon: Icons.show_chart,
              label: "Estadísticas",
              route: '/estadisticas',
              currentRoute: currentRoute,
              context: context,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
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

                    // Comprobar conexión
                    final result =
                        await DatabaseConnectionTest.testConnection();

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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.storage,
                          color: Colors.grey.shade700,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Probar Conexión BD",
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerButton({
    required IconData icon,
    required String label,
    required String route,
    required String currentRoute,
    required BuildContext context,
  }) {
    final bool highlighted = route == currentRoute;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Material(
        color: highlighted ? Colors.teal.withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pop(context);
            if (route == currentRoute) return;

            if (route == '/') {
              Navigator.pushReplacementNamed(context, route);
            } else {
              Navigator.pushNamed(context, route);
            }
          },
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
}

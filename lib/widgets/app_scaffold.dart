import 'package:flutter/material.dart';
//import '../services/connection_test.dart';

class AppScaffold extends StatelessWidget {
  // Definición de la paleta de colores en RGB
  static const Color colorPrimario = Color.fromRGBO(165, 57, 45, 1); // #A5392D
  static const Color colorOscuro = Color.fromRGBO(26, 26, 26, 1); // #1A1A1A
  static const Color colorClaro = Color.fromRGBO(247, 245, 242, 1); // #F7F5F2
  static const Color colorGrisClaro = Color.fromRGBO(
    212,
    207,
    203,
    1,
  ); // #D4CFCB
  static const Color colorAcento = Color.fromRGBO(216, 86, 62, 1); // #D8563E

  final String title;
  final String currentRoute;
  final Widget body;
  final List<Widget>? actions;
  final bool showDrawer;
  final Widget? bottomNavigationBar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.body,
    this.actions,
    this.showDrawer = true,
    this.bottomNavigationBar,
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
            color: colorPrimario,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: colorClaro,
        elevation: 2,
        shadowColor: colorOscuro.withValues(
          red: 26,
          green: 26,
          blue: 26,
          alpha: 66,
        ), // equivalente a opacidad 0.26
        iconTheme: const IconThemeData(color: colorPrimario),
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
      bottomNavigationBar: bottomNavigationBar,
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
            colors: [colorGrisClaro, colorClaro],
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
                  colors: [colorPrimario, colorAcento],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: colorClaro,
                    radius: 36,
                    child: Icon(Icons.person, size: 50, color: colorPrimario),
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
                    "Administrador",
                    style: TextStyle(
                      color: Colors.white, // Color blanco puro
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
              route: '/',
              currentRoute: currentRoute,
              context: context,
            ),
            /*_buildDrawerButton(
              icon: Icons.people,
              label: "Usuarios",
              route: '/usuario',
              currentRoute: currentRoute,
              context: context,
            ),
            */
            // Nuevo botón para Empleados
            _buildDrawerButton(
              icon: Icons.badge,
              label: "Empleados",
              route: '/empleados',
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
            // NUEVO: Botón para Proveedores
            _buildDrawerButton(
              icon: Icons.inventory,
              label: "Proveedores",
              route: '/proveedores',
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
            /*
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

                    // Comprobar conexión - ESTA ES LA CORRECCIÓN
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
                          color: colorPrimario, // Mejorar visibilidad
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "Probar Conexión BD",
                          style: TextStyle(fontSize: 16, color: colorOscuro),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),*/
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
        color:
            highlighted
                ? colorAcento.withValues(
                  red: 216,
                  green: 86,
                  blue: 62,
                  alpha: 40, // Color más suave pero visible
                )
                : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pop(context);
            if (route == currentRoute) return;

            if (route == '/') {
              // Elimina todas las rutas anteriores de la pila
              Navigator.pushNamedAndRemoveUntil(
                context,
                route,
                (route) => false,
              );
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
                  color:
                      highlighted
                          ? Colors.white
                          : colorPrimario, // Usar color primario para mejor visibilidad
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: highlighted ? Colors.white : colorOscuro,
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

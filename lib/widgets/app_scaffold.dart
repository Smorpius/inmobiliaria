import 'package:flutter/material.dart';
import '../utils/app_colors.dart'; // Importar la clase de colores centralizada

class AppScaffold extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget body;
  final List<Widget>? actions;
  final bool showDrawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton; // Nuevo parámetro

  const AppScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.body,
    this.actions,
    this.showDrawer = true,
    this.bottomNavigationBar,
    this.floatingActionButton, // Añadir al constructor
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
            color: AppColors.primario, // Usar AppColors
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: AppColors.claro, // Usar AppColors
        elevation: 2,
        shadowColor: AppColors.withValues(
          // Usar método de AppColors
          color: AppColors.oscuro,
          alpha: 66,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.primario,
        ), // Usar AppColors
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
      floatingActionButton:
          floatingActionButton, // Pasar el parámetro al Scaffold
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
            colors: [AppColors.grisClaro, AppColors.claro], // Usar AppColors
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
                  colors: [
                    AppColors.primario,
                    AppColors.acento,
                  ], // Usar AppColors
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.claro, // Usar AppColors
                    radius: 36,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primario,
                    ), // Usar AppColors
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
                    style: TextStyle(color: Colors.white, fontSize: 14),
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
                ? AppColors.withValues(
                  // Usar método de AppColors
                  color: AppColors.acento,
                  alpha: 40,
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
                          : AppColors.primario, // Usar AppColors
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        highlighted
                            ? Colors.white
                            : AppColors.oscuro, // Usar AppColors
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

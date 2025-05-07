import 'package:flutter/material.dart';
import '../utils/app_colors.dart'; // Importar AppColors

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "CASITAS REAL ESATEE",
          style: TextStyle(
            color: AppColors.primario,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.claro,
        elevation: 2,
        shadowColor: AppColors.withAlpha(AppColors.oscuro, 66), // 0.26 opacity
        iconTheme: const IconThemeData(color: AppColors.primario),
      ),
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.grisClaro, AppColors.claro],
              ),
            ),
          ),

          // Logo grande y centrado con opacidad
          Center(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/logo.png',
                width: screenWidth * 0.8,
                height: screenHeight * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Contenido principal (tarjetas)
          Padding(
            padding: const EdgeInsets.all(8.0), // Margen pequeño en los bordes
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio:
                          (screenWidth - 28) / (screenHeight - 100),
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final options = [
                        {
                          'title': 'Inmuebles',
                          'icon': Icons.home_work,
                          'color': AppColors.primario, // #A5392D - Café rojizo
                          'route': '/inmuebles',
                        },
                        {
                          'title': 'Clientes',
                          'icon': Icons.people,
                          'color': AppColors.acento, // #D8563E - Café acentuado
                          'route': '/clientes',
                        },
                        {
                          'title': 'Ventas',
                          'icon': Icons.shopping_cart,
                          'color': AppColors.withValues(
                            color: AppColors.primario,
                            red: 125, // Tono café más oscuro
                            green: 45,
                            blue: 35,
                          ),
                          'route': '/ventas',
                        },
                        {
                          'title': 'Proveedores',
                          'icon': Icons.inventory,
                          'color': AppColors.withValues(
                            color: AppColors.primario,
                            red: 190, // Tono café más claro
                            green: 70,
                            blue: 55,
                          ),
                          'route': '/proveedores',
                        },
                      ];

                      if (index < options.length) {
                        return _buildFeatureCard(
                          context,
                          options[index]['title'] as String,
                          options[index]['icon'] as IconData,
                          options[index]['color'] as Color,
                          () {
                            final route = options[index]['route'] as String?;
                            if (route != null) {
                              Navigator.pushNamed(context, route);
                            }
                          },
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para crear tarjetas de características pequeñas con hover
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return FeatureCardHover(
      title: title,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }
}

// Widget con estado para manejar el efecto hover
class FeatureCardHover extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const FeatureCardHover({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<FeatureCardHover> createState() => _FeatureCardHoverState();
}

class _FeatureCardHoverState extends State<FeatureCardHover> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Card(
          color: AppColors.primario, // Color base para la tarjeta
          elevation: isHovered ? 8 : 4,
          shadowColor: AppColors.withAlpha(widget.color, 100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color:
                  isHovered
                      ? AppColors.claro
                      : AppColors.withValues(color: AppColors.claro, alpha: 0),
              width: 1.5,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isHovered
                      ? AppColors.withValues(
                        color: widget.color,
                        alpha: 255,
                      ) // Color del icono, opaco en hover (sin cambios)
                      : AppColors.withValues(
                        color: widget.color,
                        alpha: (255 * 0.90).round(),
                      ), // Color del icono, un poco más opaco en normal
                  isHovered
                      ? AppColors.withValues(
                        color: Color.lerp(widget.color, AppColors.claro, 0.1)!,
                        alpha: 255,
                      ) // Mezcla (90% icono, 10% claro), opaco en hover
                      : AppColors.withValues(
                        color: Color.lerp(widget.color, AppColors.claro, 0.3)!,
                        alpha: (255 * 0.85).round(),
                      ), // Mezcla (70% icono, 30% claro), un poco más opaco en normal
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isHovered ? 14 : 12),
                  decoration: BoxDecoration(
                    color:
                        isHovered
                            ? AppColors
                                .claro // Color claro de la paleta para estado hover
                            : AppColors
                                .grisClaro, // Color gris claro de la paleta para estado normal
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.withValues(
                        color: AppColors.primario,
                        alpha: isHovered ? 100 : 80,
                      ),
                      width: 2.0,
                    ),
                    boxShadow:
                        isHovered
                            ? [
                              BoxShadow(
                                color: AppColors.withAlpha(
                                  AppColors.primario,
                                  60,
                                ),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                            : [],
                  ),
                  child: Icon(
                    widget.icon,
                    color:
                        widget
                            .color, // Usar el color de la tarjeta para el icono
                    size: isHovered ? 32 : 26,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.withValues(
                      color: AppColors.claro,
                      red: 250,
                      green: 245,
                      blue: 240,
                    ),
                    fontSize: isHovered ? 16 : 14,
                    letterSpacing: 0.5,
                    shadows:
                        isHovered
                            ? [
                              Shadow(
                                blurRadius: 2.0,
                                color: AppColors.withAlpha(
                                  AppColors.oscuro,
                                  80,
                                ),
                                offset: const Offset(0, 1),
                              ),
                            ]
                            : [],
                  ),
                  textAlign: TextAlign.center,
                  child: Text(widget.title),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

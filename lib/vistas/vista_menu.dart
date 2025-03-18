import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            "CASITAS REAL ESATEE",
            style: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
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
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey.shade50, Colors.white],
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
                          'color': Colors.teal,
                          'route': '/inmuebles',
                        },
                        {
                          'title': 'Clientes',
                          'icon': Icons.people,
                          'color': Colors.blue,
                          'route': '/clientes',
                        },
                        {
                          'title': 'Ventas',
                          'icon': Icons.shopping_cart,
                          'color': Colors.orange,
                          'route': null,
                        },
                        {
                          'title': 'Proveedores',
                          'icon': Icons.inventory,
                          'color': Colors.purple,
                          'route':
                              '/proveedores', // MODIFICADO: Agregar ruta correcta
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
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color:
                isHovered
                    ? widget.color.withAlpha((0.3 * 255).toInt())
                    : Colors.white.withAlpha((0.6 * 255).toInt()),
            boxShadow:
                isHovered
                    ? [
                      BoxShadow(
                        color: widget.color.withAlpha((0.5 * 255).toInt()),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: widget.color.withAlpha((0.2 * 255).toInt()),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(isHovered ? 10 : 6),
                decoration: BoxDecoration(
                  color:
                      isHovered
                          ? widget.color.withAlpha((0.4 * 255).toInt())
                          : widget.color.withAlpha((0.2 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: isHovered ? Colors.white : widget.color,
                  size: isHovered ? 28 : 22,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isHovered ? Colors.white : widget.color,
                  fontSize: isHovered ? 14 : 12,
                ),
                textAlign: TextAlign.center,
                child: Text(widget.title),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

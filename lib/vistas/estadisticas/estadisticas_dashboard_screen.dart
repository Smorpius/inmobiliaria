import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import 'ventas/reporte_ventas_screen.dart';
import 'rentas/reporte_rentas_screen.dart';

class EstadisticasDashboardScreen extends StatefulWidget {
  const EstadisticasDashboardScreen({super.key});

  @override
  State<EstadisticasDashboardScreen> createState() =>
      _EstadisticasDashboardScreenState();
}

class _EstadisticasDashboardScreenState
    extends State<EstadisticasDashboardScreen> {
  // Período por defecto: último mes
  late DateTimeRange _periodoSeleccionado;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodoSeleccionado = DateTimeRange(
      start: DateTime(now.year, now.month - 1, now.day),
      end: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Estadísticas',
      currentRoute: '/estadisticas',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel de Estadísticas',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona una categoría para ver estadísticas detalladas',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: _calcularColumnasGrid(context),
                childAspectRatio: 1.3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCategoryCard(
                    context,
                    'Ventas',
                    'Estadísticas y rendimiento de ventas',
                    Icons.monetization_on,
                    Colors.green.shade700,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ReporteVentasScreen(
                              periodoInicial: _periodoSeleccionado,
                            ),
                      ),
                    ),
                  ),
                  _buildCategoryCard(
                    context,
                    'Rentas',
                    'Rendimiento de propiedades en renta',
                    Icons.home,
                    Colors.blue.shade700,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ReporteRentasScreen(
                              periodoInicial: _periodoSeleccionado,
                            ),
                      ),
                    ),
                  ),
                  _buildCategoryCard(
                    context,
                    'Clientes',
                    'Análisis de datos de clientes',
                    Icons.people,
                    Colors.purple.shade700,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidad en desarrollo'),
                        ),
                      );
                    },
                  ),
                  _buildCategoryCard(
                    context,
                    'Financiero',
                    'Análisis financiero global',
                    Icons.account_balance,
                    Colors.amber.shade700,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidad en desarrollo'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calcularColumnasGrid(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    if (ancho > 1200) return 4;
    if (ancho > 800) return 3;
    if (ancho > 600) return 2;
    return 1;
  }
}

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../models/venta_model.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../providers/provider_ventas.dart';
import '../../../providers/inmueble_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListaVentasScreen extends ConsumerWidget {
  const ListaVentasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inmuebleController = ref.watch(inmuebleControllerProvider);
    final ventasFuture = FutureProvider<List<Venta>>((ref) {
      return inmuebleController.getVentas();
    });

    final ventasAsyncValue = ref.watch(ventasFuture);

    return AppScaffold(
      title: 'Ventas',
      currentRoute: '/ventas',
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filtrar ventas',
          onPressed: () {
            // Implementar filtro por fecha
          },
        ),
      ],
      body: Column(
        children: [
          // Resumen de estadísticas
          Consumer(
            builder: (context, ref, child) {
              final estadisticas = ref.watch(ventasEstadisticasProvider);

              return Card(
                margin: const EdgeInsets.all(16),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Total Ventas',
                        estadisticas.totalVentas.toString(),
                        Icons.sell,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Ingresos',
                        '\$${estadisticas.ingresoTotal.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Utilidad',
                        '\$${estadisticas.utilidadTotal.toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Lista de ventas
          Expanded(
            child: ventasAsyncValue.when(
              data: (ventas) {
                if (ventas.isEmpty) {
                  return const Center(child: Text('No hay ventas registradas'));
                }

                return ListView.builder(
                  itemCount: ventas.length,
                  itemBuilder: (context, index) {
                    final venta = ventas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      child: ListTile(
                        title: Text(venta.nombreInmueble ?? 'Inmueble'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cliente: ${venta.nombreCliente ?? ''} ${venta.apellidoCliente ?? ''}',
                            ),
                            Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy').format(venta.fechaVenta)}',
                            ),
                            Text(
                              'Ingreso: \$${venta.ingreso.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Utilidad: \$${venta.utilidadNeta.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        onTap: () {
                          // Aquí puedes implementar la navegación a detalles de la venta
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stack) =>
                      Center(child: Text('Error al cargar ventas: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: Colors.grey.shade700)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}

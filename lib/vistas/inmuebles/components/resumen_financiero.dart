import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';
import '../../../models/resumen_renta_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/inmueble_renta_provider.dart';
import 'package:inmobiliaria/models/movimiento_renta_model.dart';
import 'package:intl/intl.dart'; // Importar intl para formatear fechas
import '../../../utils/app_colors.dart'; // Añadimos la importación de AppColors

class ResumenFinanciero extends ConsumerWidget {
  final Inmueble inmueble;
  final int anio;
  final int mes;

  ResumenFinanciero({
    super.key,
    required this.inmueble,
    required this.anio,
    required this.mes,
  });

  // Formateadores
  final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
  final formatDate = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Crear el parámetro para el provider
    final params = ResumenRentaParams(
      idInmueble: inmueble.id!,
      anio: anio,
      mes: mes,
    );

    // Obtener el resumen de la base de datos
    final resumenAsyncValue = ref.watch(resumenRentaPorMesProvider(params));

    return resumenAsyncValue.when(
      data: (resumen) => _construirResumen(context, resumen),
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: Text(
              'Error al cargar resumen: ${error.toString().split('\n').first}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
    );
  }

  Widget _construirResumen(BuildContext context, ResumenRenta resumen) {
    return Column(
      children: [
        // Tarjeta de balance
        Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Balance del Periodo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _tarjetaInfoFinanciera(
                        'Ingresos',
                        resumen.ingresosFormateados,
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _tarjetaInfoFinanciera(
                        'Egresos',
                        resumen.egresosFormateados,
                        Colors.red,
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _tarjetaBalance(resumen),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Lista de movimientos
        _construirListaMovimientos(context, resumen.movimientos),
      ],
    );
  }

  Widget _tarjetaInfoFinanciera(
    String titulo,
    String valor,
    Color color,
    IconData icono,
  ) {
    // Usar AppColors para los colores de tarjetas financieras
    Color backgroundColor =
        titulo == 'Ingresos'
            ? AppColors.withAlpha(AppColors.exito, 30)
            : AppColors.withAlpha(AppColors.error, 30);
    Color iconColor = titulo == 'Ingresos' ? AppColors.exito : AppColors.error;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: iconColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(fontSize: 14, color: AppColors.oscuro),
                ),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaBalance(ResumenRenta resumen) {
    final color = resumen.esPositivo ? Colors.green : Colors.red;
    final icono = resumen.esPositivo ? Icons.trending_up : Icons.trending_down;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25), // ~10% opacity (255 * 0.1 = 25)
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha(77),
        ), // ~30% opacity (255 * 0.3 = 77)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                'Balance Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            resumen.balanceFormateado,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirListaMovimientos(
    BuildContext context,
    List<MovimientoRenta> movimientos,
  ) {
    if (movimientos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No hay movimientos registrados en este periodo',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Movimientos en el Periodo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movimientos.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final movimiento = movimientos[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        movimiento.esIngreso
                            ? Colors.green.withAlpha(
                              51,
                            ) // ~20% opacity (255 * 0.2 = 51)
                            : Colors.red.withAlpha(
                              51,
                            ), // ~20% opacity (255 * 0.2 = 51)
                    child: Icon(
                      movimiento.esIngreso ? Icons.add : Icons.remove,
                      color: movimiento.esIngreso ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    movimiento.concepto,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(movimiento.fechaFormateada),
                  trailing: Text(
                    movimiento.montoFormateado,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: movimiento.esIngreso ? Colors.green : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () => _mostrarDetallesMovimiento(context, movimiento),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Nuevo método para mostrar detalles del movimiento
  void _mostrarDetallesMovimiento(
    BuildContext context,
    MovimientoRenta movimiento,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  movimiento.esIngreso
                      ? Icons.arrow_circle_down
                      : Icons.arrow_circle_up,
                  color: movimiento.esIngreso ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    movimiento.concepto,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetalleMovimientoRow('Monto', movimiento.montoFormateado),
                _buildDetalleMovimientoRow('Fecha', movimiento.fechaFormateada),
                _buildDetalleMovimientoRow(
                  'Tipo',
                  movimiento.esIngreso ? 'Ingreso' : 'Egreso',
                ),
                if (movimiento.mesCorrespondiente.isNotEmpty)
                  _buildDetalleMovimientoRow(
                    'Mes correspondiente',
                    _formatMesCorrespondiente(movimiento.mesCorrespondiente),
                  ),
                if (movimiento.comentarios != null &&
                    movimiento.comentarios!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Comentarios:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(movimiento.comentarios!),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  // Método auxiliar para construir filas en el detalle de movimiento
  Widget _buildDetalleMovimientoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  // Método para formatear el mes correspondiente de YYYY-MM a un formato legible
  String _formatMesCorrespondiente(String mesCorrespondiente) {
    try {
      final parts = mesCorrespondiente.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateFormat('MMMM yyyy', 'es_ES').format(DateTime(year, month));
      }
      return mesCorrespondiente;
    } catch (e) {
      return mesCorrespondiente;
    }
  }
}

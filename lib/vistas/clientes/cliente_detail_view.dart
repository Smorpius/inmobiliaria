import 'package:flutter/material.dart';
import '../../models/inmueble_model.dart';
import '../../controllers/inmueble_controller.dart';

class InmuebleDetailView extends StatelessWidget {
  final Inmueble inmueble;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isInactivo;

  const InmuebleDetailView({
    super.key,
    required this.inmueble,
    required this.onEdit,
    required this.onDelete,
    this.isInactivo = false,
  });

  // Formateo de tipo de inmueble para mostrar con primera letra mayúscula
  String _formatTipoInmueble(String tipo) {
    return tipo[0].toUpperCase() + tipo.substring(1);
  }

  // Formateo del tipo de operación para mostrar con primera letra mayúscula
  String _formatTipoOperacion(String tipo) {
    return tipo[0].toUpperCase() + tipo.substring(1);
  }

  // Formatea montos a formato de moneda
  String _formatMonto(double? monto) {
    if (monto == null) return 'No especificado';
    return '\$${monto.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isInactivo ? Colors.grey : Colors.indigo, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isInactivo ? Colors.grey.shade600 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      color: isInactivo ? Colors.grey.shade50 : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        isInactivo
                            ? Colors.grey.shade300
                            : Colors.indigo.shade100,
                    child: Icon(
                      Icons.home,
                      size: 40,
                      color: isInactivo ? Colors.grey : Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    inmueble.nombre,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      decoration:
                          isInactivo ? TextDecoration.lineThrough : null,
                      color: isInactivo ? Colors.grey.shade700 : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isInactivo)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'NO DISPONIBLE',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 40),

            // Información básica del inmueble
            _buildDetailRow(
              'Tipo de inmueble',
              _formatTipoInmueble(inmueble.tipoInmueble),
              Icons.home,
            ),
            _buildDetailRow(
              'Tipo de operación',
              _formatTipoOperacion(inmueble.tipoOperacion),
              Icons.sell,
            ),

            // Información de precios
            _buildDetailRow(
              'Monto total',
              _formatMonto(inmueble.montoTotal),
              Icons.attach_money,
            ),
            if (inmueble.tipoOperacion == 'venta' ||
                inmueble.tipoOperacion == 'ambos')
              _buildDetailRow(
                'Precio de venta',
                _formatMonto(inmueble.precioVenta),
                Icons.monetization_on,
              ),
            if (inmueble.tipoOperacion == 'renta' ||
                inmueble.tipoOperacion == 'ambos')
              _buildDetailRow(
                'Precio de renta',
                _formatMonto(inmueble.precioRenta),
                Icons.payments,
              ),

            // Dirección completa
            _buildDetailRow(
              'Dirección completa',
              inmueble.direccionCompleta,
              Icons.location_on,
            ),

            // Componentes individuales de la dirección
            if (inmueble.calle != null && inmueble.calle!.isNotEmpty)
              _buildDetailRow('Calle', inmueble.calle!, Icons.signpost),
            if (inmueble.numero != null && inmueble.numero!.isNotEmpty)
              _buildDetailRow(
                'Número',
                inmueble.numero!,
                Icons.confirmation_number,
              ),
            if (inmueble.colonia != null && inmueble.colonia!.isNotEmpty)
              _buildDetailRow(
                'Colonia',
                inmueble.colonia!,
                Icons.holiday_village,
              ),
            if (inmueble.ciudad != null && inmueble.ciudad!.isNotEmpty)
              _buildDetailRow('Ciudad', inmueble.ciudad!, Icons.location_city),
            if (inmueble.estadoGeografico != null &&
                inmueble.estadoGeografico!.isNotEmpty)
              _buildDetailRow('Estado', inmueble.estadoGeografico!, Icons.map),
            if (inmueble.codigoPostal != null &&
                inmueble.codigoPostal!.isNotEmpty)
              _buildDetailRow(
                'Código Postal',
                inmueble.codigoPostal!,
                Icons.markunread_mailbox,
              ),
            if (inmueble.referencias != null &&
                inmueble.referencias!.isNotEmpty)
              _buildDetailRow(
                'Referencias',
                inmueble.referencias!,
                Icons.place,
              ),

            // Características adicionales
            if (inmueble.caracteristicas != null &&
                inmueble.caracteristicas!.isNotEmpty)
              _buildDetailRow(
                'Características',
                inmueble.caracteristicas!,
                Icons.list_alt,
              ),

            // Fecha de registro
            if (inmueble.fechaRegistro != null)
              _buildDetailRow(
                'Fecha de registro',
                inmueble.fechaRegistro.toString().split(' ')[0],
                Icons.calendar_today,
              ),

            // Información de cliente y empleado asociados si están disponibles
            if (inmueble.id != null)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: InmuebleController().getClientesInteresados(
                  inmueble.id!,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 40),
                        Text(
                          'Clientes interesados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final cliente = snapshot.data![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(
                                  '${cliente['nombre']} ${cliente['apellido_paterno']}',
                                ),
                                subtitle: Text(
                                  cliente['telefono_cliente'] != null
                                      ? 'Tel: ${cliente['telefono_cliente']}'
                                      : 'Sin teléfono',
                                ),
                                trailing: Text(
                                  cliente['fecha_interes'] != null
                                      ? 'Interesado: ${cliente['fecha_interes'].toString().split(' ')[0]}'
                                      : 'Interesado recientemente',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isInactivo)
                  ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (!isInactivo) const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: Icon(isInactivo ? Icons.home : Icons.delete),
                  label: Text(
                    isInactivo ? 'Reactivar' : 'Marcar no disponible',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInactivo ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

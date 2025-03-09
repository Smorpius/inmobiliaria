import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';

class ClienteDetailView extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  // Nueva propiedad para indicar si estamos viendo un cliente inactivo
  final bool isInactivo;

  const ClienteDetailView({
    super.key,
    required this.cliente,
    required this.onEdit,
    required this.onDelete,
    this.isInactivo = false, // Por defecto, asumimos que es activo
  });

  String _formatTipoCliente(String tipo) {
    switch (tipo) {
      case 'comprador':
        return 'Comprador';
      case 'arrendatario':
        return 'Arrendatario';
      case 'ambos':
        return 'Comprador y Arrendatario';
      default:
        return tipo;
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isInactivo ? Colors.grey : Colors.teal, size: 22),
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
                    // Si está inactivo, mostrar texto en gris
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
      // Si está inactivo, cambiar color de fondo
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
                    // Cambiar color según estado
                    backgroundColor:
                        isInactivo
                            ? Colors.grey.shade300
                            : Colors.teal.shade100,
                    child: Text(
                      cliente.nombre.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isInactivo ? Colors.grey : Colors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    cliente.nombreCompleto,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      // Si está inactivo, mostrar texto tachado
                      decoration:
                          isInactivo ? TextDecoration.lineThrough : null,
                      color: isInactivo ? Colors.grey.shade700 : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Mostrar etiqueta de inactivo si corresponde
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
                        'INACTIVO',
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
            _buildDetailRow('Nombre', cliente.nombre, Icons.person),
            _buildDetailRow(
              'Apellido Paterno',
              cliente.apellidoPaterno,
              Icons.person,
            ),
            if (cliente.apellidoMaterno != null &&
                cliente.apellidoMaterno!.isNotEmpty)
              _buildDetailRow(
                'Apellido Materno',
                cliente.apellidoMaterno!,
                Icons.person,
              ),
            _buildDetailRow(
              'Tipo de Cliente',
              _formatTipoCliente(cliente.tipoCliente),
              Icons.category,
            ),
            _buildDetailRow('Teléfono', cliente.telefono, Icons.phone),
            _buildDetailRow('RFC', cliente.rfc, Icons.assignment_ind),
            _buildDetailRow('CURP', cliente.curp, Icons.badge),
            if (cliente.correo != null && cliente.correo!.isNotEmpty)
              _buildDetailRow('Correo', cliente.correo!, Icons.email)
            else
              _buildDetailRow('Correo', 'No proporcionado', Icons.email),
            if (cliente.direccionCompleta != 'Dirección no disponible')
              _buildDetailRow(
                'Dirección',
                cliente.direccionCompleta,
                Icons.location_on,
              ),
            if (cliente.fechaRegistro != null)
              _buildDetailRow(
                'Fecha de registro',
                cliente.fechaRegistro.toString().split(' ')[0],
                Icons.calendar_today,
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Mostrar botón de edición solo si el cliente está activo
                if (!isInactivo)
                  ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (!isInactivo) const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onDelete,
                  // Cambiar icono según estado
                  icon: Icon(isInactivo ? Icons.person_add : Icons.delete),
                  // Cambiar texto según estado
                  label: Text(isInactivo ? 'Reactivar' : 'Inactivar'),
                  style: ElevatedButton.styleFrom(
                    // Cambiar color según estado
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

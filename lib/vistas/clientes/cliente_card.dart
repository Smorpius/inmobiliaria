import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';

class ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  // Nuevo: para determinar si mostrar reactivar en lugar de inactivar
  final bool isInactivo;

  const ClienteCard({
    super.key,
    required this.cliente,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    // Por defecto, consideramos que el cliente está activo
    this.isInactivo = false,
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      // Color de fondo distinto según estado activo/inactivo
      color:
          isInactivo
              ? (isSelected ? Colors.red.shade50 : Colors.grey.shade100)
              : (isSelected ? Colors.teal.shade50 : null),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isInactivo ? Colors.grey : Colors.teal,
          foregroundColor: Colors.white,
          child: Text(cliente.nombre.substring(0, 1).toUpperCase()),
        ),
        title: Text(
          cliente.nombreCompleto,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            // Tachamos el nombre si está inactivo
            decoration: isInactivo ? TextDecoration.lineThrough : null,
            color: isInactivo ? Colors.grey.shade700 : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tel: ${cliente.telefono}'),
            Text('RFC: ${cliente.rfc}'),
            Text('Tipo: ${_formatTipoCliente(cliente.tipoCliente)}'),
            if (isInactivo)
              Text(
                'INACTIVO',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Solo mostrar el botón de edición para clientes activos
            if (!isInactivo)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.teal),
                tooltip: 'Editar cliente',
                onPressed: onEdit,
              ),
            IconButton(
              // Cambiar icono y color según estado
              icon: Icon(
                isInactivo ? Icons.person_add : Icons.delete,
                color: isInactivo ? Colors.green : Colors.red,
              ),
              tooltip: isInactivo ? 'Reactivar cliente' : 'Inactivar cliente',
              onPressed:
                  onDelete, // Usamos la misma acción (luego será reactivar o inactivar)
            ),
          ],
        ),
      ),
    );
  }
}

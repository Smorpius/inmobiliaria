import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';
import '../../utils/app_colors.dart'; // Importar la clase centralizada

class ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isInactivo;

  const ClienteCard({
    super.key,
    required this.cliente,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
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
      color:
          isInactivo
              ? (isSelected
                  ? AppColors.withValues(color: AppColors.acento, alpha: 26)
                  : AppColors.withValues(color: AppColors.grisClaro, alpha: 77))
              : (isSelected
                  ? AppColors.withValues(color: AppColors.primario, alpha: 26)
                  : AppColors.claro),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isInactivo ? AppColors.grisClaro : AppColors.primario,
          foregroundColor: AppColors.claro,
          child: Text(cliente.nombre.substring(0, 1).toUpperCase()),
        ),
        title: Text(
          cliente.nombreCompleto,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isInactivo ? TextDecoration.lineThrough : null,
            color: isInactivo ? AppColors.grisClaro : AppColors.oscuro,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tel: ${cliente.telefono}',
              style: TextStyle(
                color: AppColors.withValues(
                  color: AppColors.oscuro,
                  alpha: 179,
                ),
              ),
            ),
            Text(
              'RFC: ${cliente.rfc}',
              style: TextStyle(
                color: AppColors.withValues(
                  color: AppColors.oscuro,
                  alpha: 179,
                ),
              ),
            ),
            Text(
              'Tipo: ${_formatTipoCliente(cliente.tipoCliente)}',
              style: TextStyle(
                color: AppColors.withValues(
                  color: AppColors.oscuro,
                  alpha: 179,
                ),
              ),
            ),
            if (isInactivo)
              Text(
                'INACTIVO',
                style: TextStyle(
                  color: AppColors.acento,
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
            if (!isInactivo)
              IconButton(
                icon: Icon(Icons.edit, color: AppColors.primario),
                tooltip: 'Editar cliente',
                onPressed: onEdit,
              ),
            IconButton(
              icon: Icon(
                isInactivo ? Icons.person_add : Icons.delete,
                color: isInactivo ? AppColors.primario : AppColors.acento,
              ),
              tooltip: isInactivo ? 'Reactivar cliente' : 'Inactivar cliente',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

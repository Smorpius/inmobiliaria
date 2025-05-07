import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';

class ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isInactivo;

  // Definición de la paleta de colores en RGB
  static const Color colorPrimario = Color.fromRGBO(165, 57, 45, 1); // #A5392D
  static const Color colorOscuro = Color.fromRGBO(26, 26, 26, 1); // #1A1A1A
  static const Color colorClaro = Color.fromRGBO(247, 245, 242, 1); // #F7F5F2
  static const Color colorGrisClaro = Color.fromRGBO(
    212,
    207,
    203,
    1,
  ); // #D4CFCB
  static const Color colorAcento = Color.fromRGBO(216, 86, 62, 1); // #D8563E

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
                  ? colorAcento.withValues(
                    alpha: 26,
                    red: 216,
                    green: 86,
                    blue: 62,
                  )
                  : colorGrisClaro.withValues(
                    alpha: 77,
                    red: 212,
                    green: 207,
                    blue: 203,
                  ))
              : (isSelected
                  ? colorPrimario.withValues(
                    alpha: 26,
                    red: 165,
                    green: 57,
                    blue: 45,
                  )
                  : colorClaro),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isInactivo ? colorGrisClaro : colorPrimario,
          foregroundColor: colorClaro,
          child: Text(cliente.nombre.substring(0, 1).toUpperCase()),
        ),
        title: Text(
          cliente.nombreCompleto,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isInactivo ? TextDecoration.lineThrough : null,
            color: isInactivo ? colorGrisClaro : colorOscuro,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tel: ${cliente.telefono}',
              style: TextStyle(
                color: colorOscuro.withValues(
                  alpha: 179,
                  red: 26,
                  green: 26,
                  blue: 26,
                ),
              ),
            ),
            Text(
              'RFC: ${cliente.rfc}',
              style: TextStyle(
                color: colorOscuro.withValues(
                  alpha: 179,
                  red: 26,
                  green: 26,
                  blue: 26,
                ),
              ),
            ),
            Text(
              'Tipo: ${_formatTipoCliente(cliente.tipoCliente)}',
              style: TextStyle(
                color: colorOscuro.withValues(
                  alpha: 179,
                  red: 26,
                  green: 26,
                  blue: 26,
                ),
              ),
            ),
            if (isInactivo)
              Text(
                'INACTIVO',
                style: TextStyle(
                  color: colorAcento,
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
                icon: Icon(Icons.edit, color: colorPrimario),
                tooltip: 'Editar cliente',
                onPressed: onEdit,
              ),
            IconButton(
              icon: Icon(
                isInactivo ? Icons.person_add : Icons.delete,
                color: isInactivo ? colorPrimario : colorAcento,
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

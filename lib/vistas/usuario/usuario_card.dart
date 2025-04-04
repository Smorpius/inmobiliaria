import 'package:flutter/material.dart';
import '../../../../models/usuario.dart';
import '../../widgets/user_avatar.dart'; // Importar el widget reutilizable

class UsuarioCard extends StatelessWidget {
  final Usuario usuario;
  final Function(Usuario) onEdit;
  final Function(Usuario) onDelete;

  const UsuarioCard({
    super.key,
    required this.usuario,
    required this.onEdit,
    required this.onDelete,
  });

  String _getEstadoTexto(int? idEstado) {
    return idEstado == 1 ? 'Activo' : 'Inactivo';
  }

  Color _getEstadoColor(int? idEstado) {
    return idEstado == 1 ? Colors.green : Colors.red;
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: _getEstadoColor(usuario.idEstado).withAlpha(76),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Usar el widget reutilizable UserAvatar en lugar de _buildUsuarioAvatar()
            UserAvatar(
              imagePath: usuario.imagenPerfil,
              nombre: usuario.nombre,
              apellido: usuario.apellido,
              radius: 28.0,
              backgroundColor: Colors.teal,
              isActive: usuario.idEstado == 1,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${usuario.nombre} ${usuario.apellido}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(usuario.idEstado),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getEstadoTexto(usuario.idEstado),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.account_circle,
                    "Usuario:",
                    usuario.nombreUsuario,
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    Icons.email,
                    "Email:",
                    (usuario.correo == null || usuario.correo!.trim().isEmpty)
                        ? 'No disponible'
                        : usuario.correo!,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (usuario.idEstado == 1)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.teal),
                    onPressed: () => onEdit(usuario),
                    tooltip: 'Editar usuario',
                  ),
                const SizedBox(height: 8),
                usuario.idEstado == 1
                    ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onDelete(usuario),
                      tooltip: 'Inactivar usuario',
                    )
                    : const Icon(Icons.block, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

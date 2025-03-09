import 'package:flutter/material.dart';
import '../../../models/usuario_empleado.dart';
import '../../../widgets/user_avatar.dart'; // Importar el widget reutilizable

class EmpleadosListView extends StatelessWidget {
  final List<UsuarioEmpleado> empleados;
  final Function(UsuarioEmpleado) onItemTap;
  final VoidCallback onAgregarEmpleado;
  final Function(UsuarioEmpleado) onEliminar;
  final Function(UsuarioEmpleado) onReactivar;
  final Function(UsuarioEmpleado) onModificar;

  const EmpleadosListView({
    super.key,
    required this.empleados,
    required this.onItemTap,
    required this.onAgregarEmpleado,
    required this.onEliminar,
    required this.onReactivar,
    required this.onModificar,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: empleados.length + 1, // +1 para el botón de agregar
      itemBuilder: (context, index) {
        if (index == empleados.length) {
          // Último elemento - Botón para agregar
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: onAgregarEmpleado,
                icon: const Icon(Icons.add),
                label: const Text('Agregar Empleado'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          );
        }

        final empleado = empleados[index];
        final isInactivo = empleado.empleado.idEstado == 2;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: isInactivo ? Colors.grey.shade100 : null,
          child: ListTile(
            leading: _buildEmpleadoAvatar(empleado),
            title: Text(
              '${empleado.empleado.nombre} ${empleado.empleado.apellidoPaterno}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isInactivo ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cargo: ${empleado.empleado.cargo}'),
                Text('Usuario: ${empleado.usuario.nombreUsuario}'),
                Text(
                  'Estado: ${isInactivo ? "Inactivo" : "Activo"}',
                  style: TextStyle(
                    color: isInactivo ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: _buildActions(empleado, isInactivo),
            onTap: () => onItemTap(empleado),
          ),
        );
      },
    );
  }

  /// Construye el avatar con la imagen o las iniciales del empleado usando UserAvatar
  Widget _buildEmpleadoAvatar(UsuarioEmpleado empleado) {
    // Usar el widget reutilizable UserAvatar en lugar de implementación manual
    return UserAvatar(
      // Priorizar la imagen del empleado, luego la de usuario
      imagePath:
          empleado.empleado.imagenEmpleado ?? empleado.usuario.imagenPerfil,
      nombre: empleado.empleado.nombre,
      apellido: empleado.empleado.apellidoPaterno,
      radius: 25.0,
      backgroundColor: Colors.teal.shade100,
      isActive: empleado.empleado.idEstado != 2,
    );
  }

  /// Despliega las acciones del menú contextual
  Widget _buildActions(UsuarioEmpleado empleado, bool isInactivo) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'modificar':
            onModificar(empleado);
            break;
          case 'eliminar':
            onEliminar(empleado);
            break;
          case 'reactivar':
            onReactivar(empleado);
            break;
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: 'modificar',
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 8),
                Text('Modificar'),
              ],
            ),
          ),
          if (isInactivo)
            const PopupMenuItem(
              value: 'reactivar',
              child: Row(
                children: [
                  Icon(Icons.restore, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Reactivar'),
                ],
              ),
            )
          else
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
        ];
      },
    );
  }
}

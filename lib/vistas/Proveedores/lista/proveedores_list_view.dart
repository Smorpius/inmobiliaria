import 'package:flutter/material.dart';
import '../../../models/proveedor.dart';

class ProveedoresListView extends StatelessWidget {
  final List<Proveedor> proveedores;
  final Function(Proveedor) onItemTap;
  final VoidCallback onAgregarProveedor;
  final Function(Proveedor) onEliminar;
  final Function(Proveedor) onReactivar;
  final Function(Proveedor) onModificar;

  const ProveedoresListView({
    super.key,
    required this.proveedores,
    required this.onItemTap,
    required this.onAgregarProveedor,
    required this.onEliminar,
    required this.onReactivar,
    required this.onModificar,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: proveedores.length + 1, // +1 para el botón de agregar
      itemBuilder: (context, index) {
        if (index == proveedores.length) {
          // Último elemento - Botón para agregar
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: onAgregarProveedor,
                icon: const Icon(Icons.add),
                label: const Text('Agregar Proveedor'),
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

        final proveedor = proveedores[index];
        final isInactivo = proveedor.idEstado == 2;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: isInactivo ? Colors.grey.shade100 : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                Icons.business,
                color: Colors.white,
              ),
            ),
            title: Text(
              proveedor.nombre,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isInactivo ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Empresa: ${proveedor.nombreEmpresa}'),
                Text('Contacto: ${proveedor.nombreContacto}'),
                Text('Servicio: ${proveedor.tipoServicio}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'modificar',
                  child: ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Modificar'),
                  ),
                ),
                if (isInactivo)
                  PopupMenuItem(
                    value: 'reactivar',
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: const Text('Reactivar'),
                    ),
                  )
                else
                  PopupMenuItem(
                    value: 'eliminar',
                    child: ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Eliminar'),
                    ),
                  ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'modificar':
                    onModificar(proveedor);
                    break;
                  case 'eliminar':
                    onEliminar(proveedor);
                    break;
                  case 'reactivar':
                    onReactivar(proveedor);
                    break;
                }
              },
            ),
            onTap: () => onItemTap(proveedor),
          ),
        );
      },
    );
  }
}
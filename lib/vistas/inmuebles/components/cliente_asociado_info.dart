import 'detail_row.dart';
import 'package:flutter/material.dart';
import '../../../models/cliente_model.dart';
import '../../../controllers/cliente_controller.dart';

class ClienteAsociadoInfo extends StatelessWidget {
  final int idCliente;
  final bool isInactivo;
  final ClienteController clienteController;

  const ClienteAsociadoInfo({
    super.key,
    required this.idCliente,
    required this.isInactivo,
    required this.clienteController,
  });

  // Método auxiliar para obtener cliente por ID
  Future<Cliente?> _obtenerClientePorID(int idCliente) async {
    try {
      // Obtenemos todos los clientes y filtramos por ID
      final clientes = await clienteController.getClientes();
      return clientes.firstWhere(
        (cliente) => cliente.id == idCliente,
        orElse: () => throw Exception('Cliente no encontrado'),
      );
    } catch (e) {
      debugPrint('Error al obtener cliente por ID: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Cliente?>(
      future: _obtenerClientePorID(idCliente),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return DetailRow(
            label: 'Cliente asociado',
            value: snapshot.data!.nombreCompleto,
            icon: Icons.person,
            isInactivo: isInactivo,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

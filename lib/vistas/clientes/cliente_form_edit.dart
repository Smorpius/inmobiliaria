import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';
import '../../controllers/cliente_controller.dart';

class ClienteFormEdit extends StatefulWidget {
  final Cliente cliente;
  final Function() onClienteUpdated;
  final ClienteController controller;

  const ClienteFormEdit({
    super.key,
    required this.cliente,
    required this.onClienteUpdated,
    required this.controller,
  });

  @override
  State<ClienteFormEdit> createState() => _ClienteFormEditState();
}

class _ClienteFormEditState extends State<ClienteFormEdit> {
  late final TextEditingController nombreController;
  late final TextEditingController apellidoPaternoController;
  late final TextEditingController apellidoMaternoController;
  late final TextEditingController telefonoController;
  late final TextEditingController rfcController;
  late final TextEditingController curpController;
  late final TextEditingController correoController;
  late String tipoCliente;

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.cliente.nombre);
    apellidoPaternoController = TextEditingController(
      text: widget.cliente.apellidoPaterno,
    );
    apellidoMaternoController = TextEditingController(
      text: widget.cliente.apellidoMaterno ?? '',
    );
    telefonoController = TextEditingController(text: widget.cliente.telefono);
    rfcController = TextEditingController(text: widget.cliente.rfc);
    curpController = TextEditingController(text: widget.cliente.curp);
    correoController = TextEditingController(text: widget.cliente.correo ?? '');
    tipoCliente = widget.cliente.tipoCliente;
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoPaternoController.dispose();
    apellidoMaternoController.dispose();
    telefonoController.dispose();
    rfcController.dispose();
    curpController.dispose();
    correoController.dispose();
    super.dispose();
  }

  bool _validarCampos(BuildContext context) {
    if (nombreController.text.isEmpty ||
        apellidoPaternoController.text.isEmpty ||
        telefonoController.text.isEmpty ||
        rfcController.text.isEmpty ||
        curpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, llene todos los campos obligatorios'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _actualizarCliente(BuildContext context) async {
    if (!_validarCampos(context)) return;

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final clienteActualizado = Cliente(
      id: widget.cliente.id,
      nombre: nombreController.text,
      apellidoPaterno: apellidoPaternoController.text,
      apellidoMaterno:
          apellidoMaternoController.text.isNotEmpty
              ? apellidoMaternoController.text
              : null,
      telefono: telefonoController.text,
      rfc: rfcController.text,
      curp: curpController.text,
      tipoCliente: tipoCliente,
      correo: correoController.text.isNotEmpty ? correoController.text : null,
      idDireccion: widget.cliente.idDireccion,
      idEstado: widget.cliente.idEstado,
      fechaRegistro: widget.cliente.fechaRegistro,
      calle: widget.cliente.calle,
      numero: widget.cliente.numero,
      ciudad: widget.cliente.ciudad,
      codigoPostal: widget.cliente.codigoPostal,
    );

    try {
      await widget.controller.updateCliente(clienteActualizado);
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cliente actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      nav.pop();
      widget.onClienteUpdated();
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al actualizar cliente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Cliente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: apellidoPaternoController,
              decoration: const InputDecoration(
                labelText: 'Apellido Paterno',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: apellidoMaternoController,
              decoration: const InputDecoration(
                labelText: 'Apellido Materno (opcional)',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Cliente',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              value: tipoCliente,
              items: const [
                DropdownMenuItem(value: 'comprador', child: Text('Comprador')),
                DropdownMenuItem(
                  value: 'arrendatario',
                  child: Text('Arrendatario'),
                ),
                DropdownMenuItem(value: 'ambos', child: Text('Ambos')),
              ],
              onChanged: (value) {
                setState(() => tipoCliente = value!);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rfcController,
              decoration: const InputDecoration(
                labelText: 'RFC',
                prefixIcon: Icon(Icons.assignment_ind),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: curpController,
              decoration: const InputDecoration(
                labelText: 'CURP',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: correoController,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.cancel),
          label: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () => _actualizarCliente(context),
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

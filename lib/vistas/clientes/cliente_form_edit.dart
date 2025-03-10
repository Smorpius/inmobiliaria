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
  // Controladores para información personal
  late final TextEditingController nombreController;
  late final TextEditingController apellidoPaternoController;
  late final TextEditingController apellidoMaternoController;
  late final TextEditingController telefonoController;
  late final TextEditingController rfcController;
  late final TextEditingController curpController;
  late final TextEditingController correoController;

  // Controladores para campos de dirección
  late final TextEditingController calleController;
  late final TextEditingController numeroController;
  late final TextEditingController coloniaController;
  late final TextEditingController ciudadController;
  late final TextEditingController estadoGeograficoController;
  late final TextEditingController codigoPostalController;
  late final TextEditingController referenciasController;

  late String tipoCliente;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con valores existentes
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

    // Inicializar controladores de dirección
    calleController = TextEditingController(text: widget.cliente.calle ?? '');
    numeroController = TextEditingController(text: widget.cliente.numero ?? '');
    coloniaController = TextEditingController(
      text: widget.cliente.colonia ?? '',
    );
    ciudadController = TextEditingController(text: widget.cliente.ciudad ?? '');
    estadoGeograficoController = TextEditingController(
      text: widget.cliente.estadoGeografico ?? '',
    );
    codigoPostalController = TextEditingController(
      text: widget.cliente.codigoPostal ?? '',
    );
    referenciasController = TextEditingController(
      text: widget.cliente.referencias ?? '',
    );

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

    // Liberar controladores de dirección
    calleController.dispose();
    numeroController.dispose();
    coloniaController.dispose();
    ciudadController.dispose();
    estadoGeograficoController.dispose();
    codigoPostalController.dispose();
    referenciasController.dispose();

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

    // Validación para campos obligatorios de dirección
    if (ciudadController.text.isEmpty ||
        estadoGeograficoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese al menos Ciudad y Estado'),
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

      // Usar los valores de los controladores de dirección
      calle: calleController.text.isNotEmpty ? calleController.text : null,
      numero: numeroController.text.isNotEmpty ? numeroController.text : null,
      colonia:
          coloniaController.text.isNotEmpty ? coloniaController.text : null,
      ciudad: ciudadController.text,
      estadoGeografico: estadoGeograficoController.text,
      codigoPostal:
          codigoPostalController.text.isNotEmpty
              ? codigoPostalController.text
              : null,
      referencias:
          referenciasController.text.isNotEmpty
              ? referenciasController.text
              : null,
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

            // Sección de dirección
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(thickness: 1),
            ),
            const Text(
              'Información de Dirección',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Todos los campos de dirección para editar
            TextField(
              controller: calleController,
              decoration: const InputDecoration(
                labelText: 'Calle',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numeroController,
              decoration: const InputDecoration(
                labelText: 'Número',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: coloniaController,
              decoration: const InputDecoration(
                labelText: 'Colonia',
                prefixIcon: Icon(Icons.grid_3x3),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ciudadController,
              decoration: const InputDecoration(
                labelText: 'Ciudad *',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: estadoGeograficoController,
              decoration: const InputDecoration(
                labelText: 'Estado *',
                prefixIcon: Icon(Icons.map),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codigoPostalController,
              decoration: const InputDecoration(
                labelText: 'Código Postal',
                prefixIcon: Icon(Icons.markunread_mailbox),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: referenciasController,
              decoration: const InputDecoration(
                labelText: 'Referencias',
                prefixIcon: Icon(Icons.info_outline),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '* Campos obligatorios',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
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

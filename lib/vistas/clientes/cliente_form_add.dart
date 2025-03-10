import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';
import '../../controllers/cliente_controller.dart';

class ClienteFormAdd extends StatefulWidget {
  final Function() onClienteAdded;
  final ClienteController controller;

  const ClienteFormAdd({
    super.key,
    required this.onClienteAdded,
    required this.controller,
  });

  @override
  State<ClienteFormAdd> createState() => _ClienteFormAddState();
}

class _ClienteFormAddState extends State<ClienteFormAdd> {
  final nombreController = TextEditingController();
  final apellidoPaternoController = TextEditingController();
  final apellidoMaternoController = TextEditingController();
  final telefonoController = TextEditingController();
  final rfcController = TextEditingController();
  final curpController = TextEditingController();
  final correoController = TextEditingController();

  // Controladores para TODOS los campos de dirección
  final calleController = TextEditingController();
  final numeroController = TextEditingController();
  final coloniaController = TextEditingController(); // Añadido
  final ciudadController = TextEditingController();
  final estadoGeograficoController = TextEditingController(); // Añadido
  final codigoPostalController = TextEditingController();
  final referenciasController = TextEditingController(); // Añadido

  String tipoCliente = 'comprador';

  @override
  void dispose() {
    nombreController.dispose();
    apellidoPaternoController.dispose();
    apellidoMaternoController.dispose();
    telefonoController.dispose();
    rfcController.dispose();
    curpController.dispose();
    correoController.dispose();

    // Liberar todos los controladores de dirección
    calleController.dispose();
    numeroController.dispose();
    coloniaController.dispose();
    ciudadController.dispose();
    estadoGeograficoController.dispose();
    codigoPostalController.dispose();
    referenciasController.dispose();
    super.dispose();
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }

  bool _validarCampos() {
    if (nombreController.text.isEmpty ||
        apellidoPaternoController.text.isEmpty ||
        telefonoController.text.isEmpty ||
        rfcController.text.isEmpty ||
        curpController.text.isEmpty) {
      _mostrarSnackBar(
        'Por favor, llene todos los campos obligatorios',
        Colors.orange,
      );
      return false;
    }

    // Validación adicional para campos obligatorios de dirección
    if (ciudadController.text.isEmpty ||
        estadoGeograficoController.text.isEmpty) {
      _mostrarSnackBar(
        'Por favor, ingrese al menos Ciudad y Estado',
        Colors.orange,
      );
      return false;
    }

    return true;
  }

  Future<void> _agregarCliente() async {
    if (!_validarCampos()) return;

    final nuevoCliente = Cliente(
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

      // Todos los campos de dirección
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
      await widget.controller.insertCliente(nuevoCliente);

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onClienteAdded();

      _mostrarSnackBar('Cliente agregado exitosamente', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _mostrarSnackBar('Error al agregar cliente: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Nuevo Cliente'),
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

            // Campos de dirección completos
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
          onPressed: _agregarCliente,
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

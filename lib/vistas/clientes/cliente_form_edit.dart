import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';
import '../../controllers/cliente_controller.dart';
import '../../utils/app_colors.dart'; // Importar la clase de colores centralizada

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
      backgroundColor: AppColors.claro,
      title: Text(
        'Editar Cliente',
        style: TextStyle(color: AppColors.primario),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: nombreController,
              labelText: 'Nombre',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: apellidoPaternoController,
              labelText: 'Apellido Paterno',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: apellidoMaternoController,
              labelText: 'Apellido Materno (opcional)',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildDropdownField(),
            const SizedBox(height: 12),
            _buildTextField(
              controller: telefonoController,
              labelText: 'Teléfono',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: rfcController,
              labelText: 'RFC',
              prefixIcon: Icons.assignment_ind,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: curpController,
              labelText: 'CURP',
              prefixIcon: Icons.badge,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: correoController,
              labelText: 'Correo',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),

            // Sección de dirección
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(thickness: 1),
            ),
            Text(
              'Información de Dirección',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primario,
              ),
            ),
            const SizedBox(height: 12),

            // Todos los campos de dirección para editar
            _buildTextField(
              controller: calleController,
              labelText: 'Calle',
              prefixIcon: Icons.location_on,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: numeroController,
              labelText: 'Número',
              prefixIcon: Icons.home,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: coloniaController,
              labelText: 'Colonia',
              prefixIcon: Icons.grid_3x3,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: ciudadController,
              labelText: 'Ciudad *',
              prefixIcon: Icons.location_city,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: estadoGeograficoController,
              labelText: 'Estado *',
              prefixIcon: Icons.map,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: codigoPostalController,
              labelText: 'Código Postal',
              prefixIcon: Icons.markunread_mailbox,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: referenciasController,
              labelText: 'Referencias',
              prefixIcon: Icons.info_outline,
              maxLines: 2,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '* Campos obligatorios',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.oscuro.withAlpha((255 * 0.6).round()),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.cancel, color: AppColors.oscuro),
          label: Text('Cancelar', style: TextStyle(color: AppColors.oscuro)),
        ),
        ElevatedButton.icon(
          onPressed: () => _actualizarCliente(context),
          icon: Icon(Icons.save, color: AppColors.claro),
          label: Text('Guardar', style: TextStyle(color: AppColors.claro)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.acento),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: AppColors.oscuro),
        prefixIcon: Icon(prefixIcon, color: AppColors.primario),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.grisClaro),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primario),
        ),
        fillColor: AppColors.claro,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Tipo de Cliente',
        labelStyle: TextStyle(color: AppColors.oscuro),
        prefixIcon: Icon(Icons.category, color: AppColors.primario),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.grisClaro),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primario),
        ),
      ),
      value: tipoCliente,
      dropdownColor: AppColors.claro,
      items: [
        DropdownMenuItem(
          value: 'comprador',
          child: Text('Comprador', style: TextStyle(color: AppColors.oscuro)),
        ),
        DropdownMenuItem(
          value: 'arrendatario',
          child: Text(
            'Arrendatario',
            style: TextStyle(color: AppColors.oscuro),
          ),
        ),
        DropdownMenuItem(
          value: 'ambos',
          child: Text('Ambos', style: TextStyle(color: AppColors.oscuro)),
        ),
      ],
      onChanged: (value) {
        setState(() => tipoCliente = value!);
      },
    );
  }
}

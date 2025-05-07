import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';
import '../../controllers/cliente_controller.dart';
import '../../utils/app_colors.dart'; // Importar la clase de colores centralizada

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
  final coloniaController = TextEditingController();
  final ciudadController = TextEditingController();
  final estadoGeograficoController = TextEditingController();
  final codigoPostalController = TextEditingController();
  final referenciasController = TextEditingController();

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
        AppColors.acento,
      );
      return false;
    }

    // Validación adicional para campos obligatorios de dirección
    if (ciudadController.text.isEmpty ||
        estadoGeograficoController.text.isEmpty) {
      _mostrarSnackBar(
        'Por favor, ingrese al menos Ciudad y Estado',
        AppColors.acento,
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
      idEstado: 1, // CORRECCIÓN: Asegurar estado activo explícitamente
      // Campos de dirección
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
      developer.log(
        'Guardando cliente: ${nuevoCliente.nombre}, Estado: ${nuevoCliente.idEstado}',
      );
      final id = await widget.controller.insertCliente(nuevoCliente);

      // Verificar si el widget sigue montado después de operación asíncrona
      if (!mounted) return;

      // Esperamos un momento para que la BD termine de procesar
      await Future.delayed(const Duration(milliseconds: 300));

      // Verificar nuevamente si sigue montado después de otra operación asíncrona
      if (!mounted) return;

      // Cerramos el diálogo
      Navigator.of(context).pop();

      // Llamada explícita para recargar datos
      developer.log('Cliente creado ID: $id, llamando a actualizar vista');
      await widget.onClienteAdded();

      // Verificar nuevamente si el widget sigue montado
      if (!mounted) return;

      _mostrarSnackBar('Cliente agregado exitosamente', Colors.green);
    } catch (e) {
      developer.log('Error al agregar cliente: $e');

      if (!mounted) return;
      _mostrarSnackBar('Error al agregar cliente: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.claro,
      title: Text(
        'Agregar Nuevo Cliente',
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

            // Campos de dirección completos
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
                  color: AppColors.oscuro.withAlpha((0.6 * 255).round()),
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
          onPressed: _agregarCliente,
          icon: Icon(Icons.save, color: AppColors.claro),
          label: Text('Guardar', style: TextStyle(color: AppColors.claro)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primario),
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

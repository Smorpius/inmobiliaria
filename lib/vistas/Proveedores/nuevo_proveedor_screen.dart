import '../../models/proveedor.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/dialog_helper.dart';
import '../../controllers/proveedor_controller.dart';

class NuevoProveedorScreen extends StatefulWidget {
  final ProveedorController controller;
  final Proveedor? proveedorEditar;

  const NuevoProveedorScreen({
    super.key,
    required this.controller,
    this.proveedorEditar,
  });

  @override
  State<NuevoProveedorScreen> createState() => _NuevoProveedorScreenState();
}

class _NuevoProveedorScreenState extends State<NuevoProveedorScreen> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final nombreEmpresaController = TextEditingController();
  final nombreContactoController = TextEditingController();
  final direccionController = TextEditingController();
  final telefonoController = TextEditingController();
  final correoController = TextEditingController();
  final tipoServicioController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.proveedorEditar != null;

    if (_isEditing) {
      final proveedor = widget.proveedorEditar!;
      nombreController.text = proveedor.nombre;
      nombreEmpresaController.text = proveedor.nombreEmpresa;
      nombreContactoController.text = proveedor.nombreContacto;
      direccionController.text = proveedor.direccion;
      telefonoController.text = proveedor.telefono;
      correoController.text = proveedor.correo;
      tipoServicioController.text = proveedor.tipoServicio;
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    nombreEmpresaController.dispose();
    nombreContactoController.dispose();
    direccionController.dispose();
    telefonoController.dispose();
    correoController.dispose();
    tipoServicioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Editar Proveedor" : "Nuevo Proveedor"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del Proveedor',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: nombreEmpresaController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la Empresa',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el nombre de la empresa';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: nombreContactoController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Contacto',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.contact_phone),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el nombre del contacto';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa la dirección';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\-\s]'),
                          ),
                          LengthLimitingTextInputFormatter(15),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el teléfono';
                          }
                          if (value.replaceAll(RegExp(r'[\s\-+]'), '').length <
                              10) {
                            return 'El teléfono debe tener al menos 10 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: correoController,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el correo';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: tipoServicioController,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Servicio',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el tipo de servicio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _guardarProveedor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _isEditing
                                ? "Actualizar Proveedor"
                                : "Guardar Proveedor",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      developer.log("=== INICIO DE CREACIÓN DE PROVEEDOR ===");
      developer.log("Datos del formulario:");
      developer.log("- Nombre: ${nombreController.text.trim()}");
      developer.log("- Empresa: ${nombreEmpresaController.text.trim()}");
      developer.log("- Contacto: ${nombreContactoController.text.trim()}");
      developer.log("- Dirección: ${direccionController.text.trim()}");
      developer.log("- Teléfono: ${telefonoController.text.trim()}");
      developer.log("- Correo: ${correoController.text.trim()}");
      developer.log(
        "- Tipo de servicio: ${tipoServicioController.text.trim()}",
      );

      final proveedor = Proveedor(
        idProveedor: _isEditing ? widget.proveedorEditar!.idProveedor : null,
        nombre: nombreController.text.trim(),
        nombreEmpresa: nombreEmpresaController.text.trim(),
        nombreContacto: nombreContactoController.text.trim(),
        direccion: direccionController.text.trim(),
        telefono: telefonoController.text.trim(),
        correo: correoController.text.trim(),
        tipoServicio: tipoServicioController.text.trim(),
        idEstado: _isEditing ? widget.proveedorEditar!.idEstado : 1,
      );

      if (_isEditing) {
        // Código existente para actualizar...
      } else {
        developer.log("Llamando a controller.crearProveedor...");
        final nuevoProveedor = await widget.controller.crearProveedor(
          proveedor,
        );
        developer.log(
          "Regresó de controller.crearProveedor con ID: ${nuevoProveedor.idProveedor}",
        );

        if (!mounted) return;
        await _mostrarExitoYRegresar(
          'El proveedor ha sido creado exitosamente.',
        );
        developer.log("=== FIN DE CREACIÓN DE PROVEEDOR ===");
      }
    } catch (e, stack) {
      developer.log(
        '=== ERROR AL CREAR PROVEEDOR ===',
        error: e,
        stackTrace: stack,
      );

      // Verificar tipo específico de error
      if (e.toString().contains('correo')) {
        await _mostrarError(
          'El correo electrónico ya está en uso. Por favor, use otro correo.',
        );
      } else if (e.toString().contains('teléfono')) {
        await _mostrarError(
          'El formato del teléfono es incorrecto. Debe tener entre 10 y 15 dígitos.',
        );
      } else {
        await _mostrarError('No se pudo crear el proveedor: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _mostrarExitoYRegresar(String mensaje) async {
    if (!mounted) return;
    await DialogHelper.mostrarMensajeExito(context, mensaje);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _mostrarError(String mensaje) async {
    if (!mounted) return;
    await DialogHelper.mostrarMensajeError(context, 'Error', mensaje);
  }
}

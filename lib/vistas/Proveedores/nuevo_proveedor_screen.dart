import 'dart:developer' as developer;
import '../../models/proveedor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/dialog_helper.dart';
import '../../providers/proveedor_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NuevoProveedorScreen extends ConsumerStatefulWidget {
  final Proveedor? proveedorEditar;

  const NuevoProveedorScreen({super.key, this.proveedorEditar});

  @override
  ConsumerState<NuevoProveedorScreen> createState() =>
      _NuevoProveedorScreenState();
}

class _NuevoProveedorScreenState extends ConsumerState<NuevoProveedorScreen> {
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: nombreEmpresaController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la Empresa',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el nombre de la empresa';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: nombreContactoController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de Contacto',
                          prefixIcon: Icon(Icons.contact_phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el nombre de contacto';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la dirección';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [LengthLimitingTextInputFormatter(15)],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el teléfono';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: correoController,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el correo electrónico';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Por favor ingrese un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: tipoServicioController,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Servicio',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el tipo de servicio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _guardarProveedor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _isEditing
                                ? 'Actualizar Proveedor'
                                : 'Crear Proveedor',
                            style: const TextStyle(fontSize: 16),
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
      developer.log(
        _isEditing
            ? "=== INICIO DE ACTUALIZACIÓN DE PROVEEDOR ==="
            : "=== INICIO DE CREACIÓN DE PROVEEDOR ===",
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
        developer.log("Actualizando proveedor con Riverpod...");
        final exito = await ref
            .read(proveedoresProvider.notifier)
            .actualizarProveedor(proveedor);

        if (exito) {
          developer.log("Proveedor actualizado correctamente");
          if (!mounted) return;
          await _mostrarExitoYRegresar(
            'El proveedor ha sido actualizado exitosamente.',
          );
        } else {
          throw Exception("No se pudo actualizar el proveedor");
        }
      } else {
        developer.log("Creando proveedor con Riverpod...");
        final nuevoProveedor = await ref
            .read(proveedoresProvider.notifier)
            .crearProveedor(proveedor);

        if (nuevoProveedor != null) {
          developer.log(
            "Proveedor creado con ID: ${nuevoProveedor.idProveedor}",
          );
          if (!mounted) return;
          await _mostrarExitoYRegresar(
            'El proveedor ha sido creado exitosamente.',
          );
        } else {
          throw Exception("No se pudo crear el proveedor");
        }
      }
    } catch (e, stack) {
      developer.log(
        _isEditing
            ? '=== ERROR AL ACTUALIZAR PROVEEDOR ==='
            : '=== ERROR AL CREAR PROVEEDOR ===',
        error: e,
        stackTrace: stack,
      );

      if (e.toString().contains('correo')) {
        await _mostrarError(
          'El correo electrónico ya está en uso. Por favor, use otro correo.',
        );
      } else if (e.toString().contains('teléfono')) {
        await _mostrarError(
          'El formato del teléfono es incorrecto. Debe tener entre 10 y 15 dígitos.',
        );
      } else {
        await _mostrarError(
          _isEditing
              ? 'No se pudo actualizar el proveedor: $e'
              : 'No se pudo crear el proveedor: $e',
        );
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

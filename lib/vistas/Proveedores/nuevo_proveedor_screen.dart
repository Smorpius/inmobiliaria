import 'package:flutter/material.dart';
import '../../utils/dialog_helper.dart';
import '../../models/proveedor.dart';
import '../../controllers/proveedor_controller.dart';
import 'package:flutter/services.dart';
import '../empleados/empleado_utils.dart';

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
      // Llenar los campos con los datos del proveedor a editar
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
      body: _isLoading
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
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Nombre
                    TextFormField(
                      controller: nombreController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Nombre',
                        Icons.person,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nombre de la Empresa
                    TextFormField(
                      controller: nombreEmpresaController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Nombre de la Empresa',
                        Icons.business,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre de la empresa';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nombre del Contacto
                    TextFormField(
                      controller: nombreContactoController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Nombre del Contacto',
                        Icons.contact_phone,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre del contacto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dirección
                    TextFormField(
                      controller: direccionController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Dirección',
                        Icons.home,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la dirección';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Teléfono
                    TextFormField(
                      controller: telefonoController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Teléfono',
                        Icons.phone,
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [TelefonoInputFormatter()],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el teléfono';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Correo
                    TextFormField(
                      controller: correoController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Correo',
                        Icons.email,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el correo';
                        }
                        if (!EmpleadoValidators.isValidEmail(value)) {
                          return 'Por favor ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tipo de Servicio
                    TextFormField(
                      controller: tipoServicioController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Tipo de Servicio',
                        Icons.build,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el tipo de servicio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botón de guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _guardarProveedor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_isEditing ? "Actualizar Proveedor" : "Guardar Proveedor"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final proveedor = Proveedor(
        idProveedor: _isEditing ? widget.proveedorEditar!.idProveedor : null,
        nombre: nombreController.text,
        nombreEmpresa: nombreEmpresaController.text,
        nombreContacto: nombreContactoController.text,
        direccion: direccionController.text,
        telefono: telefonoController.text,
        correo: correoController.text,
        tipoServicio: tipoServicioController.text,
        idEstado: _isEditing ? widget.proveedorEditar!.idEstado : 1,
      );

      if (_isEditing) {
        await widget.controller.actualizarProveedor(proveedor);
        if (mounted) {
          DialogHelper.mostrarMensajeExito(
            context,
            'Proveedor actualizado correctamente',
          );
          Navigator.pop(context, true);
        }
      } else {
        await widget.controller.crearProveedor(proveedor);
        if (mounted) {
          DialogHelper.mostrarMensajeExito(
            context,
            'Proveedor creado correctamente',
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.most// filepath: c:\Users\jedua\OneDrive\Documentos\Inmoviliaria\inmobiliaria\lib\vistas\proveedores\nuevo_proveedor_screen.dart
import 'package:flutter/material.dart';
import '../../utils/dialog_helper.dart';
import '../../models/proveedor.dart';
import '../../controllers/proveedor_controller.dart';
import 'package:flutter/services.dart';
import '../empleados/empleado_utils.dart';

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
      // Llenar los campos con los datos del proveedor a editar
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
      body: _isLoading
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
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Nombre
                    TextFormField(
                      controller: nombreController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Nombre',
                        Icons.person,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nombre de la Empresa
                    TextFormField(
                      controller: nombreEmpresaController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Nombre de la Empresa',
                        Icons.business,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre de la empresa';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nombre del Contacto
                    TextFormField(
                      controller: nombreContactoController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Nombre del Contacto',
                        Icons.contact_phone,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre del contacto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dirección
                    TextFormField(
                      controller: direccionController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Dirección',
                        Icons.home,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la dirección';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Teléfono
                    TextFormField(
                      controller: telefonoController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Teléfono',
                        Icons.phone,
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [TelefonoInputFormatter()],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el teléfono';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Correo
                    TextFormField(
                      controller: correoController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Correo',
                        Icons.email,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el correo';
                        }
                        if (!EmpleadoValidators.isValidEmail(value)) {
                          return 'Por favor ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tipo de Servicio
                    TextFormField(
                      controller: tipoServicioController,
                      decoration: EmpleadoStyles.getInputDecoration(
                        'Tipo de Servicio',
                        Icons.build,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el tipo de servicio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botón de guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _guardarProveedor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_isEditing ? "Actualizar Proveedor" : "Guardar Proveedor"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final proveedor = Proveedor(
        idProveedor: _isEditing ? widget.proveedorEditar!.idProveedor : null,
        nombre: nombreController.text,
        nombreEmpresa: nombreEmpresaController.text,
        nombreContacto: nombreContactoController.text,
        direccion: direccionController.text,
        telefono: telefonoController.text,
        correo: correoController.text,
        tipoServicio: tipoServicioController.text,
        idEstado: _isEditing ? widget.proveedorEditar!.idEstado : 1,
      );

      if (_isEditing) {
        await widget.controller.actualizarProveedor(proveedor);
        if (mounted) {
          DialogHelper.mostrarMensajeExito(
            context,
            'Proveedor actualizado correctamente',
          );
          Navigator.pop(context, true);
        }
      } else {
        await widget.controller.crearProveedor(proveedor);
        if (mounted) {
          DialogHelper.mostrarMensajeExito(
            context,
            'Proveedor creado correctamente',
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.most
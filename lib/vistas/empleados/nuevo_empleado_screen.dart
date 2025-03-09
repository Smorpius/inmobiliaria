import '../../models/usuario.dart';
import 'empleado_usuario_form.dart';
import 'empleado_laboral_form.dart';
import '../../models/empleado.dart';
import '../../utils/ui_helpers.dart';
import 'package:flutter/material.dart';
import '../../utils/dialog_helper.dart';
import '../../models/empleado_form_state.dart';
import '../../controllers/empleado_form_controller.dart';
import '../../controllers/usuario_empleado_controller.dart';

class NuevoEmpleadoScreen extends StatefulWidget {
  final UsuarioEmpleadoController usuarioEmpleadoController;

  const NuevoEmpleadoScreen({
    super.key,
    required this.usuarioEmpleadoController,
  });

  @override
  State<NuevoEmpleadoScreen> createState() => _NuevoEmpleadoScreenState();
}

class _NuevoEmpleadoScreenState extends State<NuevoEmpleadoScreen> {
  late EmpleadoFormState _formState;
  late EmpleadoFormController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _imagenPerfil;

  @override
  void initState() {
    super.initState();
    _formState = EmpleadoFormState();
    _controller = EmpleadoFormController(
      usuarioEmpleadoController: widget.usuarioEmpleadoController,
      formState: _formState,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _formState.dispose();
    super.dispose();
  }

  // Callback para cuando cambian los datos del usuario
  void _onUserDataChanged(String nombre, String apellido, String correo) {
    // Este método se llama cuando cambia algún dato en el formulario de usuario
    setState(() {}); // Actualiza la UI si es necesario
  }

  // Callback para cuando cambia la imagen de perfil
  void _onImagenPerfilChanged(String? path) {
    setState(() {
      _imagenPerfil = path;
      _formState.imagenPerfilPath = path;
    });
  }

  // Callback para cuando cambia la fecha de contratación
  void _onFechaContratacionChanged(DateTime fecha) {
    setState(() {
      _formState.fechaContratacion = fecha;
    });
  }

  Future<void> _guardarEmpleado() async {
    if (!_formKey.currentState!.validate()) return;

    if (_controller.nombreUsuarioExiste) {
      UIHelpers.mostrarError(context, "Nombre de usuario ya existe");
      return;
    }

    setState(() => _isLoading = true);
    DialogHelper.mostrarDialogoCarga(context, "Guardando empleado...");

    try {
      final usuario = Usuario(
        nombre: _formState.usuarioNombreController.text,
        apellido: _formState.usuarioApellidoController.text,
        nombreUsuario: _formState.usuarioNombreUsuarioController.text,
        contrasena: _formState.usuarioContrasenaController.text,
        correo: _formState.usuarioCorreoController.text,
        imagenPerfil: _formState.imagenPerfilPath,
        idEstado: 1,
      );

      final empleado = Empleado(
        claveSistema: _formState.claveSistemaController.text,
        nombre: _formState.usuarioNombreController.text,
        apellidoPaterno: _formState.usuarioApellidoController.text,
        apellidoMaterno: _formState.apellidoMaternoController.text,
        telefono: _formState.telefonoController.text,
        correo: _formState.usuarioCorreoController.text,
        direccion: _formState.direccionController.text,
        cargo: _formState.cargoController.text,
        sueldoActual: double.tryParse(_formState.sueldoController.text) ?? 0.0,
        fechaContratacion: _formState.fechaContratacion,
        imagenEmpleado: _formState.imagenEmpleadoPath,
        idEstado: 1,
      );

      await widget.usuarioEmpleadoController.crearEmpleado(usuario, empleado);

      if (mounted) {
        Navigator.of(context).pop(); // Cierra el diálogo de carga
        UIHelpers.mostrarExito(context, "Empleado creado exitosamente");
        Navigator.of(context).pop(); // Regresa a la pantalla anterior
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cierra el diálogo de carga
        UIHelpers.mostrarError(context, "Error al crear empleado: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo Empleado"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección para datos de usuario
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: EmpleadoUsuarioForm(
                      nombreController: _formState.usuarioNombreController,
                      apellidoController: _formState.usuarioApellidoController,
                      apellidoMaternoController:
                          _formState.apellidoMaternoController,
                      nombreUsuarioController:
                          _formState.usuarioNombreUsuarioController,
                      contrasenaController:
                          _formState.usuarioContrasenaController,
                      correoController: _formState.usuarioCorreoController,
                      isEditando: false,
                      onUserDataChanged: _onUserDataChanged,
                      controller: widget.usuarioEmpleadoController,
                      imagenPerfil: _imagenPerfil,
                      onImagenPerfilChanged: _onImagenPerfilChanged,
                      verificandoUsuario: _controller.verificandoUsuario,
                      nombreUsuarioExiste: _controller.nombreUsuarioExiste,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sección para datos laborales
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: EmpleadoLaboralForm(
                      claveSistemaController: _formState.claveSistemaController,
                      telefonoController: _formState.telefonoController,
                      direccionController: _formState.direccionController,
                      cargoController: _formState.cargoController,
                      sueldoController: _formState.sueldoController,
                      nombreController: _formState.usuarioNombreController,
                      apellidoController: _formState.usuarioApellidoController,
                      correoController: _formState.usuarioCorreoController,
                      fechaContratacion: _formState.fechaContratacion,
                      onFechaContratacionChanged: _onFechaContratacionChanged,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botón de guardar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _guardarEmpleado,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text("Crear Empleado"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

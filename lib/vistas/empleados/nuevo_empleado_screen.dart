import '../../models/usuario.dart';
import 'empleado_usuario_form.dart';
import 'empleado_laboral_form.dart';
import '../../models/empleado.dart';
import '../../utils/ui_helpers.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../utils/dialog_helper.dart';
import '../../models/empleado_form_state.dart';
import '../../controllers/empleado_form_controller.dart';
import '../../utils/app_colors.dart'; // Importar AppColors
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

  // Método para mostrar el diálogo de carga de manera segura
  void _mostrarDialogoCarga(String mensaje) {
    if (mounted) {
      DialogHelper.mostrarDialogoCarga(context, mensaje);
    }
  }

  // Método para cerrar el diálogo de carga de manera segura
  void _cerrarDialogo() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _guardarEmpleado() async {
    // CORRECCIÓN: Eliminar la llamada a limpiarContrasenaParaValidacion
    // Ya no llamamos a _controller.limpiarContrasenaParaValidacion();

    // CORRECCIÓN: No esperar, ya que no hay operación asíncrona necesaria aquí
    // await Future.delayed(const Duration(milliseconds: 50));

    developer.log('Iniciando validación del formulario...');

    if (!_formKey.currentState!.validate()) {
      developer.log('Validación de formulario falló');
      return;
    }

    developer.log('Formulario validado, verificando nombre de usuario...');

    // Validación de nombre de usuario existente
    if (_controller.nombreUsuarioExiste) {
      UIHelpers.mostrarError(context, "Nombre de usuario ya existe");
      return;
    }

    // CORRECCIÓN: Capturar la contraseña antes de validarla para asegurar que tengamos el valor correcto
    final contrasena = _formState.usuarioContrasenaController.text.trim();

    developer.log(
      'Nombre de usuario válido, verificando contraseña: "$contrasena", longitud=${contrasena.length}',
    );

    // Validación específica de contraseña - verificamos directamente aquí
    if (contrasena.length < 8) {
      UIHelpers.mostrarError(
        context,
        "La contraseña debe tener al menos 8 caracteres",
      );
      return;
    }

    developer.log('Contraseña válida, procediendo a guardar empleado...');

    // Actualizar el estado de carga y mostrar diálogo ANTES de operaciones asíncronas
    setState(() => _isLoading = true);

    // Mostrar diálogo de carga antes de la operación asíncrona
    _mostrarDialogoCarga("Guardando empleado...");

    try {
      final usuario = Usuario(
        nombre: _formState.usuarioNombreController.text,
        apellido: _formState.usuarioApellidoController.text,
        nombreUsuario: _formState.usuarioNombreUsuarioController.text,
        contrasena: contrasena, // Usamos la variable capturada previamente
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

      developer.log('Datos preparados, llamando al servicio de creación...');

      // Usar la contraseña capturada previamente
      await widget.usuarioEmpleadoController.crearUsuarioEmpleado(
        usuario,
        empleado,
        contrasena,
      );

      developer.log('Empleado creado exitosamente');

      if (!mounted) return;

      // Cerrar el diálogo de carga
      _cerrarDialogo();

      // Mostrar mensaje de éxito
      UIHelpers.mostrarExito(context, "Empleado creado exitosamente");

      // Navegar hacia atrás indicando éxito con 'true'
      Navigator.of(context).pop(true);
    } catch (e) {
      developer.log('Error al crear empleado: $e', error: e);
      if (!mounted) return;

      // Cerrar el diálogo de carga
      _cerrarDialogo();

      // Mostrar error
      UIHelpers.mostrarError(context, "Error al crear empleado: $e");
    } finally {
      // Actualizar estado de carga si todavía estamos montados
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo Empleado"),
        backgroundColor: AppColors.primario, // Aplicar color primario
        foregroundColor:
            AppColors.claro, // Aplicar color claro para el texto e iconos
        iconTheme: const IconThemeData(
          color: AppColors.claro,
        ), // Asegurar color del icono de retroceso
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
                  color: AppColors.claro, // Fondo de la tarjeta
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
                  color: AppColors.claro, // Fondo de la tarjeta
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
                      backgroundColor:
                          AppColors.primario, // Aplicar color primario
                      foregroundColor:
                          AppColors.claro, // Aplicar color claro para el texto
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color:
                                  AppColors
                                      .claro, // Aplicar color claro al indicador
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

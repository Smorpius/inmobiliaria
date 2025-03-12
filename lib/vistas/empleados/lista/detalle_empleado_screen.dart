import '../../../models/usuario.dart';
import 'package:flutter/material.dart';
import '../empleado_usuario_form.dart';
import '../empleado_laboral_form.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../controllers/empleado_form_controller.dart';
import '../../../controllers/usuario_empleado_controller.dart';
import '../../../models/empleado_form_state.dart' as form_model;

class DetalleEmpleadoScreen extends StatefulWidget {
  final UsuarioEmpleadoController controller;
  final int? idEmpleado; // Null para nuevo empleado

  const DetalleEmpleadoScreen({
    super.key,
    required this.controller,
    this.idEmpleado,
  });

  @override
  State<DetalleEmpleadoScreen> createState() => _DetalleEmpleadoScreenState();
}

class _DetalleEmpleadoScreenState extends State<DetalleEmpleadoScreen> {
  late final form_model.EmpleadoFormState _formState;
  late final EmpleadoFormController _formController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  int? _idUsuario;
  String? _imagenPerfil; // Variable para la imagen de perfil

  @override
  void initState() {
    super.initState();
    _formState = form_model.EmpleadoFormState();
    _formController = EmpleadoFormController(
      usuarioEmpleadoController: widget.controller,
      formState: _formState,
    );
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (widget.idEmpleado != null) {
      try {
        setState(() => _isLoading = true);

        final empleadoData = await widget.controller.obtenerEmpleado(
          widget.idEmpleado!,
        );

        if (empleadoData != null) {
          _idUsuario = empleadoData.usuario.id;
          _formController.nombreController.text = empleadoData.usuario.nombre;
          _formController.apellidoController.text =
              empleadoData.usuario.apellido;
          _formController.apellidoMaternoController.text =
              empleadoData.empleado.apellidoMaterno ?? '';
          _formController.nombreUsuarioController.text =
              empleadoData.usuario.nombreUsuario;
          _formController.correoController.text = empleadoData.empleado.correo;
          _formController.telefonoController.text =
              empleadoData.empleado.telefono;
          _formController.direccionController.text =
              empleadoData.empleado.direccion;
          _formController.claveSistemaController.text =
              empleadoData.empleado.claveSistema;
          _formController.cargoController.text = empleadoData.empleado.cargo;
          _formController.sueldoController.text =
              empleadoData.empleado.sueldoActual.toString();

          _formState.fechaContratacion =
              empleadoData.empleado.fechaContratacion;
          _imagenPerfil = empleadoData.usuario.imagenPerfil;
        }
      } catch (e) {
        setState(() => _errorMessage = "Error al cargar empleado: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _onFechaContratacionChanged(DateTime fecha) {
    setState(() => _formState.fechaContratacion = fecha);
  }

  void _onImagenPerfilChanged(String? imagePath) {
    setState(() => _imagenPerfil = imagePath);
  }

  Future<void> _guardar() async {
    if (!_formController.validar()) return;
    setState(() => _isSaving = true);

    try {
      final usuario = _formController.crearUsuario();
      final empleado = _formController.crearEmpleado();

      // Se crea un nuevo objeto Usuario con la imagen
      final usuarioConImagen = Usuario(
        id: usuario.id,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        nombreUsuario: usuario.nombreUsuario,
        contrasena: usuario.contrasena,
        correo: usuario.correo,
        imagenPerfil: _imagenPerfil,
        idEstado: usuario.idEstado,
        estadoNombre: usuario.estadoNombre,
      );

      if (widget.idEmpleado == null) {
        // CORRECCIÓN: Cambiar crearEmpleado por crearUsuarioEmpleado y pasar la contraseña
        await widget.controller.crearUsuarioEmpleado(
          usuarioConImagen,
          empleado,
          _formController.contrasenaController.text,
        );
      } else {
        await widget.controller.actualizarEmpleado(
          _idUsuario!,
          widget.idEmpleado!,
          usuarioConImagen,
          empleado,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.idEmpleado == null
                ? 'Empleado creado correctamente'
                : 'Empleado actualizado correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.idEmpleado == null ? 'Nuevo Empleado' : 'Editar Empleado',
      currentRoute: '/detalle_empleado',
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    EmpleadoUsuarioForm(
                      nombreController: _formController.nombreController,
                      apellidoController: _formController.apellidoController,
                      apellidoMaternoController:
                          _formController.apellidoMaternoController,
                      nombreUsuarioController:
                          _formController.nombreUsuarioController,
                      contrasenaController:
                          _formController.contrasenaController,
                      correoController: _formController.correoController,
                      isEditando: widget.idEmpleado != null,
                      verificandoUsuario: _formController.verificandoUsuario,
                      nombreUsuarioExiste: _formController.nombreUsuarioExiste,
                      controller: widget.controller,
                      imagenPerfil: _imagenPerfil,
                      onImagenPerfilChanged: _onImagenPerfilChanged,
                      onUserDataChanged: (
                        String nombre,
                        String apellido,
                        String correo,
                      ) {
                        _formController.nombreController.text = nombre;
                        _formController.apellidoController.text = apellido;
                        _formController.correoController.text = correo;
                      },
                    ),
                    const SizedBox(height: 16),
                    EmpleadoLaboralForm(
                      claveSistemaController:
                          _formController.claveSistemaController,
                      telefonoController: _formController.telefonoController,
                      direccionController: _formController.direccionController,
                      cargoController: _formController.cargoController,
                      sueldoController: _formController.sueldoController,
                      nombreController: _formController.nombreController,
                      apellidoController: _formController.apellidoController,
                      correoController: _formController.correoController,
                      fechaContratacion: _formState.fechaContratacion,
                      onFechaContratacionChanged: _onFechaContratacionChanged,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child:
                            _isSaving
                                ? const CircularProgressIndicator()
                                : Text(
                                  widget.idEmpleado == null
                                      ? 'Crear Empleado'
                                      : 'Actualizar Empleado',
                                ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

import '../../../models/usuario.dart';
import '../../../models/empleado.dart';
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
  // Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();
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

  double _parseSueldo(String text) {
    try {
      return double.parse(text);
    } catch (_) {
      return 0.0;
    }
  }

  DateTime _getFechaContratacion() {
    final DateTime? fecha = _formState.fechaContratacion;
    if (fecha == null) {
      return DateTime.now();
    }
    return fecha;
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
    // Validación inicial del formulario
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor corrige los errores en el formulario'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Determinar la contraseña de manera más explícita
      String contrasenaNueva;
      if (widget.idEmpleado != null &&
          _formController.contrasenaController.text.isEmpty) {
        contrasenaNueva = ''; // Mantener contraseña existente (cadena vacía)
      } else {
        contrasenaNueva = _formController.contrasenaController.text.trim();
      }

      // Manejar la imagen de perfil
      String imagenPerfilFinal = '';
      if (_imagenPerfil != null) {
        imagenPerfilFinal = _imagenPerfil!;
      }

      // Obtener datos actualizados
      final usuario = Usuario(
        id: _idUsuario, // ID del usuario existente para actualización
        nombre: _formController.nombreController.text.trim(),
        apellido: _formController.apellidoController.text.trim(),
        nombreUsuario: _formController.nombreUsuarioController.text.trim(),
        contrasena: contrasenaNueva,
        correo: _formController.correoController.text.trim(),
        imagenPerfil: imagenPerfilFinal,
        idEstado: 1, // Activo por defecto
      );

      final empleado = Empleado(
        id: widget.idEmpleado, // ID del empleado existente para actualización
        claveSistema: _formController.claveSistemaController.text.trim(),
        nombre: _formController.nombreController.text.trim(),
        apellidoPaterno: _formController.apellidoController.text.trim(),
        apellidoMaterno: _formController.apellidoMaternoController.text.trim(),
        telefono: _formController.telefonoController.text.trim(),
        correo: _formController.correoController.text.trim(),
        direccion: _formController.direccionController.text.trim(),
        cargo: _formController.cargoController.text.trim(),
        sueldoActual: _parseSueldo(_formController.sueldoController.text),
        fechaContratacion: _getFechaContratacion(),
        imagenEmpleado: imagenPerfilFinal,
        idEstado: 1, // Activo por defecto
      );

      if (widget.idEmpleado == null) {
        // Creación de nuevo empleado
        await widget.controller.crearUsuarioEmpleado(
          usuario,
          empleado,
          _formController.contrasenaController.text.trim(),
        );
      } else {
        // Actualización de empleado existente
        if (_idUsuario == null) {
          throw Exception("No se pudo identificar el usuario a actualizar");
        }

        await widget.controller.actualizarEmpleado(
          _idUsuario!,
          widget.idEmpleado!,
          usuario,
          empleado,
        );
      }

      if (!mounted) return;

      // Mostrar mensaje de éxito
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

      // Retornar true para indicar éxito en la pantalla anterior
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Detalles',
            textColor: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Error al guardar'),
                      content: SingleChildScrollView(child: Text(e.toString())),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ),
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
      showDrawer: false,
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
                        nombreUsuarioExiste:
                            _formController.nombreUsuarioExiste,
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
                        direccionController:
                            _formController.direccionController,
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
              ),
    );
  }
}

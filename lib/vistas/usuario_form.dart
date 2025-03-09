import 'dart:io';
import '../models/usuario.dart';
import '../utils/ui_helpers.dart';
import 'dart:developer' as developer;
import '../utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import '../utils/form_validators.dart';
import '../services/image_service.dart';
import '../widgets/custom_form_fields.dart';
import '../widgets/image_selector_widget.dart';
import '../controllers/usuario_controller.dart';

// Importando los componentes refactorizados

class UsuarioForm extends StatefulWidget {
  final UsuarioController usuarioController;
  final Function() onUsuarioAdded;
  final Function(String) onError;

  const UsuarioForm({
    super.key,
    required this.usuarioController,
    required this.onUsuarioAdded,
    required this.onError,
  });

  @override
  State<UsuarioForm> createState() => _UsuarioFormState();
}

class _UsuarioFormState extends State<UsuarioForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nombreUsuarioController =
      TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  final ImageService _imageService = ImageService();
  String? _imagenPerfil;

  bool _isEditing = false;
  int? _usuarioEditandoId;
  bool _isLoading = false;

  Future<bool> _verificarImagenValida(String? path) async {
    if (path == null || path.isEmpty) return false;

    try {
      final file = File(path);
      if (await file.exists()) {
        final extension = path.toLowerCase();
        return extension.endsWith('.jpg') ||
            extension.endsWith('.jpeg') ||
            extension.endsWith('.png');
      }
      return false;
    } catch (e) {
      developer.log('Error al verificar imagen: $e', error: e);
      return false;
    }
  }

  void _procesarUsuario() async {
    if (_isLoading) return; // Prevenir múltiples envíos

    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);

        // Mostrar diálogo de carga
        DialogHelper.mostrarDialogoCarga(context, 'Guardando usuario...');

        // Si hay una imagen seleccionada, guardarla permanentemente
        String? imagenGuardada = _imagenPerfil;
        if (_imagenPerfil != null && _imagenPerfil!.isNotEmpty) {
          try {
            // Usar getImageFile del servicio para obtener el archivo de forma segura
            final File? imagenFile = await _imageService.getImageFile(
              _imagenPerfil,
            );

            if (imagenFile != null) {
              // Verificar si la imagen es válida antes de intentar guardarla
              if (await _verificarImagenValida(_imagenPerfil)) {
                imagenGuardada = await _imageService.saveImage(
                  imagenFile,
                  'usuarios',
                  'perfil',
                );

                if (imagenGuardada == null) {
                  throw Exception('No se pudo guardar la imagen de perfil');
                }
              } else {
                throw UnsupportedError(
                  'La imagen seleccionada no tiene un formato válido',
                );
              }
            } else {
              _mostrarError('La imagen seleccionada ya no está disponible');
              developer.log(
                'Error: La imagen no existe o no se puede acceder: $_imagenPerfil',
              );
            }
          } catch (e) {
            if (e is UnsupportedError) {
              _mostrarError('Formato de imagen no soportado: ${e.message}');
              developer.log(
                'Error de formato de imagen: ${e.message}',
                error: e,
              );
            } else {
              // Si falla el guardado de la imagen, continuamos con la imagen temporal
              // pero registramos el error
              _mostrarError(
                'Advertencia: La imagen podría no persistir correctamente',
              );
              developer.log('Error al guardar imagen: $e', error: e);
            }
            // Continuamos el proceso sin la imagen
            imagenGuardada = null;
          }
        }

        if (_isEditing && _usuarioEditandoId != null) {
          final usuarioEditado = Usuario(
            id: _usuarioEditandoId,
            nombre: _nombreController.text.trim(),
            apellido: _apellidoController.text.trim(),
            nombreUsuario: _nombreUsuarioController.text.trim(),
            contrasena:
                _contrasenaController.text.isEmpty
                    ? ''
                    : _contrasenaController.text.trim(),
            correo: _emailController.text.trim(),
            imagenPerfil: imagenGuardada,
            idEstado: 1,
          );

          await widget.usuarioController.updateUsuario(usuarioEditado);
          _limpiarFormulario();
          _mostrarExito('Usuario actualizado exitosamente');
          widget.onUsuarioAdded();
        } else {
          final usuario = Usuario(
            nombre: _nombreController.text.trim(),
            apellido: _apellidoController.text.trim(),
            nombreUsuario: _nombreUsuarioController.text.trim(),
            contrasena: _contrasenaController.text.trim(),
            correo: _emailController.text.trim(),
            imagenPerfil: imagenGuardada,
            idEstado: 1,
          );

          await widget.usuarioController.insertUsuario(usuario);
          _limpiarFormulario();
          _mostrarExito('Usuario agregado exitosamente');
          widget.onUsuarioAdded();
        }
      } catch (e) {
        _mostrarError('Error al procesar usuario: $e');
        developer.log('Error al procesar usuario: $e', error: e);
      } finally {
        // Cerrar diálogo de carga si está abierto
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void setUsuarioParaEditar(Usuario usuario) {
    if (_isLoading) return; // No cambiar estado durante carga

    setState(() {
      _isEditing = true;
      _usuarioEditandoId = usuario.id;
      _nombreController.text = usuario.nombre;
      _apellidoController.text = usuario.apellido;
      _emailController.text = usuario.correo ?? '';
      _nombreUsuarioController.text = usuario.nombreUsuario;
      _contrasenaController.clear();
      _imagenPerfil = usuario.imagenPerfil;
    });
  }

  void _limpiarFormulario() {
    if (_isLoading) return; // No limpiar durante carga

    setState(() {
      _isEditing = false;
      _usuarioEditandoId = null;
      _nombreController.clear();
      _apellidoController.clear();
      _emailController.clear();
      _nombreUsuarioController.clear();
      _contrasenaController.clear();
      _imagenPerfil = null;
    });
  }

  void _onImageSelected(String path) {
    setState(() {
      _imagenPerfil = path;
    });
  }

  void _mostrarError(String mensaje) {
    widget.onError(mensaje);

    if (mounted) {
      UIHelpers.mostrarError(context, mensaje);
    }
  }

  void _mostrarExito(String mensaje) {
    if (mounted) {
      UIHelpers.mostrarExito(context, mensaje);
    }
  }

  @override
  void dispose() {
    // Liberar recursos
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _nombreUsuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isLoading,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  _isEditing ? "Editar Usuario" : "Agregar Usuario",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ImageSelectorWidget(
                  imagePath: _imagenPerfil,
                  nombre: _nombreController.text,
                  apellido: _apellidoController.text,
                  isLoading: _isLoading,
                  onImageSelected: _onImageSelected,
                  onError: _mostrarError,
                ),
                const SizedBox(height: 20),
                CustomFormFields.buildTextFormField(
                  controller: _nombreController,
                  labelText: "Nombre",
                  icon: Icons.person,
                  validator: FormValidators.validateNombre,
                  maxLength: 50,
                ),
                const SizedBox(height: 15),
                CustomFormFields.buildTextFormField(
                  controller: _apellidoController,
                  labelText: "Apellido",
                  icon: Icons.person_outline,
                  validator: FormValidators.validateApellido,
                  maxLength: 50,
                ),
                const SizedBox(height: 15),
                CustomFormFields.buildTextFormField(
                  controller: _emailController,
                  labelText: "Email",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: FormValidators.validateEmail,
                  maxLength: 100,
                ),
                const SizedBox(height: 15),
                CustomFormFields.buildTextFormField(
                  controller: _nombreUsuarioController,
                  labelText: "Nombre de Usuario",
                  icon: Icons.account_circle,
                  validator: FormValidators.validateUsername,
                  maxLength: 30,
                ),
                const SizedBox(height: 15),
                CustomFormFields.buildTextFormField(
                  controller: _contrasenaController,
                  labelText:
                      _isEditing ? "Nueva Contraseña (opcional)" : "Contraseña",
                  icon: Icons.lock,
                  obscureText: true,
                  validator:
                      (value) =>
                          FormValidators.validatePassword(value, _isEditing),
                  maxLength: 100,
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    if (_isEditing)
                      Expanded(
                        child: CustomFormFields.buildActionButton(
                          label: "Cancelar",
                          onPressed: _isLoading ? null : _limpiarFormulario,
                          icon: Icons.cancel,
                          backgroundColor: Colors.grey,
                        ),
                      ),
                    if (_isEditing) const SizedBox(width: 10),
                    Expanded(
                      child: CustomFormFields.buildActionButton(
                        label:
                            _isEditing
                                ? "Actualizar Usuario"
                                : "Agregar Usuario",
                        onPressed: _isLoading ? null : _procesarUsuario,
                        icon: _isEditing ? Icons.save : Icons.add,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

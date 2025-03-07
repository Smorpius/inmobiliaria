import '../../../models/usuario.dart';
import 'package:flutter/material.dart';
import '../../../controllers/usuario_controller.dart';

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
  final TextEditingController _nombreUsuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  bool _isEditing = false;
  int? _usuarioEditandoId;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  void _procesarUsuario() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_isEditing && _usuarioEditandoId != null) {
          final usuarioEditado = Usuario(
            id: _usuarioEditandoId,
            nombre: _nombreController.text.trim(),
            apellido: _apellidoController.text.trim(),
            nombreUsuario: _nombreUsuarioController.text.trim(),
            contrasena: _contrasenaController.text.isEmpty
                ? ''
                : _contrasenaController.text.trim(),
            correo: _emailController.text.trim(),
          );

          await widget.usuarioController.updateUsuario(usuarioEditado);
          _limpiarFormulario();
          widget.onUsuarioAdded();
        } else {
          final usuario = Usuario(
            nombre: _nombreController.text.trim(),
            apellido: _apellidoController.text.trim(),
            nombreUsuario: _nombreUsuarioController.text.trim(),
            contrasena: _contrasenaController.text.trim(),
            correo: _emailController.text.trim(),
          );

          await widget.usuarioController.insertUsuario(usuario);
          _limpiarFormulario();
          widget.onUsuarioAdded();
        }
      } catch (e) {
        widget.onError('Error al procesar usuario: $e');
      }
    }
  }

  void setUsuarioParaEditar(Usuario usuario) {
    setState(() {
      _isEditing = true;
      _usuarioEditandoId = usuario.id;
      _nombreController.text = usuario.nombre;
      _apellidoController.text = usuario.apellido;
      _emailController.text = usuario.correo ?? '';
      _nombreUsuarioController.text = usuario.nombreUsuario;
      _contrasenaController.clear();
    });
  }

  void _limpiarFormulario() {
    setState(() {
      _isEditing = false;
      _usuarioEditandoId = null;
      _nombreController.clear();
      _apellidoController.clear();
      _emailController.clear();
      _nombreUsuarioController.clear();
      _contrasenaController.clear();
    });
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _nombreController,
                labelText: "Nombre",
                icon: Icons.person,
                validator: (value) => value!.isEmpty ? "Ingrese un nombre" : null,
              ),
              const SizedBox(height: 15),
              _buildTextFormField(
                controller: _apellidoController,
                labelText: "Apellido",
                icon: Icons.person_outline,
                validator: (value) => value!.isEmpty ? "Ingrese un apellido" : null,
              ),
              const SizedBox(height: 15),
              _buildTextFormField(
                controller: _emailController,
                labelText: "Email",
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final correo = value?.trim() ?? '';
                  if (correo.isEmpty) return "Ingrese un email";
                  if (!_isValidEmail(correo)) return "Email inválido";
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextFormField(
                controller: _nombreUsuarioController,
                labelText: "Nombre de Usuario",
                icon: Icons.account_circle,
                validator: (value) {
                  final nombreUser = value?.trim() ?? '';
                  return nombreUser.isEmpty ? "Ingrese un nombre de usuario" : null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextFormField(
                controller: _contrasenaController,
                labelText: _isEditing ? "Nueva Contraseña (opcional)" : "Contraseña",
                icon: Icons.lock,
                obscureText: true,
                validator: (value) {
                  final pass = value?.trim() ?? '';
                  if (!_isEditing && pass.isEmpty) {
                    return "Ingrese una contraseña";
                  }
                  if (pass.isNotEmpty && pass.length < 8) {
                    return "La contraseña debe tener al menos 8 caracteres";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  if (_isEditing)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _limpiarFormulario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.cancel),
                        label: const Text("Cancelar"),
                      ),
                    ),
                  if (_isEditing) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _procesarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(_isEditing ? Icons.save : Icons.add),
                      label: Text(_isEditing ? "Actualizar Usuario" : "Agregar Usuario"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
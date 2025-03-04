import '../models/usuario_model.dart';
import 'package:flutter/material.dart';
import '../controllers/usuario_controller.dart';

class UsuarioPage extends StatefulWidget {
  final UsuarioController usuarioController;

  const UsuarioPage({super.key, required this.usuarioController});

  @override
  UsuarioPageState createState() => UsuarioPageState();
}

class UsuarioPageState extends State<UsuarioPage> {
  late final UsuarioController _usuarioController;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nombreUsuarioController =
      TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  List<Usuario> _usuarios = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usuarioController = widget.usuarioController;
    _loadUsuarios();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _loadUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final usuarios = await _usuarioController.getUsuarios();
      setState(() {
        _usuarios = usuarios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar usuarios');
    }
  }

  void _agregarUsuario() async {
    if (_formKey.currentState!.validate()) {
      try {
        final usuario = Usuario(
          nombre: _nombreController.text.trim(),
          apellido: _apellidoController.text.trim(),
          nombreUsuario: _nombreUsuarioController.text.trim(),
          contrasena: _contrasenaController.text,
          correo: _emailController.text.trim(),
        );

        final result = await _usuarioController.insertUsuario(usuario);

        if (result != -1) {
          _limpiarCampos();
          await _loadUsuarios();
          _showSuccessSnackBar('Usuario agregado exitosamente');
        } else {
          _showErrorSnackBar('Error al agregar usuario');
        }
      } catch (e) {
        _showErrorSnackBar('Error al guardar usuario');
      }
    }
  }

  void _limpiarCampos() {
    _nombreController.clear();
    _apellidoController.clear();
    _emailController.clear();
    _nombreUsuarioController.clear();
    _contrasenaController.clear();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Usuarios"),
        backgroundColor: const Color.fromARGB(255, 153, 32, 48),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextFormField(
                      controller: _nombreController,
                      labelText: "Nombre",
                      validator:
                          (value) =>
                              value!.isEmpty ? "Ingrese un nombre" : null,
                    ),
                    const SizedBox(height: 10),
                    _buildTextFormField(
                      controller: _apellidoController,
                      labelText: "Apellido",
                      validator:
                          (value) =>
                              value!.isEmpty ? "Ingrese un apellido" : null,
                    ),
                    const SizedBox(height: 10),
                    _buildTextFormField(
                      controller: _emailController,
                      labelText: "Email",
                      validator: (value) {
                        if (value!.isEmpty) return "Ingrese un email";
                        if (!_isValidEmail(value)) return "Email inválido";
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildTextFormField(
                      controller: _nombreUsuarioController,
                      labelText: "Nombre de Usuario",
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? "Ingrese un nombre de usuario"
                                  : null,
                    ),
                    const SizedBox(height: 10),
                    _buildTextFormField(
                      controller: _contrasenaController,
                      labelText: "Contraseña",
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Ingrese una contraseña";
                        }
                        if (value.length < 6) {
                          return "Contraseña debe tener al menos 6 caracteres";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _agregarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 153, 32, 48),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("Agregar Usuario"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Usuarios Registrados",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.separated(
                              itemCount: _usuarios.length,
                              separatorBuilder:
                                  (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final usuario = _usuarios[index];
                                return ListTile(
                                  title: Text(
                                    '${usuario.nombre} ${usuario.apellido}',
                                  ),
                                  subtitle: Text(
                                    'Usuario: ${usuario.nombreUsuario}\n'
                                    'Email: ${usuario.correo ?? 'No definido'}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      // Implementar eliminación de usuario
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      obscureText: obscureText,
      validator: validator,
    );
  }
}

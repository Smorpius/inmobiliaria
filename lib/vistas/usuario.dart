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
  bool _mostrarInactivos = false;
  bool _isEditing = false;
  int? _usuarioEditandoId;

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
      _showErrorSnackBar('Error al cargar usuarios: $e');
    }
  }

  void _agregarUsuario() async {
    if (_formKey.currentState!.validate()) {
      try {
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
          );

          final result = await _usuarioController.updateUsuario(usuarioEditado);
          if (!mounted) return;
          if (result > 0) {
            _limpiarFormulario();
            await _loadUsuarios();
            _mostrarMensajeExito('Usuario actualizado exitosamente');
          } else {
            _mostrarMensajeError('Error al actualizar usuario');
          }
        } else {
          final usuario = Usuario(
            nombre: _nombreController.text.trim(),
            apellido: _apellidoController.text.trim(),
            nombreUsuario: _nombreUsuarioController.text.trim(),
            contrasena: _contrasenaController.text.trim(),
            correo: _emailController.text.trim(),
          );

          final result = await _usuarioController.insertUsuario(usuario);
          if (!mounted) return;
          if (result != -1) {
            _limpiarFormulario();
            await _loadUsuarios();
            _mostrarMensajeExito('Usuario agregado exitosamente');
          } else {
            _mostrarMensajeError('Error al agregar usuario');
          }
        }
      } catch (e) {
        if (!mounted) return;
        _mostrarMensajeError('Error al procesar usuario: $e');
      }
    }
  }

  void _editarUsuario(Usuario usuario) {
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

  void _eliminarUsuario(Usuario usuario) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Confirmar Inactivación'),
            content: Text(
              '¿Está seguro que desea inactivar al usuario ${usuario.nombreUsuario}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final confirmContext = dialogContext;
                  try {
                    await _usuarioController.inactivarUsuario(usuario.id!);
                    if (!mounted || !confirmContext.mounted) return;
                    Navigator.pop(confirmContext);
                    await _loadUsuarios();
                    _mostrarMensajeExito('Usuario inactivado exitosamente');
                  } catch (e) {
                    if (!mounted || !confirmContext.mounted) return;
                    Navigator.pop(confirmContext);
                    _mostrarMensajeError('Error al inactivar usuario: $e');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Inactivar'),
              ),
            ],
          ),
    );
  }

  void _limpiarFormulario() {
    setState(() {
      _isEditing = false;
      _usuarioEditandoId = null;
      _limpiarCampos();
    });
  }

  void _limpiarCampos() {
    _nombreController.clear();
    _apellidoController.clear();
    _emailController.clear();
    _nombreUsuarioController.clear();
    _contrasenaController.clear();
  }

  void _mostrarMensajeExito(String mensaje) {
    if (mounted) {
      _showSuccessSnackBar(mensaje);
    }
  }

  void _mostrarMensajeError(String mensaje) {
    if (mounted) {
      _showErrorSnackBar(mensaje);
    }
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

  String _getEstadoTexto(int? idEstado) {
    return idEstado == 1 ? 'Activo' : 'Inactivo';
  }

  Color _getEstadoColor(int? idEstado) {
    return idEstado == 1 ? Colors.green : Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final usuariosVisibles =
        _mostrarInactivos
            ? _usuarios
            : _usuarios.where((usuario) => usuario.idEstado == 1).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Gestión de Usuarios",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 153, 32, 48),
        actions: [
          Row(
            children: [
              const Text(
                "Mostrar inactivos",
                style: TextStyle(color: Colors.white),
              ),
              Switch(
                value: _mostrarInactivos,
                onChanged: (value) => setState(() => _mostrarInactivos = value),
                activeColor: Colors.white,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsuarios,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulario
            Expanded(
              flex: 2,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        Text(
                          _isEditing ? "Editar Usuario" : "Agregar Usuario",
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: const Color.fromARGB(255, 153, 32, 48),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextFormField(
                          controller: _nombreController,
                          labelText: "Nombre",
                          icon: Icons.person,
                          validator:
                              (value) =>
                                  value!.isEmpty ? "Ingrese un nombre" : null,
                        ),
                        const SizedBox(height: 15),
                        _buildTextFormField(
                          controller: _apellidoController,
                          labelText: "Apellido",
                          icon: Icons.person_outline,
                          validator:
                              (value) =>
                                  value!.isEmpty ? "Ingrese un apellido" : null,
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
                            return nombreUser.isEmpty
                                ? "Ingrese un nombre de usuario"
                                : null;
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildTextFormField(
                          controller: _contrasenaController,
                          labelText:
                              _isEditing
                                  ? "Nueva Contraseña (opcional)"
                                  : "Contraseña",
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
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
                                onPressed: _agregarUsuario,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    153,
                                    32,
                                    48,
                                  ),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: Icon(_isEditing ? Icons.save : Icons.add),
                                label: Text(
                                  _isEditing
                                      ? "Actualizar Usuario"
                                      : "Agregar Usuario",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Lista de usuarios
            Expanded(
              flex: 3,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Usuarios Registrados",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall?.copyWith(
                                      color: const Color.fromARGB(
                                        255,
                                        153,
                                        32,
                                        48,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Total: ${usuariosVisibles.length}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(thickness: 1.5),
                              const SizedBox(height: 10),
                              Expanded(
                                child:
                                    usuariosVisibles.isEmpty
                                        ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.person_off,
                                                size: 64,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                "No hay usuarios registrados",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: Colors.grey,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        )
                                        : ListView.separated(
                                          itemCount: usuariosVisibles.length,
                                          separatorBuilder:
                                              (context, index) =>
                                                  const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                            final usuario =
                                                usuariosVisibles[index];
                                            return Card(
                                              elevation: 2,
                                              margin: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                side: BorderSide(
                                                  color: _getEstadoColor(
                                                    usuario.idEstado,
                                                  ).withAlpha(76),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12.0,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 28,
                                                      backgroundColor:
                                                          const Color.fromARGB(
                                                            255,
                                                            153,
                                                            32,
                                                            48,
                                                          ),
                                                      child: Text(
                                                        usuario
                                                                .nombre
                                                                .isNotEmpty
                                                            ? usuario.nombre[0]
                                                                .toUpperCase()
                                                            : '?',
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  '${usuario.nombre} ${usuario.apellido}',
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                              ),
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: _getEstadoColor(
                                                                    usuario
                                                                        .idEstado,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        20,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  _getEstadoTexto(
                                                                    usuario
                                                                        .idEstado,
                                                                  ),
                                                                  style: const TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          _buildInfoRow(
                                                            Icons
                                                                .account_circle,
                                                            "Usuario:",
                                                            usuario
                                                                .nombreUsuario,
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          _buildInfoRow(
                                                            Icons.email,
                                                            "Email:",
                                                            (usuario.correo ==
                                                                        null ||
                                                                    usuario
                                                                        .correo!
                                                                        .trim()
                                                                        .isEmpty)
                                                                ? 'No disponible'
                                                                : usuario
                                                                    .correo!,
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          _buildInfoRow(
                                                            Icons
                                                                .calendar_today,
                                                            "Registro:",
                                                            usuario.fechaCreacion !=
                                                                    null
                                                                ? _formatDate(
                                                                  usuario
                                                                      .fechaCreacion!,
                                                                )
                                                                : 'No disponible',
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Column(
                                                      children: [
                                                        if (usuario.idEstado ==
                                                            1)
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons.edit,
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                            onPressed:
                                                                () =>
                                                                    _editarUsuario(
                                                                      usuario,
                                                                    ),
                                                            tooltip:
                                                                'Editar usuario',
                                                          ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        usuario.idEstado == 1
                                                            ? IconButton(
                                                              icon: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                              onPressed:
                                                                  () =>
                                                                      _eliminarUsuario(
                                                                        usuario,
                                                                      ),
                                                              tooltip:
                                                                  'Inactivar usuario',
                                                            )
                                                            : const Icon(
                                                              Icons.block,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
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
          borderSide: const BorderSide(color: Color.fromARGB(255, 153, 32, 48)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 153, 32, 48),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}

import 'usuario_form.dart';
import 'usuario_list.dart';
import '../../../models/usuario.dart';
import 'package:flutter/material.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../controllers/usuario_controller.dart';

class UsuarioPage extends StatefulWidget {
  final UsuarioController usuarioController;

  const UsuarioPage({super.key, required this.usuarioController});

  @override
  UsuarioPageState createState() => UsuarioPageState();
}

class UsuarioPageState extends State<UsuarioPage> {
  List<Usuario> _usuarios = [];
  bool _isLoading = false;
  bool _mostrarInactivos = false;

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final usuarios = await widget.usuarioController.getUsuarios();
      setState(() {
        _usuarios = usuarios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar usuarios: $e');
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

  @override
  Widget build(BuildContext context) {
    final usuariosVisibles =
        _mostrarInactivos
            ? _usuarios
            : _usuarios.where((usuario) => usuario.idEstado == 1).toList();

    return AppScaffold(
      title: 'Gestión de Usuarios',
      currentRoute: '/usuario',
      actions: [
        Row(
          children: [
            const Text(
              "Mostrar inactivos",
              style: TextStyle(color: Colors.teal),
            ),
            Switch(
              value: _mostrarInactivos,
              onChanged: (value) => setState(() => _mostrarInactivos = value),
              activeColor: Colors.teal,
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadUsuarios,
          tooltip: 'Actualizar',
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulario
            Expanded(
              flex: 2,
              child: UsuarioForm(
                usuarioController: widget.usuarioController,
                onUsuarioAdded: () {
                  _loadUsuarios();
                  _showSuccessSnackBar('Usuario procesado exitosamente');
                },
                onError: (message) => _showErrorSnackBar(message),
              ),
            ),

            const SizedBox(width: 20),

            // Lista de usuarios
            Expanded(
              flex: 3,
              child: UsuarioList(
                usuarios: usuariosVisibles,
                isLoading: _isLoading,
                usuarioController: widget.usuarioController,
                onUsuarioEdited: (usuario) {
                  _loadUsuarios();
                  _showSuccessSnackBar('Usuario actualizado exitosamente');
                },
                onUsuarioInactivated: () {
                  _loadUsuarios();
                  _showSuccessSnackBar('Usuario inactivado exitosamente');
                },
                onError: (message) => _showErrorSnackBar(message),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

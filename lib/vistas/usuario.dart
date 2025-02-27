import 'package:flutter/material.dart';

class UsuarioPage extends StatefulWidget {
  const UsuarioPage({super.key});

  @override
  _UsuarioPageState createState() => _UsuarioPageState();
}

class _UsuarioPageState extends State<UsuarioPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nombreUsuarioController =
      TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();
  final List<Map<String, String>> _usuarios = [];

  void _agregarUsuario() {
    setState(() {
      if (_idController.text.isNotEmpty &&
          _nombreController.text.isNotEmpty &&
          _apellidoController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _nombreUsuarioController.text.isNotEmpty &&
          _contrasenaController.text.isNotEmpty &&
          _fechaNacimientoController.text.isNotEmpty) {
        _usuarios.add({
          'id': _idController.text,
          'nombre': _nombreController.text,
          'apellido': _apellidoController.text,
          'email': _emailController.text,
          'nombreUsuario': _nombreUsuarioController.text,
          'contrasena': _contrasenaController.text,
          'fechaNacimiento': _fechaNacimientoController.text,
        });
        _idController.clear();
        _nombreController.clear();
        _apellidoController.clear();
        _emailController.clear();
        _nombreUsuarioController.clear();
        _contrasenaController.clear();
        _fechaNacimientoController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar Usuario"),
        backgroundColor: const Color.fromARGB(255, 153, 32, 48),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: "ID",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _apellidoController,
              decoration: InputDecoration(
                labelText: "Apellido",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nombreUsuarioController,
              decoration: InputDecoration(
                labelText: "Nombre de Usuario",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contrasenaController,
              decoration: InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                obscuringCharacter: '*',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fechaNacimientoController,
              decoration: InputDecoration(
                labelText: "Fecha de Nacimiento",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _agregarUsuario,
              child: const Text("Agregar Usuario"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = _usuarios[index];
                  return ListTile(
                    title: Text('${usuario['nombre']} ${usuario['apellido']}'),
                    subtitle: Text(
                      'Email: ${usuario['email']}\nUsuario: ${usuario['nombreUsuario']}\nFecha de Nacimiento: ${usuario['fechaNacimiento']}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

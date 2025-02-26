import 'package:flutter/material.dart';

class UsuarioPage extends StatefulWidget {
  const UsuarioPage({super.key});

  @override
  _UsuarioPageState createState() => _UsuarioPageState();
}

class _UsuarioPageState extends State<UsuarioPage> {
  final TextEditingController _nombreController = TextEditingController();
  final List<String> _usuarios = [];

  void _agregarUsuario() {
    setState(() {
      if (_nombreController.text.isNotEmpty) {
        _usuarios.add(_nombreController.text);
        _nombreController.clear();
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
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: "Nombre",
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
                  return ListTile(title: Text(_usuarios[index]));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'usuario_card.dart';
import '../../../models/usuario.dart';
import 'package:flutter/material.dart';
import '../../../controllers/usuario_controller.dart';

class UsuarioList extends StatelessWidget {
  final List<Usuario> usuarios;
  final bool isLoading;
  final UsuarioController usuarioController;
  final Function(Usuario) onUsuarioEdited;
  final Function() onUsuarioInactivated;
  final Function(String) onError;

  const UsuarioList({
    super.key,
    required this.usuarios,
    required this.isLoading,
    required this.usuarioController,
    required this.onUsuarioEdited,
    required this.onUsuarioInactivated,
    required this.onError,
  });

  void _eliminarUsuario(BuildContext context, Usuario usuario) {
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
                  try {
                    Navigator.pop(dialogContext);
                    await usuarioController.inactivarUsuario(usuario.id!);
                    onUsuarioInactivated();
                  } catch (e) {
                    onError('Error al inactivar usuario: $e');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Inactivar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Usuarios Registrados",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Total: ${usuarios.length}",
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
                          usuarios.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                itemCount: usuarios.length,
                                separatorBuilder:
                                    (context, index) =>
                                        const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final usuario = usuarios[index];
                                  return UsuarioCard(
                                    usuario: usuario,
                                    onEdit: onUsuarioEdited,
                                    onDelete:
                                        (usuario) =>
                                            _eliminarUsuario(context, usuario),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "No hay usuarios registrados",
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

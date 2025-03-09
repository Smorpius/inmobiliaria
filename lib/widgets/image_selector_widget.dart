import 'dart:io';
import 'dart:developer' as developer;
import '../widgets/user_avatar.dart';
import '../utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSelectorWidget extends StatelessWidget {
  final String? imagePath;
  final String nombre;
  final String apellido;
  final bool isLoading;
  final Function(String) onImageSelected;
  final Function(String) onError;

  const ImageSelectorWidget({
    super.key,
    this.imagePath,
    required this.nombre,
    required this.apellido,
    required this.isLoading,
    required this.onImageSelected,
    required this.onError,
  });

  Future<void> _seleccionarImagen(BuildContext context) async {
    if (isLoading) return; // Prevenir múltiples llamadas durante carga

    try {
      // Mostrar diálogo de carga
      DialogHelper.mostrarDialogoCarga(context, 'Procesando imagen...');

      // Selección de imagen
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      // Cerrar diálogo de carga
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (pickedFile != null) {
        onImageSelected(pickedFile.path);
      }
    } on UnsupportedError catch (e) {
      onError('Formato de imagen no soportado: ${e.message}');
      developer.log('Error de formato de imagen: ${e.message}', error: e);
    } on Exception catch (e) {
      onError('Error al seleccionar imagen: $e');
      developer.log('Error al seleccionar imagen: $e', error: e);
    } catch (e) {
      onError('Error desconocido: $e');
      developer.log('Error desconocido: $e', error: e);
    }
  }

  Widget _buildImageDisplay() {
    if (imagePath != null && imagePath!.isNotEmpty) {
      try {
        final file = File(imagePath!);
        return FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasData && snapshot.data == true) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.file(
                  file,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackAvatar(isError: true);
                  },
                ),
              );
            }

            return _buildFallbackAvatar();
          },
        );
      } catch (e) {
        developer.log('Error al cargar imagen: $e', error: e);
        return _buildFallbackAvatar(isError: true);
      }
    } else {
      return _buildFallbackAvatar();
    }
  }

  Widget _buildFallbackAvatar({bool isError = false}) {
    return UserAvatar(
      imagePath: null,
      nombre: nombre.isEmpty ? (isError ? "!" : "U") : nombre,
      apellido: apellido.isEmpty ? (isError ? "!" : "S") : apellido,
      radius: 50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          GestureDetector(
            onTap: isLoading ? null : () => _seleccionarImagen(context),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                _buildImageDisplay(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            icon:
                isLoading
                    ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.photo_camera),
            label: Text(isLoading ? "Procesando..." : "Seleccionar imagen"),
            onPressed: isLoading ? null : () => _seleccionarImagen(context),
            style: TextButton.styleFrom(foregroundColor: Colors.teal),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'empleado_utils.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../widgets/user_avatar.dart';
import '../../services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/usuario_empleado_controller.dart';

class EmpleadoUsuarioForm extends StatefulWidget {
  final TextEditingController nombreController;
  final TextEditingController apellidoController;
  final TextEditingController apellidoMaternoController;
  final TextEditingController nombreUsuarioController;
  final TextEditingController contrasenaController;
  final TextEditingController correoController;
  final bool isEditando;
  final Function(String, String, String) onUserDataChanged;
  final bool verificandoUsuario;
  final bool nombreUsuarioExiste;
  final UsuarioEmpleadoController controller;
  final String? imagenPerfil;
  final Function(String?) onImagenPerfilChanged;

  const EmpleadoUsuarioForm({
    super.key,
    required this.nombreController,
    required this.apellidoController,
    required this.apellidoMaternoController,
    required this.nombreUsuarioController,
    required this.contrasenaController,
    required this.correoController,
    required this.isEditando,
    required this.onUserDataChanged,
    this.verificandoUsuario = false,
    this.nombreUsuarioExiste = false,
    required this.controller,
    this.imagenPerfil,
    required this.onImagenPerfilChanged,
  });

  @override
  State<EmpleadoUsuarioForm> createState() => _EmpleadoUsuarioFormState();
}

class _EmpleadoUsuarioFormState extends State<EmpleadoUsuarioForm> {
  bool _verificandoUsuario = false;
  bool _nombreUsuarioExiste = false;
  Timer? _debounceTimer;
  final ImageService _imageService = ImageService();

  // Banderas para controlar flujo de actualización y prevenir inversiones
  final bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();

    // Configurar listeners para propagar cambios al formulario de empleado
    // Evitamos añadir listeners directos para prevenir bucles de actualización
    // Usamos onChanged en los TextFormField en su lugar

    // Listener para verificar nombre de usuario
    if (!widget.isEditando) {
      widget.nombreUsuarioController.addListener(_verificarNombreUsuario);
    }

    // Sincronizar estado con props
    _verificandoUsuario = widget.verificandoUsuario;
    _nombreUsuarioExiste = widget.nombreUsuarioExiste;
  }

  void _onDataChanged() {
    // Solo propagar cambios si no estamos en una actualización interna
    // Esto previene bucles de actualización
    if (!_isInternalUpdate) {
      widget.onUserDataChanged(
        widget.nombreController.text,
        widget.apellidoController.text,
        widget.correoController.text,
      );
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      final imagen = await _imageService.pickImage(ImageSource.gallery);
      if (imagen != null) {
        widget.onImagenPerfilChanged(imagen.path);
      }
    } catch (e) {
      developer.log('Error al seleccionar imagen: $e', error: e);
      // Aquí se podría mostrar un SnackBar o algún mensaje al usuario
    }
  }

  void _verificarNombreUsuario() {
    final nombreUsuario = widget.nombreUsuarioController.text.trim();
    // Solo verificar si no estamos editando y hay un valor
    if (!widget.isEditando && nombreUsuario.isNotEmpty) {
      // Usar debounce para no hacer muchas peticiones mientras se escribe
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

      _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        if (mounted) {
          setState(() => _verificandoUsuario = true);
        }
        try {
          final existe = await widget.controller.nombreUsuarioExiste(
            nombreUsuario,
          );
          if (mounted) {
            setState(() {
              _nombreUsuarioExiste = existe;
              _verificandoUsuario = false;
            });
          }
        } catch (e) {
          developer.log('Error al verificar nombre de usuario: $e', error: e);
          if (mounted) {
            setState(() => _verificandoUsuario = false);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    // Ya no necesitamos eliminar listeners para nombre y apellido
    if (!widget.isEditando) {
      widget.nombreUsuarioController.removeListener(_verificarNombreUsuario);
    }
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(EmpleadoUsuarioForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar estado local si las props cambian
    if (oldWidget.verificandoUsuario != widget.verificandoUsuario ||
        oldWidget.nombreUsuarioExiste != widget.nombreUsuarioExiste) {
      setState(() {
        _verificandoUsuario = widget.verificandoUsuario;
        _nombreUsuarioExiste = widget.nombreUsuarioExiste;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Personal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Divider(),
        const SizedBox(height: 10),

        // Avatar del empleado (AÑADIDO)
        Center(
          child: Column(
            children: [
              UserAvatar(
                imagePath: widget.imagenPerfil,
                nombre:
                    widget.nombreController.text.isEmpty
                        ? "E"
                        : widget.nombreController.text,
                apellido:
                    widget.apellidoController.text.isEmpty
                        ? "P"
                        : widget.apellidoController.text,
                radius: 50,
                backgroundColor: Colors.teal.shade700,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.photo_camera),
                label: const Text("Foto de perfil"),
                onPressed: _seleccionarImagen,
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        // Primera fila - Nombre
        TextFormField(
          controller: widget.nombreController,
          decoration: EmpleadoStyles.getInputDecoration('Nombre', Icons.person),
          // Usar onChanged en lugar de controllers listeners para prevenir ciclos
          onChanged: (value) {
            _onDataChanged();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese el nombre';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Segunda fila - Apellidos (Paterno y Materno)
        Row(
          children: [
            // Apellido Paterno (1/2 del ancho)
            Expanded(
              child: TextFormField(
                controller: widget.apellidoController,
                decoration: EmpleadoStyles.getInputDecoration(
                  'Apellido Paterno',
                  Icons.person_outline,
                ),
                // Usar onChanged en lugar de controllers listeners para prevenir ciclos
                onChanged: (value) {
                  _onDataChanged();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el apellido paterno';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),

            // Apellido Materno (1/2 del ancho)
            Expanded(
              child: TextFormField(
                controller: widget.apellidoMaternoController,
                decoration: EmpleadoStyles.getInputDecoration(
                  'Apellido Materno',
                  Icons.person_outline,
                ),
                // El apellido materno suele ser opcional
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text(
          'Información de Acceso',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Divider(),
        const SizedBox(height: 10),

        // Usuario y Contraseña
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.nombreUsuarioController,
                decoration: InputDecoration(
                  labelText: 'Nombre de Usuario',
                  prefixIcon: const Icon(Icons.account_circle),
                  suffixIcon:
                      _verificandoUsuario
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : _nombreUsuarioExiste
                          ? const Icon(Icons.error, color: Colors.red)
                          : widget.nombreUsuarioController.text.isNotEmpty &&
                              !widget.isEditando
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                  errorText:
                      _nombreUsuarioExiste
                          ? 'Este nombre de usuario ya está en uso'
                          : null,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el nombre de usuario';
                  }
                  if (_nombreUsuarioExiste) {
                    return 'Este nombre de usuario ya está en uso';
                  }
                  return null;
                },
                enabled: !widget.isEditando,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: widget.contrasenaController,
                decoration: EmpleadoStyles.getInputDecoration(
                  widget.isEditando
                      ? 'Nueva Contraseña (opcional)'
                      : 'Contraseña',
                  Icons.lock,
                ),
                obscureText: true,
                validator: (value) {
                  if (!widget.isEditando && (value == null || value.isEmpty)) {
                    return 'Ingrese la contraseña';
                  } else if (value != null &&
                      value.isNotEmpty &&
                      value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Correo
        TextFormField(
          controller: widget.correoController,
          decoration: EmpleadoStyles.getInputDecoration(
            'Correo personal',
            Icons.email,
          ),
          // Usar onChanged en lugar de controllers listeners para prevenir ciclos
          onChanged: (value) {
            _onDataChanged();
          },
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese el correo personal';
            } else if (!EmpleadoValidators.isValidEmail(value)) {
              return 'Correo electrónico inválido';
            }
            return null;
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

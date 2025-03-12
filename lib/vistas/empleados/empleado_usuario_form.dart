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
  bool _mostrarContrasena = false;
  Timer? _debounceTimer;
  final ImageService _imageService = ImageService();
  final bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();

    // Listener para verificar nombre de usuario
    if (!widget.isEditando) {
      widget.nombreUsuarioController.addListener(_verificarNombreUsuario);
    }

    // Sincronizar estado con props
    _verificandoUsuario = widget.verificandoUsuario;
    _nombreUsuarioExiste = widget.nombreUsuarioExiste;

    // Asegurar que la contraseña inicial esté limpia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _limpiarContrasena(true);
    });
  }

  void _onDataChanged() {
    // Solo propagar cambios si no estamos en una actualización interna
    if (!_isInternalUpdate) {
      widget.onUserDataChanged(
        widget.nombreController.text,
        widget.apellidoController.text,
        widget.correoController.text,
      );
    }
  }

  // MEJORADO: Método para limpiar espacios en la contraseña
  void _limpiarContrasena([bool forzar = false]) {
    final textoActual = widget.contrasenaController.text;
    final textoLimpio = textoActual.trim();

    // Solo actualizar si hay diferencia o si forzamos la limpieza
    if (forzar || textoLimpio != textoActual) {
      // Guardar la posición actual del cursor
      final cursorPos = widget.contrasenaController.selection.baseOffset;

      // Actualizar el texto usando el método value que notificará automáticamente
      widget.contrasenaController.value = TextEditingValue(
        text: textoLimpio,
        selection: TextSelection.fromPosition(
          TextPosition(
            offset: min(
              max(0, cursorPos - (textoActual.length - textoLimpio.length)),
              textoLimpio.length,
            ),
          ),
        ),
      );

      developer.log(
        'Contraseña limpiada: "$textoLimpio" (${textoLimpio.length} caracteres)',
      );
    }
  }

  int max(int a, int b) => a > b ? a : b;
  int min(int a, int b) => a < b ? a : b;

  Future<void> _seleccionarImagen() async {
    try {
      final imagen = await _imageService.pickImage(ImageSource.gallery);
      if (imagen != null) {
        widget.onImagenPerfilChanged(imagen.path);
      }
    } catch (e) {
      developer.log('Error al seleccionar imagen: $e', error: e);
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

        // Avatar del empleado
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

        // Segunda fila - Apellidos
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
                decoration: InputDecoration(
                  labelText:
                      widget.isEditando
                          ? 'Nueva Contraseña (opcional)'
                          : 'Contraseña (min. 8 caracteres)',
                  helperText: !widget.isEditando ? 'Mínimo 8 caracteres' : null,
                  prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarContrasena
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.teal,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarContrasena = !_mostrarContrasena;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
                obscureText: !_mostrarContrasena,
                // Mejorado: manejo de cambios y limpieza
                onChanged: (value) {
                  developer.log('Longitud antes de limpiar: ${value.length}');
                },
                onTap: () {
                  // Al tocar el campo, limpiar espacios
                  _limpiarContrasena();
                },
                onEditingComplete: () {
                  // Al completar edición, limpiar espacios
                  _limpiarContrasena();
                  FocusScope.of(context).nextFocus();
                },
                onFieldSubmitted: (_) => _limpiarContrasena(),
                validator: (value) {
                  // Limpiar espacios durante validación
                  _limpiarContrasena(true);

                  final cleanValue = widget.contrasenaController.text;
                  if (!widget.isEditando && cleanValue.isEmpty) {
                    return 'Ingrese la contraseña';
                  } else if (cleanValue.isNotEmpty && cleanValue.length < 8) {
                    developer.log(
                      'Validación falló: longitud ${cleanValue.length}',
                    );
                    return 'La contraseña debe tener 8+ caracteres (${cleanValue.length})';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        // NUEVO: Panel de información sobre la contraseña
        if (!widget.isEditando || widget.contrasenaController.text.isNotEmpty)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            color:
                widget.contrasenaController.text.trim().length >= 8
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.contrasenaController.text.trim().length >= 8
                            ? Icons.check_circle
                            : Icons.warning,
                        color:
                            widget.contrasenaController.text.trim().length >= 8
                                ? Colors.green
                                : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Longitud: ${widget.contrasenaController.text.trim().length} caracteres',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.contrasenaController.text.trim().length >=
                                      8
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  if (widget.contrasenaController.text.trim().length < 8)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 20.0),
                      child: Text(
                        'Necesita ${8 - widget.contrasenaController.text.trim().length} caracteres más',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Correo
        TextFormField(
          controller: widget.correoController,
          decoration: EmpleadoStyles.getInputDecoration(
            'Correo personal',
            Icons.email,
          ),
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

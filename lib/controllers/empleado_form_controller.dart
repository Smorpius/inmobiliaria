import 'dart:io';
import 'dart:async';
import '../models/usuario.dart';
import '../models/empleado.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/empleado_form_state.dart';
import '../controllers/usuario_empleado_controller.dart';

class EmpleadoFormController {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();
  final TextEditingController apellidoMaternoController =
      TextEditingController();
  final TextEditingController nombreUsuarioController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController claveSistemaController = TextEditingController();
  final TextEditingController cargoController = TextEditingController();
  final TextEditingController sueldoController = TextEditingController();

  final UsuarioEmpleadoController _usuarioEmpleadoController;
  final EmpleadoFormState formState;

  Timer? _debounceTimer;
  bool verificandoUsuario = false;
  bool nombreUsuarioExiste = false;

  EmpleadoFormController({
    required UsuarioEmpleadoController usuarioEmpleadoController,
    required this.formState,
  }) : _usuarioEmpleadoController = usuarioEmpleadoController {
    // Listener para el nombre de usuario
    if (!formState.isEditando) {
      nombreUsuarioController.addListener(_verificarNombreUsuario);
    }
  }

  void _verificarNombreUsuario() {
    final nombreUsuario = nombreUsuarioController.text.trim();
    if (!formState.isEditando && nombreUsuario.isNotEmpty) {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        verificandoUsuario = true;
        try {
          final existe = await _usuarioEmpleadoController.nombreUsuarioExiste(
            nombreUsuario,
          );
          nombreUsuarioExiste = existe;
        } catch (e) {
          developer.log('Error al verificar nombre de usuario: $e', error: e);
        } finally {
          verificandoUsuario = false;
        }
      });
    }
  }

  bool validar() {
    if (nombreController.text.isEmpty ||
        apellidoController.text.isEmpty ||
        nombreUsuarioController.text.isEmpty ||
        correoController.text.isEmpty ||
        telefonoController.text.isEmpty ||
        direccionController.text.isEmpty ||
        claveSistemaController.text.isEmpty ||
        cargoController.text.isEmpty ||
        sueldoController.text.isEmpty) {
      return false;
    }
    if (nombreUsuarioExiste) return false;
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(correoController.text)) {
      return false;
    }
    if (double.tryParse(sueldoController.text) == null) {
      return false;
    }
    if (formState.fechaContratacion.isAfter(DateTime.now())) {
      return false;
    }
    return true;
  }

  Usuario crearUsuario() {
    return Usuario(
      nombre: nombreController.text,
      apellido: apellidoController.text,
      nombreUsuario: nombreUsuarioController.text,
      contrasena: contrasenaController.text,
      correo: correoController.text,
      imagenPerfil: formState.imagenPerfilPath,
      idEstado: 1,
    );
  }

  Empleado crearEmpleado() {
    return Empleado(
      claveSistema: claveSistemaController.text,
      nombre: nombreController.text,
      apellidoPaterno: apellidoController.text,
      apellidoMaterno:
          apellidoMaternoController.text.isNotEmpty
              ? apellidoMaternoController.text
              : null,
      telefono: telefonoController.text,
      correo: correoController.text,
      direccion: direccionController.text,
      cargo: cargoController.text,
      sueldoActual: double.tryParse(sueldoController.text) ?? 0.0,
      fechaContratacion: formState.fechaContratacion,
      imagenEmpleado: formState.imagenEmpleadoPath,
      idEstado: 1,
    );
  }

  void setImagenPerfil(File? file, String? path) {
    formState.imagenPerfilFile = file;
    formState.imagenPerfilPath = path;
  }

  void setImagenEmpleado(File? file, String? path) {
    formState.imagenEmpleadoFile = file;
    formState.imagenEmpleadoPath = path;
  }

  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    apellidoMaternoController.dispose();
    nombreUsuarioController.dispose();
    contrasenaController.dispose();
    correoController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    claveSistemaController.dispose();
    cargoController.dispose();
    sueldoController.dispose();
    _debounceTimer?.cancel();
    if (!formState.isEditando) {
      nombreUsuarioController.removeListener(_verificarNombreUsuario);
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';

class EmpleadoFormState {
  // Controladores existentes
  final usuarioNombreController = TextEditingController();
  final usuarioApellidoController = TextEditingController();
  final apellidoMaternoController = TextEditingController();
  final usuarioNombreUsuarioController = TextEditingController();
  final usuarioContrasenaController = TextEditingController();
  final usuarioCorreoController = TextEditingController();
  final claveSistemaController = TextEditingController();
  final telefonoController = TextEditingController();
  final direccionController = TextEditingController();
  final cargoController = TextEditingController();
  final sueldoController = TextEditingController();

  // Campos para imágenes
  DateTime fechaContratacion = DateTime.now();
  File? imagenPerfilFile;
  String? imagenPerfilPath;
  File? imagenEmpleadoFile;
  String? imagenEmpleadoPath;

  // Otros estados
  bool isLoading = false;
  bool isEditando = false;
  bool verificandoUsuario = false;
  bool nombreUsuarioExiste = false;

  // IDs para edición
  int? idUsuario;
  int? idEmpleado;

  // Limpieza de recursos
  void dispose() {
    usuarioNombreController.dispose();
    usuarioApellidoController.dispose();
    apellidoMaternoController.dispose();
    usuarioNombreUsuarioController.dispose();
    usuarioContrasenaController.dispose();
    usuarioCorreoController.dispose();
    claveSistemaController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    cargoController.dispose();
    sueldoController.dispose();
  }
}

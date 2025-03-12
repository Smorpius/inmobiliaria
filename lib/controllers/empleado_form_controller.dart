import 'dart:io';
import 'dart:async';
import '../models/usuario.dart';
import '../models/empleado.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/empleado_form_state.dart';
import '../controllers/usuario_empleado_controller.dart';

class EmpleadoFormController {
  // Controladores de texto
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

  int? _idUsuarioActual;
  String? _nombreUsuarioOriginal;

  Timer? _debounceTimer;
  bool verificandoUsuario = false;
  bool nombreUsuarioExiste = false;

  // Flag para bloquear edición de nombre de usuario cuando se está editando
  bool nombreUsuarioEditableBloqueado = false;

  // Funciones auxiliares para cálculos
  int max(int a, int b) => a > b ? a : b;
  int min(int a, int b) => a < b ? a : b;

  EmpleadoFormController({
    required UsuarioEmpleadoController usuarioEmpleadoController,
    required this.formState,
  }) : _usuarioEmpleadoController = usuarioEmpleadoController {
    nombreUsuarioController.addListener(_verificarNombreUsuario);
  }

  void _verificarNombreUsuario() {
    final nombreUsuario = nombreUsuarioController.text.trim();

    // Mejorado: Evitar verificación si estamos editando y el nombre no cambió
    if (formState.isEditando && nombreUsuario == _nombreUsuarioOriginal) {
      nombreUsuarioExiste = false;
      return;
    }

    if (nombreUsuario.isNotEmpty) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        verificandoUsuario = true;
        try {
          final existe =
              formState.isEditando && _idUsuarioActual != null
                  ? await _usuarioEmpleadoController
                      .nombreUsuarioExisteExcluyendo(
                        nombreUsuario,
                        _idUsuarioActual!,
                      )
                  : await _usuarioEmpleadoController.nombreUsuarioExiste(
                    nombreUsuario,
                  );
          nombreUsuarioExiste = existe;
          developer.log('Nombre usuario "$nombreUsuario" existe: $existe');
        } catch (e) {
          developer.log('Error verificando nombre de usuario: $e', error: e);
        } finally {
          verificandoUsuario = false;
        }
      });
    }
  }

  void cargarDatosEmpleado(Usuario usuario, Empleado empleado) {
    _idUsuarioActual = usuario.id;
    _nombreUsuarioOriginal = usuario.nombreUsuario;
    formState.isEditando = true;

    // Bloquear la edición del nombre de usuario
    nombreUsuarioEditableBloqueado = true;

    // Cargar datos de usuario (campos no nulos)
    nombreController.text = usuario.nombre;
    apellidoController.text = usuario.apellido;
    nombreUsuarioController.text = usuario.nombreUsuario;
    contrasenaController.text = '';
    correoController.text = usuario.correo ?? '';

    // Cargar datos de empleado (campos no nulos)
    claveSistemaController.text = empleado.claveSistema;
    apellidoMaternoController.text = empleado.apellidoMaterno ?? '';
    telefonoController.text = empleado.telefono;
    direccionController.text = empleado.direccion;
    cargoController.text = empleado.cargo;
    sueldoController.text = empleado.sueldoActual.toString();

    formState.fechaContratacion = empleado.fechaContratacion;

    // Manejo seguro de valores que pueden ser nulos
    formState.imagenEmpleadoPath = empleado.imagenEmpleado ?? '';
    formState.imagenPerfilPath = usuario.imagenPerfil ?? '';
  }

  void prepararNuevoEmpleado() {
    formState.isEditando = false;
    _idUsuarioActual = null;
    _nombreUsuarioOriginal = null;
    nombreUsuarioEditableBloqueado = false;

    nombreController.clear();
    apellidoController.clear();
    apellidoMaternoController.clear();
    nombreUsuarioController.clear();
    contrasenaController.clear();
    correoController.clear();
    telefonoController.clear();
    direccionController.clear();
    claveSistemaController.clear();
    cargoController.clear();
    sueldoController.clear();

    formState.fechaContratacion = DateTime.now();
    formState.imagenEmpleadoPath = '';
    formState.imagenPerfilPath = '';
    formState.imagenEmpleadoFile = null;
    formState.imagenPerfilFile = null;
  }

  void limpiarContrasenaParaValidacion() {
    final textoOriginal = contrasenaController.text;
    final textoLimpio = textoOriginal.trim();

    if (textoOriginal != textoLimpio) {
      final cursorPos = contrasenaController.selection.start;
      contrasenaController.text = textoLimpio;
      if (cursorPos > -1) {
        final nuevaPosicion = max(
          0,
          cursorPos - (textoOriginal.length - textoLimpio.length),
        );
        contrasenaController.selection = TextSelection.fromPosition(
          TextPosition(offset: min(nuevaPosicion, textoLimpio.length)),
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final longitud = textoLimpio.length;
      developer.log(
        'Contraseña limpiada para validación: "$textoLimpio" (longitud=$longitud)',
      );
    });
  }

  bool validar() {
    limpiarContrasenaParaValidacion();

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

    if (nombreUsuarioExiste) {
      return false;
    }

    if (!formState.isEditando && contrasenaController.text.isEmpty) {
      return false;
    }

    if (!formState.isEditando && contrasenaController.text.length < 8) {
      final longitud = contrasenaController.text.length;
      final valor = contrasenaController.text;
      developer.log(
        'Validación de contraseña falló: longitud=$longitud, valor="$valor"',
      );
      return false;
    }

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

  String obtenerTextoBoton() {
    return formState.isEditando ? 'Actualizar Empleado' : 'Agregar Empleado';
  }

  bool validarContrasena() {
    // Capturar directamente el texto del controlador sin llamar a limpiarContrasenaParaValidacion()
    final textoOriginal = contrasenaController.text;
    final textoContrasena = textoOriginal.trim();

    developer.log('Validando contraseña original: "$textoOriginal"');
    developer.log(
      'Validando contraseña limpia: "$textoContrasena", longitud=${textoContrasena.length}',
    );

    if (formState.isEditando && textoContrasena.isEmpty) {
      return true; // En edición, contraseña vacía es válida (no se cambia)
    }

    final esValida = textoContrasena.length >= 8;
    if (!esValida) {
      developer.log('Contraseña inválida: longitud menor a 8 caracteres');
    }
    return esValida;
  }

  Usuario crearUsuario() {
    limpiarContrasenaParaValidacion();

    return Usuario(
      id: formState.isEditando ? _idUsuarioActual : null,
      nombre: nombreController.text,
      apellido: apellidoController.text,
      nombreUsuario: nombreUsuarioController.text,
      contrasena:
          contrasenaController.text.isNotEmpty ? contrasenaController.text : '',
      correo: correoController.text,
      imagenPerfil: formState.imagenPerfilPath ?? '',
      idEstado: 1,
    );
  }

  Empleado crearEmpleado() {
    return Empleado(
      id: formState.isEditando ? _idUsuarioActual : null,
      idUsuario: _idUsuarioActual,
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
      imagenEmpleado: formState.imagenEmpleadoPath ?? '',
      idEstado: 1,
    );
  }

  // Método actualizado para guardar empleado con el tercer parámetro (contraseña)
  Future<void> guardarEmpleado() async {
    if (!validar()) return;

    try {
      if (formState.isEditando && _idUsuarioActual != null) {
        // Actualizar empleado existente
        await _usuarioEmpleadoController.actualizarEmpleado(
          _idUsuarioActual!,
          _idUsuarioActual!,
          crearUsuario(),
          crearEmpleado(),
        );
      } else {
        // Crear nuevo empleado
        await _usuarioEmpleadoController.crearUsuarioEmpleado(
          crearUsuario(),
          crearEmpleado(),
          contrasenaController.text, // Aseguramos pasar la contraseña
        );
      }
      // Manejo de éxito
    } catch (e) {
      developer.log('Error al guardar empleado: $e', error: e);
      // Manejo de error
    }
  }

  void setImagenPerfil(File? file, String? path) {
    formState.imagenPerfilFile = file;
    formState.imagenPerfilPath = path ?? '';
  }

  void setImagenEmpleado(File? file, String? path) {
    formState.imagenEmpleadoFile = file;
    formState.imagenEmpleadoPath = path ?? '';
  }

  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    apellidoMaternoController.dispose();
    nombreUsuarioController.removeListener(_verificarNombreUsuario);
    nombreUsuarioController.dispose();
    contrasenaController.dispose();
    correoController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    claveSistemaController.dispose();
    cargoController.dispose();
    sueldoController.dispose();
    _debounceTimer?.cancel();
  }
}

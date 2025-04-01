import 'dart:io';
import '../utils/applogger.dart';
import 'package:flutter/material.dart';

/// Clase para gestionar el estado del formulario de empleados
///
/// Mantiene todos los controladores y estados relacionados con
/// el formulario de creación/edición de empleados.
class EmpleadoFormState {
  // Controladores de texto para el formulario
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

  // Estados del formulario
  bool isLoading = false;
  bool isEditando = false;
  bool verificandoUsuario = false;
  bool nombreUsuarioExiste = false;

  // IDs para edición
  int? idUsuario;
  int? idEmpleado;

  // Clave global para el formulario
  final formKey = GlobalKey<FormState>();

  /// Limpia todos los campos del formulario
  void limpiarCampos() {
    try {
      // Limpiar controladores
      usuarioNombreController.clear();
      usuarioApellidoController.clear();
      apellidoMaternoController.clear();
      usuarioNombreUsuarioController.clear();
      usuarioContrasenaController.clear();
      usuarioCorreoController.clear();
      claveSistemaController.clear();
      telefonoController.clear();
      direccionController.clear();
      cargoController.clear();
      sueldoController.clear();

      // Reiniciar campos de imágenes y fechas
      fechaContratacion = DateTime.now();
      imagenPerfilFile = null;
      imagenPerfilPath = null;
      imagenEmpleadoFile = null;
      imagenEmpleadoPath = null;

      // Reiniciar estados
      isEditando = false;
      verificandoUsuario = false;
      nombreUsuarioExiste = false;
      idUsuario = null;
      idEmpleado = null;

      AppLogger.info(
        'Se limpiaron todos los campos del formulario de empleado',
      );
    } catch (e) {
      AppLogger.error(
        'Error al limpiar campos del formulario',
        e,
        StackTrace.current,
      );
    }
  }

  /// Inicializa el estado para edición con datos existentes
  void setDatosEdicion({
    required String nombre,
    required String apellido,
    required String nombreUsuario,
    required String correo,
    required String clave,
    required String telefono,
    required String direccion,
    required String cargo,
    required double sueldo,
    String? apellidoMaterno,
    DateTime? fechaContratacion,
    String? imagenPerfil,
    String? imagenEmpleado,
    required int idUsuario,
    required int idEmpleado,
  }) {
    try {
      // Establecer texto en controladores
      usuarioNombreController.text = nombre;
      usuarioApellidoController.text = apellido;
      apellidoMaternoController.text = apellidoMaterno ?? '';
      usuarioNombreUsuarioController.text = nombreUsuario;
      usuarioCorreoController.text = correo;
      claveSistemaController.text = clave;
      telefonoController.text = telefono;
      direccionController.text = direccion;
      cargoController.text = cargo;
      sueldoController.text = sueldo.toString();

      // Establecer otras propiedades
      this.fechaContratacion = fechaContratacion ?? DateTime.now();
      imagenPerfilPath = imagenPerfil;
      imagenEmpleadoPath = imagenEmpleado;

      // Establecer IDs y estado
      this.idUsuario = idUsuario;
      this.idEmpleado = idEmpleado;
      isEditando = true;

      AppLogger.info(
        'Datos de empleado ID:$idEmpleado cargados en el formulario',
      );
    } catch (e) {
      AppLogger.error(
        'Error al cargar datos para edición',
        e,
        StackTrace.current,
      );
    }
  }

  /// Valida el formulario de empleado
  Map<String, String> validarFormulario() {
    final errores = <String, String>{};

    // Validar campos obligatorios
    if (usuarioNombreController.text.isEmpty) {
      errores['nombre'] = 'El nombre es obligatorio';
    }

    if (usuarioApellidoController.text.isEmpty) {
      errores['apellido'] = 'El apellido es obligatorio';
    }

    if (usuarioNombreUsuarioController.text.isEmpty) {
      errores['nombreUsuario'] = 'El nombre de usuario es obligatorio';
    }

    if (!isEditando && usuarioContrasenaController.text.isEmpty) {
      errores['contrasena'] =
          'La contraseña es obligatoria para nuevos empleados';
    }

    if (!isEditando && usuarioContrasenaController.text.length < 8) {
      errores['contrasenaLongitud'] =
          'La contraseña debe tener al menos 8 caracteres';
    }

    if (usuarioCorreoController.text.isEmpty) {
      errores['correo'] = 'El correo es obligatorio';
    } else if (!_validarFormatoCorreo(usuarioCorreoController.text)) {
      errores['correoFormato'] = 'El formato de correo no es válido';
    }

    if (telefonoController.text.isEmpty) {
      errores['telefono'] = 'El teléfono es obligatorio';
    }

    if (direccionController.text.isEmpty) {
      errores['direccion'] = 'La dirección es obligatoria';
    }

    if (claveSistemaController.text.isEmpty) {
      errores['claveSistema'] = 'La clave de sistema es obligatoria';
    }

    if (cargoController.text.isEmpty) {
      errores['cargo'] = 'El cargo es obligatorio';
    }

    if (sueldoController.text.isEmpty) {
      errores['sueldo'] = 'El sueldo es obligatorio';
    } else {
      try {
        final sueldo = double.parse(sueldoController.text);
        if (sueldo <= 0) {
          errores['sueldoValor'] = 'El sueldo debe ser mayor a 0';
        }
      } catch (e) {
        errores['sueldoFormato'] = 'El sueldo debe ser un número válido';
      }
    }

    if (nombreUsuarioExiste) {
      errores['nombreUsuarioDuplicado'] =
          'Este nombre de usuario ya está en uso';
    }

    return errores;
  }

  /// Valida el formato del correo electrónico
  bool _validarFormatoCorreo(String correo) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(correo);
  }

  /// Limpia los recursos cuando ya no son necesarios
  void dispose() {
    try {
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

      AppLogger.info('Recursos de EmpleadoFormState liberados correctamente');
    } catch (e) {
      AppLogger.error(
        'Error al liberar recursos de EmpleadoFormState',
        e,
        StackTrace.current,
      );
    }
  }
}

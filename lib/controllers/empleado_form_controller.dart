import 'dart:io';
import 'dart:async';
import '../models/usuario.dart';
import '../models/empleado.dart';
import '../utils/applogger.dart';
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

  // Control de estado para evitar verificaciones redundantes
  String? _ultimoNombreUsuarioVerificado;

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
    AppLogger.info('EmpleadoFormController inicializado');
  }

  void _verificarNombreUsuario() {
    final nombreUsuario = nombreUsuarioController.text.trim();

    // Evitar verificaciones repetidas del mismo texto
    if (_ultimoNombreUsuarioVerificado == nombreUsuario) return;

    // Mejorado: Evitar verificación si estamos editando y el nombre no cambió
    if (formState.isEditando && nombreUsuario == _nombreUsuarioOriginal) {
      nombreUsuarioExiste = false;
      return;
    }

    if (nombreUsuario.isNotEmpty) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        // Solo verificar si no estamos ya verificando
        if (verificandoUsuario) return;

        verificandoUsuario = true;
        try {
          AppLogger.info(
            'Verificando disponibilidad de nombre de usuario: "$nombreUsuario"',
          );
          _ultimoNombreUsuarioVerificado = nombreUsuario;

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
          AppLogger.info('Nombre usuario "$nombreUsuario" existe: $existe');
        } catch (e) {
          AppLogger.error(
            'Error verificando nombre de usuario',
            e,
            StackTrace.current,
          );
        } finally {
          verificandoUsuario = false;
        }
      });
    }
  }

  void cargarDatosEmpleado(Usuario usuario, Empleado empleado) {
    try {
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

      AppLogger.info(
        'Datos de empleado ID: ${empleado.id} cargados correctamente',
      );
    } catch (e) {
      AppLogger.error(
        'Error al cargar datos de empleado',
        e,
        StackTrace.current,
      );
    }
  }

  void prepararNuevoEmpleado() {
    try {
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

      AppLogger.info('Formulario preparado para nuevo empleado');
    } catch (e) {
      AppLogger.error(
        'Error al preparar formulario de nuevo empleado',
        e,
        StackTrace.current,
      );
    }
  }

  void limpiarContrasenaParaValidacion() {
    try {
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
    } catch (e) {
      AppLogger.error(
        'Error al limpiar contraseña para validación',
        e,
        StackTrace.current,
      );
    }
  }

  bool validar() {
    try {
      limpiarContrasenaParaValidacion();

      // Validar campos obligatorios
      if (nombreController.text.isEmpty ||
          apellidoController.text.isEmpty ||
          nombreUsuarioController.text.isEmpty ||
          correoController.text.isEmpty ||
          telefonoController.text.isEmpty ||
          direccionController.text.isEmpty ||
          claveSistemaController.text.isEmpty ||
          cargoController.text.isEmpty ||
          sueldoController.text.isEmpty) {
        AppLogger.warning('Validación fallida: Campos obligatorios vacíos');
        return false;
      }

      // Validar nombre de usuario único
      if (nombreUsuarioExiste) {
        AppLogger.warning('Validación fallida: Nombre de usuario duplicado');
        return false;
      }

      // Validar contraseña en modo de creación
      if (!formState.isEditando && contrasenaController.text.isEmpty) {
        AppLogger.warning(
          'Validación fallida: Contraseña vacía en nuevo empleado',
        );
        return false;
      }

      if (!formState.isEditando && contrasenaController.text.length < 8) {
        AppLogger.warning(
          'Validación fallida: Contraseña demasiado corta (min. 8 caracteres)',
        );
        return false;
      }

      // Validar formato de correo electrónico
      if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(correoController.text)) {
        AppLogger.warning(
          'Validación fallida: Formato de correo electrónico inválido',
        );
        return false;
      }

      // Validar sueldo como número
      if (double.tryParse(sueldoController.text) == null) {
        AppLogger.warning('Validación fallida: Sueldo no es un número válido');
        return false;
      }

      // Validar fecha de contratación
      if (formState.fechaContratacion.isAfter(DateTime.now())) {
        AppLogger.warning(
          'Validación fallida: Fecha de contratación en el futuro',
        );
        return false;
      }

      AppLogger.info('Validación de formulario exitosa');
      return true;
    } catch (e) {
      AppLogger.error(
        'Error en validación de formulario',
        e,
        StackTrace.current,
      );
      return false;
    }
  }

  String obtenerTextoBoton() {
    return formState.isEditando ? 'Actualizar Empleado' : 'Agregar Empleado';
  }

  bool validarContrasena() {
    try {
      final textoOriginal = contrasenaController.text;
      final textoContrasena = textoOriginal.trim();

      // En edición, contraseña vacía es válida (no se cambia)
      if (formState.isEditando && textoContrasena.isEmpty) {
        return true;
      }

      final esValida = textoContrasena.length >= 8;
      if (!esValida) {
        AppLogger.debug('Contraseña inválida: longitud menor a 8 caracteres');
      }
      return esValida;
    } catch (e) {
      AppLogger.error('Error validando contraseña', e, StackTrace.current);
      return false;
    }
  }

  Usuario crearUsuario() {
    try {
      limpiarContrasenaParaValidacion();

      return Usuario(
        id: formState.isEditando ? _idUsuarioActual : null,
        nombre: nombreController.text,
        apellido: apellidoController.text,
        nombreUsuario: nombreUsuarioController.text,
        contrasena:
            contrasenaController.text.isNotEmpty
                ? contrasenaController.text
                : '',
        correo: correoController.text,
        imagenPerfil: formState.imagenPerfilPath ?? '',
        idEstado: 1,
      );
    } catch (e) {
      AppLogger.error('Error al crear objeto Usuario', e, StackTrace.current);
      // Retornar un objeto mínimo para evitar null exceptions
      return Usuario(
        nombre: '',
        apellido: '',
        nombreUsuario: '',
        contrasena: '',
        idEstado: 1,
      );
    }
  }

  Empleado crearEmpleado() {
    try {
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
    } catch (e) {
      AppLogger.error('Error al crear objeto Empleado', e, StackTrace.current);
      // Retornar un objeto mínimo para evitar null exceptions
      return Empleado(
        nombre: '',
        apellidoPaterno: '',
        telefono: '',
        direccion: '',
        cargo: '',
        sueldoActual: 0,
        fechaContratacion: DateTime.now(),
        idEstado: 1,
        correo: '',
        claveSistema: '',
      );
    }
  }

  Future<bool> guardarEmpleado() async {
    if (!validar()) {
      AppLogger.warning('Validación fallida, no se puede guardar el empleado');
      return false;
    }

    try {
      AppLogger.info(
        'Iniciando proceso de ${formState.isEditando ? "actualización" : "creación"} de empleado',
      );

      if (formState.isEditando && _idUsuarioActual != null) {
        // Actualizar empleado existente
        await _usuarioEmpleadoController.actualizarEmpleado(
          _idUsuarioActual!,
          _idUsuarioActual!,
          crearUsuario(),
          crearEmpleado(),
        );
        AppLogger.info(
          'Empleado actualizado exitosamente (ID: $_idUsuarioActual)',
        );
      } else {
        // Crear nuevo empleado
        final id = await _usuarioEmpleadoController.crearUsuarioEmpleado(
          crearUsuario(),
          crearEmpleado(),
          contrasenaController.text,
        );
        AppLogger.info('Nuevo empleado creado exitosamente (ID: $id)');
      }
      return true;
    } catch (e) {
      AppLogger.error('Error al guardar empleado', e, StackTrace.current);
      return false;
    }
  }

  void setImagenPerfil(File? file, String? path) {
    try {
      formState.imagenPerfilFile = file;
      formState.imagenPerfilPath = path ?? '';
      AppLogger.debug('Imagen de perfil actualizada: ${path ?? "ninguna"}');
    } catch (e) {
      AppLogger.error(
        'Error al establecer imagen de perfil',
        e,
        StackTrace.current,
      );
    }
  }

  void setImagenEmpleado(File? file, String? path) {
    try {
      formState.imagenEmpleadoFile = file;
      formState.imagenEmpleadoPath = path ?? '';
      AppLogger.debug('Imagen de empleado actualizada: ${path ?? "ninguna"}');
    } catch (e) {
      AppLogger.error(
        'Error al establecer imagen de empleado',
        e,
        StackTrace.current,
      );
    }
  }

  void dispose() {
    try {
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
      AppLogger.info(
        'EmpleadoFormController: recursos liberados correctamente',
      );
    } catch (e) {
      AppLogger.error(
        'Error al liberar recursos del controlador',
        e,
        StackTrace.current,
      );
    }
  }
}

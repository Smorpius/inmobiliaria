import 'dart:async';
import '../models/usuario.dart';
import '../models/empleado.dart';
import 'dart:developer' as developer;
import '../models/usuario_empleado.dart';
import '../services/usuario_empleado_service.dart';
import 'package:inmobiliaria/services/usuario_service.dart';

class EmpleadoController {
  final UsuarioEmpleadoService _service;
  final UsuarioService _usuarioService;

  // Stream for reactive management of employee data
  final _empleadosController =
      StreamController<List<UsuarioEmpleado>>.broadcast();

  // Expose the stream for external observers
  Stream<List<UsuarioEmpleado>> get empleados => _empleadosController.stream;

  bool _isInitialized = false;

  // Constructor
  EmpleadoController(this._service, this._usuarioService) {
    _empleadosController.sink.add([]);
  }

  // Initialization state
  bool get isInitialized => _isInitialized;

  // Optimized initialization
  Future<void> inicializar() async {
    if (_isInitialized) return;
    try {
      await cargarEmpleados(forceRefresh: true);
      _isInitialized = true;
    } catch (e) {
      developer.log(
        'Error al inicializar el controlador de empleados: $e',
        error: e,
      );
      rethrow;
    }
  }

  // Load employees with refresh control
  Future<void> cargarEmpleados({bool forceRefresh = false}) async {
    try {
      developer.log('Iniciando carga de empleados');
      final empleados = await _service.obtenerEmpleados();
      _empleadosController.sink.add(List.from(empleados));
      developer.log('Empleados cargados: ${empleados.length}');
      return;
    } catch (e) {
      developer.log('Error al cargar empleados: $e', error: e);
      _empleadosController.sink.addError("Error al cargar empleados: $e");
      throw Exception("Error al cargar empleados: $e");
    }
  }

  // NUEVO MÉTODO: obtenerEmpleados - Obtiene la lista completa de empleados
  Future<List<Empleado>> obtenerEmpleados() async {
    try {
      developer.log('Obteniendo lista de empleados');
      final usuariosEmpleados = await _service.obtenerEmpleados();
      // Convertir la lista de UsuarioEmpleado a lista de Empleado
      final listaEmpleados =
          usuariosEmpleados
              .map((usuarioEmpleado) => usuarioEmpleado.empleado)
              .toList();
      return listaEmpleados;
    } catch (e) {
      developer.log('Error al obtener lista de empleados: $e', error: e);
      throw Exception("Error al obtener lista de empleados: $e");
    }
  }

  // Validate if username exists, excluding optionally the current id
  Future<bool> existeNombreUsuario(
    String nombreUsuario, {
    int? idUsuarioActual,
  }) async {
    try {
      developer.log(
        'Verificando si existe el nombre de usuario: $nombreUsuario',
      );
      final existe = await _usuarioService.existeNombreUsuario(
        nombreUsuario,
        idExcluido: idUsuarioActual,
      );
      developer.log('Nombre usuario "$nombreUsuario" existe: $existe');
      return existe;
    } catch (e) {
      developer.log('Error al verificar nombre de usuario: $e', error: e);
      throw Exception('Error al verificar nombre de usuario: $e');
    }
  }

  // MÉTODO CORREGIDO: Create an employee with improved validation and password parameter
  Future<int> crearEmpleado(
    Usuario usuario,
    Empleado empleado,
    String contrasena,
  ) async {
    try {
      // If in creation mode, check username existence
      if (usuario.id == null) {
        final existe = await existeNombreUsuario(usuario.nombreUsuario);
        if (existe) {
          throw Exception(
            "El nombre de usuario '${usuario.nombreUsuario}' ya existe. Elige otro.",
          );
        }
      }
      final id = await _service.crearUsuarioEmpleado(
        usuario,
        empleado,
        contrasena,
      );
      await cargarEmpleados(forceRefresh: true);
      return id;
    } catch (e) {
      developer.log('Error al crear empleado: $e', error: e);
      throw Exception("Error al crear empleado: $e");
    }
  }

  // Update employee with proper state management
  Future<bool> actualizarEmpleado(Usuario usuario, Empleado empleado) async {
    if (usuario.id == null) {
      throw Exception("No se puede actualizar un empleado sin ID de usuario");
    }
    try {
      if (usuario.nombreUsuario.isNotEmpty) {
        final existe = await existeNombreUsuario(
          usuario.nombreUsuario,
          idUsuarioActual: usuario.id,
        );
        if (existe) {
          throw Exception(
            "El nombre de usuario '${usuario.nombreUsuario}' ya está en uso por otro usuario",
          );
        }
      }
      await _service.actualizarUsuarioEmpleado(
        usuario.id!,
        empleado.id!,
        usuario,
        empleado,
      );
      await cargarEmpleados(forceRefresh: true);
      return true;
    } catch (e) {
      developer.log('Error al actualizar empleado: $e', error: e);
      throw Exception("Error al actualizar empleado: $e");
    }
  }

  // Get a specific employee by id
  Future<UsuarioEmpleado?> obtenerEmpleado(int id) async {
    try {
      developer.log('Iniciando obtenerEmpleadoPorId con ID: $id');
      return await _service.obtenerEmpleadoPorId(id);
    } catch (e) {
      developer.log('Error al obtener empleado #$id: $e', error: e);
      throw Exception("Error al obtener empleado: $e");
    }
  }

  // Change the employee's state (activate/deactivate)
  Future<bool> cambiarEstadoEmpleado(
    int idUsuario,
    int idEmpleado,
    bool activar,
  ) async {
    try {
      if (activar) {
        await _service.reactivarUsuarioEmpleado(idUsuario, idEmpleado);
      } else {
        await _service.inactivarUsuarioEmpleado(idUsuario, idEmpleado);
      }
      await cargarEmpleados(forceRefresh: true);
      return true;
    } catch (e) {
      developer.log('Error al cambiar estado del empleado: $e', error: e);
      throw Exception("Error al cambiar estado del empleado: $e");
    }
  }

  // Dispose resources
  void dispose() {
    _empleadosController.close();
  }
}

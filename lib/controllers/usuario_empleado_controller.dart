import 'dart:async';
import '../models/usuario.dart';
import '../models/empleado.dart';
import '../models/usuario_empleado.dart';
import '../services/usuario_empleado_service.dart';

class UsuarioEmpleadoController {
  final UsuarioEmpleadoService _service;

  UsuarioEmpleadoController(this._service);

  // Stream para manejo reactivo de la lista de empleados
  final _empleadosController =
      StreamController<List<UsuarioEmpleado>>.broadcast();
  Stream<List<UsuarioEmpleado>> get empleados => _empleadosController.stream;

  // Cargar lista de empleados
  Future<void> cargarEmpleados() async {
    try {
      final empleados = await _service.obtenerEmpleados();
      _empleadosController.sink.add(empleados);
    } catch (e) {
      _empleadosController.sink.addError("Error al cargar empleados: $e");
      rethrow;
    }
  }

  // Obtener un empleado específico
  Future<UsuarioEmpleado?> obtenerEmpleado(int id) async {
    try {
      return await _service.obtenerEmpleadoPorId(id);
    } catch (e) {
      throw Exception("Error al obtener empleado: $e");
    }
  }

  // Crear nuevo empleado con usuario
  Future<int> crearEmpleado(Usuario usuario, Empleado empleado) async {
    try {
      final id = await _service.crearUsuarioEmpleado(usuario, empleado);
      await cargarEmpleados(); // Actualizar lista
      return id;
    } catch (e) {
      throw Exception("Error al crear empleado: $e");
    }
  }

  // Actualizar empleado existente
  Future<void> actualizarEmpleado(
    int idUsuario,
    int idEmpleado,
    Usuario usuario,
    Empleado empleado,
  ) async {
    try {
      await _service.actualizarUsuarioEmpleado(
        idUsuario,
        idEmpleado,
        usuario,
        empleado,
      );
      await cargarEmpleados(); // Actualizar lista
    } catch (e) {
      throw Exception("Error al actualizar empleado: $e");
    }
  }

  // Inactivar empleado
  Future<void> inactivarEmpleado(int idUsuario, int idEmpleado) async {
    try {
      await _service.inactivarUsuarioEmpleado(idUsuario, idEmpleado);
      await cargarEmpleados(); // Actualizar lista
    } catch (e) {
      throw Exception("Error al inactivar empleado: $e");
    }
  }

  void dispose() {
    _empleadosController.close();
  }
}

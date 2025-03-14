import 'dart:async';
import '../models/usuario.dart';
import '../models/empleado.dart';
import 'dart:developer' as developer;
import '../models/usuario_empleado.dart';
import '../services/usuario_empleado_service.dart';

class UsuarioEmpleadoController {
  final UsuarioEmpleadoService _service;
  final _empleadosController =
      StreamController<List<UsuarioEmpleado>>.broadcast();
  List<UsuarioEmpleado> _empleadosList = [];
  bool _isInitialized = false;

  UsuarioEmpleadoController(this._service) {
    // Inicializar el stream con una lista vacía para evitar estado nulo
    _empleadosController.sink.add([]);
  }

  // Stream para manejo reactivo de la lista de empleados
  Stream<List<UsuarioEmpleado>> get empleados => _empleadosController.stream;

  // Verifica si ya se inicializó
  bool get isInitialized => _isInitialized;

  // Inicializar controlador con carga de datos
  Future<void> inicializar() async {
    if (_isInitialized) return;
    try {
      // Reducimos reintentos a 2 para minimizar esperas
      await cargarEmpleadosConReintentos(2);
      _isInitialized = true;
    } catch (e) {
      developer.log('Error al inicializar el controlador: $e', error: e);
    }
  }

  // Verificar conexión a la base de datos
  Future<bool> verificarConexion() async {
    try {
      developer.log('Verificando conexión desde el controlador');
      return await _service.verificarConexion();
    } catch (e) {
      developer.log(
        'Error al verificar conexión desde el controlador: $e',
        error: e,
      );
      throw Exception("Error al verificar conexión: $e");
    }
  }

  // Verificar si un nombre de usuario ya existe
  Future<bool> nombreUsuarioExiste(String nombreUsuario) async {
    try {
      developer.log(
        'Verificando si existe el nombre de usuario: $nombreUsuario',
      );
      final existe = await _service.nombreUsuarioExiste(nombreUsuario);
      developer.log('Nombre usuario "$nombreUsuario" existe: $existe');
      return existe;
    } catch (e) {
      developer.log('Error al verificar nombre de usuario: $e', error: e);
      throw Exception('Error al verificar nombre de usuario: $e');
    }
  }

  // NUEVO MÉTODO: Verificar si existe nombre de usuario excluyendo el usuario actual
  Future<bool> nombreUsuarioExisteExcluyendo(
    String nombreUsuario,
    int idUsuarioExcluir,
  ) async {
    try {
      developer.log(
        'Verificando si existe el nombre de usuario: $nombreUsuario (excluyendo ID: $idUsuarioExcluir)',
      );

      // Si el nombre de usuario es el mismo que ya tenía, no es duplicado
      final empleadoActual = await obtenerEmpleado(idUsuarioExcluir);
      if (empleadoActual?.usuario.nombreUsuario == nombreUsuario) {
        developer.log('Es el mismo nombre de usuario actual, no es duplicado');
        return false;
      }

      // Verificar si hay otro usuario con ese nombre
      return await _service.nombreUsuarioExisteExcluyendoId(
        nombreUsuario,
        idUsuarioExcluir,
      );
    } catch (e) {
      developer.log(
        'Error al verificar nombre de usuario excluyendo: $e',
        error: e,
      );
      // En caso de error, devolvemos falso para permitir continuar
      // Alternativamente, podrías lanzar una excepción dependiendo de tu manejo de errores
      return false;
    }
  }

  // Cargar empleados con cierto número de reintentos
  Future<void> cargarEmpleadosConReintentos(int maxIntentos) async {
    int intentos = 0;
    Exception? ultimoError;

    while (intentos < maxIntentos) {
      try {
        await cargarEmpleados();
        return; // Éxito, salir del método
      } catch (e) {
        intentos++;
        ultimoError = Exception('Error al cargar empleados: $e');
        developer.log(
          'Error al cargar empleados (intento $intentos/$maxIntentos): $e',
          error: e,
        );
        if (intentos < maxIntentos) {
          await Future.delayed(Duration(milliseconds: 400 * intentos));
        }
      }
    }

    if (ultimoError != null) {
      throw ultimoError;
    }
  }

  // Carga la lista de empleados
  Future<void> cargarEmpleados() async {
    try {
      developer.log('Iniciando carga de empleados desde el controlador');
      final empleados = await _service.obtenerEmpleados();
      _empleadosList = empleados;
      developer.log('Empleados cargados: ${empleados.length}');
      _empleadosController.sink.add([...empleados]);
      developer.log('Stream de empleados actualizado con nueva referencia');
    } catch (e) {
      developer.log(
        'Error al cargar empleados en controlador: $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      _empleadosController.sink.addError("Error al cargar empleados: $e");
      rethrow;
    }
  }

  // Cargar empleados con refresco forzado
  Future<void> cargarEmpleadosConRefresco() async {
    try {
      developer.log('Iniciando carga con refresco forzado');

      // Se reduce el tiempo de espera para agilizar la actualización
      await Future.delayed(const Duration(milliseconds: 300));

      // Solo un refresco en vez de múltiples llamadas
      final empleados = await _service.obtenerEmpleados();
      _empleadosList = empleados;
      developer.log('Refresco: Empleados cargados: ${empleados.length}');
      _empleadosController.sink.add([...empleados]);

      developer.log('Refresco de lista de empleados completado con éxito');
    } catch (e) {
      developer.log(
        'Error en cargarEmpleadosConRefresco: $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      _empleadosController.sink.addError("Error al recargar empleados: $e");
      rethrow;
    }
  }

  // Obtener la lista de empleados en memoria
  List<UsuarioEmpleado> get listaEmpleados => _empleadosList;

  // Obtener un empleado específico por ID
  Future<UsuarioEmpleado?> obtenerEmpleado(int id) async {
    try {
      return await _service.obtenerEmpleadoPorId(id);
    } catch (e) {
      developer.log('Error al obtener empleado #$id: $e', error: e);
      throw Exception("Error al obtener empleado: $e");
    }
  }

  // MÉTODO MODIFICADO: Crear usuario y empleado pasando contraseña
  Future<int> crearUsuarioEmpleado(
    Usuario usuario,
    Empleado empleado,
    String contrasena,
  ) async {
    try {
      developer.log('Creando empleado para usuario: ${usuario.nombreUsuario}');

      // Verificar si el nombre de usuario ya existe
      final existe = await nombreUsuarioExiste(usuario.nombreUsuario);
      if (existe) {
        throw Exception(
          "El nombre de usuario '${usuario.nombreUsuario}' ya existe. Elige otro.",
        );
      }

      final id = await _service.crearUsuarioEmpleado(
        usuario,
        empleado,
        contrasena,
      );
      // Pausa ligera para asegurar actualización de BD
      await Future.delayed(const Duration(milliseconds: 200));
      await cargarEmpleadosConRefresco();

      return id;
    } catch (e) {
      developer.log('Error al crear empleado: $e', error: e);
      throw Exception("Error al crear empleado: $e");
    }
  }

  // MÉTODO MEJORADO: Actualizar un empleado existente con validación de nombre de usuario
  Future<void> actualizarEmpleado(
    int idUsuario,
    int idEmpleado,
    Usuario usuario,
    Empleado empleado,
  ) async {
    try {
      // Si el nombre de usuario ha cambiado, verificar que no esté duplicado
      if (usuario.nombreUsuario.isNotEmpty) {
        // Usamos el nuevo método para verificar duplicados excluyendo el ID actual
        final existeNombreUsuario = await _service
            .nombreUsuarioExisteExcluyendoId(usuario.nombreUsuario, idUsuario);

        if (existeNombreUsuario) {
          throw Exception(
            "El nombre de usuario '${usuario.nombreUsuario}' ya está en uso por otro empleado.",
          );
        }
      }

      await _service.actualizarUsuarioEmpleado(
        idUsuario,
        idEmpleado,
        usuario,
        empleado,
      );
      await Future.delayed(const Duration(milliseconds: 200));
      await cargarEmpleadosConRefresco();
    } catch (e) {
      developer.log('Error al actualizar empleado: $e', error: e);
      throw Exception("Error al actualizar empleado: $e");
    }
  }

  // Inactivar empleado
  Future<void> inactivarEmpleado(int idUsuario, int idEmpleado) async {
    try {
      await _service.inactivarUsuarioEmpleado(idUsuario, idEmpleado);
      await Future.delayed(const Duration(milliseconds: 200));
      await cargarEmpleadosConRefresco();
    } catch (e) {
      developer.log('Error al inactivar empleado: $e', error: e);
      throw Exception("Error al inactivar empleado: $e");
    }
  }

  // Reactivar empleado
  Future<void> reactivarEmpleado(int idUsuario, int idEmpleado) async {
    try {
      developer.log('Reactivando empleado #$idEmpleado');
      await _service.reactivarUsuarioEmpleado(idUsuario, idEmpleado);
      await Future.delayed(const Duration(milliseconds: 200));
      await cargarEmpleadosConRefresco();
    } catch (e) {
      developer.log('Error al reactivar empleado: $e', error: e);
      throw Exception("Error al reactivar empleado: $e");
    }
  }

  // Liberar recursos
  void dispose() {
    _empleadosController.close();
    developer.log('UsuarioEmpleadoController: recursos liberados');
  }
}

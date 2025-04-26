import 'dart:async';
import '../models/usuario.dart';
import '../models/empleado.dart';
import '../utils/applogger.dart';
import '../models/usuario_empleado.dart';
import '../services/usuario_empleado_service.dart';

class UsuarioEmpleadoController {
  final UsuarioEmpleadoService _service;
  final _empleadosController =
      StreamController<List<UsuarioEmpleado>>.broadcast();
  List<UsuarioEmpleado> _empleadosList = [];
  bool _isInitialized = false;

  // Control para evitar errores duplicados en consola
  bool _procesandoError = false;

  // Nueva propiedad para rastrear cuando se completó la última actualización
  DateTime? _ultimaActualizacion;

  // Nueva propiedad para rastrear si hay una actualización en progreso
  bool _actualizacionEnProgreso = false;

  UsuarioEmpleadoController(this._service) {
    // Inicializar el stream con una lista vacía para evitar estado nulo
    _empleadosController.sink.add([]);
  }

  // Stream para manejo reactivo de la lista de empleados
  Stream<List<UsuarioEmpleado>> get empleados => _empleadosController.stream;

  // Acceso directo a la última lista actualizada
  List<UsuarioEmpleado> get empleadosActuales =>
      List.unmodifiable(_empleadosList);

  // Estado de última actualización
  DateTime? get ultimaActualizacion => _ultimaActualizacion;

  // Indicador si hay una actualización en progreso
  bool get actualizandoEmpleados => _actualizacionEnProgreso;

  // Verifica si ya se inicializó
  bool get isInitialized => _isInitialized;

  /// Método auxiliar para ejecutar operaciones con manejo de errores consistente
  Future<T> _ejecutarOperacion<T>(
    String descripcion,
    Future<T> Function() operacion,
  ) async {
    try {
      AppLogger.info('Iniciando operación: $descripcion');
      final resultado = await operacion();
      AppLogger.info('Operación completada: $descripcion');
      return resultado;
    } catch (e, stackTrace) {
      // Evitar logs duplicados para el mismo error
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error en operación "$descripcion"', e, stackTrace);
        _empleadosController.sink.addError("Error en $descripcion: $e");
        _procesandoError = false;
      }
      throw Exception('Error en $descripcion: $e');
    }
  }

  // Inicializar controlador con carga de datos
  Future<void> inicializar() async {
    if (_isInitialized) return;

    return _ejecutarOperacion(
      'inicializar controlador de empleados-usuarios',
      () async {
        // Reducimos reintentos a 2 para minimizar esperas
        await cargarEmpleadosConReintentos(2);
        _isInitialized = true;
        return;
      },
    );
  }

  // Verificar conexión a la base de datos
  Future<bool> verificarConexion() async {
    return _ejecutarOperacion('verificar conexión a base de datos', () async {
      AppLogger.info('Verificando conexión desde el controlador');
      return await _service.verificarConexion();
    });
  }

  // Verificar si un nombre de usuario ya existe
  Future<bool> nombreUsuarioExiste(String nombreUsuario) async {
    return _ejecutarOperacion(
      'verificar nombre de usuario existente',
      () async {
        AppLogger.info(
          'Verificando si existe el nombre de usuario: $nombreUsuario',
        );
        final existe = await _service.nombreUsuarioExiste(nombreUsuario);
        AppLogger.info('Nombre usuario "$nombreUsuario" existe: $existe');
        return existe;
      },
    );
  }

  // Verificar si existe nombre de usuario excluyendo el usuario actual
  Future<bool> nombreUsuarioExisteExcluyendo(
    String nombreUsuario,
    int idUsuarioExcluir,
  ) async {
    return _ejecutarOperacion(
      'verificar nombre de usuario existente excluyendo ID',
      () async {
        AppLogger.info(
          'Verificando si existe el nombre de usuario: $nombreUsuario (excluyendo ID: $idUsuarioExcluir)',
        );

        // Si el nombre de usuario es el mismo que ya tenía, no es duplicado
        final empleadoActual = await obtenerEmpleado(idUsuarioExcluir);
        if (empleadoActual?.usuario.nombreUsuario == nombreUsuario) {
          AppLogger.info(
            'Es el mismo nombre de usuario actual, no es duplicado',
          );
          return false;
        }

        // Verificar si hay otro usuario con ese nombre
        final existe = await _service.nombreUsuarioExisteExcluyendoId(
          nombreUsuario,
          idUsuarioExcluir,
        );

        AppLogger.info(
          'Nombre usuario "$nombreUsuario" existe (excluyendo ID $idUsuarioExcluir): $existe',
        );
        return existe;
      },
    );
  }

  // Cargar empleados con cierto número de reintentos
  Future<void> cargarEmpleadosConReintentos(int maxIntentos) async {
    return _ejecutarOperacion('cargar empleados con reintentos', () async {
      int intentos = 0;
      Exception? ultimoError;

      while (intentos < maxIntentos) {
        try {
          await cargarEmpleados();
          AppLogger.info(
            'Empleados cargados exitosamente en intento ${intentos + 1}',
          );
          return;
        } catch (e) {
          intentos++;
          ultimoError = Exception('Error al cargar empleados: $e');

          AppLogger.warning(
            'Error al cargar empleados (intento $intentos/$maxIntentos): $e',
          );

          if (intentos < maxIntentos) {
            await Future.delayed(Duration(milliseconds: 400 * intentos));
            AppLogger.info(
              'Reintentando cargar empleados (intento $intentos/$maxIntentos)',
            );
          }
        }
      }

      throw ultimoError ??
          Exception(
            'Error al cargar empleados después de $maxIntentos intentos',
          );
    });
  }

  // Carga la lista de empleados
  Future<void> cargarEmpleados() async {
    return _ejecutarOperacion('cargar empleados', () async {
      AppLogger.info('Iniciando carga de empleados desde el controlador');
      final empleados = await _service.obtenerEmpleados();
      _empleadosList = empleados;
      AppLogger.info('Empleados cargados: ${empleados.length}');
      _empleadosController.sink.add(List<UsuarioEmpleado>.from(empleados));
      AppLogger.info('Stream de empleados actualizado con nueva referencia');
      return;
    });
  }

  // Cargar empleados con refresco forzado
  Future<void> cargarEmpleadosConRefresco() async {
    return _ejecutarOperacion('cargar empleados con refresco', () async {
      AppLogger.info('[Controller] Iniciando carga con refresco forzado...');

      // Marcar que hay una actualización en progreso
      _actualizacionEnProgreso = true;

      try {
        // Solo un refresco en vez de múltiples llamadas
        final empleados = await _service.obtenerEmpleadosRefrescados();
        _empleadosList = empleados;
        AppLogger.info(
          '[Controller] Refresco: Empleados recibidos del servicio: ${empleados.length}',
        );

        // Crear una nueva lista para asegurar que el stream detecte el cambio
        final nuevaLista = List<UsuarioEmpleado>.from(empleados);
        _empleadosController.sink.add(nuevaLista);

        // Registrar cuando se completó la actualización
        _ultimaActualizacion = DateTime.now();

        AppLogger.info(
          '[Controller] Refresco: Stream actualizado con ${nuevaLista.length} empleados.',
        );
        return;
      } finally {
        // Asegurar que se marca como completado incluso en caso de error
        _actualizacionEnProgreso = false;
      }
    });
  }

  // Obtener la lista de empleados en memoria
  List<UsuarioEmpleado> get listaEmpleados => _empleadosList;

  // Obtener un empleado específico por ID
  Future<UsuarioEmpleado?> obtenerEmpleado(int id) async {
    return _ejecutarOperacion('obtener empleado por ID', () async {
      AppLogger.info('Buscando empleado con ID: $id');
      final empleado = await _service.obtenerEmpleadoPorId(id);

      if (empleado == null) {
        AppLogger.info('No se encontró empleado con ID: $id');
      } else {
        AppLogger.info(
          'Empleado encontrado: ${empleado.empleado.nombre} ${empleado.empleado.apellidoPaterno}',
        );
      }

      return empleado;
    });
  }

  // Crear usuario y empleado pasando contraseña
  Future<int> crearUsuarioEmpleado(
    Usuario usuario,
    Empleado empleado,
    String contrasena,
  ) async {
    return _ejecutarOperacion('crear usuario empleado', () async {
      AppLogger.info('Creando empleado para usuario: ${usuario.nombreUsuario}');

      // Verificar si el nombre de usuario ya existe
      final existe = await nombreUsuarioExiste(usuario.nombreUsuario);
      if (existe) {
        AppLogger.warning(
          'Nombre de usuario duplicado: ${usuario.nombreUsuario}',
        );
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

      AppLogger.info('Usuario empleado creado exitosamente con ID: $id');
      return id;
    });
  }

  // Actualizar un empleado existente con validación de nombre de usuario
  Future<void> actualizarEmpleado(
    int idUsuario,
    int idEmpleado,
    Usuario usuario,
    Empleado empleado,
  ) async {
    return _ejecutarOperacion('actualizar empleado', () async {
      AppLogger.info(
        'Actualizando empleado ID: $idEmpleado, Usuario: ${usuario.nombreUsuario}',
      );

      // Si el nombre de usuario ha cambiado, verificar que no esté duplicado
      if (usuario.nombreUsuario.isNotEmpty) {
        // Usamos el método para verificar duplicados excluyendo el ID actual
        final existeNombreUsuario = await nombreUsuarioExisteExcluyendo(
          usuario.nombreUsuario,
          idUsuario,
        );

        if (existeNombreUsuario) {
          AppLogger.warning(
            'El nombre de usuario está en uso por otro usuario: ${usuario.nombreUsuario}',
          );
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

      AppLogger.info('Empleado actualizado exitosamente');
      return;
    });
  }

  // Inactivar empleado
  Future<void> inactivarEmpleado(int idUsuario, int idEmpleado) async {
    return _ejecutarOperacion('inactivar empleado', () async {
      AppLogger.info(
        'Inactivando empleado: ID Usuario=$idUsuario, ID Empleado=$idEmpleado',
      );

      await _service.inactivarUsuarioEmpleado(idUsuario, idEmpleado);
      await Future.delayed(const Duration(milliseconds: 200));
      await cargarEmpleadosConRefresco();

      AppLogger.info('Empleado inactivado exitosamente');
      return;
    });
  }

  // Reactivar empleado
  Future<void> reactivarEmpleado(int idUsuario, int idEmpleado) async {
    return _ejecutarOperacion('reactivar empleado', () async {
      AppLogger.info(
        'Reactivando empleado: ID Usuario=$idUsuario, ID Empleado=$idEmpleado',
      );

      await _service.reactivarUsuarioEmpleado(idUsuario, idEmpleado);
      await Future.delayed(const Duration(milliseconds: 200));
      await cargarEmpleadosConRefresco();

      AppLogger.info('Empleado reactivado exitosamente');
      return;
    });
  }

  // Liberar recursos
  void dispose() {
    try {
      AppLogger.info('Liberando recursos de UsuarioEmpleadoController');
      _empleadosController.close();
    } catch (e) {
      AppLogger.warning('Error al liberar recursos del controlador: $e');
    }
  }
}

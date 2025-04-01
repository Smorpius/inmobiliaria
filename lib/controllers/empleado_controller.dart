import 'dart:async';
import '../models/usuario.dart';
import '../models/empleado.dart';
import '../utils/applogger.dart';
import '../models/usuario_empleado.dart';
import '../services/usuario_service.dart';
import '../services/usuario_empleado_service.dart';

class EmpleadoController {
  final UsuarioEmpleadoService _service;
  final UsuarioService _usuarioService;

  // Stream para gestión reactiva de datos de empleados
  final _empleadosController =
      StreamController<List<UsuarioEmpleado>>.broadcast();

  // Evitar múltiples procesamientos del mismo error
  bool _procesandoError = false;

  // Exponer el stream para observadores externos
  Stream<List<UsuarioEmpleado>> get empleados => _empleadosController.stream;

  bool _isInitialized = false;

  // Constructor
  EmpleadoController(this._service, this._usuarioService) {
    _empleadosController.sink.add([]);
  }

  // Estado de inicialización
  bool get isInitialized => _isInitialized;

  // Método auxiliar para ejecutar operaciones con manejo de errores consistente
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

        // Solo añadir error al stream si no es un error de inicialización
        if (_isInitialized) {
          _empleadosController.sink.addError("Error en $descripcion: $e");
        }

        _procesandoError = false;
      }
      throw Exception('Error en $descripcion: $e');
    }
  }

  // Inicialización optimizada
  Future<void> inicializar() async {
    if (_isInitialized) return;
    return _ejecutarOperacion('inicializar controlador de empleados', () async {
      await cargarEmpleados(forceRefresh: true);
      _isInitialized = true;
      return;
    });
  }

  // Cargar empleados con control de refresco
  Future<void> cargarEmpleados({bool forceRefresh = false}) async {
    return _ejecutarOperacion('cargar empleados', () async {
      AppLogger.info('Solicitando lista de empleados al servicio');
      final empleados = await _service.obtenerEmpleados(
        forzarRefresco: forceRefresh,
      );

      // Usar nueva lista para forzar actualización del stream
      _empleadosController.sink.add(List<UsuarioEmpleado>.from(empleados));

      AppLogger.info(
        'Lista de empleados actualizada: ${empleados.length} registros',
      );
      return;
    });
  }

  // Obtener la lista completa de empleados
  Future<List<Empleado>> obtenerEmpleados() async {
    return _ejecutarOperacion('obtener lista de empleados', () async {
      AppLogger.info('Obteniendo lista completa de empleados');
      final usuariosEmpleados = await _service.obtenerEmpleados();

      // Convertir la lista a modelo Empleado
      final listaEmpleados =
          usuariosEmpleados
              .map((usuarioEmpleado) => usuarioEmpleado.empleado)
              .toList();

      AppLogger.info(
        'Procesados ${listaEmpleados.length} registros de empleados',
      );
      return listaEmpleados;
    });
  }

  // Validar si el nombre de usuario existe, excluyendo opcionalmente el ID actual
  Future<bool> existeNombreUsuario(
    String nombreUsuario, {
    int? idUsuarioActual,
  }) async {
    return _ejecutarOperacion(
      'verificar disponibilidad de nombre de usuario',
      () async {
        AppLogger.info('Verificando nombre de usuario: $nombreUsuario');

        final existe =
            idUsuarioActual != null
                ? await _usuarioService.existeNombreUsuario(
                  nombreUsuario,
                  idExcluido: idUsuarioActual,
                )
                : await _service.nombreUsuarioExiste(nombreUsuario);

        AppLogger.info(
          'Nombre usuario "$nombreUsuario" ${existe ? "ya existe" : "disponible"}',
        );
        return existe;
      },
    );
  }

  // Crear un empleado con validación mejorada
  Future<int> crearEmpleado(
    Usuario usuario,
    Empleado empleado,
    String contrasena,
  ) async {
    return _ejecutarOperacion('crear empleado', () async {
      AppLogger.info('Creando nuevo empleado: ${usuario.nombreUsuario}');

      // Si es un nuevo empleado, verificar que el nombre de usuario esté disponible
      if (usuario.id == null) {
        final existe = await existeNombreUsuario(usuario.nombreUsuario);
        if (existe) {
          AppLogger.warning(
            'Nombre de usuario duplicado: ${usuario.nombreUsuario}',
          );
          throw Exception(
            "El nombre de usuario '${usuario.nombreUsuario}' ya existe. Elige otro.",
          );
        }
      }

      // Llamar al servicio para crear el usuario empleado - ya utiliza withConnection internamente
      final id = await _service.crearUsuarioEmpleado(
        usuario,
        empleado,
        contrasena,
      );

      // Pausa ligera para asegurar que la BD ha procesado el cambio
      await Future.delayed(const Duration(milliseconds: 200));

      // Actualizar la lista de empleados
      await cargarEmpleados(forceRefresh: true);

      AppLogger.info('Empleado creado exitosamente con ID: $id');
      return id;
    });
  }

  // Actualizar empleado con gestión de estado apropiada
  Future<bool> actualizarEmpleado(
    int idUsuario,
    int idEmpleado,
    Usuario usuario,
    Empleado empleado,
  ) async {
    if (usuario.id == null || idUsuario <= 0) {
      AppLogger.error(
        'Intento de actualizar empleado sin ID de usuario válido',
        null,
        StackTrace.current,
      );
      throw Exception(
        "No se puede actualizar un empleado sin ID de usuario válido",
      );
    }

    return _ejecutarOperacion('actualizar empleado', () async {
      AppLogger.info(
        'Actualizando empleado ID: $idEmpleado, Usuario: ${usuario.nombreUsuario}',
      );

      // Verificar que el nombre de usuario no exista (excepto para el mismo usuario)
      if (usuario.nombreUsuario.isNotEmpty) {
        final existe = await existeNombreUsuario(
          usuario.nombreUsuario,
          idUsuarioActual: idUsuario,
        );

        if (existe) {
          AppLogger.warning(
            'El nombre de usuario está en uso por otro usuario: ${usuario.nombreUsuario}',
          );
          throw Exception(
            "El nombre de usuario '${usuario.nombreUsuario}' ya está en uso por otro usuario",
          );
        }
      }

      // Actualizar usuario empleado - ya utiliza withConnection internamente
      await _service.actualizarUsuarioEmpleado(
        idUsuario,
        idEmpleado,
        usuario,
        empleado,
      );

      // Pausa ligera para asegurar que la BD ha procesado el cambio
      await Future.delayed(const Duration(milliseconds: 200));

      // Actualizar la lista de empleados
      await cargarEmpleados(forceRefresh: true);

      AppLogger.info('Empleado actualizado exitosamente');
      return true;
    });
  }

  // Obtener un empleado específico por ID
  Future<UsuarioEmpleado?> obtenerEmpleado(int id) async {
    return _ejecutarOperacion('obtener empleado', () async {
      AppLogger.info('Buscando empleado con ID: $id');
      // Este método ya usa el procedimiento almacenado ObtenerEmpleadoUsuario internamente
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

  // Cambiar el estado del empleado (activar/desactivar)
  Future<bool> cambiarEstadoEmpleado(
    int idUsuario,
    int idEmpleado,
    bool activar,
  ) async {
    return _ejecutarOperacion(
      activar ? 'reactivar empleado' : 'inactivar empleado',
      () async {
        AppLogger.info(
          '${activar ? "Reactivando" : "Inactivando"} empleado: ID Usuario=$idUsuario, ID Empleado=$idEmpleado',
        );

        if (activar) {
          // Usa el procedimiento almacenado ReactivarUsuarioEmpleado internamente
          await _service.reactivarUsuarioEmpleado(idUsuario, idEmpleado);
          AppLogger.info('Empleado reactivado exitosamente');
        } else {
          // Usa el procedimiento almacenado InactivarUsuarioEmpleado internamente
          await _service.inactivarUsuarioEmpleado(idUsuario, idEmpleado);
          AppLogger.info('Empleado inactivado exitosamente');
        }

        // Pausa ligera para asegurar que la BD ha procesado el cambio
        await Future.delayed(const Duration(milliseconds: 200));

        // Actualizar la lista de empleados
        await cargarEmpleados(forceRefresh: true);
        return true;
      },
    );
  }

  // Liberar recursos
  void dispose() {
    try {
      AppLogger.info('Liberando recursos de EmpleadoController');
      _empleadosController.close();
    } catch (e) {
      AppLogger.warning('Error al liberar recursos del controlador: $e');
    }
  }
}

import 'dart:async';
import '../utils/applogger.dart';
import '../models/proveedor.dart';
import '../services/proveedores_service.dart';

class ProveedorController {
  final ProveedoresService _service;
  bool isInitialized = false;

  // Control para evitar errores duplicados en la consola
  bool _procesandoError = false;

  // Stream controller para proveedores
  final StreamController<List<Proveedor>> _proveedoresController =
      StreamController<List<Proveedor>>.broadcast();

  // Stream de proveedores
  Stream<List<Proveedor>> get proveedores => _proveedoresController.stream;

  // Lista interna de proveedores
  List<Proveedor> _proveedoresList = [];

  // ID del usuario actual para operaciones de auditoría (público)
  int? usuarioActualId;

  // Constructor que requiere explícitamente un ProveedoresService
  ProveedorController(this._service);

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
      // Evitar múltiples procesamientos del mismo error
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error en operación "$descripcion"', e, stackTrace);
        _proveedoresController.sink.addError("Error en $descripcion: $e");
        _procesandoError = false;
      }
      throw Exception('Error en $descripcion: $e');
    }
  }

  /// Verifica y crea el usuario administrador si no existe
  Future<void> crearUsuarioAdministrador() async {
    return _ejecutarOperacion(
      'verificar/crear usuario administrador',
      () async {
        AppLogger.info('Verificando existencia del usuario administrador');
        final conn = await _service.verificarConexion();

        // Llamar al procedimiento almacenado para verificar existencia
        await conn.query('CALL VerificarUsuarioExiste(1, @existe)');
        final resultadoQuery = await conn.query('SELECT @existe as existe');

        final bool existe =
            resultadoQuery.isNotEmpty && resultadoQuery.first['existe'] == 1;

        if (!existe) {
          AppLogger.info('Creando usuario administrador automáticamente');

          // Llamar al procedimiento almacenado para crear admin
          await conn.query('CALL CrearUsuarioAdministrador(?, ?, ?, ?, ?)', [
            'Admin',
            'Sistema',
            'admin',
            'admin123',
            'admin@sistema.com',
          ]);

          AppLogger.info('Usuario administrador creado exitosamente');
        } else {
          AppLogger.info('El usuario administrador ya existe');
        }
        return;
      },
    );
  }

  /// Filtra los proveedores por un término de búsqueda
  Future<void> filtrarProveedores(String termino) async {
    return _ejecutarOperacion('filtrar proveedores', () async {
      AppLogger.info('Filtrando proveedores con término: "$termino"');

      if (termino.trim().isEmpty) {
        // Si no hay término de búsqueda, cargar todos los proveedores
        await cargarProveedores();
        return;
      }

      // Usar el método del servicio para buscar proveedores (ya usa procedimiento almacenado)
      final proveedoresFiltrados = await _service.buscarProveedores(termino);

      // Actualizar la lista local y el stream
      _proveedoresList = proveedoresFiltrados;
      _proveedoresController.sink.add(List<Proveedor>.from(_proveedoresList));

      AppLogger.info(
        'Lista de proveedores filtrada: ${_proveedoresList.length} resultados',
      );
      return;
    });
  }

  /// Inicializa el controlador cargando los proveedores
  Future<void> inicializar() async {
    if (isInitialized) return;

    return _ejecutarOperacion('inicializar controlador', () async {
      AppLogger.info('Inicializando controlador de proveedores');

      // Verificar y crear usuario administrador si es necesario
      await crearUsuarioAdministrador();

      // Establecer ID de usuario por defecto para operaciones de auditoría
      usuarioActualId = 1;
      AppLogger.info('Inicializando con usuarioActualId=$usuarioActualId');

      await cargarProveedores();
      isInitialized = true;
      AppLogger.info('Controlador de proveedores inicializado correctamente');
      return;
    });
  }

  /// Carga o actualiza la lista de proveedores
  Future<void> cargarProveedores() async {
    return _ejecutarOperacion('cargar proveedores', () async {
      // El método obtenerProveedores ya usa CALL ObtenerProveedores() internamente
      _proveedoresList = await _service.obtenerProveedores();
      AppLogger.info('Proveedores cargados: ${_proveedoresList.length}');

      // Crear nueva instancia de lista para forzar la actualización del stream
      _proveedoresController.add(List<Proveedor>.from(_proveedoresList));
      AppLogger.info('Stream de proveedores actualizado');
      return;
    });
  }

  /// Crea un nuevo proveedor
  Future<Proveedor> crearProveedor(Proveedor proveedor) async {
    return _ejecutarOperacion('crear proveedor', () async {
      // Verificar la conexión a la base de datos antes de la operación
      try {
        await _service.verificarConexion();
        AppLogger.info('Conexión a base de datos verificada correctamente');
      } catch (e) {
        AppLogger.warning('Problema con la conexión a la base de datos: $e');
        // Intentaremos de todos modos, ya que el servicio tiene reintentos
      }

      // Verificar si hay un ID de usuario válido
      if (usuarioActualId == null) {
        AppLogger.warning(
          'No hay ID de usuario actual, usando ID=1 por defecto',
        );
        usuarioActualId = 1;

        // Verificar si existe el usuario administrador
        await crearUsuarioAdministrador();
      }

      // El método crearProveedor ya usa CALL CrearProveedor() internamente
      // Ahora con reintentos automáticos implementados en el servicio
      final nuevoProveedor = await _service.crearProveedor(
        proveedor,
        usuarioModificacion: usuarioActualId,
      );

      // Refrescar la lista después de crear un proveedor
      await Future.delayed(const Duration(milliseconds: 300));
      await cargarProveedores();

      return nuevoProveedor;
    });
  }

  /// Actualiza un proveedor existente
  Future<void> actualizarProveedor(Proveedor proveedor) async {
    return _ejecutarOperacion('actualizar proveedor', () async {
      if (proveedor.idProveedor == null) {
        throw Exception(
          'El ID del proveedor no puede ser nulo para actualizar',
        );
      }

      // Verificar si hay un ID de usuario válido
      if (usuarioActualId == null) {
        AppLogger.warning(
          'No hay ID de usuario actual, usando ID=1 por defecto',
        );
        usuarioActualId = 1;

        // Verificar si existe el usuario administrador
        await crearUsuarioAdministrador();
      }

      // El método actualizarProveedor ya usa CALL ActualizarProveedor() internamente
      await _service.actualizarProveedor(
        proveedor,
        usuarioModificacion: usuarioActualId,
      );

      // Esperar un poco para que la BD procese el cambio
      await Future.delayed(const Duration(milliseconds: 300));
      await cargarProveedores();

      return;
    });
  }

  /// Marca un proveedor como inactivo
  Future<void> inactivarProveedor(int idProveedor) async {
    return _ejecutarOperacion('inactivar proveedor', () async {
      // Verificar si hay un ID de usuario válido
      if (usuarioActualId == null) {
        AppLogger.warning(
          'No hay ID de usuario actual, usando ID=1 por defecto',
        );
        usuarioActualId = 1;

        // Verificar si existe el usuario administrador
        await crearUsuarioAdministrador();
      }

      AppLogger.info('Inactivando proveedor ID: $idProveedor');

      // El método inactivarProveedor ya usa CALL InactivarProveedor() internamente
      await _service.inactivarProveedor(
        idProveedor,
        usuarioModificacion: usuarioActualId,
      );

      // Esperar un poco para que la BD procese el cambio
      await Future.delayed(const Duration(milliseconds: 300));
      await cargarProveedores();

      AppLogger.info('Proveedor inactivado y lista actualizada');
      return;
    });
  }

  /// Reactiva un proveedor inactivo
  Future<void> reactivarProveedor(int idProveedor) async {
    return _ejecutarOperacion('reactivar proveedor', () async {
      // Verificar si hay un ID de usuario válido
      if (usuarioActualId == null) {
        AppLogger.warning(
          'No hay ID de usuario actual, usando ID=1 por defecto',
        );
        usuarioActualId = 1;

        // Verificar si existe el usuario administrador
        await crearUsuarioAdministrador();
      }

      AppLogger.info('Reactivando proveedor ID: $idProveedor');

      // El método reactivarProveedor ya usa CALL ReactivarProveedor() internamente
      await _service.reactivarProveedor(
        idProveedor,
        usuarioModificacion: usuarioActualId,
      );

      // Esperar un poco para que la BD procese el cambio
      await Future.delayed(const Duration(milliseconds: 300));
      await cargarProveedores();

      AppLogger.info('Proveedor reactivado y lista actualizada');
      return;
    });
  }

  /// Establece el ID del usuario actual para operaciones de auditoría
  void setUsuarioActual(int idUsuario) {
    usuarioActualId = idUsuario;
    AppLogger.info('ID de usuario establecido: $idUsuario');
  }

  /// Libera recursos cuando el controlador ya no se necesita
  void dispose() {
    AppLogger.info('Liberando recursos de ProveedorController');
    _proveedoresController.close();
  }
}

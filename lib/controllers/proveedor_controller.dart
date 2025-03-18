import 'dart:async';
import '../models/proveedor.dart';
import 'dart:developer' as developer;
import '../services/proveedores_service.dart';

class ProveedorController {
  final ProveedoresService _service;
  bool isInitialized = false;

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

  /// Verifica y crea el usuario administrador si no existe
  Future<void> crearUsuarioAdministrador() async {
    try {
      developer.log('Verificando existencia del usuario administrador...');
      final conn = await _service.verificarConexion();

      // Verificar si existe el usuario
      final verificacion = await conn.query(
        'SELECT id_usuario FROM usuarios WHERE id_usuario = ?',
        [1],
      );

      if (verificacion.isEmpty) {
        developer.log('Creando usuario administrador automáticamente...');

        // Crear usuario con todos los campos requeridos
        await conn.query('''
          INSERT INTO usuarios (
            id_usuario, 
            nombre, 
            apellido, 
            nombre_usuario, 
            contraseña_usuario, 
            correo_cliente,
            id_estado
          ) 
          VALUES (1, 'Admin', 'Sistema', 'admin', 'admin123', 'admin@sistema.com', 1)
          ON DUPLICATE KEY UPDATE id_usuario = 1
        ''');

        developer.log('Usuario administrador creado exitosamente');
      } else {
        developer.log('El usuario administrador ya existe');
      }
    } catch (e) {
      developer.log(
        'Error verificando/creando usuario administrador: $e',
        error: e,
      );
      // No relanzamos la excepción para permitir que la aplicación continúe
    }
  }

  /// Inicializa el controlador cargando los proveedores
  Future<void> inicializar() async {
    if (isInitialized) return;

    try {
      developer.log('Inicializando controlador de proveedores');

      // Verificar y crear usuario administrador si es necesario
      await crearUsuarioAdministrador();

      // Establecer ID de usuario por defecto para operaciones de auditoría
      usuarioActualId = 1;
      developer.log(
        'Inicializando controlador de proveedores con usuarioActualId=$usuarioActualId',
      );

      await cargarProveedores();
      isInitialized = true;
      developer.log('Controlador de proveedores inicializado correctamente');
    } catch (e) {
      developer.log(
        'Error al inicializar el controlador de proveedores: $e',
        error: e,
      );
      rethrow;
    }
  }

  /// Carga o actualiza la lista de proveedores
  Future<void> cargarProveedores() async {
    try {
      _proveedoresList = await _service.obtenerProveedores();
      developer.log('Proveedores cargados: ${_proveedoresList.length}');

      // Depuración extra
      for (var p in _proveedoresList) {
        developer.log(
          '  - ${p.idProveedor}: ${p.nombre} (Estado: ${p.idEstado})',
        );
      }

      // CORREGIDO: Crear una nueva instancia de lista para forzar la actualización del stream
      _proveedoresController.add(List<Proveedor>.from(_proveedoresList));
      developer.log('Stream de proveedores actualizado con nueva referencia');
    } catch (e) {
      developer.log('Error al cargar proveedores: $e', error: e);
      rethrow;
    }
  }

  /// Crea un nuevo proveedor
  Future<Proveedor> crearProveedor(Proveedor proveedor) async {
    try {
      // Verificar si hay un ID de usuario válido
      if (usuarioActualId == null) {
        developer.log(
          'Advertencia: No hay ID de usuario actual, usando ID=1 por defecto',
        );
        usuarioActualId = 1;

        // Verificar si existe el usuario administrador
        await crearUsuarioAdministrador();
      }

      final nuevoProveedor = await _service.crearProveedor(
        proveedor,
        usuarioModificacion: usuarioActualId,
      );

      await cargarProveedores(); // Actualizar la lista
      return nuevoProveedor;
    } catch (e) {
      developer.log('Error al crear proveedor: $e', error: e);
      rethrow;
    }
  }

  /// Actualiza un proveedor existente
  Future<void> actualizarProveedor(Proveedor proveedor) async {
    try {
      if (proveedor.idProveedor == null) {
        throw Exception(
          'El ID del proveedor no puede ser nulo para actualizar',
        );
      }

      // Verificar si hay un ID de usuario válido
      if (usuarioActualId == null) {
        developer.log(
          'Advertencia: No hay ID de usuario actual, usando ID=1 por defecto',
        );
        usuarioActualId = 1;

        // Verificar si existe el usuario administrador
        await crearUsuarioAdministrador();
      }

      await _service.actualizarProveedor(
        proveedor,
        usuarioModificacion: usuarioActualId,
      );
      await cargarProveedores(); // Actualizar la lista
    } catch (e) {
      developer.log('Error al actualizar proveedor: $e', error: e);
      rethrow;
    }
  }

  /// Marca un proveedor como inactivo
  Future<void> inactivarProveedor(int idProveedor) async {
    try {
      // Verificar si hay un ID de usuario válido
      if (usuarioActualId == null) {
        developer.log(
          'Advertencia: No hay ID de usuario actual, usando ID=1 por defecto',
        );
        usuarioActualId = 1;

        // Verificar si existe el usuario administrador
        await crearUsuarioAdministrador();
      }

      developer.log('Inactivando proveedor ID: $idProveedor');

      // CORREGIDO: Usar la implementación corregida del servicio
      await _service.inactivarProveedor(
        idProveedor,
        usuarioModificacion: usuarioActualId,
      );

      await cargarProveedores(); // Actualizar la lista
      developer.log('Proveedor inactivado y lista actualizada');
    } catch (e) {
      developer.log('Error al inactivar proveedor: $e', error: e);
      rethrow;
    }
  }

  /// Reactiva un proveedor inactivo
  Future<void> reactivarProveedor(int idProveedor) async {
    try {
      // Verificar si hay un ID de usuario válido
      if (usuarioActualId == null) {
        developer.log(
          'Advertencia: No hay ID de usuario actual, usando ID=1 por defecto',
        );
        usuarioActualId = 1;

        // Verificar si existe el usuario administrador
        await crearUsuarioAdministrador();
      }

      developer.log('Reactivando proveedor ID: $idProveedor');

      // CORREGIDO: Usar la implementación corregida del servicio
      await _service.reactivarProveedor(
        idProveedor,
        usuarioModificacion: usuarioActualId,
      );

      await cargarProveedores(); // Actualizar la lista
      developer.log('Proveedor reactivado y lista actualizada');
    } catch (e) {
      developer.log('Error al reactivar proveedor: $e', error: e);
      rethrow;
    }
  }

  /// Establece el ID del usuario actual para operaciones de auditoría
  void setUsuarioActual(int idUsuario) {
    usuarioActualId = idUsuario;
    developer.log('ID de usuario establecido: $idUsuario');
  }

  /// Libera recursos cuando el controlador ya no se necesita
  void dispose() {
    _proveedoresController.close();
  }
}

import '../models/proveedor.dart';
import 'dart:developer' as developer;
import '../services/mysql_helper.dart';
import '../services/proveedores_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para el servicio de base de datos
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Provider para el servicio de proveedores
final proveedoresServiceProvider = Provider<ProveedoresService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ProveedoresService(dbService);
});

// Estados para la gestión de proveedores
class ProveedoresState {
  final List<Proveedor> proveedores;
  final bool isLoading;
  final String? errorMessage;
  final bool mostrarInactivos;
  final String terminoBusqueda;
  final bool buscando;

  ProveedoresState({
    required this.proveedores,
    required this.isLoading,
    this.errorMessage,
    required this.mostrarInactivos,
    required this.terminoBusqueda,
    required this.buscando,
  });

  // Constructor para el estado inicial
  factory ProveedoresState.initial() => ProveedoresState(
        proveedores: [],
        isLoading: false,
        errorMessage: null,
        mostrarInactivos: false,
        terminoBusqueda: '',
        buscando: false,
      );

  // Método para crear un nuevo estado con algunos valores cambiados
  ProveedoresState copyWith({
    List<Proveedor>? proveedores,
    bool? isLoading,
    String? errorMessage,
    bool? mostrarInactivos,
    String? terminoBusqueda,
    bool? buscando,
  }) {
    return ProveedoresState(
      proveedores: proveedores ?? this.proveedores,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      mostrarInactivos: mostrarInactivos ?? this.mostrarInactivos,
      terminoBusqueda: terminoBusqueda ?? this.terminoBusqueda,
      buscando: buscando ?? this.buscando,
    );
  }

  // Método para obtener proveedores filtrados
  List<Proveedor> get proveedoresFiltrados => mostrarInactivos
      ? proveedores.where((p) => p.idEstado != 1).toList()
      : proveedores.where((p) => p.idEstado == 1).toList();
}

// Controlador de estado para proveedores
class ProveedoresNotifier extends StateNotifier<ProveedoresState> {
  final ProveedoresService _service;
  int? usuarioActualId = 1;

  ProveedoresNotifier(this._service) : super(ProveedoresState.initial()) {
    inicializar();
  }

  // Inicializar el controlador
  Future<void> inicializar() async {
    if (state.isLoading) return;

    try {
      developer.log('[Riverpod] Inicializando controlador de proveedores');
      state = state.copyWith(isLoading: true, errorMessage: null);

      await crearUsuarioAdministrador();
      await cargarProveedores();

      developer.log('[Riverpod] Controlador de proveedores inicializado correctamente');
    } catch (e) {
      developer.log(
        '[Riverpod] Error al inicializar el controlador de proveedores: $e',
        error: e,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Verificar y crear usuario administrador
  Future<void> crearUsuarioAdministrador() async {
    try {
      developer.log('[Riverpod] Verificando existencia del usuario administrador');
      final conn = await _service.verificarConexion();

      final verificacion = await conn.query(
        'SELECT id_usuario FROM usuarios WHERE id_usuario = ?',
        [1],
      );

      if (verificacion.isEmpty) {
        developer.log('[Riverpod] Creando usuario administrador automáticamente');

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

        developer.log('[Riverpod] Usuario administrador creado exitosamente');
      }
    } catch (e) {
      developer.log(
        '[Riverpod] Error al verificar/crear usuario administrador: $e',
        error: e,
      );
      // No lanzamos excepción para permitir que la aplicación continúe
    }
  }

  // Cargar la lista de proveedores
  Future<void> cargarProveedores() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      developer.log('[Riverpod] Cargando proveedores');

      final proveedoresCargados = await _service.obtenerProveedores();
      developer.log('[Riverpod] Proveedores cargados: ${proveedoresCargados.length}');

      state = state.copyWith(
        proveedores: proveedoresCargados,
        isLoading: false,
        // Solo limpiar búsqueda si no estamos buscando activamente
        terminoBusqueda: state.buscando ? state.terminoBusqueda : '',
        buscando: state.buscando,
      );
    } catch (e) {
      developer.log('[Riverpod] Error al cargar proveedores: $e', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Buscar proveedores
  Future<void> buscarProveedores(String termino) async {
    if (state.isLoading) return;

    try {
      developer.log('[Riverpod] Buscando proveedores con término: "$termino"');
      state = state.copyWith(
        isLoading: true,
        terminoBusqueda: termino,
        buscando: termino.isNotEmpty,
        errorMessage: null,
      );

      if (termino.isEmpty) {
        await cargarProveedores();
      } else {
        final resultados = await _service.buscarProveedores(termino);
        state = state.copyWith(
          proveedores: resultados,
          isLoading: false,
        );
      }

      developer.log('[Riverpod] Búsqueda completada');
    } catch (e) {
      developer.log('[Riverpod] Error en búsqueda: $e', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Cambiar filtro de inactivos
  void cambiarFiltroInactivos(bool mostrarInactivos) {
    if (state.mostrarInactivos != mostrarInactivos) {
      developer.log('[Riverpod] Cambiando filtro de inactivos: $mostrarInactivos');
      state = state.copyWith(mostrarInactivos: mostrarInactivos);
    }
  }

  // Crear un nuevo proveedor
  Future<Proveedor?> crearProveedor(Proveedor proveedor) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      developer.log('[Riverpod] Creando nuevo proveedor');

      final nuevoProveedor = await _service.crearProveedor(
        proveedor,
        usuarioModificacion: usuarioActualId,
      );

      await cargarProveedores();
      return nuevoProveedor;
    } catch (e) {
      developer.log('[Riverpod] Error al crear proveedor: $e', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  // Actualizar un proveedor existente
  Future<bool> actualizarProveedor(Proveedor proveedor) async {
    try {
      if (proveedor.idProveedor == null) {
        throw Exception('El ID del proveedor no puede ser nulo para actualizar');
      }

      state = state.copyWith(isLoading: true, errorMessage: null);
      developer.log('[Riverpod] Actualizando proveedor ID: ${proveedor.idProveedor}');

      await _service.actualizarProveedor(
        proveedor,
        usuarioModificacion: usuarioActualId,
      );

      await cargarProveedores();
      return true;
    } catch (e) {
      developer.log('[Riverpod] Error al actualizar proveedor: $e', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // Inactivar un proveedor
  Future<bool> inactivarProveedor(int idProveedor) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      developer.log('[Riverpod] Inactivando proveedor ID: $idProveedor');

      await _service.inactivarProveedor(
        idProveedor,
        usuarioModificacion: usuarioActualId,
      );

      await cargarProveedores();
      return true;
    } catch (e) {
      developer.log('[Riverpod] Error al inactivar proveedor: $e', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // Reactivar un proveedor
  Future<bool> reactivarProveedor(int idProveedor) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      developer.log('[Riverpod] Reactivando proveedor ID: $idProveedor');

      await _service.reactivarProveedor(
        idProveedor,
        usuarioModificacion: usuarioActualId,
      );

      await cargarProveedores();
      return true;
    } catch (e) {
      developer.log('[Riverpod] Error al reactivar proveedor: $e', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

// Provider para el controlador de proveedores
final proveedoresProvider = StateNotifierProvider<ProveedoresNotifier, ProveedoresState>((ref) {
  final service = ref.watch(proveedoresServiceProvider);
  return ProveedoresNotifier(service);
});
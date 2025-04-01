import 'providers_global.dart';
import '../models/proveedor.dart';
import '../services/proveedores_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/applogger.dart'; // Usar AppLogger en lugar de developer.log

/// Provider para el servicio de proveedores
final proveedoresServiceProvider = Provider<ProveedoresService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ProveedoresService(dbService);
});

/// Estados para la gestión de proveedores
class ProveedoresState {
  final List<Proveedor> proveedores;
  final bool isLoading;
  final String? errorMessage;
  final bool mostrarInactivos;
  final String terminoBusqueda;
  final bool buscando;

  const ProveedoresState({
    required this.proveedores,
    required this.isLoading,
    this.errorMessage,
    required this.mostrarInactivos,
    required this.terminoBusqueda,
    required this.buscando,
  });

  /// Constructor para el estado inicial
  factory ProveedoresState.initial() => const ProveedoresState(
    proveedores: [],
    isLoading: false,
    errorMessage: null,
    mostrarInactivos: false,
    terminoBusqueda: '',
    buscando: false,
  );

  /// Método para crear un nuevo estado con algunos valores cambiados
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

  /// Método para obtener proveedores filtrados según estado
  List<Proveedor> get proveedoresFiltrados =>
      mostrarInactivos
          ? proveedores.where((p) => p.idEstado != 1).toList()
          : proveedores.where((p) => p.idEstado == 1).toList();
}

/// Controlador de estado para proveedores
class ProveedoresNotifier extends StateNotifier<ProveedoresState> {
  final ProveedoresService _service;
  int? usuarioActualId = 1;

  // Control para evitar procesamiento de errores duplicados
  bool _procesandoError = false;

  ProveedoresNotifier(this._service) : super(ProveedoresState.initial()) {
    inicializar();
  }

  /// Inicializar el controlador con manejo de errores mejorado
  Future<void> inicializar() async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      AppLogger.info('Inicializando controlador de proveedores');

      await crearUsuarioAdministrador();
      await cargarProveedores();

      AppLogger.info('Controlador de proveedores inicializado correctamente');
    } catch (e) {
      _manejarError('inicializar controlador', e);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Verifica y crea usuario administrador si no existe usando procedimiento almacenado
  Future<void> crearUsuarioAdministrador() async {
    try {
      AppLogger.info('Verificando existencia del usuario administrador');

      // Usar withConnection para gestionar la conexión correctamente
      await _service.verificarConexion().then((conn) async {
        // Usar procedimiento almacenado en lugar de consulta directa
        await conn.query('CALL VerificarUsuarioExiste(?, @existe)', [1]);
        final resultadoExiste = await conn.query('SELECT @existe as existe');

        final bool existe =
            resultadoExiste.isNotEmpty &&
            resultadoExiste.first.fields['existe'] == 1;

        if (!existe) {
          AppLogger.info('Creando usuario administrador automáticamente');

          // Usar procedimiento almacenado para crear admin
          await conn.query(
            'CALL CrearUsuarioAdministrador(?, ?, ?, ?, ?, @id_admin_out)',
            [
              'Administrador',
              'Sistema',
              'admin',
              'admin123',
              'admin@sistema.com',
            ],
          );

          AppLogger.info('Usuario administrador creado exitosamente');
        } else {
          AppLogger.info('El usuario administrador ya existe');
        }
      });
    } catch (e) {
      _manejarError('verificar/crear usuario administrador', e);
      // No lanzamos excepción para permitir que la aplicación continúe
    }
  }

  /// Cargar la lista de proveedores usando el procedimiento almacenado
  Future<void> cargarProveedores() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      AppLogger.info('Cargando proveedores');

      // Obtener proveedores usando el procedimiento almacenado a través del servicio
      final proveedoresCargados = await _service.obtenerProveedores();
      AppLogger.info('Proveedores cargados: ${proveedoresCargados.length}');

      state = state.copyWith(
        proveedores: proveedoresCargados,
        isLoading: false,
        // Solo limpiar búsqueda si no estamos buscando activamente
        terminoBusqueda: state.buscando ? state.terminoBusqueda : '',
        buscando: state.buscando,
      );
    } catch (e) {
      _manejarError('cargar proveedores', e);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Buscar proveedores usando el procedimiento almacenado
  Future<void> buscarProveedores(String termino) async {
    if (state.isLoading) return;

    try {
      AppLogger.info('Buscando proveedores con término: "$termino"');
      state = state.copyWith(
        isLoading: true,
        terminoBusqueda: termino,
        buscando: termino.isNotEmpty,
        errorMessage: null,
      );

      if (termino.isEmpty) {
        await cargarProveedores();
      } else {
        // Usar el método del servicio que ya implementa el procedimiento almacenado
        final resultados = await _service.buscarProveedores(termino);
        state = state.copyWith(proveedores: resultados, isLoading: false);
      }

      AppLogger.info('Búsqueda completada');
    } catch (e) {
      _manejarError('buscar proveedores', e);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Cambiar filtro de inactivos
  void cambiarFiltroInactivos(bool mostrarInactivos) {
    if (state.mostrarInactivos != mostrarInactivos) {
      AppLogger.info('Cambiando filtro de inactivos: $mostrarInactivos');
      state = state.copyWith(mostrarInactivos: mostrarInactivos);
    }
  }

  /// Crear un nuevo proveedor usando procedimiento almacenado
  Future<Proveedor?> crearProveedor(Proveedor proveedor) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      AppLogger.info('Creando nuevo proveedor');

      // El servicio ya implementa el procedimiento almacenado CrearProveedor
      final nuevoProveedor = await _service.crearProveedor(
        proveedor,
        usuarioModificacion: usuarioActualId,
      );

      // Actualizar la lista después de crear
      await cargarProveedores();
      return nuevoProveedor;
    } catch (e) {
      _manejarError('crear proveedor', e);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Actualizar un proveedor existente usando procedimiento almacenado
  Future<bool> actualizarProveedor(Proveedor proveedor) async {
    try {
      if (proveedor.idProveedor == null) {
        throw Exception(
          'El ID del proveedor no puede ser nulo para actualizar',
        );
      }

      state = state.copyWith(isLoading: true, errorMessage: null);
      AppLogger.info('Actualizando proveedor ID: ${proveedor.idProveedor}');

      // El servicio ya implementa el procedimiento almacenado ActualizarProveedor
      await _service.actualizarProveedor(
        proveedor,
        usuarioModificacion: usuarioActualId,
      );

      // Actualizar la lista después de modificar
      await cargarProveedores();
      return true;
    } catch (e) {
      _manejarError('actualizar proveedor', e);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Inactivar un proveedor usando procedimiento almacenado
  Future<bool> inactivarProveedor(int idProveedor) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      AppLogger.info('Inactivando proveedor ID: $idProveedor');

      // El servicio ya implementa el procedimiento almacenado InactivarProveedor
      await _service.inactivarProveedor(
        idProveedor,
        usuarioModificacion: usuarioActualId,
      );

      // Actualizar la lista después de inactivar
      await cargarProveedores();
      return true;
    } catch (e) {
      _manejarError('inactivar proveedor', e);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Reactivar un proveedor usando procedimiento almacenado
  Future<bool> reactivarProveedor(int idProveedor) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      AppLogger.info('Reactivando proveedor ID: $idProveedor');

      // El servicio ya implementa el procedimiento almacenado ReactivarProveedor
      await _service.reactivarProveedor(
        idProveedor,
        usuarioModificacion: usuarioActualId,
      );

      // Actualizar la lista después de reactivar
      await cargarProveedores();
      return true;
    } catch (e) {
      _manejarError('reactivar proveedor', e);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Método para manejar errores evitando duplicados
  void _manejarError(String operacion, dynamic error) {
    if (!_procesandoError) {
      _procesandoError = true;
      AppLogger.error(
        'Error en operación "$operacion"',
        error,
        StackTrace.current,
      );
      _procesandoError = false;
    }
  }
}

/// Provider para el controlador de proveedores
final proveedoresProvider =
    StateNotifierProvider<ProveedoresNotifier, ProveedoresState>((ref) {
      final service = ref.watch(proveedoresServiceProvider);
      return ProveedoresNotifier(service);
    });

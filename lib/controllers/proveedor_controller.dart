import 'dart:async';
import '../models/proveedor.dart';
import '../services/proveedores_service.dart';
import 'dart:developer' as developer;

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

  ProveedorController([ProveedoresService? service]) 
      : _service = service ?? ProveedoresService();
  
  /// Inicializa el controlador cargando los proveedores
  Future<void> inicializar() async {
    if (isInitialized) return;
    
    try {
      await cargarProveedores();
      isInitialized = true;
    } catch (e) {
      developer.log('Error al inicializar el controlador de proveedores: $e', error: e);
      rethrow;
    }
  }

  /// Carga o actualiza la lista de proveedores
  Future<void> cargarProveedores() async {
    try {
      _proveedoresList = await _service.obtenerProveedores();
      _proveedoresController.add(_proveedoresList);
    } catch (e) {
      developer.log('Error al cargar proveedores: $e', error: e);
      rethrow;
    }
  }

  /// Crea un nuevo proveedor
  Future<Proveedor> crearProveedor(Proveedor proveedor) async {
    try {
      final nuevoProveedor = await _service.crearProveedor(proveedor);
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
        throw Exception('El ID del proveedor no puede ser nulo para actualizar');
      }
      
      await _service.actualizarProveedor(proveedor);
      await cargarProveedores(); // Actualizar la lista
    } catch (e) {
      developer.log('Error al actualizar proveedor: $e', error: e);
      rethrow;
    }
  }

  /// Marca un proveedor como inactivo
  Future<void> inactivarProveedor(int idProveedor) async {
    try {
      await _service.inactivarProveedor(idProveedor);
      await cargarProveedores(); // Actualizar la lista
    } catch (e) {
      developer.log('Error al inactivar proveedor: $e', error: e);
      rethrow;
    }
  }

  /// Reactiva un proveedor inactivo
  Future<void> reactivarProveedor(int idProveedor) async {
    try {
      await _service.reactivarProveedor(idProveedor);
      await cargarProveedores(); // Actualizar la lista
    } catch (e) {
      developer.log('Error al reactivar proveedor: $e', error: e);
      rethrow;
    }
  }

  /// Libera recursos cuando el controlador ya no se necesita
  void dispose() {
    _proveedoresController.close();
  }
}


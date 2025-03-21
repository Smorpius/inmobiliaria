import 'package:flutter/material.dart';
import 'detalle_proveedor_screen.dart';
import '../../../models/proveedor.dart';
import '../nuevo_proveedor_screen.dart';
import '../../../utils/dialog_helper.dart';
import '../../../providers/proveedor_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin ProveedoresAcciones {
  late BuildContext _context;
  late WidgetRef _ref;
  bool _isMounted = true;
  StateSetter? _setState;

  void inicializarAcciones(
    BuildContext context,
    WidgetRef ref,
    StateSetter setState,
  ) {
    _context = context;
    _ref = ref;
    _setState = setState;
    _isMounted = true;
  }

  bool get _contextDisponible => _isMounted && _context.mounted;

  // Método para actualizar la UI de forma segura (no asíncrona)
  void _actualizarUI(VoidCallback fn) {
    if (_contextDisponible && _setState != null) {
      _setState!.call(fn);
    }
  }

  Future<void> inactivarProveedor(
    Proveedor proveedor, {
    required VoidCallback onSuccess,
  }) async {
    if (!_contextDisponible) return;

    // Ejecutar la acción de confirmación antes de llamar a setState
    final confirmar = await DialogHelper.confirmarAccion(
      _context,
      '¿Desea eliminar este proveedor?',
      'Esta acción cambiará el estado del proveedor a inactivo.',
      'Eliminar',
      const TextStyle(color: Colors.red),
    );

    if (confirmar) {
      try {
        // Usar Riverpod para inactivar el proveedor
        final exito = await _ref.read(proveedoresProvider.notifier)
            .inactivarProveedor(proveedor.idProveedor!);
            
        if (exito && _contextDisponible) {
          // Actualización de UI de forma síncrona
          _actualizarUI(() {
            // Se puede mostrar el mensaje sin esperar su finalización
            DialogHelper.mostrarMensajeExito(
              _context,
              'Proveedor inactivado correctamente',
            );
            onSuccess();
          });
        }
      } catch (e) {
        if (_contextDisponible) {
          _actualizarUI(() {
            DialogHelper.mostrarMensajeError(
              _context,
              'Error al inactivar el proveedor',
              e.toString(),
            );
          });
        }
      }
    }
  }

  Future<void> reactivarProveedor(
    Proveedor proveedor, {
    required VoidCallback onSuccess,
  }) async {
    if (!_contextDisponible) return;

    final confirmar = await DialogHelper.confirmarAccion(
      _context,
      '¿Desea reactivar este proveedor?',
      'Esta acción cambiará el estado del proveedor a activo.',
      'Reactivar',
      const TextStyle(color: Colors.green),
    );

    if (confirmar) {
      try {
        // Usar Riverpod para reactivar el proveedor
        final exito = await _ref.read(proveedoresProvider.notifier)
            .reactivarProveedor(proveedor.idProveedor!);
            
        if (exito && _contextDisponible) {
          _actualizarUI(() {
            DialogHelper.mostrarMensajeExito(
              _context,
              'Proveedor reactivado correctamente',
            );
            onSuccess();
          });
        }
      } catch (e) {
        if (_contextDisponible) {
          _actualizarUI(() {
            DialogHelper.mostrarMensajeError(
              _context,
              'Error al reactivar el proveedor',
              e.toString(),
            );
          });
        }
      }
    }
  }

  Future<void> modificarProveedor(
    Proveedor proveedor, {
    required VoidCallback onSuccess,
  }) async {
    if (!_contextDisponible) return;
    
    // Ejecutar la navegación fuera de setState
    // Ya no pasamos el controller porque DetalleProveedorScreen usa Riverpod
    final result = await Navigator.push(
      _context,
      MaterialPageRoute(
        builder: (_) => DetalleProveedorScreen(proveedor: proveedor),
      ),
    );

    if (_contextDisponible && result == true) {
      // Recargar proveedores usando Riverpod
      await _ref.read(proveedoresProvider.notifier).cargarProveedores();
      
      _actualizarUI(() {
        onSuccess();
      });
    }
  }
  
  Future<void> nuevoProveedor({
    required VoidCallback onSuccess,
  }) async {
    if (!_contextDisponible) return;
    
    final result = await Navigator.push(
      _context,
      MaterialPageRoute(
        builder: (_) => const NuevoProveedorScreen(),
      ),
    );

    if (_contextDisponible && result == true) {
      // Recargar proveedores usando Riverpod
      await _ref.read(proveedoresProvider.notifier).cargarProveedores();
      
      _actualizarUI(() {
        onSuccess();
      });
    }
  }

  void dispose() {
    _isMounted = false;
    _setState = null;
  }
}
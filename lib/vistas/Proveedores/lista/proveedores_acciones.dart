import 'package:flutter/material.dart';
import '../../../models/proveedor.dart';
import '../../../utils/dialog_helper.dart';
import '../../../controllers/proveedor_controller.dart';
import 'package:inmobiliaria/vistas/Proveedores/lista/detalle_proveedor_screen.dart';

mixin ProveedoresAcciones {
  late ProveedorController _controller;
  late BuildContext _context;
  bool _isMounted = true;
  StateSetter? _setState;

  void inicializarAcciones(
    ProveedorController controller,
    BuildContext context,
    StateSetter setState,
  ) {
    _controller = controller;
    _context = context;
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

    // Ejecutar la acción de confirmación antes de llamar a setState.
    final confirmar = await DialogHelper.confirmarAccion(
      _context,
      '¿Desea eliminar este proveedor?',
      'Esta acción cambiará el estado del proveedor a inactivo.',
      'Eliminar',
      const TextStyle(color: Colors.red),
    );

    if (confirmar) {
      try {
        await _controller.inactivarProveedor(proveedor.idProveedor!);
        if (_contextDisponible) {
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
        await _controller.reactivarProveedor(proveedor.idProveedor!);
        if (_contextDisponible) {
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
    final result = await Navigator.push(
      _context,
      MaterialPageRoute(
        builder:
            (_) => DetalleProveedorScreen(
              proveedor: proveedor,
              controller: _controller,
            ),
      ),
    );

    if (_contextDisponible && result == true) {
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

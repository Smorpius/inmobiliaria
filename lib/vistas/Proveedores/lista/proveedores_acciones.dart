import 'package:flutter/material.dart';
import '../../../models/proveedor.dart';
import '../../../utils/dialog_helper.dart';
import '../../../controllers/proveedor_controller.dart';

mixin ProveedoresAcciones {
  late ProveedorController _controller;
  late BuildContext _context;

  void inicializarAcciones(ProveedorController controller, BuildContext context) {
    _controller = controller;
    _context = context;
  }

  Future<void> inactivarProveedor(Proveedor proveedor, {required VoidCallback onSuccess}) async {
    final confirmar = await DialogHelper.confirmarAccion(
      _context,
      '¿Desea eliminar este proveedor?',
      'Esta acción cambiará el estado del proveedor a inactivo.',
      'Eliminar',
      TextStyle(color: Colors.red),
    );

    if (confirmar) {
      try {
        await _controller.inactivarProveedor(proveedor.idProveedor!);
        DialogHelper.mostrarMensajeExito(
          _context,
          'Proveedor inactivado correctamente',
        );
        onSuccess();
      } catch (e) {
        DialogHelper.mostrarMensajeError(
          _context,
          'Error al inactivar el proveedor',
          e.toString(),
        );
      }
    }
  }

  Future<void> reactivarProveedor(Proveedor proveedor, {required VoidCallback onSuccess}) async {
    final confirmar = await DialogHelper.confirmarAccion(
      _context,
      '¿Desea reactivar este proveedor?',
      'Esta acción cambiará el estado del proveedor a activo.',
      'Reactivar',
      TextStyle(color: Colors.green),
    );

    if (confirmar) {
      try {
        await _controller.reactivarProveedor(proveedor.idProveedor!);
        DialogHelper.mostrarMensajeExito(
          _context,
          'Proveedor reactivado correctamente',
        );
        onSuccess();
      } catch (e) {
        DialogHelper.mostrarMensajeError(
          _context,
          'Error al reactivar el proveedor',
          e.toString(),
        );
      }
    }
  }

  Future<void> modificarProveedor(Proveedor proveedor, {required VoidCallback onSuccess}) async {
    final result = await Navigator.push(
      _context,
      MaterialPageRoute(
        builder: (context) => DetalleProveedorScreen(
          proveedor: proveedor,
          controller: _controller,
        ),
      ),
    );

    if (result == true) {
      onSuccess();
    }
  }
}
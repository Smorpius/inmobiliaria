import 'dart:developer' as developer;
import 'detalle_empleado_screen.dart';
import 'package:flutter/material.dart';
import '../../../models/usuario_empleado.dart';
import '../../../controllers/usuario_empleado_controller.dart';

mixin EmpleadosAcciones<T extends StatefulWidget> on State<T> {
  late UsuarioEmpleadoController _controller;
  late BuildContext _context;

  void inicializarAcciones(
    UsuarioEmpleadoController controller,
    BuildContext context,
  ) {
    _controller = controller;
    _context = context;
  }

  Future<void> modificarEmpleado(
    UsuarioEmpleado empleado, {
    required Function onSuccess,
  }) async {
    try {
      final result = await Navigator.push(
        _context,
        MaterialPageRoute(
          builder:
              (context) => DetalleEmpleadoScreen(
                controller: _controller,
                idEmpleado: empleado.empleado.id!,
              ),
        ),
      );

      if (result == true && mounted) {
        setState(() => (this as dynamic).estado.iniciarCarga());
        await Future.delayed(const Duration(milliseconds: 300));
        await onSuccess();
      }
    } catch (e) {
      developer.log('Error al abrir detalles del empleado: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir detalles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> inactivarEmpleado(
    UsuarioEmpleado empleado, {
    required Function onSuccess,
  }) async {
    final confirmar = await _confirmarAccion(
      titulo: 'Inactivar empleado',
      mensaje:
          '¿Está seguro que desea inactivar al empleado '
          '${empleado.empleado.nombre} ${empleado.empleado.apellidoPaterno}?',
      accionText: 'Inactivar',
      accionColor: Colors.red,
    );

    if (confirmar == true) {
      try {
        setState(() => (this as dynamic).estado.iniciarCarga());
        await _controller.inactivarEmpleado(
          empleado.usuario.id!,
          empleado.empleado.id!,
        );
        if (mounted) {
          ScaffoldMessenger.of(_context).showSnackBar(
            const SnackBar(
              content: Text('Empleado inactivado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          await onSuccess();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(_context).showSnackBar(
            SnackBar(
              content: Text('Error al inactivar empleado: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => (this as dynamic).estado.finalizarCarga());
        }
      }
    }
  }

  Future<void> reactivarEmpleado(
    UsuarioEmpleado empleado, {
    required Function onSuccess,
  }) async {
    final confirmar = await _confirmarAccion(
      titulo: 'Reactivar empleado',
      mensaje:
          '¿Está seguro que desea reactivar al empleado '
          '${empleado.empleado.nombre} ${empleado.empleado.apellidoPaterno}?',
      accionText: 'Reactivar',
      accionColor: Colors.green,
    );

    if (confirmar == true) {
      try {
        setState(() => (this as dynamic).estado.iniciarCarga());
        await _controller.reactivarEmpleado(
          empleado.usuario.id!,
          empleado.empleado.id!,
        );
        if (mounted) {
          ScaffoldMessenger.of(_context).showSnackBar(
            const SnackBar(
              content: Text('Empleado reactivado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          await onSuccess();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(_context).showSnackBar(
            SnackBar(
              content: Text('Error al reactivar empleado: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => (this as dynamic).estado.finalizarCarga());
        }
      }
    }
  }

  Future<void> agregarEmpleado({required Function onSuccess}) async {
    try {
      final result = await Navigator.push(
        _context,
        MaterialPageRoute(
          builder: (context) => DetalleEmpleadoScreen(controller: _controller),
        ),
      );

      if (result == true && mounted) {
        developer.log('Regresando de agregar empleado. Recargando lista...');
        setState(() => (this as dynamic).estado.iniciarCarga());

        // Llamar a cargarEmpleadosConRefresco para asegurar la actualización
        await _controller.cargarEmpleadosConRefresco();

        if (mounted) {
          setState(() => (this as dynamic).estado.finalizarCarga());

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(_context).showSnackBar(
            const SnackBar(
              content: Text('Empleado agregado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error al abrir formulario de nuevo empleado: $e',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir formulario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _confirmarAccion({
    required String titulo,
    required String mensaje,
    required String accionText,
    required Color accionColor,
  }) {
    return showDialog<bool>(
      context: _context,
      builder:
          (context) => AlertDialog(
            title: Text(titulo),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: accionColor),
                child: Text(accionText),
              ),
            ],
          ),
    );
  }
}

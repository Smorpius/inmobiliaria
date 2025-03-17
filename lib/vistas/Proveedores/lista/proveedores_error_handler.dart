import 'package:flutter/material.dart';
import '../../../utils/dialog_helper.dart';
import 'dart:developer' as developer;

mixin ProveedoresErrorHandler {
  late BuildContext _context;

  void inicializarErrorHandler(BuildContext context) {
    _context = context;
  }

  void manejarError(dynamic error) {
    developer.log(
      'Error en el controlador de proveedores: $error',
      error: error,
      name: 'ProveedoresErrorHandler',
    );

    // Mostrar un diálogo de error según el tipo
    if (error.toString().contains('timeout') || 
        error.toString().contains('connection')) {
      DialogHelper.mostrarMensajeError(
        _context,
        'Error de conexión',
        'No se pudo conectar con el servidor. Verifica tu conexión a internet e intenta nuevamente.',
      );
    } else if (error.toString().contains('permission') || 
              error.toString().contains('denied')) {
      DialogHelper.mostrarMensajeError(
        _context,
        'Error de permisos',
        'No tienes permiso para realizar esta operación.',
      );
    } else {
      DialogHelper.mostrarMensajeError(
        _context,
        'Error inesperado',
        'Ocurrió un error al procesar la solicitud: ${error.toString()}',
      );
    }
  }
}
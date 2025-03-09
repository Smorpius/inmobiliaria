import 'package:flutter/material.dart';

class EmpleadosEstado {
  bool isLoading = false;
  bool mostrarInactivos = false;
  String? mensajeError;
  StackTrace? stackTrace;

  // Clave para forzar reconstrucción del StreamBuilder
  final streamKey = GlobalKey();

  bool get tieneError => mensajeError != null;

  void iniciarCarga() {
    isLoading = true;
    mensajeError = null;
    stackTrace = null;
  }

  void finalizarCarga() {
    isLoading = false;
  }

  void establecerError(String mensaje, StackTrace? stack) {
    isLoading = false;
    mensajeError = mensaje;
    stackTrace = stack;
  }
}

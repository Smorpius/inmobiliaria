import 'package:flutter/material.dart';

class ProveedoresEstado {
  bool isLoading = false;
  bool tieneError = false;
  String? mensajeError;
  StackTrace? stackTrace;
  bool mostrarInactivos = false;
  Key streamKey = UniqueKey();

  void regenerarStreamKey() {
    streamKey = UniqueKey();
  }
}
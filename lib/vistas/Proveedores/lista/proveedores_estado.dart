import 'package:flutter/material.dart';

class ProveedoresEstado {
  bool isLoading = false;
  bool tieneError = false;
  String? mensajeError;
  StackTrace? stackTrace;
  bool mostrarInactivos = false;

  // Nuevos campos para la búsqueda
  String terminoBusqueda = '';
  bool buscando = false;

  // Usar clave estática para evitar recreación constante del StreamBuilder
  // Esta clave debe mantenerse constante la mayor parte del tiempo
  static final Key _staticKey = UniqueKey();
  Key streamKey = _staticKey;

  // Modificar este método para que SOLO se use cuando realmente sea necesario
  // como al cambiar filtros, no después de cada carga regular
  void regenerarStreamKey() {
    // SOLO cuando se necesite forzar una reconstrucción completa del StreamBuilder
    streamKey = UniqueKey();
  }
}

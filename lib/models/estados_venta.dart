import 'package:flutter/material.dart';

class EstadosVenta {
  static const int enProceso = 7;
  static const int completada = 8;
  static const int cancelada = 9;

  static const Map<String, String> nombres = {
    '7': 'En proceso',
    '8': 'Completada',
    '9': 'Cancelada',
  };

  static String obtenerNombre(String idEstado) {
    return nombres[idEstado] ?? 'Desconocido';
  }

  static Color obtenerColor(int idEstado) {
    switch (idEstado) {
      case enProceso:
        return Colors.orange;
      case completada:
        return Colors.green;
      case cancelada:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

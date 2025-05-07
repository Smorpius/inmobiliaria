import 'package:flutter/material.dart';
import '../utils/app_colors.dart'; // Importar la clase de colores

class EstadosVenta {
  static const int enProceso = 7;
  static const int completada = 8;
  static const int cancelada = 9;

  static String obtenerNombre(dynamic idEstado) {
    // Convertir a entero si es String
    int id = idEstado is String ? int.tryParse(idEstado) ?? 0 : idEstado;

    switch (id) {
      case enProceso:
        return 'En Proceso';
      case completada:
        return 'Completada';
      case cancelada:
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }

  static Color obtenerColor(int idEstado) {
    switch (idEstado) {
      case enProceso:
        return AppColors.advertencia;
      case completada:
        return AppColors.exito;
      case cancelada:
        return AppColors.error;
      default:
        return AppColors.grisClaro;
    }
  }
}

import 'package:flutter/material.dart';

class AppColors {
  // Colores principales
  static const Color primario = Color.fromRGBO(165, 57, 45, 1); // #A5392D
  static const Color oscuro = Color.fromRGBO(26, 26, 26, 1); // #1A1A1A
  static const Color claro = Color.fromRGBO(247, 245, 242, 1); // #F7F5F2
  static const Color grisClaro = Color.fromRGBO(212, 207, 203, 1); // #D4CFCB
  static const Color acento = Color.fromRGBO(216, 86, 62, 1); // #D8563E

  // Colores semánticos
  static const Color error = Color.fromRGBO(216, 86, 62, 1); // como acento
  static const Color exito = Color.fromRGBO(76, 175, 80, 1); // verde
  static const Color advertencia = Color.fromRGBO(255, 152, 0, 1); // ámbar
  static const Color info = Color.fromRGBO(33, 150, 243, 1); // azul

  // Métodos de utilidad
  static Color withAlpha(Color color, int alpha) {
    return color.withAlpha(alpha);
  }

  static Color withValues({
    required Color color,
    int? red,
    int? green,
    int? blue,
    int? alpha,
  }) {
    return Color.fromRGBO(
      red ?? color.r.toInt(),
      green ?? color.g.toInt(),
      blue ?? color.b.toInt(),
      alpha != null ? alpha / 255 : color.a,
    );
  }
}

import 'package:flutter/material.dart';

/// Clase que centraliza los colores utilizados en los gráficos estadísticos
class ChartColors {
  /// Color para representar ingresos
  static final ingresos = Colors.green.shade700;

  /// Color para representar egresos
  static final egresos = Colors.red.shade700;

  /// Color para representar balance
  static final balance = Colors.blue.shade700;

  /// Color para el fondo de ingresos en gráficos de área
  static Color ingresosBackground = Colors.green.shade100.withAlpha(
    (255 * 0.3).round(),
  );

  /// Color para el fondo de egresos en gráficos de área
  static Color egresosBackground = Colors.red.shade100.withAlpha(
    (255 * 0.3).round(),
  );

  /// Color para el fondo de balance en gráficos de área
  static Color balanceBackground = Colors.blue.shade100.withAlpha(
    (255 * 0.3).round(),
  );

  /// Lista de colores para gráficos de pie y barras múltiples
  static List<Color> pieChartColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.amber,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
  ];

  /// Obtiene un color de la lista de colores para gráficos basado en el índice
  static Color getColorForIndex(int index) {
    return pieChartColors[index % pieChartColors.length];
  }
}

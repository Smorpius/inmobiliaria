import 'package:flutter/material.dart';
import 'app_colors.dart'; // Importar la clase AppColors

/// Clase que centraliza los colores utilizados en los gráficos estadísticos
class ChartColors {
  /// Color para representar ingresos
  static final ingresos = AppColors.exito;

  /// Color para representar egresos
  static final egresos = AppColors.error;

  /// Color para representar balance
  static final balance = AppColors.info;

  /// Color para el fondo de ingresos en gráficos de área
  static Color ingresosBackground = AppColors.withAlpha(
    AppColors.exito,
    77, // aproximadamente 0.3 de opacidad
  );

  /// Color para el fondo de egresos en gráficos de área
  static Color egresosBackground = AppColors.withAlpha(
    AppColors.error,
    77, // aproximadamente 0.3 de opacidad
  );

  /// Color para el fondo de balance en gráficos de área
  static Color balanceBackground = AppColors.withAlpha(
    AppColors.info,
    77, // aproximadamente 0.3 de opacidad
  );

  /// Lista de colores para gráficos de pie y barras múltiples
  static List<Color> pieChartColors = [
    AppColors.info,
    AppColors.exito,
    AppColors.error,
    AppColors.advertencia,
    AppColors.acento,
    AppColors.primario,
    AppColors.oscuro,
  ];

  /// Obtiene un color de la lista de colores para gráficos basado en el índice
  static Color getColorForIndex(int index) {
    return pieChartColors[index % pieChartColors.length];
  }
}

import 'package:flutter/material.dart';

class Responsive {
  final double width;
  final double height;
  final BuildContext context;

  Responsive(this.context)
    : width = MediaQuery.of(context).size.width,
      height = MediaQuery.of(context).size.height;

  static Responsive of(BuildContext context) => Responsive(context);

  // Breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;

  // Getters para determinar el tipo de dispositivo
  bool get isMobile => width < _mobileBreakpoint;
  bool get isTablet => width >= _mobileBreakpoint && width < _tabletBreakpoint;
  bool get isDesktop => width >= _tabletBreakpoint;

  // Funciones para obtener porcentajes de la pantalla
  double wp(double percent) => width * percent / 100;
  double hp(double percent) => height * percent / 100;

  // Funciones para obtener tamaños adaptados a la pantalla
  double getProportionalWidth(double value) {
    // Usando un diseño base de 375 (como iPhone X)
    const double designWidth = 375;
    return (value / designWidth) * width;
  }

  double getProportionalHeight(double value) {
    // Usando un diseño base de 812 (como iPhone X)
    const double designHeight = 812;
    return (value / designHeight) * height;
  }

  // Obtener tamaños adaptables para fuentes
  double sp(double size) {
    if (isDesktop) return size * 1.0;
    if (isTablet) return size * 0.9;
    return size * 0.85;
  }

  // Obtener padding adaptable según el tamaño de pantalla
  EdgeInsets get screenPadding {
    if (isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }
}

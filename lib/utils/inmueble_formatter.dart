class InmuebleFormatter {
  // Formateo de tipo de inmueble para mostrar con primera letra mayúscula
  static String formatTipoInmueble(String tipo) {
    return tipo[0].toUpperCase() + tipo.substring(1);
  }

  // Formateo del tipo de operación para mostrar con primera letra mayúscula
  static String formatTipoOperacion(String tipo) {
    return tipo[0].toUpperCase() + tipo.substring(1);
  }

  // Formatea montos a formato de moneda
  static String formatMonto(double? monto) {
    if (monto == null) return 'No especificado';
    return '\$${monto.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  // Obtiene el estado del inmueble a partir del idEstado
  static String obtenerEstadoInmueble(int? idEstado) {
    switch (idEstado) {
      case 1:
        return 'Activo';
      case 2:
        return 'Inactivo';
      case 3:
        return 'Disponible';
      case 4:
        return 'Vendido';
      case 5:
        return 'Rentado';
      case 6:
        return 'En Negociación';
      default:
        return 'No especificado';
    }
  }
}

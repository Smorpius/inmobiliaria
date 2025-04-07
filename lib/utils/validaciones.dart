/// Clase utilitaria para centralizar las validaciones comunes del sistema
///
/// Esta clase proporciona métodos estáticos para validar datos de entrada
/// como correos electrónicos, teléfonos, RFC, CURP y otros datos comunes.
class Validaciones {
  /// Valida que un correo electrónico tenga formato válido
  static bool esCorreoValido(String correo) {
    if (correo.isEmpty) return false;
    return RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(correo);
  }

  /// Valida que un número de teléfono tenga formato válido
  static bool esTelefonoValido(String telefono) {
    if (telefono.isEmpty) return false;
    return RegExp(r'^[+]?[0-9]{10,15}$').hasMatch(telefono);
  }

  /// Valida que un RFC mexicano tenga formato válido
  static bool esRfcValido(String rfc) {
    if (rfc.isEmpty) return false;
    // Formato para personas físicas y morales
    return RegExp(
      r'^[A-Z&Ñ]{3,4}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[A-Z0-9]{3}$',
    ).hasMatch(rfc);
  }

  /// Valida que una CURP mexicana tenga formato válido
  static bool esCurpValido(String curp) {
    if (curp.isEmpty) return false;
    return RegExp(
      r'^[A-Z][AEIOUX][A-Z]{2}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[HM][A-Z]{2}[BCDFGHJKLMNPQRSTVWXYZ]{3}[0-9A-Z][0-9]$',
    ).hasMatch(curp);
  }

  /// Valida que un código postal mexicano tenga formato válido
  static bool esCodigoPostalValido(String cp) {
    if (cp.isEmpty) return false;
    return RegExp(r'^[0-9]{5}$').hasMatch(cp);
  }

  /// Valida que una cadena no esté vacía y tenga una longitud mínima
  static bool esCadenaValida(String texto, {int longitudMinima = 1}) {
    return texto.isNotEmpty && texto.length >= longitudMinima;
  }

  /// Valida que un precio o monto tenga un valor válido
  static bool esMontoValido(double? monto, {double minimo = 0.0}) {
    if (monto == null) return false;
    return monto >= minimo && !monto.isNaN && !monto.isInfinite;
  }

  /// Valida que una fecha esté dentro de un rango válido
  static bool esFechaValida(
    DateTime? fecha, {
    DateTime? minima,
    DateTime? maxima,
  }) {
    if (fecha == null) return false;

    if (minima != null && fecha.isBefore(minima)) {
      return false;
    }

    if (maxima != null && fecha.isAfter(maxima)) {
      return false;
    }

    return true;
  }

  /// Valida que una fecha no sea futura (útil para fechas de nacimiento)
  static bool esNoFutura(DateTime fecha) {
    final ahora = DateTime.now();
    return !fecha.isAfter(ahora);
  }

  /// Valida que un nombre de usuario sea válido
  static bool esNombreUsuarioValido(String nombreUsuario) {
    if (nombreUsuario.isEmpty) return false;
    // Al menos 4 caracteres, letras, números y guiones bajos
    return RegExp(r'^[a-zA-Z0-9_]{4,20}$').hasMatch(nombreUsuario);
  }

  /// Valida que una contraseña cumpla con requisitos de seguridad
  static bool esContrasenaValida(String contrasena) {
    if (contrasena.length < 8) return false;

    // Al menos una letra mayúscula, una minúscula y un número
    final tieneMinuscula = RegExp(r'[a-z]').hasMatch(contrasena);
    final tieneMayuscula = RegExp(r'[A-Z]').hasMatch(contrasena);
    final tieneNumero = RegExp(r'[0-9]').hasMatch(contrasena);

    return tieneMinuscula && tieneMayuscula && tieneNumero;
  }

  /// Obtiene errores específicos para una contraseña
  static List<String> validarContrasena(String contrasena) {
    final errores = <String>[];

    if (contrasena.length < 8) {
      errores.add('La contraseña debe tener al menos 8 caracteres');
    }

    if (!RegExp(r'[a-z]').hasMatch(contrasena)) {
      errores.add('Debe incluir al menos una letra minúscula');
    }

    if (!RegExp(r'[A-Z]').hasMatch(contrasena)) {
      errores.add('Debe incluir al menos una letra mayúscula');
    }

    if (!RegExp(r'[0-9]').hasMatch(contrasena)) {
      errores.add('Debe incluir al menos un número');
    }

    return errores;
  }
}

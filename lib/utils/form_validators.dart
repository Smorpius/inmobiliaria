class FormValidators {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  static String? validateNombre(String? value) {
    final nombre = value?.trim() ?? '';
    if (nombre.isEmpty) return "Ingrese un nombre";
    if (nombre.length < 2) {
      return "El nombre es demasiado corto";
    }
    return null;
  }

  static String? validateApellido(String? value) {
    final apellido = value?.trim() ?? '';
    if (apellido.isEmpty) return "Ingrese un apellido";
    if (apellido.length < 2) {
      return "El apellido es demasiado corto";
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final correo = value?.trim() ?? '';
    if (correo.isEmpty) return "Ingrese un email";
    if (!isValidEmail(correo)) return "Email inválido";
    return null;
  }

  static String? validateUsername(String? value) {
    final nombreUser = value?.trim() ?? '';
    if (nombreUser.isEmpty) {
      return "Ingrese un nombre de usuario";
    }
    if (nombreUser.length < 4) {
      return "El nombre de usuario es demasiado corto";
    }
    if (nombreUser.contains(" ")) {
      return "El nombre de usuario no debe contener espacios";
    }
    return null;
  }

  static String? validatePassword(String? value, bool isEditing) {
    final pass = value?.trim() ?? '';
    if (!isEditing && pass.isEmpty) {
      return "Ingrese una contraseña";
    }
    if (pass.isNotEmpty && pass.length < 8) {
      return "La contraseña debe tener al menos 8 caracteres";
    }
    return null;
  }
}

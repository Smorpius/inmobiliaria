import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart'; // Importar AppColors

/// Clase para formatear el teléfono mientras se escribe
class TelefonoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si el usuario está eliminando caracteres, permitirlo sin formatear
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    // Limpiar el texto de formatos
    final String cleanText = newValue.text.replaceAll(RegExp(r'[-\s]'), '');

    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Aplicar formato: XXX-XXX-XXXX
    String formattedText = cleanText;
    if (cleanText.length > 3) {
      formattedText = '${cleanText.substring(0, 3)}-${cleanText.substring(3)}';
    }
    if (cleanText.length > 6) {
      formattedText =
          '${formattedText.substring(0, 7)}-${formattedText.substring(7)}';
    }

    // Limitar a 10 dígitos (12 caracteres con guiones)
    if (cleanText.length > 10) {
      formattedText = formattedText.substring(0, 12);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

/// Funciones de validación comunes
class EmpleadoValidators {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Estilos y decoraciones comunes
class EmpleadoStyles {
  static InputDecoration getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: AppColors.primario,
      ), // Aplicar color primario
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.acento,
          width: 2,
        ), // Aplicar color de acento
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}

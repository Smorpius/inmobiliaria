import 'package:flutter/material.dart';

class UIHelpers {
  static void mostrarSnackbar({
    required BuildContext context,
    required String mensaje,
    bool isError = false,
    Duration? duracion,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: duracion ?? Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  static void mostrarExito(BuildContext context, String mensaje) {
    mostrarSnackbar(context: context, mensaje: mensaje, isError: false);
  }

  static void mostrarError(BuildContext context, String mensaje) {
    mostrarSnackbar(context: context, mensaje: mensaje, isError: true);
  }

  // Verifica si los cambios de formulario son válidos para habilitar/deshabilitar botones
  static bool hayCambiosValidos({
    required bool isEditing,
    required List<TextEditingController> controllers,
    required Map<String, String> valoresOriginales,
  }) {
    if (!isEditing) {
      // Para nuevo registro, verificar que todos tengan valor
      return controllers.every(
        (controller) => controller.text.trim().isNotEmpty,
      );
    }

    // Para edición, verificar que al menos uno haya cambiado
    for (var i = 0; i < controllers.length; i++) {
      final key = controllers[i].text.trim();
      final originalValue = valoresOriginales[key] ?? '';
      if (key != originalValue) {
        return true;
      }
    }

    return false;
  }
}

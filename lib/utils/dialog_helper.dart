import 'package:flutter/material.dart';

class DialogHelper {
  // Método existente
  static void mostrarDialogoCarga(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(mensaje),
            ],
          ),
        );
      },
    );
  }

  // Método existente
  static Future<bool> mostrarConfirmacion({
    required BuildContext context,
    required String titulo,
    required String mensaje,
    String? confirmText,
    String? cancelText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText ?? 'Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: Text(confirmText ?? 'Confirmar'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // NUEVOS MÉTODOS NECESARIOS

  /// Muestra un mensaje de error
  static Future<void> mostrarMensajeError(
    BuildContext context,
    String titulo,
    String mensaje,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un mensaje de éxito
  static Future<void> mostrarMensajeExito(
    BuildContext context,
    String mensaje,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Éxito'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo de confirmación para una acción
  static Future<bool> confirmarAccion(
    BuildContext context,
    String titulo,
    String mensaje,
    String textoBoton,
    TextStyle estilo,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(textoBoton, style: estilo),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

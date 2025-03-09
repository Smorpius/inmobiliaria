import 'package:flutter/material.dart';

class DialogHelper {
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
}

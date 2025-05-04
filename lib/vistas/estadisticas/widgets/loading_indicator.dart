import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String mensaje;
  final double? size;
  final double strokeWidth;

  const LoadingIndicator({
    super.key,
    this.mensaje = 'Cargando datos...',
    this.size,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (mensaje.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ],
      ),
    );
  }
}

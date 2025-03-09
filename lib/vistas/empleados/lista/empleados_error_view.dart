import 'package:flutter/material.dart';

class EmpleadosErrorView extends StatelessWidget {
  final String errorMessage;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;

  const EmpleadosErrorView({
    super.key,
    required this.errorMessage,
    this.stackTrace,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar datos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Detalles del error'),
                      content: SingleChildScrollView(
                        child: SelectableText(
                          stackTrace?.toString() ??
                              'No hay detalles disponibles',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
              );
            },
            child: const Text('Ver detalles técnicos'),
          ),
        ],
      ),
    );
  }
}

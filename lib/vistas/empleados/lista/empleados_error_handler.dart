import 'empleados_estado.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';

mixin EmpleadosErrorHandler<T extends StatefulWidget> on State<T> {
  late BuildContext _context;
  late EmpleadosEstado _estado;

  void inicializarErrorHandler(BuildContext context) {
    _context = context;
    _estado = (this as dynamic).estado;
  }

  void manejarError(dynamic error, [StackTrace? stackTrace]) {
    if (!mounted) return;

    stackTrace ??= StackTrace.current;
    developer.log('Error: $error', error: error, stackTrace: stackTrace);

    setState(() {
      _estado.establecerError(error.toString(), stackTrace);
    });

    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(
        content: Text('Error: ${error.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Detalles',
          onPressed: () => _mostrarDialogoError(error, stackTrace!),
          textColor: Colors.white,
        ),
      ),
    );
  }

  void _mostrarDialogoError(Object error, StackTrace stackTrace) {
    showDialog(
      context: _context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error al cargar empleados'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Detalles del error:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString()),
                  const SizedBox(height: 16),
                  const Text(
                    'Stack trace:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey.shade200,
                    child: Text(
                      stackTrace.toString().length > 500
                          ? '${stackTrace.toString().substring(0, 500)}...'
                          : stackTrace.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  (this as dynamic).cargarEmpleados();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
    );
  }
}

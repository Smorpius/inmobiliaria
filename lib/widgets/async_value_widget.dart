import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final Widget? loadingWidget;
  final Widget Function(Object, StackTrace?)? errorWidget;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading:
          () =>
              loadingWidget ?? const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) =>
              errorWidget?.call(error, stackTrace) ??
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${error.toString()}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // En un caso real, se implementaría la lógica de reintentar
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
    );
  }
}

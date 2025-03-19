import 'package:flutter/material.dart';
import 'dart:async'; // Esta importación falta para usar Timer

class ProveedoresBusqueda extends StatefulWidget {
  final Function(String) onSearch;
  final bool isLoading;

  const ProveedoresBusqueda({
    super.key,
    required this.onSearch,
    this.isLoading = false,
  });

  @override
  State<ProveedoresBusqueda> createState() => _ProveedoresBusquedaState();
}

class _ProveedoresBusquedaState extends State<ProveedoresBusqueda> {
  final _searchController = TextEditingController();
  final _debounce = _Debounce(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (!widget.isLoading) {
      _debounce.run(() {
        widget.onSearch(_searchController.text);
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar proveedores...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
          enabled: !widget.isLoading,
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

// Clase auxiliar para limitar las llamadas de búsqueda
class _Debounce {
  final int milliseconds;
  Timer? _timer;

  _Debounce({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
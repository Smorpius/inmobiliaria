import 'package:flutter/material.dart';
import '../../../providers/documento_provider.dart';
import '../../../utils/app_colors.dart'; // Importar la paleta de colores

class FiltroDocumentosWidget extends StatefulWidget {
  final DocumentoFiltro filtro;
  final Function(DocumentoFiltro) onFiltroChanged;

  const FiltroDocumentosWidget({
    super.key,
    required this.filtro,
    required this.onFiltroChanged,
  });

  @override
  State<FiltroDocumentosWidget> createState() => _FiltroDocumentosWidgetState();
}

class _FiltroDocumentosWidgetState extends State<FiltroDocumentosWidget> {
  late TextEditingController _busquedaController;
  late String? _tipoSeleccionado;
  late String? _categoriaSeleccionada;
  late bool _soloFavoritos;

  @override
  void initState() {
    super.initState();
    _busquedaController = TextEditingController(
      text: widget.filtro.terminoBusqueda,
    );
    _tipoSeleccionado = widget.filtro.tipoDocumento;
    _categoriaSeleccionada = widget.filtro.categoria;
    _soloFavoritos = widget.filtro.soloFavoritos;
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.claro, // Usar AppColors
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de búsqueda
          TextField(
            controller: _busquedaController,
            decoration: InputDecoration(
              labelText: 'Buscar documentos',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
              suffixIcon:
                  _busquedaController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaController.clear();
                          _actualizarFiltro();
                        },
                      )
                      : null,
            ),
            onChanged: (_) => _actualizarFiltro(),
          ),

          const SizedBox(height: 16),

          // Filtros adicionales
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // Tipo de documento
              DropdownButton<String>(
                hint: const Text('Tipo de documento'),
                value: _tipoSeleccionado,
                underline: Container(
                  height: 2,
                  color: AppColors.primario, // Usar AppColors
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _tipoSeleccionado = newValue;
                    _actualizarFiltro();
                  });
                },
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos los tipos')),
                  DropdownMenuItem(value: 'contrato', child: Text('Contratos')),
                  DropdownMenuItem(
                    value: 'comprobante',
                    child: Text('Comprobantes'),
                  ),
                  DropdownMenuItem(value: 'reporte', child: Text('Reportes')),
                  DropdownMenuItem(value: 'documento', child: Text('Otros')),
                ],
              ),

              // Categoría
              DropdownButton<String>(
                hint: const Text('Categoría'),
                value: _categoriaSeleccionada,
                underline: Container(
                  height: 2,
                  color: AppColors.primario, // Usar AppColors
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _categoriaSeleccionada = newValue;
                    _actualizarFiltro();
                  });
                },
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Todas las categorías'),
                  ),
                  DropdownMenuItem(value: 'venta', child: Text('Ventas')),
                  DropdownMenuItem(value: 'renta', child: Text('Rentas')),
                  DropdownMenuItem(
                    value: 'movimiento',
                    child: Text('Movimientos'),
                  ),
                  DropdownMenuItem(
                    value: 'estadística',
                    child: Text('Estadísticas'),
                  ),
                  DropdownMenuItem(value: 'general', child: Text('General')),
                ],
              ),

              // Checkbox para favoritos
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _soloFavoritos,
                    activeColor: AppColors.primario, // Usar AppColors
                    onChanged: (bool? value) {
                      setState(() {
                        _soloFavoritos = value ?? false;
                        _actualizarFiltro();
                      });
                    },
                  ),
                  const Text('Solo favoritos'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botón para limpiar filtros si hay alguno activo
          if (_hayFiltrosActivos())
            ElevatedButton.icon(
              onPressed: _limpiarFiltros,
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primario, // Usar AppColors
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  bool _hayFiltrosActivos() {
    return _busquedaController.text.isNotEmpty ||
        _tipoSeleccionado != null ||
        _categoriaSeleccionada != null ||
        _soloFavoritos;
  }

  void _limpiarFiltros() {
    setState(() {
      _busquedaController.clear();
      _tipoSeleccionado = null;
      _categoriaSeleccionada = null;
      _soloFavoritos = false;
      _actualizarFiltro();
    });
  }

  void _actualizarFiltro() {
    final nuevoFiltro = DocumentoFiltro(
      terminoBusqueda: _busquedaController.text,
      tipoDocumento: _tipoSeleccionado,
      categoria: _categoriaSeleccionada,
      soloFavoritos: _soloFavoritos,
    );
    widget.onFiltroChanged(nuevoFiltro);
  }
}

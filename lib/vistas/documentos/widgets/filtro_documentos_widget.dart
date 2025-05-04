import 'package:flutter/material.dart';
import '../../../providers/documento_provider.dart';

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
  late TextEditingController _buscadorController;

  final List<String> _tiposDocumento = [
    'contrato',
    'comprobante',
    'reporte',
    'documento',
  ];

  final List<String> _categorias = [
    'venta',
    'renta',
    'movimiento',
    'estadística',
    'general',
  ];

  @override
  void initState() {
    super.initState();
    _buscadorController = TextEditingController(
      text: widget.filtro.terminoBusqueda,
    );
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador
          TextField(
            controller: _buscadorController,
            decoration: InputDecoration(
              hintText: 'Buscar documentos...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _buscadorController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscadorController.clear();
                          _actualizarFiltro(terminoBusqueda: '');
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => _actualizarFiltro(terminoBusqueda: value),
          ),

          const SizedBox(height: 16),

          // Filtros de tipo y categoría
          Row(
            children: [
              // Tipo de documento
              Expanded(
                child: _buildDropdown(
                  label: 'Tipo',
                  value: widget.filtro.tipoDocumento,
                  items: _tiposDocumento,
                  itemBuilder: (tipo) => Text(_formatearTexto(tipo)),
                  onChanged:
                      (String? value) =>
                          _actualizarFiltro(tipoDocumento: value),
                ),
              ),

              const SizedBox(width: 16),

              // Categoría
              Expanded(
                child: _buildDropdown(
                  label: 'Categoría',
                  value: widget.filtro.categoria,
                  items: _categorias,
                  itemBuilder: (categoria) => Text(_formatearTexto(categoria)),
                  onChanged:
                      (String? value) => _actualizarFiltro(categoria: value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Opciones adicionales
          Row(
            children: [
              // Favoritos
              FilterChip(
                label: const Text('Favoritos'),
                selected: widget.filtro.soloFavoritos,
                onSelected:
                    (selected) => _actualizarFiltro(soloFavoritos: selected),
                avatar: const Icon(Icons.star),
              ),

              const SizedBox(width: 8),

              // Botón para limpiar filtros
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
                onPressed: _limpiarFiltros,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    required void Function(T?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: const Text('Todos'),
          items: [
            DropdownMenuItem<T>(child: const Text('Todos')),
            ...items.map(
              (item) =>
                  DropdownMenuItem<T>(value: item, child: itemBuilder(item)),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _actualizarFiltro({
    String? terminoBusqueda,
    String? tipoDocumento,
    String? categoria,
    bool? soloFavoritos,
  }) {
    final nuevoFiltro = DocumentoFiltro(
      terminoBusqueda: terminoBusqueda ?? widget.filtro.terminoBusqueda,
      tipoDocumento: tipoDocumento,
      categoria: categoria,
      soloFavoritos: soloFavoritos ?? widget.filtro.soloFavoritos,
    );

    widget.onFiltroChanged(nuevoFiltro);
  }

  void _limpiarFiltros() {
    _buscadorController.clear();
    widget.onFiltroChanged(DocumentoFiltro());
  }

  String _formatearTexto(String texto) {
    if (texto.isEmpty) return '';
    return "${texto[0].toUpperCase()}${texto.substring(1).toLowerCase()}";
  }
}

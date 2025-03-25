import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InmuebleFiltroAvanzado extends StatefulWidget {
  final Function({
    String? tipo,
    String? operacion,
    double? precioMin,
    double? precioMax,
    String? ciudad,
    int? idEstado,
    double? margenMin, // Añadido nuevo parámetro
  })
  onFiltrar;

  final Function() onLimpiar;

  const InmuebleFiltroAvanzado({
    super.key,
    required this.onFiltrar,
    required this.onLimpiar,
  });

  @override
  State<InmuebleFiltroAvanzado> createState() => _InmuebleFiltroAvanzadoState();
}

class _InmuebleFiltroAvanzadoState extends State<InmuebleFiltroAvanzado> {
  bool _isExpanded = false;

  // Controladores para los campos de filtro
  final _precioMinController = TextEditingController();
  final _precioMaxController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _margenMinController =
      TextEditingController(); // Nuevo controlador para margen mínimo

  String? _tipoInmuebleSeleccionado;
  String? _tipoOperacionSeleccionado;
  int? _estadoSeleccionado;

  final _formKey = GlobalKey<FormState>();

  final List<String> _tiposInmueble = [
    'casa',
    'departamento',
    'terreno',
    'oficina',
    'bodega',
    'otro',
  ];

  final List<String> _tiposOperacion = ['venta', 'renta'];

  final Map<int, String> _estados = {
    3: 'Disponible',
    6: 'En Negociación',
    4: 'Vendido',
    5: 'Rentado',
  };

  @override
  void dispose() {
    _precioMinController.dispose();
    _precioMaxController.dispose();
    _ciudadController.dispose();
    _margenMinController.dispose(); // Liberar recursos del nuevo controlador
    super.dispose();
  }

  void _limpiarFiltros() {
    setState(() {
      _precioMinController.clear();
      _precioMaxController.clear();
      _ciudadController.clear();
      _margenMinController.clear(); // Limpiar el nuevo campo
      _tipoInmuebleSeleccionado = null;
      _tipoOperacionSeleccionado = null;
      _estadoSeleccionado = null;
    });

    widget.onLimpiar();
  }

  void _aplicarFiltros() {
    if (_formKey.currentState?.validate() ?? false) {
      // Convertir valores de precio a double si están presentes
      double? precioMin;
      double? precioMax;
      double? margenMin; // Variable para el margen mínimo

      if (_precioMinController.text.isNotEmpty) {
        precioMin = double.tryParse(_precioMinController.text);
      }

      if (_precioMaxController.text.isNotEmpty) {
        precioMax = double.tryParse(_precioMaxController.text);
      }

      // Convertir valor de margen mínimo a double si está presente
      if (_margenMinController.text.isNotEmpty) {
        margenMin = double.tryParse(_margenMinController.text);
      }

      widget.onFiltrar(
        tipo: _tipoInmuebleSeleccionado,
        operacion: _tipoOperacionSeleccionado,
        precioMin: precioMin,
        precioMax: precioMax,
        ciudad: _ciudadController.text.isEmpty ? null : _ciudadController.text,
        idEstado: _estadoSeleccionado,
        margenMin: margenMin, // Incluir el margen mínimo en el filtro
      );

      // Cerrar el panel de filtros
      setState(() {
        _isExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botón para expandir/contraer el panel de filtros
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Filtros Avanzados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
            // Panel de filtros (visible solo cuando está expandido)
            if (_isExpanded) _buildFilterForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filtro por tipo de inmueble
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Inmueble',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              value: _tipoInmuebleSeleccionado,
              hint: const Text('Seleccione un tipo'),
              items:
                  _tiposInmueble.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(
                        tipo.substring(0, 1).toUpperCase() + tipo.substring(1),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoInmuebleSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Filtro por tipo de operación
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Operación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sell),
              ),
              value: _tipoOperacionSeleccionado,
              hint: const Text('Seleccione operación'),
              items:
                  _tiposOperacion.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(
                        tipo.substring(0, 1).toUpperCase() + tipo.substring(1),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoOperacionSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Filtro por estado
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              value: _estadoSeleccionado,
              hint: const Text('Seleccione estado'),
              items:
                  _estados.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _estadoSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Filtros de precio (min y max)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precioMinController,
                    decoration: const InputDecoration(
                      labelText: 'Precio Mínimo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final precio = double.tryParse(value);
                        if (precio == null) {
                          return 'Ingrese un número válido';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _precioMaxController,
                    decoration: const InputDecoration(
                      labelText: 'Precio Máximo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final precio = double.tryParse(value);
                        if (precio == null) {
                          return 'Ingrese un número válido';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filtro por ciudad
            TextFormField(
              controller: _ciudadController,
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 16),

            // Nuevo filtro por margen de utilidad mínimo
            TextFormField(
              controller: _margenMinController,
              decoration: const InputDecoration(
                labelText: 'Margen de Utilidad Mínimo (%)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.trending_up),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final margen = double.tryParse(value);
                  if (margen == null) {
                    return 'Ingrese un número válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _limpiarFiltros,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpiar Filtros'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _aplicarFiltros,
                    icon: const Icon(Icons.search),
                    label: const Text('Aplicar Filtros'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

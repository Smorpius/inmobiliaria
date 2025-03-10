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
    super.dispose();
  }

  void _limpiarFiltros() {
    setState(() {
      _precioMinController.clear();
      _precioMaxController.clear();
      _ciudadController.clear();
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

      if (_precioMinController.text.isNotEmpty) {
        precioMin = double.tryParse(
          _precioMinController.text.replaceAll(',', ''),
        );
      }

      if (_precioMaxController.text.isNotEmpty) {
        precioMax = double.tryParse(
          _precioMaxController.text.replaceAll(',', ''),
        );
      }

      widget.onFiltrar(
        tipo: _tipoInmuebleSeleccionado,
        operacion: _tipoOperacionSeleccionado,
        precioMin: precioMin,
        precioMax: precioMax,
        ciudad:
            _ciudadController.text.isNotEmpty ? _ciudadController.text : null,
        idEstado: _estadoSeleccionado,
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
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 * 255 = 26 (redondeado)
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabecera del filtro
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros Avanzados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),

          // Contenido del filtro (expandible)
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: _buildFilterForm(),
            crossFadeState:
                _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 16),

            // Filtro por tipo de inmueble
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Inmueble',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              value: _tipoInmuebleSeleccionado,
              onChanged: (value) {
                setState(() {
                  _tipoInmuebleSeleccionado = value;
                });
              },
              items:
                  _tiposInmueble.map((tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo,
                      child: Text(tipo[0].toUpperCase() + tipo.substring(1)),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            // Filtro por tipo de operación
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Operación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.real_estate_agent),
              ),
              value: _tipoOperacionSeleccionado,
              onChanged: (value) {
                setState(() {
                  _tipoOperacionSeleccionado = value;
                });
              },
              items:
                  _tiposOperacion.map((tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo,
                      child: Text(tipo[0].toUpperCase() + tipo.substring(1)),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            // Filtro por rango de precios
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final price = double.tryParse(value);
                        if (price == null) {
                          return 'Ingrese un valor válido';
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final price = double.tryParse(value);
                        if (price == null) {
                          return 'Ingrese un valor válido';
                        }

                        if (_precioMinController.text.isNotEmpty) {
                          final minPrice = double.tryParse(
                            _precioMinController.text,
                          );
                          if (minPrice != null && price < minPrice) {
                            return 'Debe ser mayor que el precio mínimo';
                          }
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

            // Filtro por estado del inmueble
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Estado del Inmueble',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.check_circle),
              ),
              value: _estadoSeleccionado,
              onChanged: (value) {
                setState(() {
                  _estadoSeleccionado = value;
                });
              },
              items:
                  _estados.entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _limpiarFiltros,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Limpiar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _aplicarFiltros,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.search),
                  label: const Text('Aplicar Filtros'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

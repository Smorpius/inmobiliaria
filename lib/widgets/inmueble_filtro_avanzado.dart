import '../utils/applogger.dart';
import 'package:flutter/material.dart';

/// Widget que proporciona filtros avanzados para la búsqueda de inmuebles.
///
/// Permite filtrar por tipo, operación, precio, ciudad, estado y margen de utilidad.
/// Implementa manejo de errores con AppLogger y optimiza operaciones para evitar congelamientos.
class InmuebleFiltroAvanzado extends StatefulWidget {
  /// Callback que se ejecuta cuando se aplican los filtros.
  final Function({
    String? tipo,
    String? operacion,
    double? precioMin,
    double? precioMax,
    String? ciudad,
    int? idEstado,
    double? margenMin,
  })
  onFiltrar;

  /// Callback que se ejecuta cuando se limpian los filtros.
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
  // Control para evitar operaciones duplicadas
  bool _operacionEnProceso = false;

  // Controladores para los campos de filtro
  final _precioMinController = TextEditingController();
  final _precioMaxController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _margenMinController = TextEditingController();

  // Variables para almacenar los valores seleccionados
  String? _tipoInmuebleSeleccionado;
  String? _tipoOperacionSeleccionado;
  int? _estadoSeleccionado;

  // Datos para los desplegables
  final List<String> _tiposInmueble = [
    'casa',
    'departamento',
    'terreno',
    'oficina',
    'bodega',
    'otro',
  ];

  final List<String> _tiposOperacion = ['venta', 'renta', 'ambos'];

  final Map<int, String> _estados = {
    3: 'Disponible',
    6: 'En Negociación',
    4: 'Vendido',
    5: 'Rentado',
  };

  @override
  void initState() {
    super.initState();
    AppLogger.debug('Inicializando widget InmuebleFiltroAvanzado');
  }

  @override
  void dispose() {
    // Liberar recursos
    _precioMinController.dispose();
    _precioMaxController.dispose();
    _ciudadController.dispose();
    _margenMinController.dispose();

    AppLogger.debug('Liberando recursos de InmuebleFiltroAvanzado');
    super.dispose();
  }

  /// Limpia todos los filtros y notifica al widget padre
  void _limpiarFiltros() {
    try {
      if (_operacionEnProceso) {
        AppLogger.info(
          'Operación en proceso, ignorando solicitud de limpiar filtros',
        );
        return;
      }

      _operacionEnProceso = true;

      AppLogger.info('Limpiando todos los filtros avanzados');
      setState(() {
        _precioMinController.clear();
        _precioMaxController.clear();
        _ciudadController.clear();
        _margenMinController.clear();
        _tipoInmuebleSeleccionado = null;
        _tipoOperacionSeleccionado = null;
        _estadoSeleccionado = null;
      });

      widget.onLimpiar();
    } catch (e, stackTrace) {
      AppLogger.error('Error al limpiar filtros', e, stackTrace);
    } finally {
      _operacionEnProceso = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del filtro
          const Text(
            'Filtros Avanzados',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Campos de filtro
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildDropdownField(
                label: 'Tipo de Inmueble',
                value: _tipoInmuebleSeleccionado,
                items: _tiposInmueble,
                onChanged: (value) {
                  setState(() {
                    _tipoInmuebleSeleccionado = value;
                  });
                },
              ),
              _buildDropdownField(
                label: 'Tipo de Operación',
                value: _tipoOperacionSeleccionado,
                items: _tiposOperacion,
                onChanged: (value) {
                  setState(() {
                    _tipoOperacionSeleccionado = value;
                  });
                },
              ),
              _buildDropdownField(
                label: 'Estado',
                value: _estadoSeleccionado?.toString(),
                items: _estados.values.toList(),
                onChanged: (value) {
                  setState(() {
                    _estadoSeleccionado =
                        _estados.entries
                            .firstWhere((entry) => entry.value == value)
                            .key;
                  });
                },
              ),
              _buildTextField(
                label: 'Precio Mínimo',
                controller: _precioMinController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                label: 'Precio Máximo',
                controller: _precioMaxController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(label: 'Ciudad', controller: _ciudadController),
              _buildTextField(
                label: 'Margen de Utilidad Mínimo (%)',
                controller: _margenMinController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _operacionEnProceso ? null : _limpiarFiltros,
                icon: const Icon(Icons.clear, color: Colors.red),
                label: const Text(
                  'Limpiar Filtros',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton.icon(
                onPressed:
                    _operacionEnProceso
                        ? null
                        : () {
                          widget.onFiltrar(
                            tipo: _tipoInmuebleSeleccionado,
                            operacion: _tipoOperacionSeleccionado,
                            idEstado: _estadoSeleccionado,
                            precioMin: double.tryParse(
                              _precioMinController.text,
                            ),
                            precioMax: double.tryParse(
                              _precioMaxController.text,
                            ),
                            ciudad: _ciudadController.text,
                            margenMin: double.tryParse(
                              _margenMinController.text,
                            ),
                          );
                        },
                icon: const Icon(Icons.filter_list),
                label: const Text('Aplicar Filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        value: value,
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      width: 180,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

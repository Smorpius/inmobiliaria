import 'dart:async';
import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _isExpanded = false;

  // Control para evitar operaciones duplicadas
  bool _operacionEnProceso = false;

  // Control para debounce de operaciones
  Timer? _debounceTimer;

  // Controladores para los campos de filtro
  final _precioMinController = TextEditingController();
  final _precioMaxController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _margenMinController = TextEditingController();

  // Variables para almacenar los valores seleccionados
  String? _tipoInmuebleSeleccionado;
  String? _tipoOperacionSeleccionado;
  int? _estadoSeleccionado;

  final _formKey = GlobalKey<FormState>();

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

  // Mapa para registrar errores previos y evitar duplicados
  final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _tiempoMinimoEntreErrores = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    AppLogger.debug('Inicializando widget InmuebleFiltroAvanzado');
    _inicializarControladores();
  }

  /// Inicializa los controladores de texto y valores por defecto
  void _inicializarControladores() {
    try {
      // No hay valores por defecto que establecer
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'inicializar_controladores',
        'Error al inicializar controladores de filtros',
        e,
        stackTrace,
      );
    }
  }

  @override
  void dispose() {
    // Cancelar operaciones pendientes
    _debounceTimer?.cancel();

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
      _registrarErrorControlado(
        'limpiar_filtros',
        'Error al limpiar filtros',
        e,
        stackTrace,
      );
    } finally {
      _operacionEnProceso = false;
    }
  }

  /// Aplica los filtros con validación y manejo de errores
  void _aplicarFiltros() {
    // Evitar múltiples pulsaciones rápidas
    if (_operacionEnProceso) {
      AppLogger.info(
        'Operación en proceso, ignorando solicitud de aplicar filtros',
      );
      return;
    }

    // Cancelar operaciones pendientes
    _debounceTimer?.cancel();

    try {
      _operacionEnProceso = true;

      // Validar el formulario
      if (_formKey.currentState?.validate() ?? false) {
        AppLogger.info('Aplicando filtros avanzados');

        // Convertir valores de precio a double si están presentes
        double? precioMin;
        double? precioMax;
        double? margenMin;

        try {
          if (_precioMinController.text.isNotEmpty) {
            precioMin = double.tryParse(_precioMinController.text);
            if (precioMin == null) {
              AppLogger.warning(
                'No se pudo convertir precio mínimo: ${_precioMinController.text}',
              );
            }
          }

          if (_precioMaxController.text.isNotEmpty) {
            precioMax = double.tryParse(_precioMaxController.text);
            if (precioMax == null) {
              AppLogger.warning(
                'No se pudo convertir precio máximo: ${_precioMaxController.text}',
              );
            }
          }

          // Convertir valor de margen mínimo a double si está presente
          if (_margenMinController.text.isNotEmpty) {
            margenMin = double.tryParse(_margenMinController.text);
            if (margenMin == null) {
              AppLogger.warning(
                'No se pudo convertir margen mínimo: ${_margenMinController.text}',
              );
            }
          }
        } catch (e, stackTrace) {
          _registrarErrorControlado(
            'conversion_valores',
            'Error al convertir valores de filtro',
            e,
            stackTrace,
          );
        }

        // Validar que el rango de precios sea lógico
        if (precioMin != null && precioMax != null && precioMin > precioMax) {
          AppLogger.warning(
            'Rango de precios inválido: mín=$precioMin, máx=$precioMax',
          );
          _mostrarMensajeValidacion(
            'El precio mínimo no puede ser mayor que el precio máximo',
          );
          _operacionEnProceso = false;
          return;
        }

        // Aplicar debounce para evitar múltiples llamadas
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          // Ejecutar la función de filtrado con los parámetros
          widget.onFiltrar(
            tipo: _tipoInmuebleSeleccionado,
            operacion: _tipoOperacionSeleccionado,
            precioMin: precioMin,
            precioMax: precioMax,
            ciudad:
                _ciudadController.text.isEmpty ? null : _ciudadController.text,
            idEstado: _estadoSeleccionado,
            margenMin: margenMin,
          );

          // Cerrar el panel de filtros
          if (mounted) {
            setState(() {
              _isExpanded = false;
            });
          }

          AppLogger.info('Filtros aplicados con éxito');
        });
      }
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'aplicar_filtros',
        'Error al aplicar filtros',
        e,
        stackTrace,
      );
    } finally {
      _operacionEnProceso = false;
    }
  }

  /// Muestra un mensaje de validación en la UI
  void _mostrarMensajeValidacion(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Registra errores evitando duplicados en intervalo corto
  void _registrarErrorControlado(
    String codigo,
    String mensaje,
    dynamic error,
    StackTrace stackTrace,
  ) {
    final now = DateTime.now();
    final errorKey = '$codigo-${error.hashCode}';

    // Evitar logs duplicados en intervalo corto
    if (_ultimosErrores.containsKey(errorKey)) {
      final lastLog = _ultimosErrores[errorKey]!;
      if (now.difference(lastLog) < _tiempoMinimoEntreErrores) {
        return;
      }
    }

    // Registrar error y actualizar timestamp
    _ultimosErrores[errorKey] = now;

    // Limpiar mapa de errores si crece demasiado
    if (_ultimosErrores.length > 50) {
      // Eliminar entradas antiguas
      final entriesToRemove = _ultimosErrores.entries.toList().sublist(
        0,
        25,
      ); // Eliminar la mitad más antigua

      for (var entry in entriesToRemove) {
        _ultimosErrores.remove(entry.key);
      }
    }

    AppLogger.error(mensaje, error, stackTrace);
  }

  @override
  Widget build(BuildContext context) {
    try {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        child: Card(
          elevation: 4,
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera del panel de filtros
              _buildFilterHeader(),

              // Panel de filtros expandible
              if (_isExpanded) _buildFilterForm(),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'build_widget',
        'Error al construir widget de filtros',
        e,
        stackTrace,
      );

      // Devolver un widget de respaldo en caso de error
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Error al cargar filtros. Por favor, intente de nuevo.'),
        ),
      );
    }
  }

  /// Construye la cabecera del panel de filtros
  Widget _buildFilterHeader() {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
          AppLogger.debug(
            'Panel de filtros ${_isExpanded ? 'expandido' : 'contraído'}',
          );
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Filtros Avanzados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    );
  }

  /// Construye el formulario de filtrado
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
                  child: _buildNumericField(
                    controller: _precioMinController,
                    label: 'Precio Mínimo',
                    icon: Icons.attach_money,
                    validator: _validarPrecioMinimo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumericField(
                    controller: _precioMaxController,
                    label: 'Precio Máximo',
                    icon: Icons.attach_money,
                    validator: _validarPrecioMaximo,
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

            // Filtro por margen de utilidad mínimo
            _buildNumericField(
              controller: _margenMinController,
              label: 'Margen de Utilidad Mínimo (%)',
              icon: Icons.trending_up,
              validator: _validarMargenMinimo,
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _operacionEnProceso ? null : _limpiarFiltros,
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
                    onPressed: _operacionEnProceso ? null : _aplicarFiltros,
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

  /// Construye un campo de entrada numérica con validación
  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: validator,
    );
  }

  /// Valida el precio mínimo
  String? _validarPrecioMinimo(String? value) {
    try {
      if (value != null && value.isNotEmpty) {
        final numero = double.tryParse(value);
        if (numero == null) {
          return 'Ingrese un número válido';
        }
        if (numero < 0) {
          return 'El precio no puede ser negativo';
        }
      }
      return null;
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'validar_precio_min',
        'Error al validar precio mínimo',
        e,
        stackTrace,
      );
      return 'Error en el campo';
    }
  }

  /// Valida el precio máximo
  String? _validarPrecioMaximo(String? value) {
    try {
      if (value != null && value.isNotEmpty) {
        final numero = double.tryParse(value);
        if (numero == null) {
          return 'Ingrese un número válido';
        }
        if (numero < 0) {
          return 'El precio no puede ser negativo';
        }

        // Verificar que sea mayor o igual que el mínimo si existe
        if (_precioMinController.text.isNotEmpty) {
          final minimo = double.tryParse(_precioMinController.text);
          if (minimo != null && numero < minimo) {
            return 'Debe ser mayor que el mínimo';
          }
        }
      }
      return null;
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'validar_precio_max',
        'Error al validar precio máximo',
        e,
        stackTrace,
      );
      return 'Error en el campo';
    }
  }

  /// Valida el margen mínimo
  String? _validarMargenMinimo(String? value) {
    try {
      if (value != null && value.isNotEmpty) {
        final numero = double.tryParse(value);
        if (numero == null) {
          return 'Ingrese un número válido';
        }
        if (numero < 0) {
          return 'El margen no puede ser negativo';
        }
        if (numero > 100) {
          return 'El margen no puede exceder 100%';
        }
      }
      return null;
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'validar_margen_min',
        'Error al validar margen mínimo',
        e,
        stackTrace,
      );
      return 'Error en el campo';
    }
  }
}

import 'package:intl/intl.dart';
import 'registrar_venta_screen.dart';
import 'package:flutter/material.dart';
import '../../models/inmueble_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/providers/inmuebles_disponibles_provider.dart';

class RegistrarNuevaVentaScreen extends ConsumerStatefulWidget {
  const RegistrarNuevaVentaScreen({super.key});

  @override
  ConsumerState<RegistrarNuevaVentaScreen> createState() =>
      _RegistrarNuevaVentaScreenState();
}

class _RegistrarNuevaVentaScreenState
    extends ConsumerState<RegistrarNuevaVentaScreen> {
  final _ingresoController = TextEditingController();
  final _comisionProveedoresController = TextEditingController();
  int? _inmuebleSeleccionado;
  String _filtroTipo = 'Todos';
  String _busqueda = '';

  // Para mostrar detalles del inmueble
  Inmueble? _inmuebleDetalle;

  @override
  void dispose() {
    _ingresoController.dispose();
    _comisionProveedoresController.dispose();
    super.dispose();
  }

  void _seleccionarInmueble(Inmueble inmueble) {
    setState(() {
      _inmuebleSeleccionado = inmueble.id;
      _inmuebleDetalle = inmueble;

      // Establecer precio inicial según el tipo de operación y precio final calculado
      if (inmueble.precioVentaFinal != null) {
        _ingresoController.text = inmueble.precioVentaFinal!.toString();
      } else if (inmueble.tipoOperacion == 'venta' &&
          inmueble.precioVenta != null) {
        _ingresoController.text = inmueble.precioVenta!.toString();
      } else if (inmueble.tipoOperacion == 'renta' &&
          inmueble.precioRenta != null) {
        _ingresoController.text = inmueble.precioRenta!.toString();
      }
    });
  }

  void _continuarARegistro() {
    if (_inmuebleSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un inmueble primero')),
      );
      return;
    }

    if (_inmuebleDetalle == null) {
      return;
    }

    // Verificar que el inmueble esté en estado disponible (3)
    if (_inmuebleDetalle!.idEstado != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo pueden registrarse ventas de inmuebles en estado disponible',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrarVentaScreen(inmueble: _inmuebleDetalle!),
      ),
    ).then((result) {
      if (result == true && mounted) {
        // Verificar que el widget esté montado antes de usar el contexto
        Navigator.of(context).pop(true);
      }
    });
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filtroTipo == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroTipo = selected ? label : 'Todos';
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.teal.shade100,
        checkmarkColor: Colors.teal,
        labelStyle: TextStyle(
          color: isSelected ? Colors.teal.shade700 : Colors.black87,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  String _getEstadoText(int idEstado) {
    switch (idEstado) {
      case 3:
        return 'Disponible';
      case 6:
        return 'En negociación';
      default:
        return 'Otro';
    }
  }

  Color _getEstadoColor(int idEstado) {
    switch (idEstado) {
      case 3:
        return Colors.green;
      case 6:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inmueblesAsyncValue = ref.watch(inmueblesDisponiblesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Inmueble')),
      body: Column(
        children: [
          // Sección de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar inmuebles',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _busqueda = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Filtros de tipo de inmueble
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos'),
                      _buildFilterChip('Casa'),
                      _buildFilterChip('Departamento'),
                      _buildFilterChip('Terreno'),
                      _buildFilterChip('Oficina'),
                      _buildFilterChip('Local'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de inmuebles
          Expanded(
            child: inmueblesAsyncValue.when(
              data: (inmuebles) {
                // Filtrar inmuebles según búsqueda y tipo
                final inmueblesFiltrados =
                    inmuebles.where((i) {
                      // Construir una cadena con los datos de dirección disponibles
                      final direccionCompleta = i.direccionCompleta;

                      final matchesBusqueda =
                          i.nombre.toLowerCase().contains(
                            _busqueda.toLowerCase(),
                          ) ||
                          direccionCompleta.toLowerCase().contains(
                            _busqueda.toLowerCase(),
                          );

                      final matchesTipo =
                          _filtroTipo == 'Todos' ||
                          i.tipoInmueble.toLowerCase() ==
                              _filtroTipo.toLowerCase();

                      return matchesBusqueda && matchesTipo;
                    }).toList();

                if (inmueblesFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.home, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No hay inmuebles disponibles${_busqueda.isEmpty ? '' : ' con esos criterios'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: inmueblesFiltrados.length,
                  itemBuilder: (context, index) {
                    final inmueble = inmueblesFiltrados[index];
                    final isSelected = _inmuebleSeleccionado == inmueble.id;

                    // Usar la propiedad direccionCompleta del inmueble
                    final direccionCompleta = inmueble.direccionCompleta;

                    // Formatear precio con NumberFormat
                    final formatCurrency = NumberFormat.currency(
                      symbol: '\$',
                      locale: 'es_MX',
                    );
                    final precioFormateado =
                        inmueble.tipoOperacion == 'venta'
                            ? formatCurrency.format(inmueble.precioVenta)
                            : "${formatCurrency.format(inmueble.precioRenta)}/mes";

                    // Formatear precio final si existe
                    final precioFinalFormateado =
                        inmueble.precioVentaFinal != null
                            ? formatCurrency.format(inmueble.precioVentaFinal)
                            : "No calculado";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.teal : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          inmueble.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Tipo: ${inmueble.tipoInmueble ?? 'No especificado'}',
                                ),
                                const SizedBox(width: 10),
                                Chip(
                                  label: Text(
                                    _getEstadoText(inmueble.idEstado ?? 0),
                                  ),
                                  backgroundColor: _getEstadoColor(
                                    inmueble.idEstado ?? 0,
                                  ),
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            Text('Operación: ${inmueble.tipoOperacion}'),
                            Text('Precio anunciado: $precioFormateado'),
                            Text('Precio final: $precioFinalFormateado'),
                            if (inmueble.margenUtilidad != null)
                              Text(
                                'Margen: ${inmueble.margenUtilidad!.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color:
                                      inmueble.margenUtilidad! > 20
                                          ? Colors.green
                                          : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (direccionCompleta.isNotEmpty)
                              Text(
                                'Ubicación: $direccionCompleta',
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing:
                            isSelected
                                ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.teal,
                                )
                                : null,
                        onTap: () => _seleccionarInmueble(inmueble),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) =>
                      Center(child: Text('Error al cargar inmuebles: $error')),
            ),
          ),

          // Botón de continuar
          if (_inmuebleSeleccionado != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _continuarARegistro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CONTINUAR AL REGISTRO DE VENTA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

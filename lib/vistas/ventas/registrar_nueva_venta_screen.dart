import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'registrar_operacion_screen.dart';
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
      if (inmueble.tipoOperacion == 'venta' ||
          inmueble.tipoOperacion == 'ambos') {
        if (inmueble.precioVentaFinal != null) {
          _ingresoController.text = inmueble.precioVentaFinal!.toString();
        } else if (inmueble.precioVenta != null) {
          _ingresoController.text = inmueble.precioVenta!.toString();
        }
      } else if (inmueble.tipoOperacion == 'renta') {
        if (inmueble.precioRenta != null) {
          _ingresoController.text = inmueble.precioRenta!.toString();
        }
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
            'Solo pueden registrarse operaciones de inmuebles en estado disponible',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navegar a la pantalla universal de registro de operación
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RegistrarOperacionScreen(inmueble: _inmuebleDetalle!),
      ),
    ).then((result) {
      if (result == true && mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filtroTipo == label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _filtroTipo = selected ? label : 'Todos';
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.teal.shade300,
      ),
    );
  }

  String _getEstadoText(int idEstado) {
    switch (idEstado) {
      case 3:
        return 'Disponible';
      case 6:
        return 'En Negociación';
      default:
        return 'Desconocido';
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
      appBar: AppBar(title: const Text('Registrar Nueva Venta')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra de búsqueda
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar inmueble...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
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
                        inmueble.tipoOperacion == 'venta' ||
                                inmueble.tipoOperacion == 'ambos'
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
                        title: Text(
                          inmueble.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: _getEstadoColor(inmueble.idEstado!),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getEstadoText(inmueble.idEstado!),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getEstadoColor(inmueble.idEstado!),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildTipoOperacionIndicator(
                                  inmueble.tipoOperacion,
                                ),
                                const SizedBox(width: 4),
                                Text(inmueble.tipoOperacion),
                              ],
                            ),
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
                child: Text(
                  _inmuebleDetalle?.tipoOperacion == 'renta'
                      ? 'CONTINUAR AL REGISTRO DE RENTA'
                      : _inmuebleDetalle?.tipoOperacion == 'venta'
                      ? 'CONTINUAR AL REGISTRO DE VENTA'
                      : 'CONTINUAR AL REGISTRO DE OPERACIÓN',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Indicador visual para el tipo de operación
  Widget _buildTipoOperacionIndicator(String tipoOperacion) {
    IconData icon;
    Color color;

    switch (tipoOperacion) {
      case 'venta':
        icon = Icons.sell;
        color = Colors.green;
        break;
      case 'renta':
        icon = Icons.home;
        color = Colors.blue;
        break;
      case 'ambos':
        icon = Icons.compare_arrows;
        color = Colors.purple;
        break;
      default:
        icon = Icons.error;
        color = Colors.red;
    }

    return Icon(icon, color: color, size: 16);
  }
}

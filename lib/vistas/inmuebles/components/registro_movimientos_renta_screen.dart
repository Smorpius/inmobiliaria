import 'resumen_financiero.dart';
import 'galeria_comprobantes.dart';
import 'formulario_movimiento.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/inmueble_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/inmueble_renta_provider.dart';

class RegistroMovimientosRentaScreen extends ConsumerStatefulWidget {
  final Inmueble inmueble;

  const RegistroMovimientosRentaScreen({super.key, required this.inmueble});

  @override
  ConsumerState<RegistroMovimientosRentaScreen> createState() =>
      _RegistroMovimientosRentaScreenState();
}

class _RegistroMovimientosRentaScreenState
    extends ConsumerState<RegistroMovimientosRentaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _anioSeleccionado = DateTime.now().year;
  int _mesSeleccionado = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      ref
          .read(movimientosRentaStateProvider(widget.inmueble.id!).notifier)
          .cargarMovimientos(widget.inmueble.id!);
    } catch (e, stack) {
      AppLogger.error('Error al cargar movimientos', e, stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          esPantallaPequena
              ? widget.inmueble.nombre.length > 15
                  ? '${widget.inmueble.nombre.substring(0, 15)}...'
                  : widget.inmueble.nombre
              : 'Registro de Renta: ${widget.inmueble.nombre}',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_box), text: 'Registrar'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Resumen'),
            Tab(icon: Icon(Icons.image), text: 'Comprobantes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Pestaña 1: Formulario de registro
          FormularioMovimiento(
            inmueble: widget.inmueble,
            onSuccess: () {
              // Después de un registro exitoso, cambiamos a la pestaña de resumen
              _tabController.animateTo(1);
              // Refrescamos los datos
              _cargarDatos();
            },
          ),

          // Pestaña 2: Resumen financiero
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _construirSelectorMes(),
                  const SizedBox(height: 16),
                  ResumenFinanciero(
                    inmueble: widget.inmueble,
                    anio: _anioSeleccionado,
                    mes: _mesSeleccionado,
                  ),
                ],
              ),
            ),
          ),

          // Pestaña 3: Galería de comprobantes
          GaleriaComprobantes(inmueble: widget.inmueble),
        ],
      ),
    );
  }

  Widget _construirSelectorMes() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona periodo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                      border: OutlineInputBorder(),
                    ),
                    value: _mesSeleccionado,
                    items: List.generate(12, (index) {
                      final mes = index + 1;
                      return DropdownMenuItem(
                        value: mes,
                        child: Text(_obtenerNombreMes(mes)),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _mesSeleccionado = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(),
                    ),
                    value: _anioSeleccionado,
                    items: List.generate(5, (index) {
                      final anio = DateTime.now().year - 2 + index;
                      return DropdownMenuItem(
                        value: anio,
                        child: Text(anio.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _anioSeleccionado = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _obtenerNombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return meses[mes - 1];
  }
}

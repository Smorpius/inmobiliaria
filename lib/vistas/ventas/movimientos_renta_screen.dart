import 'package:intl/intl.dart';
import '../../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../../models/resumen_renta_model.dart';
import '../../models/movimiento_renta_model.dart';
import '../../providers/inmueble_renta_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MovimientosRentaScreen extends ConsumerStatefulWidget {
  final int idInmueble;
  final String nombreInmueble;
  final int idCliente;
  final String nombreCliente;

  const MovimientosRentaScreen({
    super.key,
    required this.idInmueble,
    required this.nombreInmueble,
    required this.idCliente,
    required this.nombreCliente,
  });

  @override
  ConsumerState<MovimientosRentaScreen> createState() =>
      _MovimientosRentaScreenState();
}

class _MovimientosRentaScreenState
    extends ConsumerState<MovimientosRentaScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();
  final _comentariosController = TextEditingController();
  bool _isIngreso = true;
  DateTime _fechaMovimiento = DateTime.now();
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isRegistering = false;

  final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
  final formatDate = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // Cargar movimientos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(movimientosRentaStateProvider(widget.idInmueble).notifier)
          .cargarMovimientos(widget.idInmueble);
    });
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaMovimiento,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaMovimiento) {
      setState(() {
        _fechaMovimiento = picked;
      });
    }
  }

  Future<void> _registrarMovimiento() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isRegistering = true;
      });

      try {
        final monto = double.parse(_montoController.text);
        final movimiento = MovimientoRenta(
          idInmueble: widget.idInmueble,
          idCliente: widget.idCliente,
          tipoMovimiento: _isIngreso ? 'ingreso' : 'egreso',
          concepto: _conceptoController.text,
          monto: monto,
          fechaMovimiento: _fechaMovimiento,
          mesCorrespondiente:
              '${_fechaMovimiento.year}-${_fechaMovimiento.month.toString().padLeft(2, '0')}',
          comentarios: _comentariosController.text,
        );

        final success = await ref
            .read(movimientosRentaStateProvider(widget.idInmueble).notifier)
            .registrarMovimiento(movimiento);

        if (success && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Movimiento de ${_isIngreso ? "ingreso" : "egreso"} registrado correctamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        AppLogger.error('Error al registrar movimiento', e, StackTrace.current);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al registrar movimiento: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isRegistering = false;
          });
        }
      }
    }
  }

  Future<void> _confirmarEliminarMovimiento(int idMovimiento) async {
    // Capturar el contexto actual antes de operaciones asíncronas
    final navigatorContext = context;

    return showDialog(
      context: navigatorContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
            '¿Está seguro de eliminar este movimiento? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                // Usamos dialogContext para cerrar el diálogo
                Navigator.of(dialogContext).pop();

                // Para la operación asíncrona, creamos una función que será ejecutada
                _procesarEliminacion(idMovimiento);
              },
              child: const Text('ELIMINAR'),
            ),
          ],
        );
      },
    );
  }

  // Separar la operación asíncrona a un método distinto
  Future<void> _procesarEliminacion(int idMovimiento) async {
    try {
      // Eliminando la variable 'success' no utilizada - directamente llamamos al método
      await ref
          .read(movimientosRentaStateProvider(widget.idInmueble).notifier)
          .eliminarMovimiento(idMovimiento, widget.idInmueble);

      // Verificar que el widget esté montado antes de usar el contexto
      if (!mounted) return;

      // Ahora es seguro usar ScaffoldMessenger con el contexto actual
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimiento eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Verificar que el widget esté montado antes de usar el contexto
      if (!mounted) return;

      // Ahora es seguro usar ScaffoldMessenger con el contexto actual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar movimiento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final movimientosState = ref.watch(
      movimientosRentaStateProvider(widget.idInmueble),
    );
    final resumenParams = ResumenRentaParams(
      idInmueble: widget.idInmueble,
      anio: _selectedYear,
      mes: _selectedMonth,
    );
    final resumenAsync = ref.watch(resumenRentaPorMesProvider(resumenParams));

    return Scaffold(
      appBar: AppBar(title: Text('Movimientos: ${widget.nombreInmueble}')),
      body: Column(
        children: [
          // Resumen financiero
          _buildResumenWidget(resumenAsync),

          // Selector de período
          _buildPeriodSelector(),

          // Lista de movimientos
          Expanded(child: _buildMovimientosList(movimientosState)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioMovimiento(),
        icon: const Icon(Icons.add),
        label: const Text('Registrar movimiento'),
      ),
    );
  }

  Widget _buildResumenWidget(AsyncValue<ResumenRenta> resumenAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51), // 0.2 * 255 = ~51
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: resumenAsync.when(
        data: (resumen) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen Financiero',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResumenItem(
                    Colors.green,
                    'Ingresos',
                    resumen.ingresosFormateados,
                  ),
                  _buildResumenItem(
                    Colors.red,
                    'Gastos',
                    resumen.egresosFormateados,
                  ),
                  _buildResumenItem(
                    resumen.esPositivo ? Colors.blue : Colors.orange,
                    'Balance',
                    resumen.balanceFormateado,
                  ),
                ],
              ),
            ],
          );
        },
        loading:
            () => const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        error:
            (e, st) => Center(
              child: Text(
                'Error al cargar resumen: ${e.toString()}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
      ),
    );
  }

  /// Construye un item individual del resumen financiero
  Widget _buildResumenItem(Color color, String title, String formattedValue) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedValue,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Text(
            'Período: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),

          // Año
          DropdownButton<int>(
            value: _selectedYear,
            onChanged: (int? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedYear = newValue;
                });
              }
            },
            items:
                List.generate(
                  5,
                  (index) => DateTime.now().year - 2 + index,
                ).map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
          ),

          const SizedBox(width: 16),

          // Mes
          DropdownButton<int>(
            value: _selectedMonth,
            onChanged: (int? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedMonth = newValue;
                });
              }
            },
            items:
                List.generate(
                  12,
                  (index) => index + 1,
                ).map<DropdownMenuItem<int>>((int value) {
                  final monthName = DateFormat(
                    'MMMM',
                    'es_ES',
                  ).format(DateTime(2022, value, 1));
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(
                      monthName.substring(0, 1).toUpperCase() +
                          monthName.substring(1),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMovimientosList(MovimientosRentaState state) {
    if (state.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error al cargar movimientos: ${state.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(
                      movimientosRentaStateProvider(widget.idInmueble).notifier,
                    )
                    .cargarMovimientos(widget.idInmueble);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.movimientos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay movimientos registrados',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Registre ingresos o gastos con el botón +',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Filtrar movimientos por mes y año seleccionados
    final filteredMovimientos =
        state.movimientos.where((mov) {
          final movDate = mov.fechaMovimiento;
          return movDate.year == _selectedYear &&
              movDate.month == _selectedMonth;
        }).toList();

    if (filteredMovimientos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay movimientos en el período seleccionado',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredMovimientos.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final movimiento = filteredMovimientos[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  movimiento.esIngreso
                      ? Colors.green.shade100
                      : Colors.red.shade100,
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor:
                  movimiento.esIngreso
                      ? Colors.green.withAlpha(26) // 0.1 * 255 ≈ 26
                      : Colors.red.withAlpha(26), // 0.1 * 255 ≈ 26
              child: Icon(
                movimiento.esIngreso
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: movimiento.esIngreso ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              movimiento.concepto,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  movimiento.fechaFormateada,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                if (movimiento.comentarios != null &&
                    movimiento.comentarios!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      movimiento.comentarios!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  movimiento.montoFormateado,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color:
                        movimiento.esIngreso
                            ? Colors.green[700]
                            : Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => _confirmarEliminarMovimiento(movimiento.id!),
                  tooltip: 'Eliminar',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarFormularioMovimiento() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Registrar ${_isIngreso ? "Ingreso" : "Egreso"}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tipo de movimiento
                  Row(
                    children: [
                      const Text('Tipo de Movimiento:'),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('Ingreso'),
                        selected: _isIngreso,
                        onSelected: (selected) {
                          setState(() {
                            _isIngreso = selected;
                          });
                          // Sin cerrar y reabrir el diálogo
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Egreso'),
                        selected: !_isIngreso,
                        onSelected: (selected) {
                          setState(() {
                            _isIngreso = !selected;
                            Navigator.pop(context);
                            _mostrarFormularioMovimiento();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Concepto
                  TextFormField(
                    controller: _conceptoController,
                    decoration: InputDecoration(
                      labelText: 'Concepto',
                      hintText:
                          _isIngreso
                              ? 'Ej: Pago de renta'
                              : 'Ej: Mantenimiento',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Debe ingresar un concepto';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Monto
                  TextFormField(
                    controller: _montoController,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      hintText: 'Ej: 5000.00',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Debe ingresar un monto';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Ingrese un valor numérico válido';
                      }
                      if (double.parse(value) <= 0) {
                        return 'El monto debe ser mayor a cero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fecha
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(formatDate.format(_fechaMovimiento)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comentarios
                  TextFormField(
                    controller: _comentariosController,
                    decoration: const InputDecoration(
                      labelText: 'Comentarios (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _isRegistering ? null : _registrarMovimiento,
                    child:
                        _isRegistering
                            ? const CircularProgressIndicator()
                            : Text(
                              'Registrar ${_isIngreso ? "Ingreso" : "Egreso"}',
                            ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

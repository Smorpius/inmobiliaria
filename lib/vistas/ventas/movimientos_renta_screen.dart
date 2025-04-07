import 'package:intl/intl.dart';
import '../../utils/applogger.dart';
import 'package:flutter/material.dart';
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
  int _selectedYear = 0; // Inicializado en 0 para no filtrar por defecto
  int _selectedMonth = 0; // Inicializado en 0 para no filtrar por defecto
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

  // Método para limpiar el formulario después del registro exitoso
  void _limpiarFormulario() {
    _conceptoController.clear();
    _montoController.clear();
    _comentariosController.clear();
    _fechaMovimiento = DateTime.now();
  }

  // Método para verificar si ya existe un pago para el mes seleccionado
  Future<bool> _verificarPagoExistente(DateTime mesPagoRenta) async {
    final movimientosState = ref.read(
      movimientosRentaStateProvider(widget.idInmueble),
    );

    // Formato año-mes que queremos verificar
    final mesFormateado = mesPagoRenta.month.toString().padLeft(2, '0');
    final mesCorrespondiente = '${mesPagoRenta.year}-$mesFormateado';

    // Verificar si ya existe un movimiento con el mismo mes correspondiente y concepto de renta
    final pagoExistente =
        movimientosState.movimientos.where((movimiento) {
          return movimiento.mesCorrespondiente == mesCorrespondiente &&
              movimiento.concepto.startsWith('Pago de renta:') &&
              movimiento.tipoMovimiento == 'ingreso';
        }).isNotEmpty;

    return pagoExistente;
  }

  Future<void> _registrarMovimiento() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isRegistering = true;
      });

      try {
        final monto = double.parse(_montoController.text);

        // Aseguramos que el mesCorrespondiente se genere correctamente
        final mesFormateado = _fechaMovimiento.month.toString().padLeft(2, '0');
        final mesCorrespondiente = '${_fechaMovimiento.year}-$mesFormateado';

        final movimiento = MovimientoRenta(
          idInmueble: widget.idInmueble,
          idCliente: widget.idCliente,
          tipoMovimiento: _isIngreso ? 'ingreso' : 'egreso',
          concepto: _conceptoController.text,
          monto: monto,
          fechaMovimiento: _fechaMovimiento,
          mesCorrespondiente: mesCorrespondiente,
          comentarios:
              _comentariosController.text.isEmpty
                  ? null
                  : _comentariosController.text,
        );

        AppLogger.info(
          'Registrando movimiento: ${movimiento.concepto} con fecha ${movimiento.fechaMovimiento}, mesCorrespondiente: ${movimiento.mesCorrespondiente}',
        );

        final success = await ref
            .read(movimientosRentaStateProvider(widget.idInmueble).notifier)
            .registrarMovimiento(movimiento);

        if (success && mounted) {
          // Actualizamos aquí el año y mes seleccionados para que coincidan con el movimiento nuevo
          setState(() {
            _selectedYear = _fechaMovimiento.year;
            _selectedMonth = _fechaMovimiento.month;
          });

          // Recargamos los movimientos explícitamente
          await ref
              .read(movimientosRentaStateProvider(widget.idInmueble).notifier)
              .cargarMovimientos(widget.idInmueble);

          // Cerramos solo el modal de formulario, no la pantalla completa
          if (mounted) {
            Navigator.pop(context);
          }

          // Limpiamos el formulario para un posible uso futuro
          _limpiarFormulario();

          // Verificamos explícitamente que el movimiento aparezca en los logs
          AppLogger.info(
            'Movimiento registrado. Actualizando vista para mostrar el período: $_selectedYear-$_selectedMonth',
          );

          // Mostramos mensaje de éxito
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Movimiento de ${_isIngreso ? "ingreso" : "egreso"} registrado correctamente',
                ),
                backgroundColor: Colors.green,
              ),
            );

            // Forzar un rebuild del widget después de un breve retraso
            // para asegurar que los cambios de estado han sido procesados
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  // Este setState vacío fuerza un rebuild
                });
              }
            });
          }
        } else {
          AppLogger.warning(
            'No se pudo registrar el movimiento o el widget ya no está montado',
          );
          if (!mounted) return;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No se pudo registrar el movimiento. Intente nuevamente.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        AppLogger.error('Error al registrar movimiento', e, StackTrace.current);
        if (mounted) {
          String mensajeError = 'Error al registrar movimiento';

          // Mensajes de error más amigables basados en el tipo de error
          if (e.toString().contains('connection')) {
            mensajeError =
                'Error de conexión. Verifique su red e intente nuevamente';
          } else if (e.toString().contains('permission')) {
            mensajeError =
                'No tiene permisos suficientes para realizar esta operación';
          } else if (e.toString().contains('format')) {
            mensajeError =
                'Error en el formato de los datos. Verifique e intente nuevamente';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
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

  Future<void> _registrarPagoRenta(DateTime mesPagoRenta) async {
    if (_formKey.currentState!.validate()) {
      // Verificar primero si ya existe un pago para este mes
      final existePago = await _verificarPagoExistente(mesPagoRenta);
      if (existePago) {
        // Mostrar diálogo de advertencia
        if (!mounted) return;

        final confirmarPago = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700]),
                  const SizedBox(width: 10),
                  const Text('Pago Duplicado'),
                ],
              ),
              content: Text(
                'Ya existe un pago registrado para ${DateFormat('MMMM yyyy', 'es_ES').format(mesPagoRenta)}.\n\n¿Desea registrar este pago de todas formas?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('CANCELAR'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('REGISTRAR DE TODAS FORMAS'),
                ),
              ],
            );
          },
        );

        if (confirmarPago != true) {
          return;
        }
      }

      setState(() {
        _isRegistering = true;
      });

      try {
        final monto = double.parse(_montoController.text);

        final mesFormateado = mesPagoRenta.month.toString().padLeft(2, '0');
        final mesCorrespondiente = '${mesPagoRenta.year}-$mesFormateado';

        final movimiento = MovimientoRenta(
          idInmueble: widget.idInmueble,
          idCliente: widget.idCliente,
          tipoMovimiento: 'ingreso',
          concepto: _conceptoController.text,
          monto: monto,
          fechaMovimiento: _fechaMovimiento,
          mesCorrespondiente: mesCorrespondiente,
          comentarios:
              _comentariosController.text.isEmpty
                  ? null
                  : _comentariosController.text,
        );

        AppLogger.info(
          'Registrando pago de renta: ${movimiento.concepto} con fecha ${movimiento.fechaMovimiento}, mesCorrespondiente: ${movimiento.mesCorrespondiente}',
        );

        final success = await ref
            .read(movimientosRentaStateProvider(widget.idInmueble).notifier)
            .registrarMovimiento(movimiento);

        if (success && mounted) {
          setState(() {
            _selectedYear = mesPagoRenta.year;
            _selectedMonth = mesPagoRenta.month;
          });

          await ref
              .read(movimientosRentaStateProvider(widget.idInmueble).notifier)
              .cargarMovimientos(widget.idInmueble);

          if (mounted) {
            Navigator.pop(context);
            _limpiarFormulario();

            AppLogger.info(
              'Pago de renta registrado. Actualizando vista para mostrar el período: $_selectedYear-$_selectedMonth',
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pago de renta registrado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {});
            }
          });
        } else {
          AppLogger.warning(
            'No se pudo registrar el pago de renta o el widget ya no está montado',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No se pudo registrar el pago de renta. Intente nuevamente.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        AppLogger.error(
          'Error al registrar pago de renta',
          e,
          StackTrace.current,
        );
        if (mounted) {
          String mensajeError = 'Error al registrar pago de renta';

          if (e.toString().contains('connection')) {
            mensajeError =
                'Error de conexión. Verifique su red e intente nuevamente';
          } else if (e.toString().contains('permission')) {
            mensajeError =
                'No tiene permisos suficientes para realizar esta operación';
          } else if (e.toString().contains('format')) {
            mensajeError =
                'Error en el formato de los datos. Verifique e intente nuevamente';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movimiento eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
    ref.watch(resumenRentaPorMesProvider(resumenParams));

    return Scaffold(
      appBar: AppBar(title: Text(widget.nombreInmueble)),
      body: Column(
        children: [
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

          // Botón "Todos"
          TextButton(
            onPressed: () {
              setState(() {
                _selectedYear = 0;
                _selectedMonth = 0;
              });
            },
            style: TextButton.styleFrom(
              backgroundColor:
                  (_selectedYear == 0) ? Colors.blue.withAlpha(25) : null,
              foregroundColor: (_selectedYear == 0) ? Colors.blue : null,
            ),
            child: const Text('Todos'),
          ),

          const SizedBox(width: 16),

          // Año
          DropdownButton<int>(
            value: _selectedYear == 0 ? DateTime.now().year : _selectedYear,
            onChanged: (int? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedYear = newValue;
                  // Si seleccionamos año, también necesitamos un mes
                  if (_selectedMonth == 0) {
                    _selectedMonth = DateTime.now().month;
                  }
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
            value: _selectedMonth == 0 ? DateTime.now().month : _selectedMonth,
            onChanged: (int? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedMonth = newValue;
                  // Si seleccionamos mes, también necesitamos un año
                  if (_selectedYear == 0) {
                    _selectedYear = DateTime.now().year;
                  }
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

    // Variable que determina si estamos filtrando por período específico
    final bool filtrandoPorPeriodo = _selectedYear != 0 && _selectedMonth != 0;

    // Si no estamos filtrando específicamente, mostrar todos los movimientos
    // Si estamos filtrando, aplicar filtro por año y mes
    final List<MovimientoRenta> movimientosAMostrar =
        filtrandoPorPeriodo
            ? state.movimientos.where((mov) {
              final movDate = mov.fechaMovimiento;
              return movDate.year == _selectedYear &&
                  movDate.month == _selectedMonth;
            }).toList()
            : state.movimientos; // Mostrar todos los movimientos

    // Si no hay movimientos después de aplicar el filtro, mostrar mensaje
    if (movimientosAMostrar.isEmpty && filtrandoPorPeriodo) {
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
            TextButton(
              onPressed: () {
                setState(() {
                  // Resetear selección para mostrar todos
                  _selectedYear = 0;
                  _selectedMonth = 0;
                });
              },
              child: const Text('Mostrar todos los movimientos'),
            ),
          ],
        ),
      );
    }

    // Organizamos los movimientos por fecha (más recientes primero)
    final sortedMovimientos = List<MovimientoRenta>.from(movimientosAMostrar)
      ..sort((a, b) => b.fechaMovimiento.compareTo(a.fechaMovimiento));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mostrar chip cuando está activo el filtrado
        if (filtrandoPorPeriodo)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text(
                    'Período: ${_getMonthName(_selectedMonth)} $_selectedYear',
                  ),
                  onSelected: (_) {
                    setState(() {
                      // Resetear selección para mostrar todos
                      _selectedYear = 0;
                      _selectedMonth = 0;
                    });
                  },
                  selected: true,
                  showCheckmark: false,
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() {
                      // Resetear selección para mostrar todos
                      _selectedYear = 0;
                      _selectedMonth = 0;
                    });
                  },
                ),
              ],
            ),
          ),

        // Lista de movimientos
        Expanded(
          child: ListView.builder(
            itemCount: sortedMovimientos.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final movimiento = sortedMovimientos[index];
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
                      // Usar icono específico para pagos de renta
                      movimiento.concepto.startsWith('Pago de renta:')
                          ? Icons.home
                          : (movimiento.esIngreso
                              ? Icons.arrow_downward
                              : Icons.arrow_upward),
                      color: movimiento.esIngreso ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          movimiento.concepto,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (movimiento.concepto.startsWith('Pago de renta:'))
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Renta',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                        ),
                        onPressed:
                            () => _confirmarEliminarMovimiento(movimiento.id!),
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
          ),
        ),
      ],
    );
  }

  // Método auxiliar para obtener el nombre del mes
  String _getMonthName(int month) {
    final monthName = DateFormat(
      'MMMM',
      'es_ES',
    ).format(DateTime(2022, month, 1));
    return monthName.substring(0, 1).toUpperCase() + monthName.substring(1);
  }

  void _mostrarFormularioMovimiento() {
    // Capturamos una referencia al contexto actual
    final currentContext = context;

    // Variable para saber si estamos registrando un pago de renta específicamente
    bool esPagoRenta = false;
    DateTime mesPagoRenta = DateTime.now();

    showModalBottomSheet(
      context: currentContext,
      isScrollControlled: true,
      isDismissible: true, // Permite cerrar al tocar fuera
      enableDrag: true, // Permite arrastrar hacia abajo para cerrar
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext modalContext) {
        // StatefulBuilder permite actualizar el estado dentro del modal
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                              // Actualizamos tanto el estado del widget como el modal
                              setState(() {
                                _isIngreso = selected;
                              });
                              setModalState(() {
                                // Actualizamos también el estado dentro del modal
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Egreso'),
                            selected: !_isIngreso,
                            onSelected: (selected) {
                              setState(() {
                                _isIngreso = !selected;
                              });
                              setModalState(() {
                                // Actualizamos también el estado dentro del modal
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Pago de renta
                      if (_isIngreso)
                        Row(
                          children: [
                            const Text('¿Es pago de renta?'),
                            const SizedBox(width: 16),
                            Switch(
                              value: esPagoRenta,
                              onChanged: (value) {
                                setModalState(() {
                                  esPagoRenta = value;
                                  if (esPagoRenta) {
                                    // Si es pago de renta, establecer concepto automáticamente
                                    final mesAnioStr = DateFormat(
                                          'MMMM yyyy',
                                          'es_ES',
                                        )
                                        .format(mesPagoRenta)
                                        .toLowerCase()
                                        .replaceFirstMapped(
                                          RegExp(r'^.'),
                                          (match) =>
                                              match.group(0)!.toUpperCase(),
                                        );
                                    _conceptoController.text =
                                        'Pago de renta: $mesAnioStr';
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),

                      // Selector de mes correspondiente (solo para pagos de renta)
                      if (_isIngreso && esPagoRenta)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mes correspondiente del pago:'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: mesPagoRenta,
                                  firstDate: DateTime(
                                    DateTime.now().year - 2,
                                    1,
                                  ),
                                  lastDate: DateTime(
                                    DateTime.now().year + 1,
                                    12,
                                  ),
                                  helpText: 'Seleccione mes correspondiente',
                                  cancelText: 'CANCELAR',
                                  confirmText: 'ACEPTAR',
                                  initialDatePickerMode: DatePickerMode.year,
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    mesPagoRenta = picked;
                                    // Actualizar el concepto automáticamente
                                    final mesAnioStr = DateFormat(
                                          'MMMM yyyy',
                                          'es_ES',
                                        )
                                        .format(mesPagoRenta)
                                        .toLowerCase()
                                        .replaceFirstMapped(
                                          RegExp(r'^.'),
                                          (match) =>
                                              match.group(0)!.toUpperCase(),
                                        );
                                    _conceptoController.text =
                                        'Pago de renta: $mesAnioStr';
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Mes correspondiente',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_month),
                                ),
                                child: Text(
                                  DateFormat('MMMM yyyy', 'es_ES')
                                      .format(mesPagoRenta)
                                      .toLowerCase()
                                      .replaceFirstMapped(
                                        RegExp(r'^.'),
                                        (match) =>
                                            match.group(0)!.toUpperCase(),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

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
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _fechaMovimiento,
                            firstDate: DateTime(_selectedYear - 1, 1),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                            helpText: 'Seleccione fecha del movimiento',
                            cancelText: 'CANCELAR',
                            confirmText: 'ACEPTAR',
                          );
                          if (picked != null && picked != _fechaMovimiento) {
                            setState(() {
                              _fechaMovimiento = picked;
                            });
                            setModalState(() {
                              // Actualizar el estado del modal
                            });
                          }
                        },
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
                        onPressed:
                            _isRegistering
                                ? null
                                : () async {
                                  // Usamos el contexto del modal aquí
                                  if (esPagoRenta && _isIngreso) {
                                    await _registrarPagoRenta(mesPagoRenta);
                                  } else {
                                    await _registrarMovimiento();
                                  }
                                },
                        child:
                            _isRegistering
                                ? const CircularProgressIndicator()
                                : Text(
                                  esPagoRenta && _isIngreso
                                      ? 'Registrar Pago de Renta'
                                      : 'Registrar ${_isIngreso ? "Ingreso" : "Egreso"}',
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
      },
    );
  }
}

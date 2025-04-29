import 'package:intl/intl.dart';
import '../../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../../models/movimiento_renta_model.dart';
import '../../widgets/filtro_periodo_widget.dart';
import '../../providers/inmueble_renta_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para filtrar movimientos por período
final movimientosFiltradosPorPeriodoProvider = Provider.family<
  AsyncValue<List<MovimientoRenta>>,
  ({int idInmueble, DateTimeRange periodo})
>((ref, params) {
  // Obtener todos los movimientos del inmueble
  final movimientosAsyncValue = ref.watch(
    movimientosPorInmuebleProvider(params.idInmueble),
  );

  // Mapear el estado de los movimientos para aplicar el filtro por período
  return movimientosAsyncValue.when(
    data: (movimientos) {
      // Filtrar los movimientos por el período seleccionado
      final movimientosFiltrados =
          movimientos.where((movimiento) {
            final fechaMovimiento = movimiento.fechaMovimiento;

            // Normalizar las fechas para comparación (sin hora, minutos, etc.)
            final fechaInicio = DateTime(
              params.periodo.start.year,
              params.periodo.start.month,
              params.periodo.start.day,
            );

            final fechaFin = DateTime(
              params.periodo.end.year,
              params.periodo.end.month,
              params.periodo.end.day,
              23,
              59,
              59, // Incluir todo el día final
            );

            final fechaMovimientoNormalizada = DateTime(
              fechaMovimiento.year,
              fechaMovimiento.month,
              fechaMovimiento.day,
            );

            // Incluir fechas que están dentro del rango, incluyendo los límites
            return (fechaMovimientoNormalizada.isAtSameMomentAs(fechaInicio) ||
                    fechaMovimientoNormalizada.isAfter(fechaInicio)) &&
                (fechaMovimientoNormalizada.isAtSameMomentAs(fechaFin) ||
                    fechaMovimientoNormalizada.isBefore(fechaFin));
          }).toList();

      return AsyncValue.data(movimientosFiltrados);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Provider para calcular el balance de un período
final balancePeriodoProvider =
    Provider.family<Map<String, double>, AsyncValue<List<MovimientoRenta>>>((
      ref,
      movimientosAsyncValue,
    ) {
      return movimientosAsyncValue.when(
        data: (movimientos) {
          double ingresos = 0;
          double egresos = 0;

          for (final movimiento in movimientos) {
            if (movimiento.tipoMovimiento == 'ingreso') {
              ingresos += movimiento.monto;
            } else {
              egresos += movimiento.monto;
            }
          }

          return {
            'ingresos': ingresos,
            'egresos': egresos,
            'balance': ingresos - egresos,
          };
        },
        loading: () => {'ingresos': 0, 'egresos': 0, 'balance': 0},
        error: (_, __) => {'ingresos': 0, 'egresos': 0, 'balance': 0},
      );
    });

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
  bool _isRegistering = false;

  final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
  final formatDate = DateFormat('dd/MM/yyyy');

  TipoPeriodo _tipoPeriodSeleccionado = TipoPeriodo.mes;
  late DateTimeRange _periodoSeleccionado;

  @override
  void initState() {
    super.initState();
    _periodoSeleccionado = FiltroPeriodoWidget.calcularRangoPorTipoEstatico(
      TipoPeriodo.mes,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(movimientosPorInmuebleProvider(widget.idInmueble));
    });
  }

  void _cambiarPeriodo(TipoPeriodo tipo) {
    setState(() {
      _tipoPeriodSeleccionado = tipo;
      _periodoSeleccionado = FiltroPeriodoWidget.calcularRangoPorTipoEstatico(
        tipo,
      );

      ref.invalidate(movimientosPorInmuebleProvider(widget.idInmueble));
    });
  }

  void _seleccionarPeriodoPersonalizado() async {
    final DateTimeRange? resultado = await showDateRangePicker(
      context: context,
      initialDateRange: _periodoSeleccionado,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );

    if (resultado != null) {
      setState(() {
        _tipoPeriodSeleccionado = TipoPeriodo.personalizado;
        _periodoSeleccionado = resultado;

        ref.invalidate(movimientosPorInmuebleProvider(widget.idInmueble));
      });
    }
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  void _limpiarFormulario() {
    _conceptoController.clear();
    _montoController.clear();
    _comentariosController.clear();
    _fechaMovimiento = DateTime.now();
  }

  Future<bool> _verificarPagoExistente(DateTime mesPagoRenta) async {
    final movimientosState = ref.read(
      movimientosRentaStateProvider(widget.idInmueble),
    );

    final mesFormateado = mesPagoRenta.month.toString().padLeft(2, '0');
    final mesCorrespondiente = '${mesPagoRenta.year}-$mesFormateado';

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
          // Actualizar el período seleccionado para mostrar el mes del movimiento registrado
          setState(() {
            _cambiarPeriodo(TipoPeriodo.mes);
            _periodoSeleccionado =
                FiltroPeriodoWidget.calcularRangoPorTipoEstatico(
                  TipoPeriodo.mes,
                  _fechaMovimiento,
                );
          });

          ref.invalidate(movimientosRentaStateProvider(widget.idInmueble));
          ref.invalidate(movimientosPorInmuebleProvider(widget.idInmueble));

          final resumenParams = ResumenRentaParams(
            idInmueble: widget.idInmueble,
            anio: _fechaMovimiento.year,
            mes: _fechaMovimiento.month,
          );
          ref.invalidate(resumenRentaPorMesProvider(resumenParams));

          await ref
              .read(movimientosRentaStateProvider(widget.idInmueble).notifier)
              .cargarMovimientos(widget.idInmueble);

          if (mounted) {
            Navigator.pop(context);
          }

          _limpiarFormulario();

          AppLogger.info(
            'Movimiento registrado. Actualizando vista para mostrar el período: ${_fechaMovimiento.year}-${_fechaMovimiento.month}',
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Movimiento de ${_isIngreso ? "ingreso" : "egreso"} registrado correctamente',
                ),
                backgroundColor: Colors.green,
              ),
            );

            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {});
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
      final existePago = await _verificarPagoExistente(mesPagoRenta);
      if (existePago) {
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
          // Actualizar el período seleccionado para que coincida con el mes del pago
          setState(() {
            _cambiarPeriodo(TipoPeriodo.mes);
            _periodoSeleccionado =
                FiltroPeriodoWidget.calcularRangoPorTipoEstatico(
                  TipoPeriodo.mes,
                  mesPagoRenta,
                );
          });

          ref.invalidate(movimientosRentaStateProvider(widget.idInmueble));
          ref.invalidate(movimientosPorInmuebleProvider(widget.idInmueble));

          final resumenParams = ResumenRentaParams(
            idInmueble: widget.idInmueble,
            anio: mesPagoRenta.year,
            mes: mesPagoRenta.month,
          );
          ref.invalidate(resumenRentaPorMesProvider(resumenParams));

          await ref
              .read(movimientosRentaStateProvider(widget.idInmueble).notifier)
              .cargarMovimientos(widget.idInmueble);

          if (mounted) {
            Navigator.pop(context);
            _limpiarFormulario();

            AppLogger.info(
              'Pago de renta registrado. Actualizando vista para mostrar el período: ${mesPagoRenta.year}-${mesPagoRenta.month}',
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
                Navigator.of(dialogContext).pop();
                _procesarEliminacion(idMovimiento);
              },
              child: const Text('ELIMINAR'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _procesarEliminacion(int idMovimiento) async {
    try {
      await ref
          .read(movimientosRentaStateProvider(widget.idInmueble).notifier)
          .eliminarMovimiento(idMovimiento, widget.idInmueble);

      if (!mounted) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movimiento eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar movimiento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _construirListaMovimientos(
    AsyncValue<List<MovimientoRenta>> movimientos,
  ) {
    return movimientos.when(
      data: (data) {
        if (data.isEmpty) {
          return const Center(
            child: Text('No hay movimientos en este período'),
          );
        }

        final movimientosOrdenados = List<MovimientoRenta>.from(data)
          ..sort((a, b) => b.fechaMovimiento.compareTo(a.fechaMovimiento));

        return ListView.builder(
          itemCount: movimientosOrdenados.length,
          itemBuilder: (context, index) {
            final movimiento = movimientosOrdenados[index];
            return _construirItemMovimiento(movimiento);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar movimientos: ${error.toString()}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(
                      movimientosPorInmuebleProvider(widget.idInmueble),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
    );
  }

  Widget _construirItemMovimiento(MovimientoRenta movimiento) {
    final esIngreso = movimiento.tipoMovimiento == 'ingreso';
    final color = esIngreso ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(
            51,
          ), // Equivalent to withOpacity(0.2)
          child: Icon(
            esIngreso ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
          ),
        ),
        title: Text(movimiento.concepto),
        subtitle: Text(formatDate.format(movimiento.fechaMovimiento)),
        trailing: Text(
          formatCurrency.format(movimiento.monto),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        onTap: () => _mostrarDetalleMovimiento(movimiento),
      ),
    );
  }

  void _mostrarDetalleMovimiento(MovimientoRenta movimiento) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalle del Movimiento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Divider(),
                _buildDetalleItem('Concepto', movimiento.concepto),
                _buildDetalleItem(
                  'Tipo',
                  movimiento.tipoMovimiento == 'ingreso' ? 'Ingreso' : 'Egreso',
                ),
                _buildDetalleItem(
                  'Monto',
                  formatCurrency.format(movimiento.monto),
                ),
                _buildDetalleItem(
                  'Fecha',
                  formatDate.format(movimiento.fechaMovimiento),
                ),
                if (movimiento.comentarios != null &&
                    movimiento.comentarios!.isNotEmpty)
                  _buildDetalleItem('Comentarios', movimiento.comentarios!),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _confirmarEliminarMovimiento(movimiento.id!);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'MMMM yyyy',
                                        'es_ES',
                                      ).format(mesPagoRenta),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const Icon(Icons.calendar_today),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                      // Campo de concepto
                      TextFormField(
                        controller: _conceptoController,
                        decoration: const InputDecoration(
                          labelText: 'Concepto',
                          hintText: 'Ej: Pago de renta, Reparación, etc.',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un concepto';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo de monto
                      TextFormField(
                        controller: _montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          hintText: 'Ej: 5000',
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un monto';
                          }
                          try {
                            final monto = double.parse(value);
                            if (monto <= 0) {
                              return 'El monto debe ser mayor a cero';
                            }
                          } catch (e) {
                            return 'Por favor ingrese un monto válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Selector de fecha
                      Row(
                        children: [
                          const Text('Fecha:'),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _fechaMovimiento,
                                  firstDate: DateTime(
                                    DateTime.now().year - 2,
                                    1,
                                  ),
                                  lastDate: DateTime.now(),
                                  helpText: 'Seleccione fecha del movimiento',
                                  cancelText: 'CANCELAR',
                                  confirmText: 'ACEPTAR',
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    _fechaMovimiento = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_fechaMovimiento),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const Icon(Icons.calendar_today),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Campo de comentarios (opcional)
                      TextFormField(
                        controller: _comentariosController,
                        decoration: const InputDecoration(
                          labelText: 'Comentarios (opcional)',
                          hintText: 'Información adicional',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),

                      // Botones de acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCELAR'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed:
                                _isRegistering
                                    ? null
                                    : () {
                                      if (esPagoRenta) {
                                        _registrarPagoRenta(mesPagoRenta);
                                      } else {
                                        _registrarMovimiento();
                                      }
                                    },
                            child:
                                _isRegistering
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      'REGISTRAR ${esPagoRenta
                                          ? "PAGO"
                                          : _isIngreso
                                          ? "INGRESO"
                                          : "EGRESO"}',
                                    ),
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    final movimientosFiltrados = ref.watch(
      movimientosFiltradosPorPeriodoProvider((
        idInmueble: widget.idInmueble,
        periodo: _periodoSeleccionado,
      )),
    );

    final balancePeriodo = ref.watch(
      balancePeriodoProvider(movimientosFiltrados),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Movimientos: ${widget.nombreInmueble}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarSelectorPeriodo,
            tooltip: 'Filtrar por período',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Período: ${_formatearPeriodo(_tipoPeriodSeleccionado, _periodoSeleccionado)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

          _construirTarjetaBalance(balancePeriodo),

          Expanded(child: _construirListaMovimientos(movimientosFiltrados)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioMovimiento(),
        tooltip: 'Registrar movimiento',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarSelectorPeriodo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar período'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _botonPeriodo(TipoPeriodo.dia, 'Día'),
              _botonPeriodo(TipoPeriodo.semana, 'Semana'),
              _botonPeriodo(TipoPeriodo.mes, 'Mes'),
              _botonPeriodo(TipoPeriodo.bimestre, 'Bimestre'),
              _botonPeriodo(TipoPeriodo.trimestre, 'Trimestre'),
              _botonPeriodo(TipoPeriodo.semestre, 'Semestre'),
              _botonPeriodo(TipoPeriodo.anio, 'Año'),
              ListTile(
                title: const Text('Personalizado'),
                leading: const Icon(Icons.date_range),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarPeriodoPersonalizado();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _botonPeriodo(TipoPeriodo tipo, String label) {
    return ListTile(
      title: Text(label),
      leading: Icon(
        _getIconoTipoPeriodo(tipo),
        color:
            _tipoPeriodSeleccionado == tipo
                ? Theme.of(context).primaryColor
                : null,
      ),
      selected: _tipoPeriodSeleccionado == tipo,
      onTap: () {
        Navigator.pop(context);
        _cambiarPeriodo(tipo);
      },
    );
  }

  IconData _getIconoTipoPeriodo(TipoPeriodo tipo) {
    switch (tipo) {
      case TipoPeriodo.dia:
        return Icons.today;
      case TipoPeriodo.semana:
        return Icons.view_week;
      case TipoPeriodo.mes:
        return Icons.calendar_view_month;
      case TipoPeriodo.bimestre:
        return Icons.calendar_today;
      case TipoPeriodo.trimestre:
        return Icons.date_range;
      case TipoPeriodo.semestre:
        return Icons.event_note;
      case TipoPeriodo.anio:
        return Icons.calendar_month;
      case TipoPeriodo.personalizado:
        return Icons.date_range;
    }
  }

  String _formatearPeriodo(TipoPeriodo tipo, DateTimeRange periodo) {
    final formatter = DateFormat('dd/MM/yyyy');
    final inicio = formatter.format(periodo.start);
    final fin = formatter.format(periodo.end);

    switch (tipo) {
      case TipoPeriodo.dia:
        return 'Día $inicio';
      case TipoPeriodo.semana:
        return 'Semana del $inicio al $fin';
      case TipoPeriodo.mes:
        return 'Mes ${DateFormat('MMMM yyyy', 'es_ES').format(periodo.start)}';
      case TipoPeriodo.bimestre:
        return 'Bimestre ${periodo.start.month}-${periodo.start.month + 1} ${periodo.start.year}';
      case TipoPeriodo.trimestre:
        return 'Trimestre ${((periodo.start.month - 1) ~/ 3) + 1} del ${periodo.start.year}';
      case TipoPeriodo.semestre:
        return 'Semestre ${periodo.start.month <= 6 ? 1 : 2} del ${periodo.start.year}';
      case TipoPeriodo.anio:
        return 'Año ${periodo.start.year}';
      case TipoPeriodo.personalizado:
        return '$inicio - $fin';
    }
  }

  Widget _construirTarjetaBalance(Map<String, double> balance) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Balance del Período',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _construirItemBalance(
                  'Ingresos',
                  balance['ingresos'] ?? 0,
                  Icons.arrow_upward,
                  Colors.green,
                ),
                _construirItemBalance(
                  'Egresos',
                  balance['egresos'] ?? 0,
                  Icons.arrow_downward,
                  Colors.red,
                ),
                _construirItemBalance(
                  'Balance',
                  balance['balance'] ?? 0,
                  Icons.account_balance,
                  (balance['balance'] ?? 0) >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirItemBalance(
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color),
        Text(label),
        Text(
          formatCurrency.format(value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}

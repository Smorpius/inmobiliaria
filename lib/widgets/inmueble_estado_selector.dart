import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import '../models/inmueble_model.dart';
import '../controllers/inmueble_controller.dart';
import '../utils/app_colors.dart'; // Importar AppColors

class InmuebleEstadoSelector extends StatefulWidget {
  final Inmueble inmueble;
  final Function() onEstadoChanged;
  final InmuebleController controller;

  const InmuebleEstadoSelector({
    super.key,
    required this.inmueble,
    required this.onEstadoChanged,
    required this.controller,
  });

  @override
  State<InmuebleEstadoSelector> createState() => _InmuebleEstadoSelectorState();
}

class _InmuebleEstadoSelectorState extends State<InmuebleEstadoSelector> {
  int? _estadoSeleccionado;
  bool _isLoading = false;

  // Control para evitar operaciones concurrentes
  bool _operacionEnProceso = false;

  // Control para registrar errores sin duplicados
  final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _intervaloMinimoErrores = Duration(minutes: 1);

  final Map<int, String> _estados = {
    3: 'Disponible',
    6: 'En Negociación',
    4: 'Vendido',
    5: 'Rentado',
    2: 'No Disponible', // Agregado estado No Disponible
  };

  // Mapa de colores para cada estado según la paleta centralizada
  final Map<int, Color> _estadoColores = {
    1: AppColors.error.withAlpha(204), // No disponible oscuro
    2: AppColors.error, // No disponible
    3: AppColors.exito, // Disponible
    4: AppColors.info, // Vendido
    5: AppColors.acento, // Rentado
    6: AppColors.advertencia, // En negociación
  };

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.inmueble.idEstado ?? 3;
    AppLogger.debug(
      'InmuebleEstadoSelector inicializado con estado: $_estadoSeleccionado',
    );
  }

  @override
  void didUpdateWidget(InmuebleEstadoSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inmueble.idEstado != widget.inmueble.idEstado) {
      setState(() {
        _estadoSeleccionado = widget.inmueble.idEstado ?? 3;
      });
      AppLogger.debug(
        'Estado actualizado por prop change a: $_estadoSeleccionado',
      );
    }
  }

  Future<void> _cambiarEstado(int nuevoEstado) async {
    // Evitar operaciones duplicadas
    if (_operacionEnProceso) {
      AppLogger.warning('Operación ya en progreso, evitando duplicación');
      return;
    }

    // Verificar si realmente hay cambio de estado
    if (nuevoEstado == _estadoSeleccionado) {
      AppLogger.debug('Mismo estado seleccionado, no se requiere cambio');
      return;
    }

    AppLogger.info(
      'Iniciando cambio de estado: ${_estados[_estadoSeleccionado]} -> ${_estados[nuevoEstado]}',
    );

    // Iniciar control operación
    _operacionEnProceso = true;

    // Estados que requieren confirmación
    final estadosImportantes = [4, 5]; // Vendido, Rentado

    if (estadosImportantes.contains(nuevoEstado)) {
      final confirmar = await _mostrarDialogoConfirmacion(nuevoEstado);
      if (confirmar != true) {
        _operacionEnProceso = false;
        return;
      }
    }

    if (!mounted) {
      _operacionEnProceso = false;
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verificar que el inmueble tenga ID válido
      if (widget.inmueble.id == null) {
        throw Exception('No se puede actualizar un inmueble sin ID');
      }

      AppLogger.info(
        'Actualizando estado de inmueble ID: ${widget.inmueble.id} a ${_estados[nuevoEstado]}',
      );

      // Crear una copia del inmueble con el nuevo estado
      final inmuebleActualizado = Inmueble(
        id: widget.inmueble.id,
        nombre: widget.inmueble.nombre,
        montoTotal: widget.inmueble.montoTotal,
        idDireccion: widget.inmueble.idDireccion,
        idEstado: nuevoEstado,
        idCliente: widget.inmueble.idCliente,
        idEmpleado: widget.inmueble.idEmpleado,
        tipoInmueble: widget.inmueble.tipoInmueble,
        tipoOperacion: widget.inmueble.tipoOperacion,
        precioVenta: widget.inmueble.precioVenta,
        precioRenta: widget.inmueble.precioRenta,
        caracteristicas: widget.inmueble.caracteristicas,
        calle: widget.inmueble.calle,
        numero: widget.inmueble.numero,
        colonia: widget.inmueble.colonia,
        ciudad: widget.inmueble.ciudad,
        estadoGeografico: widget.inmueble.estadoGeografico,
        codigoPostal: widget.inmueble.codigoPostal,
        referencias: widget.inmueble.referencias,
        // Preservar otros campos financieros
        costoCliente: widget.inmueble.costoCliente,
        costoServicios: widget.inmueble.costoServicios,
        comisionAgencia: widget.inmueble.comisionAgencia,
        comisionAgente: widget.inmueble.comisionAgente,
        precioVentaFinal: widget.inmueble.precioVentaFinal,
        margenUtilidad: widget.inmueble.margenUtilidad,
      );

      // Actualizar en la base de datos
      await widget.controller
          .updateInmueble(inmuebleActualizado)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('La operación tardó demasiado tiempo');
            },
          );

      if (!mounted) return;

      setState(() {
        _estadoSeleccionado = nuevoEstado;
        _isLoading = false;
      });

      widget.onEstadoChanged();
      AppLogger.info(
        'Estado actualizado exitosamente a: ${_estados[nuevoEstado]}',
      );

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a ${_estados[nuevoEstado]}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      // Registrar error sin duplicados
      _registrarErrorControlado(
        'cambiar_estado',
        'Error al actualizar estado',
        e,
        stackTrace,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Determinar tipo de error para mostrar mensaje más específico
      final errorMessage = _obtenerMensajeErrorFriendly(e.toString());

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      // Siempre liberar el control de operación
      _operacionEnProceso = false;
    }
  }

  /// Muestra un diálogo para confirmar cambio de estado
  Future<bool?> _mostrarDialogoConfirmacion(int nuevoEstado) async {
    if (!mounted) return false;

    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar cambio de estado'),
            content: Text(
              '¿Está seguro de cambiar el estado a ${_estados[nuevoEstado]}? '
              'Esta acción puede tener implicaciones importantes en el proceso de venta/renta.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
  }

  /// Registra errores evitando duplicados en periodo corto
  void _registrarErrorControlado(
    String codigo,
    String mensaje,
    Object error,
    StackTrace stackTrace,
  ) {
    final ahora = DateTime.now();
    final errorKey = codigo;

    // Evitar errores duplicados en corto periodo
    if (_ultimosErrores.containsKey(errorKey) &&
        ahora.difference(_ultimosErrores[errorKey]!) <
            _intervaloMinimoErrores) {
      return;
    }

    // Registrar error
    _ultimosErrores[errorKey] = ahora;

    // Limpiar mapa para evitar fugas de memoria
    if (_ultimosErrores.length > 10) {
      final entradaAntigua =
          _ultimosErrores.entries
              .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
              .key;
      _ultimosErrores.remove(entradaAntigua);
    }

    AppLogger.error('$mensaje: ${error.toString()}', error, stackTrace);
  }

  /// Convierte errores técnicos en mensajes amigables
  String _obtenerMensajeErrorFriendly(String errorOriginal) {
    if (errorOriginal.contains('Connection refused') ||
        errorOriginal.contains('socket') ||
        errorOriginal.contains('timeout')) {
      return 'Error de conexión. Por favor verifique su conexión e intente nuevamente.';
    } else if (errorOriginal.contains('MySQL') ||
        errorOriginal.contains('database') ||
        errorOriginal.contains('SQL')) {
      return 'Error en la base de datos. Intente nuevamente más tarde.';
    } else {
      return 'Error al cambiar estado: ${errorOriginal.split('\n').first}';
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estado del Inmueble',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _estadoColores[_estadoSeleccionado]?.withAlpha(51) ??
                          Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            _estadoColores[_estadoSeleccionado] ?? Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForEstado(_estadoSeleccionado ?? 3),
                          color:
                              _estadoColores[_estadoSeleccionado] ??
                              Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _estados[_estadoSeleccionado] ?? 'Desconocido',
                          style: TextStyle(
                            color:
                                _estadoColores[_estadoSeleccionado] ??
                                Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : PopupMenuButton<int>(
                        tooltip: 'Cambiar estado',
                        icon: const Icon(Icons.edit),
                        onSelected: _cambiarEstado,
                        itemBuilder:
                            (context) =>
                                _estados.entries
                                    .map((entry) {
                                      // No mostrar opción del estado actual
                                      if (entry.key == _estadoSeleccionado) {
                                        return null;
                                      }

                                      return PopupMenuItem<int>(
                                        value: entry.key,
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getIconForEstado(entry.key),
                                              color: _estadoColores[entry.key],
                                              size: 18,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(entry.value),
                                          ],
                                        ),
                                      );
                                    })
                                    .whereType<PopupMenuItem<int>>()
                                    .toList(),
                      ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'build_error',
        'Error al construir widget de estado',
        e,
        stackTrace,
      );

      // Widget de fallback en caso de error
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar selector de estado: ${e.toString().split('\n').first}',
            style: TextStyle(color: Colors.red.shade800),
          ),
        ),
      );
    }
  }

  IconData _getIconForEstado(int estado) {
    try {
      switch (estado) {
        case 2: // No Disponible
          return Icons.cancel;
        case 3: // Disponible
          return Icons.check_circle;
        case 4: // Vendido
          return Icons.sell;
        case 5: // Rentado
          return Icons.home;
        case 6: // En Negociación
          return Icons.handshake;
        default:
          return Icons.help;
      }
    } catch (e) {
      AppLogger.warning('Error al obtener icono para estado $estado: $e');
      return Icons.error;
    }
  }

  @override
  void dispose() {
    // Limpiar recursos
    _ultimosErrores.clear();
    AppLogger.debug('InmuebleEstadoSelector - Recursos liberados');
    super.dispose();
  }
}

/// Excepción personalizada para timeout
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

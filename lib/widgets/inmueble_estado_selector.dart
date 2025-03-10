import 'package:flutter/material.dart';
import '../models/inmueble_model.dart';
import '../controllers/inmueble_controller.dart';

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

  final Map<int, String> _estados = {
    3: 'Disponible',
    6: 'En Negociación',
    4: 'Vendido',
    5: 'Rentado',
  };

  final Map<int, Color> _estadoColores = {
    3: Colors.green, // Disponible
    6: Colors.orange, // En Negociación
    4: Colors.blue, // Vendido
    5: Colors.purple, // Rentado
  };

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.inmueble.idEstado ?? 3;
  }

  @override
  void didUpdateWidget(InmuebleEstadoSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inmueble.idEstado != widget.inmueble.idEstado) {
      _estadoSeleccionado = widget.inmueble.idEstado ?? 3;
    }
  }

  Future<void> _cambiarEstado(int nuevoEstado) async {
    // Si es el mismo estado, no hacemos nada
    if (nuevoEstado == _estadoSeleccionado) return;

    // Estados que requieren confirmación
    final estadosImportantes = [4, 5]; // Vendido, Rentado

    if (estadosImportantes.contains(nuevoEstado)) {
      final confirmar = await showDialog<bool>(
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

      if (confirmar != true) return;
    }

    setState(() => _isLoading = true);

    try {
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
      );

      await widget.controller.updateInmueble(inmuebleActualizado);

      setState(() {
        _estadoSeleccionado = nuevoEstado;
        _isLoading = false;
      });

      widget.onEstadoChanged();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a ${_estados[nuevoEstado]}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        _estadoColores[_estadoSeleccionado]?.withAlpha(
                          51,
                        ) ?? // 0.2 * 255 = 51
                        Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _estadoColores[_estadoSeleccionado] ?? Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconForEstado(_estadoSeleccionado ?? 3),
                        color:
                            _estadoColores[_estadoSeleccionado] ?? Colors.grey,
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
                              _estados.entries.map((entry) {
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
                              }).toList(),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForEstado(int estado) {
    switch (estado) {
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
  }
}

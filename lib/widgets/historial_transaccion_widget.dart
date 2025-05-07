import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/historial_transaccion_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_colors.dart'; // Importando AppColors
import '../providers/historial_transaccion_provider.dart';

/// Widget para mostrar el historial de cambios de una entidad
class HistorialTransaccionWidget extends ConsumerStatefulWidget {
  final String
  tipoEntidad; // 'venta', 'contrato_renta', 'movimiento_renta', etc.
  final int idEntidad;

  const HistorialTransaccionWidget({
    super.key,
    required this.tipoEntidad,
    required this.idEntidad,
  });

  @override
  ConsumerState<HistorialTransaccionWidget> createState() =>
      _HistorialTransaccionWidgetState();
}

class _HistorialTransaccionWidgetState
    extends ConsumerState<HistorialTransaccionWidget> {
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  bool _mostrarFiltros = false;

  @override
  Widget build(BuildContext context) {
    // Elegir el provider adecuado según el tipo de entidad
    final AsyncValue<List<HistorialTransaccion>> historialAsyncValue;

    if (widget.tipoEntidad == 'venta') {
      historialAsyncValue = ref.watch(historialVentaProvider(widget.idEntidad));
    } else if (widget.tipoEntidad == 'movimiento_renta') {
      historialAsyncValue = ref.watch(
        historialMovimientoProvider(widget.idEntidad),
      );
    } else if (widget.tipoEntidad == 'contrato_renta') {
      historialAsyncValue = ref.watch(
        historialContratoProvider(widget.idEntidad),
      );
    } else {
      // Para otros tipos o filtros personalizados
      historialAsyncValue = ref.watch(
        historialFiltradoProvider((
          tipoEntidad: widget.tipoEntidad,
          idEntidad: widget.idEntidad,
          fechaDesde: _fechaDesde,
          fechaHasta: _fechaHasta,
        )),
      );
    }

    return Column(
      children: [
        _buildHeader(context),

        if (_mostrarFiltros) _buildFiltros(),

        Expanded(
          child: historialAsyncValue.when(
            data: (historial) {
              if (historial.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay cambios registrados en el historial',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: historial.length,
                itemBuilder: (context, index) {
                  final item = historial[index];
                  return _HistorialTransaccionItem(
                    historialItem: item,
                    colorFondo:
                        index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar historial: $error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refrescarHistorial,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Historial de Cambios',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: Icon(
              _mostrarFiltros ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() {
                _mostrarFiltros = !_mostrarFiltros;
              });
            },
            tooltip: _mostrarFiltros ? 'Ocultar filtros' : 'Mostrar filtros',
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar por fecha',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Desde',
                    selectedDate: _fechaDesde,
                    onChanged: (date) {
                      setState(() {
                        _fechaDesde = date;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'Hasta',
                    selectedDate: _fechaHasta,
                    onChanged: (date) {
                      setState(() {
                        _fechaHasta = date;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _limpiarFiltros,
                  child: const Text('Limpiar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _refrescarHistorial,
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime?) onChanged,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final displayText =
        selectedDate != null ? dateFormat.format(selectedDate) : 'Seleccionar';

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );

        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon:
              selectedDate != null
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => onChanged(null),
                  )
                  : const Icon(Icons.calendar_today),
        ),
        child: Text(displayText),
      ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
    });
    _refrescarHistorial();
  }

  void _refrescarHistorial() {
    if (widget.tipoEntidad == 'venta') {
      final refreshedValue = ref.refresh(
        historialVentaProvider(widget.idEntidad),
      );
      refreshedValue
          .toString(); // Using the refreshed value to avoid unused variable warning
    } else if (widget.tipoEntidad == 'movimiento_renta') {
      final refreshedValue = ref.refresh(
        historialMovimientoProvider(widget.idEntidad),
      );
      refreshedValue
          .toString(); // Using the refreshed value to avoid unused variable warning
    } else if (widget.tipoEntidad == 'contrato_renta') {
      final refreshedValue = ref.refresh(
        historialContratoProvider(widget.idEntidad),
      );
      refreshedValue
          .toString(); // Using the refreshed value to avoid unused variable warning
    } else {
      final refreshedValue = ref.refresh(
        historialFiltradoProvider((
          tipoEntidad: widget.tipoEntidad,
          idEntidad: widget.idEntidad,
          fechaDesde: _fechaDesde,
          fechaHasta: _fechaHasta,
        )),
      );
      refreshedValue
          .toString(); // Using the refreshed value to avoid unused variable warning
    }
  }
}

/// Item que muestra un registro en el historial
class _HistorialTransaccionItem extends StatelessWidget {
  final HistorialTransaccion historialItem;
  final Color colorFondo;

  const _HistorialTransaccionItem({
    required this.historialItem,
    this.colorFondo = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = dateFormat.format(historialItem.fechaModificacion);

    // Determinar icono según el campo modificado
    IconData? iconoSegunCampo = _getIconoSegunCampo(
      historialItem.campoModificado,
    );

    // Determinar color según el tipo de cambio
    Color? colorCambio = _getColorSegunCambio(historialItem.campoModificado);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: colorFondo,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con fecha e icono
            Row(
              children: [
                Icon(iconoSegunCampo, color: colorCambio),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Campo: ${_formatCampo(historialItem.campoModificado)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorCambio,
                    ),
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Valores anteriores y nuevos
            if (historialItem.valorAnterior != null ||
                historialItem.valorNuevo != null)
              _buildCambioValores(
                historialItem.valorAnterior,
                historialItem.valorNuevo,
              ),

            // Usuario que realizó el cambio
            if (historialItem.nombreUsuario != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Modificado por: ${historialItem.nombreUsuario}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCambioValores(String? valorAnterior, String? valorNuevo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Valor anterior:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                width: double.infinity,
                child: Text(
                  valorAnterior ?? 'N/A',
                  style: TextStyle(color: Colors.red[800]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Valor nuevo:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                width: double.infinity,
                child: Text(
                  valorNuevo ?? 'N/A',
                  style: TextStyle(color: Colors.green[800]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconoSegunCampo(String campo) {
    campo = campo.toLowerCase();

    if (campo.contains('estado')) {
      return Icons.sync;
    } else if (campo.contains('monto') ||
        campo.contains('precio') ||
        campo.contains('costo')) {
      return Icons.attach_money;
    } else if (campo.contains('fecha')) {
      return Icons.calendar_today;
    } else if (campo.contains('descripcion') ||
        campo.contains('comentario') ||
        campo.contains('nota')) {
      return Icons.description;
    } else if (campo.contains('cliente') ||
        campo.contains('usuario') ||
        campo.contains('empleado')) {
      return Icons.person;
    } else {
      return Icons.edit;
    }
  }

  Color _getColorSegunCambio(String campo) {
    campo = campo.toLowerCase();

    if (campo.contains('estado')) {
      return AppColors.advertencia;
    } else if (campo.contains('monto') ||
        campo.contains('precio') ||
        campo.contains('costo')) {
      return AppColors.exito;
    } else if (campo.contains('eliminado') || campo.contains('cancelado')) {
      return AppColors.error;
    } else {
      return AppColors.info;
    }
  }

  String _formatCampo(String campo) {
    // Convertir snake_case o camelCase a formato legible
    campo = campo
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)?.toLowerCase() ?? ''}',
        );

    // Capitalizar la primera letra
    if (campo.isNotEmpty) {
      campo = campo[0].toUpperCase() + campo.substring(1);
    }

    return campo;
  }
}

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart'; // Importando AppColors

// Enumeración para los tipos de período
enum TipoPeriodo {
  dia,
  semana,
  mes,
  bimestre,
  trimestre,
  semestre,
  anio,
  personalizado,
}

// Callback para notificar cambios en el período
typedef PeriodoCallback = void Function(TipoPeriodo tipo, DateTimeRange rango);

class FiltroPeriodoWidget extends StatefulWidget {
  final TipoPeriodo initialPeriodo;
  final PeriodoCallback onPeriodoChanged;
  final DateTime? initialStartDate; // Opcional: para restaurar estado
  final DateTime? initialEndDate; // Opcional: para restaurar estado

  const FiltroPeriodoWidget({
    super.key,
    this.initialPeriodo = TipoPeriodo.mes,
    required this.onPeriodoChanged,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<FiltroPeriodoWidget> createState() => _FiltroPeriodoWidgetState();

  // Convertir _calcularRangoPorTipo a un método estático
  static DateTimeRange calcularRangoPorTipoEstatico(
    TipoPeriodo tipo, [
    DateTime? baseDate,
  ]) {
    final now = baseDate ?? DateTime.now();
    // Normalizar 'now' a medianoche para evitar problemas con la hora
    final today = DateTime(now.year, now.month, now.day);
    DateTime inicio;
    DateTime fin;

    switch (tipo) {
      case TipoPeriodo.dia:
        inicio = today;
        fin = DateTime(today.year, today.month, today.day, 23, 59, 59);
        break;
      case TipoPeriodo.semana:
        // Encontrar el lunes de la semana actual (primer día de la semana)
        final weekday = today.weekday;
        inicio = today.subtract(Duration(days: weekday - 1));
        fin = inicio.add(
          Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case TipoPeriodo.mes:
        // Primer día del mes actual
        inicio = DateTime(today.year, today.month, 1);
        // Último día del mes actual
        fin = DateTime(today.year, today.month + 1, 0, 23, 59, 59);
        break;
      case TipoPeriodo.bimestre:
        // Calcula el bimestre (1-2, 3-4, 5-6, etc.)
        final mesInicio = ((today.month - 1) ~/ 2) * 2 + 1;
        inicio = DateTime(today.year, mesInicio, 1);
        fin = DateTime(today.year, mesInicio + 2, 0, 23, 59, 59);
        break;
      case TipoPeriodo.trimestre:
        // Calcula el trimestre (1-3, 4-6, 7-9, 10-12)
        final mesInicio = ((today.month - 1) ~/ 3) * 3 + 1;
        inicio = DateTime(today.year, mesInicio, 1);
        fin = DateTime(today.year, mesInicio + 3, 0, 23, 59, 59);
        break;
      case TipoPeriodo.semestre:
        // Primer o segundo semestre
        final mesInicio = today.month <= 6 ? 1 : 7;
        inicio = DateTime(today.year, mesInicio, 1);
        fin = DateTime(today.year, mesInicio + 6, 0, 23, 59, 59);
        break;
      case TipoPeriodo.anio:
        inicio = DateTime(today.year, 1, 1);
        fin = DateTime(today.year, 12, 31, 23, 59, 59);
        break;
      case TipoPeriodo.personalizado:
        // Para personalizado, usa un mes por defecto
        inicio = DateTime(today.year, today.month, 1);
        fin = DateTime(today.year, today.month + 1, 0, 23, 59, 59);
        break;
    }
    // Asegurarse de que fin sea siempre después de inicio
    if (fin.isBefore(inicio)) {
      fin = inicio.add(const Duration(days: 1, seconds: -1));
    }
    return DateTimeRange(start: inicio, end: fin);
  }
}

class _FiltroPeriodoWidgetState extends State<FiltroPeriodoWidget> {
  late TipoPeriodo _selectedPeriodo;
  late DateTimeRange _rangoFechas;
  final DateFormat _formatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _selectedPeriodo = widget.initialPeriodo;
    // Si se proporcionan fechas iniciales y el período es personalizado, usarlas
    if (_selectedPeriodo == TipoPeriodo.personalizado &&
        widget.initialStartDate != null &&
        widget.initialEndDate != null) {
      _rangoFechas = DateTimeRange(
        start: widget.initialStartDate!,
        end: widget.initialEndDate!,
      );
    } else {
      // Calcular el rango basado en el tipo de período inicial usando el método estático
      _rangoFechas = FiltroPeriodoWidget.calcularRangoPorTipoEstatico(
        _selectedPeriodo,
      );
    }

    // Notificar el período inicial al widget padre después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPeriodoChanged(_selectedPeriodo, _rangoFechas);
    });
  }

  // Muestra el selector de rango de fechas personalizado
  Future<void> _mostrarSelectorFechaPersonalizado() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _rangoFechas,
      firstDate: DateTime(2000), // Fecha mínima seleccionable
      lastDate: DateTime.now().add(
        const Duration(days: 365 * 5),
      ), // Fecha máxima seleccionable (5 años a futuro)
      locale: const Locale('es', 'ES'), // Establecer localización en español
      helpText: 'Selecciona un rango de fechas',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      saveText: 'Guardar',
      errorFormatText: 'Formato inválido',
      errorInvalidText: 'Rango inválido',
      errorInvalidRangeText: 'Rango no válido',
      fieldStartHintText: 'Fecha de inicio',
      fieldEndHintText: 'Fecha de fin',
      fieldStartLabelText: 'Inicio',
      fieldEndLabelText: 'Fin',
    );

    if (picked != null && picked != _rangoFechas) {
      setState(() {
        _selectedPeriodo = TipoPeriodo.personalizado;
        // Ajustar la hora final a las 23:59:59.999
        _rangoFechas = DateTimeRange(
          start: picked.start,
          end: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
            999,
          ),
        );
      });
      widget.onPeriodoChanged(_selectedPeriodo, _rangoFechas);
    }
  }

  // Obtiene el nombre legible del tipo de período
  String _getNombrePeriodo(TipoPeriodo tipo) {
    switch (tipo) {
      case TipoPeriodo.dia:
        return 'Día';
      case TipoPeriodo.semana:
        return 'Semana';
      case TipoPeriodo.mes:
        return 'Mes';
      case TipoPeriodo.bimestre:
        return 'Bimestre';
      case TipoPeriodo.trimestre:
        return 'Trimestre';
      case TipoPeriodo.semestre:
        return 'Semestre';
      case TipoPeriodo.anio:
        return 'Año';
      case TipoPeriodo.personalizado:
        return 'Personalizado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chips para seleccionar el período
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children:
              TipoPeriodo.values.map((tipo) {
                // Omitir 'personalizado' de los chips directos
                if (tipo == TipoPeriodo.personalizado) {
                  return const SizedBox.shrink();
                }
                return ChoiceChip(
                  label: Text(_getNombrePeriodo(tipo)),
                  selected: _selectedPeriodo == tipo,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPeriodo = tipo;
                        // Usar el método estático para calcular el rango
                        _rangoFechas =
                            FiltroPeriodoWidget.calcularRangoPorTipoEstatico(
                              tipo,
                            );
                      });
                      widget.onPeriodoChanged(_selectedPeriodo, _rangoFechas);
                    }
                  },
                  selectedColor: Theme.of(context).primaryColor.withAlpha(
                    (255 * 0.2).round(),
                  ), // Usar withAlpha en lugar de withOpacity
                  labelStyle: TextStyle(
                    color:
                        _selectedPeriodo == tipo
                            ? Theme.of(context).primaryColor
                            : null,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 12),
        // Indicador del período seleccionado y botón para personalizar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedPeriodo == TipoPeriodo.personalizado
                    ? 'Periodo: ${_formatter.format(_rangoFechas.start)} - ${_formatter.format(_rangoFechas.end)}'
                    : 'Periodo: ${_getNombrePeriodo(_selectedPeriodo)} (${_formatter.format(_rangoFechas.start)} - ${_formatter.format(_rangoFechas.end)})',
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text('Personalizar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                textStyle: const TextStyle(fontSize: 12),
                side: BorderSide(
                  color:
                      _selectedPeriodo == TipoPeriodo.personalizado
                          ? AppColors.primario
                          : AppColors.grisClaro,
                ),
                foregroundColor:
                    _selectedPeriodo == TipoPeriodo.personalizado
                        ? AppColors.primario
                        : null,
              ),
              onPressed: _mostrarSelectorFechaPersonalizado,
            ),
          ],
        ),
      ],
    );
  }
}

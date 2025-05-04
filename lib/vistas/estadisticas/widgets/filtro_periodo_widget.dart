import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class FiltroPeriodoWidget extends StatelessWidget {
  final DateTimeRange periodo;
  final Function(DateTimeRange) onPeriodChanged;

  const FiltroPeriodoWidget({
    super.key,
    required this.periodo,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Periodo de análisis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectCustomRange(context),
                    child: Card(
                      elevation: 0,
                      color: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Desde',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(dateFormat.format(periodo.start)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectCustomRange(context),
                    child: Card(
                      elevation: 0,
                      color: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hasta',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(dateFormat.format(periodo.end)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPredefinedButtons(context),
                TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: const Text('Seleccionar'),
                  onPressed: () => _selectCustomRange(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredefinedButtons(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        icon: const Icon(Icons.filter_list),
        hint: const Text('Filtro rápido'),
        onChanged: (value) {
          if (value == null) return;

          final now = DateTime.now();
          DateTimeRange newPeriod;

          switch (value) {
            case 'mes_actual':
              final firstDay = DateTime(now.year, now.month, 1);
              final lastDay = DateTime(now.year, now.month + 1, 0);
              newPeriod = DateTimeRange(start: firstDay, end: lastDay);
              break;
            case 'mes_anterior':
              final firstDay = DateTime(now.year, now.month - 1, 1);
              final lastDay = DateTime(now.year, now.month, 0);
              newPeriod = DateTimeRange(start: firstDay, end: lastDay);
              break;
            case 'trimestre':
              final currentQuarter = (now.month - 1) ~/ 3;
              final firstDay = DateTime(now.year, currentQuarter * 3 + 1, 1);
              final lastDay = DateTime(
                now.year,
                (currentQuarter + 1) * 3 + 1,
                0,
              );
              newPeriod = DateTimeRange(start: firstDay, end: lastDay);
              break;
            case 'anio_actual':
              final firstDay = DateTime(now.year, 1, 1);
              final lastDay = DateTime(now.year, 12, 31);
              newPeriod = DateTimeRange(start: firstDay, end: lastDay);
              break;
            case 'anio_anterior':
              final firstDay = DateTime(now.year - 1, 1, 1);
              final lastDay = DateTime(now.year - 1, 12, 31);
              newPeriod = DateTimeRange(start: firstDay, end: lastDay);
              break;
            default:
              return;
          }

          onPeriodChanged(newPeriod);
        },
        items: [
          const DropdownMenuItem(
            value: 'mes_actual',
            child: Text('Mes actual'),
          ),
          const DropdownMenuItem(
            value: 'mes_anterior',
            child: Text('Mes anterior'),
          ),
          const DropdownMenuItem(
            value: 'trimestre',
            child: Text('Trimestre actual'),
          ),
          const DropdownMenuItem(
            value: 'anio_actual',
            child: Text('Año actual'),
          ),
          const DropdownMenuItem(
            value: 'anio_anterior',
            child: Text('Año anterior'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectCustomRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: periodo,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != periodo) {
      onPeriodChanged(picked);
    }
  }
}

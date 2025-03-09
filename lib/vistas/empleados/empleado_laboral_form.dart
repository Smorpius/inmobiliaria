import 'empleado_utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class EmpleadoLaboralForm extends StatefulWidget {
  final TextEditingController claveSistemaController;
  final TextEditingController telefonoController;
  final TextEditingController direccionController;
  final TextEditingController cargoController;
  final TextEditingController sueldoController;
  final TextEditingController nombreController;
  final TextEditingController apellidoController;
  final TextEditingController correoController;
  final DateTime? fechaContratacion;
  final Function(DateTime) onFechaContratacionChanged;

  const EmpleadoLaboralForm({
    super.key,
    required this.claveSistemaController,
    required this.telefonoController,
    required this.direccionController,
    required this.cargoController,
    required this.sueldoController,
    required this.nombreController,
    required this.apellidoController,
    required this.correoController,
    this.fechaContratacion,
    required this.onFechaContratacionChanged,
  });

  @override
  State<EmpleadoLaboralForm> createState() => _EmpleadoLaboralFormState();
}

class _EmpleadoLaboralFormState extends State<EmpleadoLaboralForm> {
  // Formato para mostrar la fecha
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // No agregamos listeners directamente a los controladores
  }

  // Validadores simples para teléfono y cantidad
  bool _isValidPhone(String phone) {
    // Validar que solo contenga números y tenga una longitud adecuada (entre 8 y 15 dígitos)
    final phoneRegExp = RegExp(r'^[0-9]{8,15}$');
    return phoneRegExp.hasMatch(phone);
  }

  bool _isValidAmount(String amount) {
    // Validar que sea un número decimal válido
    try {
      final value = double.parse(amount);
      return value > 0; // El sueldo debe ser positivo
    } catch (e) {
      return false;
    }
  }

  // Método de selección de fecha utilizando un diálogo personalizado
  Future<void> _seleccionarFechaAlternativo(BuildContext context) async {
    // Fecha inicial a mostrar
    final initialDate = widget.fechaContratacion ?? DateTime.now();

    // Variables para construir el calendario
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    int selectedDay = initialDate.day;

    // Nombres de meses en español
    const List<String> meses = [
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

    // Mostrar diálogo personalizado
    final result = await showDialog<DateTime>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleccionar fecha'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selector de año
                    DropdownButton<int>(
                      value: selectedYear,
                      items: List.generate(
                        51, // Años desde 2000 hasta 2050
                        (index) => DropdownMenuItem(
                          value: 2000 + index,
                          child: Text('${2000 + index}'),
                        ),
                      ),
                      onChanged: (year) {
                        if (year != null) {
                          setState(() => selectedYear = year);
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // Selector de mes
                    DropdownButton<int>(
                      value: selectedMonth,
                      items: List.generate(
                        12,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text(meses[index]),
                        ),
                      ),
                      onChanged: (month) {
                        if (month != null) {
                          setState(() => selectedMonth = month);

                          // Ajustar día si es necesario (para meses con menos días)
                          final daysInMonth =
                              DateTime(selectedYear, selectedMonth + 1, 0).day;
                          if (selectedDay > daysInMonth) {
                            selectedDay = daysInMonth;
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // Selector de día
                    DropdownButton<int>(
                      value: selectedDay,
                      items: List.generate(
                        DateTime(selectedYear, selectedMonth + 1, 0).day,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1}'),
                        ),
                      ),
                      onChanged: (day) {
                        if (day != null) {
                          setState(() => selectedDay = day);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    DateTime(selectedYear, selectedMonth, selectedDay),
                  );
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );

    if (result != null && result != widget.fechaContratacion) {
      widget.onFechaContratacionChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Laboral',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Divider(),
        const SizedBox(height: 10),

        // Clave y Cargo
        Row(
          children: [
            // Clave Sistema
            Expanded(
              child: TextFormField(
                controller: widget.claveSistemaController,
                decoration: EmpleadoStyles.getInputDecoration(
                  'Clave Sistema',
                  Icons.badge,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la clave del sistema';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            // Cargo
            Expanded(
              child: TextFormField(
                controller: widget.cargoController,
                decoration: EmpleadoStyles.getInputDecoration(
                  'Cargo',
                  Icons.work,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el cargo';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Teléfono y Sueldo
        Row(
          children: [
            // Teléfono
            Expanded(
              child: TextFormField(
                controller: widget.telefonoController,
                decoration: EmpleadoStyles.getInputDecoration(
                  'Teléfono',
                  Icons.phone,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el teléfono';
                  } else if (!_isValidPhone(value)) {
                    return 'Teléfono inválido (8-15 dígitos)';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            // Sueldo
            Expanded(
              child: TextFormField(
                controller: widget.sueldoController,
                decoration: InputDecoration(
                  labelText: 'Sueldo',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: '₽',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el sueldo';
                  } else if (!_isValidAmount(value)) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Dirección (fila completa)
        TextFormField(
          controller: widget.direccionController,
          decoration: EmpleadoStyles.getInputDecoration(
            'Dirección',
            Icons.home,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese la dirección';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Fecha de contratación (con selector)
        InkWell(
          onTap: () => _seleccionarFechaAlternativo(context),
          child: InputDecorator(
            decoration: EmpleadoStyles.getInputDecoration(
              'Fecha de Contratación',
              Icons.calendar_today,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.fechaContratacion != null
                      ? _dateFormat.format(widget.fechaContratacion!)
                      : 'Seleccionar fecha',
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

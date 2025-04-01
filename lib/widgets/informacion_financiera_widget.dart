import 'dart:async';
import '../utils/applogger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InformacionFinancieraWidget extends StatefulWidget {
  final TextEditingController costoClienteController;
  final TextEditingController costoServiciosController;
  final TextEditingController comisionAgenciaController;
  final TextEditingController comisionAgenteController;
  final TextEditingController precioVentaFinalController;
  final TextEditingController margenUtilidadController;
  final Function() onCostoChanged;
  final String? Function(String?) validarCostos;
  final bool isLoading;

  const InformacionFinancieraWidget({
    super.key,
    required this.costoClienteController,
    required this.costoServiciosController,
    required this.comisionAgenciaController,
    required this.comisionAgenteController,
    required this.precioVentaFinalController,
    required this.margenUtilidadController,
    required this.onCostoChanged,
    required this.validarCostos,
    this.isLoading = false,
  });

  @override
  State<InformacionFinancieraWidget> createState() =>
      _InformacionFinancieraWidgetState();
}

class _InformacionFinancieraWidgetState
    extends State<InformacionFinancieraWidget> {
  // Control para evitar operaciones duplicadas
  bool _procesandoOperacion = false;

  // Control para verificar si el widget está montado
  bool _isDisposed = false;

  // Debounce para evitar múltiples cálculos al modificar valores
  Timer? _debounceTimer;

  // Mapa para control de errores y evitar duplicados
  final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _intervaloMinimoErrores = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    AppLogger.debug('Inicializando InformacionFinancieraWidget');
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _ultimosErrores.clear();
    AppLogger.debug('Liberando recursos de InformacionFinancieraWidget');
    super.dispose();
  }

  /// Registra un error controlando duplicados
  void _registrarErrorControlado(
    String codigo,
    String mensaje,
    dynamic error,
    StackTrace stackTrace,
  ) {
    final errorKey = codigo;
    final ahora = DateTime.now();

    // Evitar errores duplicados en corto periodo
    if (_ultimosErrores.containsKey(errorKey) &&
        ahora.difference(_ultimosErrores[errorKey]!) <
            _intervaloMinimoErrores) {
      return;
    }

    // Registrar error
    _ultimosErrores[errorKey] = ahora;

    // Limitar tamaño del mapa para evitar fugas de memoria
    if (_ultimosErrores.length > 10) {
      final entradaAntigua =
          _ultimosErrores.entries
              .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
              .key;
      _ultimosErrores.remove(entradaAntigua);
    }

    AppLogger.error('$mensaje: ${error.toString()}', error, stackTrace);
  }

  /// Método seguro para manejar cambios de costo con debounce
  void _manejarCambioCosto() {
    if (_procesandoOperacion || widget.isLoading) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      try {
        if (_isDisposed || !mounted) return;

        _procesandoOperacion = true;
        widget.onCostoChanged();
      } catch (e, stackTrace) {
        _registrarErrorControlado(
          'cambio_costo_error',
          'Error al actualizar los costos',
          e,
          stackTrace,
        );
      } finally {
        _procesandoOperacion = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Financiera',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Costo del Cliente
          _buildNumberField(
            controller: widget.costoClienteController,
            labelText: 'Costo del Cliente',
            hintText: 'Ingrese el costo solicitado por el cliente',
            icon: Icons.person_outline,
            validator: widget.validarCostos,
            onChanged: _manejarCambioCosto,
          ),
          const SizedBox(height: 16),

          // Costo de Servicios
          _buildNumberField(
            controller: widget.costoServiciosController,
            labelText: 'Costo de Servicios',
            hintText: 'Ingrese el costo de servicios y proveedores',
            icon: Icons.home_repair_service,
            validator: widget.validarCostos,
            onChanged: _manejarCambioCosto,
          ),
          const SizedBox(height: 16),

          // Comisión Agencia (solo lectura)
          _buildReadOnlyField(
            controller: widget.comisionAgenciaController,
            labelText: 'Comisión Agencia (30%)',
            icon: Icons.business,
            helperText:
                'Calculado automáticamente como 30% del costo del cliente',
          ),
          const SizedBox(height: 16),

          // Comisión Agente (solo lectura)
          _buildReadOnlyField(
            controller: widget.comisionAgenteController,
            labelText: 'Comisión Agente (3%)',
            icon: Icons.person,
            helperText:
                'Calculado automáticamente como 3% del costo del cliente',
          ),
          const SizedBox(height: 16),

          // Precio Venta Final (solo lectura)
          _buildReadOnlyField(
            controller: widget.precioVentaFinalController,
            labelText: 'Precio de Venta Final',
            icon: Icons.money,
            helperText: 'Suma del costo del cliente, servicios y comisiones',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Margen de Utilidad (solo lectura)
          _buildReadOnlyField(
            controller: widget.margenUtilidadController,
            labelText: 'Margen de Utilidad (%)',
            icon: Icons.trending_up,
            helperText: 'Porcentaje de ganancia sobre el precio final',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            suffixText: '%',
            showPrefixSign: false,
          ),
        ],
      );
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'informacion_financiera_build_error',
        'Error al construir widget de información financiera',
        e,
        stackTrace,
      );

      // En caso de error, devolver un widget mínimo para evitar pantalla en blanco
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar el formulario de información financiera',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  /// Widget para campos numéricos con manejo de error consistente
  Widget _buildNumberField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required Function(String?) validator,
    required VoidCallback onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        prefixText: '\$ ',
        errorStyle: const TextStyle(height: 0.7),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (value) => validator(value),
      onChanged: (value) {
        if (value.isEmpty) return; // Evitar cálculos con valores vacíos

        // Validación adicional para asegurar formato numérico correcto
        try {
          final numValue = double.tryParse(value);
          if (numValue == null) return;

          onChanged();
        } catch (e, stackTrace) {
          _registrarErrorControlado(
            'validacion_numerica',
            'Error al validar formato numérico',
            e,
            stackTrace,
          );
        }
      },
      enabled: !widget.isLoading,
    );
  }

  /// Widget para campos de solo lectura con estilo uniforme
  Widget _buildReadOnlyField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required String helperText,
    TextStyle? style,
    String? suffixText,
    bool showPrefixSign = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        prefixText: showPrefixSign ? '\$ ' : null,
        suffixText: suffixText,
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 12),
        errorStyle: const TextStyle(height: 0.7),
        fillColor: Colors.grey.shade50,
        filled: true,
      ),
      style: style,
      readOnly: true,
    );
  }
}

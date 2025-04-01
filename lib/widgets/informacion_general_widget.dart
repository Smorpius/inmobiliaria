import '../utils/applogger.dart';
import '../models/cliente_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InformacionGeneralWidget extends StatefulWidget {
  final TextEditingController nombreController;
  final String tipoInmuebleSeleccionado;
  final String tipoOperacionSeleccionado;
  final TextEditingController precioVentaController;
  final TextEditingController precioRentaController;
  final TextEditingController montoController;
  final TextEditingController caracteristicasController;
  final List<String> tiposInmueble;
  final List<String> tiposOperacion;
  final Function(String?) onTipoInmuebleChanged;
  final Function(String?) onTipoOperacionChanged;
  final Function(String?) validarNombre;
  final Function(String?) validarMonto;
  final Function(String?) validarPrecioVenta;
  final Function(String?) validarPrecioRenta;
  final bool isLoading;

  const InformacionGeneralWidget({
    super.key,
    required this.nombreController,
    required this.tipoInmuebleSeleccionado,
    required this.tipoOperacionSeleccionado,
    required this.precioVentaController,
    required this.precioRentaController,
    required this.montoController,
    required this.caracteristicasController,
    required this.tiposInmueble,
    required this.tiposOperacion,
    required this.onTipoInmuebleChanged,
    required this.onTipoOperacionChanged,
    required this.validarNombre,
    required this.validarMonto,
    required this.validarPrecioVenta,
    required this.validarPrecioRenta,
    this.isLoading = false,
  });

  @override
  State<InformacionGeneralWidget> createState() =>
      _InformacionGeneralWidgetState();
}

class _InformacionGeneralWidgetState extends State<InformacionGeneralWidget> {
  // Control para evitar procesamiento de operaciones duplicadas
  bool _procesandoOperacion = false;

  // Control para verificar si el widget está montado

  // Mapa para control de errores y evitar duplicados
  final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _intervaloMinimoErrores = Duration(minutes: 1);

  @override
  @override
  void dispose() {
    _ultimosErrores.clear();
    super.dispose();
  }

  // Registrar error controlando duplicados
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

  // Método para actualización segura tras cambio de tipo
  void _manejarCambioTipo(String? value, Function(String?) handler) {
    if (_procesandoOperacion) return;

    try {
      _procesandoOperacion = true;

      if (value != null) {
        handler(value);
      }
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'cambio_tipo_error',
        'Error al cambiar tipo de inmueble/operación',
        e,
        stackTrace,
      );
    } finally {
      _procesandoOperacion = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información General',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Nombre del inmueble
          TextFormField(
            controller: widget.nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre del Inmueble',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home),
            ),
            enabled: !widget.isLoading,
            validator: (value) => widget.validarNombre(value),
          ),
          const SizedBox(height: 16),

          // Tipo de inmueble
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Tipo de Inmueble',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            value: widget.tipoInmuebleSeleccionado,
            items:
                widget.tiposInmueble.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo[0].toUpperCase() + tipo.substring(1)),
                  );
                }).toList(),
            onChanged:
                widget.isLoading
                    ? null
                    : (value) =>
                        _manejarCambioTipo(value, widget.onTipoInmuebleChanged),
          ),
          const SizedBox(height: 16),

          // Tipo de operación
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Tipo de Operación',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sell),
            ),
            value: widget.tipoOperacionSeleccionado,
            items:
                widget.tiposOperacion.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo[0].toUpperCase() + tipo.substring(1)),
                  );
                }).toList(),
            onChanged:
                widget.isLoading
                    ? null
                    : (value) => _manejarCambioTipo(
                      value,
                      widget.onTipoOperacionChanged,
                    ),
          ),
          const SizedBox(height: 16),

          // Precio según tipo de operación
          if (widget.tipoOperacionSeleccionado == 'venta' ||
              widget.tipoOperacionSeleccionado == 'ambos')
            _buildCurrencyField(
              controller: widget.precioVentaController,
              labelText: 'Precio de Venta',
              icon: Icons.attach_money,
              validator: widget.validarPrecioVenta,
            ),

          if (widget.tipoOperacionSeleccionado == 'renta' ||
              widget.tipoOperacionSeleccionado == 'ambos')
            _buildCurrencyField(
              controller: widget.precioRentaController,
              labelText: 'Precio de Renta',
              icon: Icons.attach_money,
              validator: widget.validarPrecioRenta,
            ),

          // Monto total
          _buildCurrencyField(
            controller: widget.montoController,
            labelText: 'Monto Total',
            icon: Icons.monetization_on,
            validator: widget.validarMonto,
          ),
          const SizedBox(height: 16),

          // Características
          TextFormField(
            controller: widget.caracteristicasController,
            decoration: const InputDecoration(
              labelText: 'Características',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              hintText: 'Describa las principales características del inmueble',
            ),
            maxLines: 3,
            enabled: !widget.isLoading,
          ),
        ],
      );
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'informacion_general_build_error',
        'Error al construir widget de información general',
        e,
        stackTrace,
      );

      // En caso de error, devolver un widget mínimo para evitar pantalla en blanco
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar el formulario de información general',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  // Método para construir campos de moneda con formato y validación consistentes
  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
          prefixText: '\$ ',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        validator: (value) => validator(value),
        enabled: !widget.isLoading,
      ),
    );
  }
}

class DireccionWidget extends StatefulWidget {
  final TextEditingController calleController;
  final TextEditingController numeroController;
  final TextEditingController coloniaController;
  final TextEditingController ciudadController;
  final TextEditingController estadoGeograficoController;
  final TextEditingController codigoPostalController;
  final TextEditingController referenciasController;
  final Function(String?) validarCalle;
  final Function(String?) validarCiudad;
  final Function(String?) validarEstado;
  final bool isLoading;

  const DireccionWidget({
    super.key,
    required this.calleController,
    required this.numeroController,
    required this.coloniaController,
    required this.ciudadController,
    required this.estadoGeograficoController,
    required this.codigoPostalController,
    required this.referenciasController,
    required this.validarCalle,
    required this.validarCiudad,
    required this.validarEstado,
    this.isLoading = false,
  });

  @override
  State<DireccionWidget> createState() => _DireccionWidgetState();
}

class _DireccionWidgetState extends State<DireccionWidget> {
  final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _intervaloMinimoErrores = Duration(minutes: 1);

  @override
  void dispose() {
    _ultimosErrores.clear();
    super.dispose();
  }

  void _registrarErrorControlado(
    String codigo,
    String mensaje,
    dynamic error,
    StackTrace stackTrace,
  ) {
    final errorKey = codigo;
    final ahora = DateTime.now();

    if (_ultimosErrores.containsKey(errorKey) &&
        ahora.difference(_ultimosErrores[errorKey]!) <
            _intervaloMinimoErrores) {
      return;
    }

    _ultimosErrores[errorKey] = ahora;

    if (_ultimosErrores.length > 10) {
      final entradaAntigua =
          _ultimosErrores.entries
              .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
              .key;
      _ultimosErrores.remove(entradaAntigua);
    }

    AppLogger.error('$mensaje: ${error.toString()}', error, stackTrace);
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dirección',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Calle
          TextFormField(
            controller: widget.calleController,
            decoration: const InputDecoration(
              labelText: 'Calle',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) => widget.validarCalle(value),
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),

          // Número y Colonia
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.numeroController,
                  decoration: const InputDecoration(
                    labelText: 'Número',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  enabled: !widget.isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: widget.coloniaController,
                  decoration: const InputDecoration(
                    labelText: 'Colonia',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !widget.isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ciudad
          TextFormField(
            controller: widget.ciudadController,
            decoration: const InputDecoration(
              labelText: 'Ciudad',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
            validator: (value) => widget.validarCiudad(value),
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),

          // Estado y Código Postal
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: widget.estadoGeograficoController,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => widget.validarEstado(value),
                  enabled: !widget.isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: widget.codigoPostalController,
                  decoration: const InputDecoration(
                    labelText: 'Código Postal',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  enabled: !widget.isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Referencias
          TextFormField(
            controller: widget.referenciasController,
            decoration: const InputDecoration(
              labelText: 'Referencias',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.near_me),
              hintText: 'Referencias adicionales para ubicar el inmueble',
            ),
            maxLines: 2,
            enabled: !widget.isLoading,
          ),
        ],
      );
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'direccion_build_error',
        'Error al construir widget de dirección',
        e,
        stackTrace,
      );

      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar el formulario de dirección',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }
}

class AsignacionWidget extends StatefulWidget {
  final bool clientesLoading;
  final List<Cliente> clientesDisponibles;
  final int? clienteSeleccionado;
  final Function(int?) onClienteChanged;
  final bool isLoading;

  const AsignacionWidget({
    super.key,
    required this.clientesLoading,
    required this.clientesDisponibles,
    required this.clienteSeleccionado,
    required this.onClienteChanged,
    this.isLoading = false,
  });

  @override
  State<AsignacionWidget> createState() => _AsignacionWidgetState();
}

class _AsignacionWidgetState extends State<AsignacionWidget> {
  bool _procesandoOperacion = false;
  final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _intervaloMinimoErrores = Duration(minutes: 1);

  @override
  void dispose() {
    _ultimosErrores.clear();
    super.dispose();
  }

  void _registrarErrorControlado(
    String codigo,
    String mensaje,
    dynamic error,
    StackTrace stackTrace,
  ) {
    final errorKey = codigo;
    final ahora = DateTime.now();

    if (_ultimosErrores.containsKey(errorKey) &&
        ahora.difference(_ultimosErrores[errorKey]!) <
            _intervaloMinimoErrores) {
      return;
    }

    _ultimosErrores[errorKey] = ahora;
    AppLogger.error('$mensaje: ${error.toString()}', error, stackTrace);
  }

  // Método seguro para manejar cambios de cliente
  void _manejarCambioCliente(int? clienteId) {
    if (_procesandoOperacion || widget.isLoading) return;

    try {
      _procesandoOperacion = true;
      widget.onClienteChanged(clienteId);
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'cambio_cliente_error',
        'Error al cambiar selección de cliente',
        e,
        stackTrace,
      );
    } finally {
      _procesandoOperacion = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Asignación',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Cliente
          widget.clientesLoading || widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildClientesDropdown(),
          const SizedBox(height: 16),

          // Nota para empleados
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'La asignación de empleados estará disponible próximamente',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
        ],
      );
    } catch (e, stackTrace) {
      _registrarErrorControlado(
        'asignacion_build_error',
        'Error al construir widget de asignación',
        e,
        stackTrace,
      );

      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar el formulario de asignación',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Widget _buildClientesDropdown() {
    // Si no hay clientes, mostrar mensaje informativo
    if (widget.clientesDisponibles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'No hay clientes disponibles',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Cliente',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      value: widget.clienteSeleccionado,
      items:
          widget.clientesDisponibles.map((cliente) {
            return DropdownMenuItem<int>(
              value: cliente.id,
              child: Text(
                '${cliente.nombre} ${cliente.apellidoPaterno}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
      onChanged: (value) => _manejarCambioCliente(value),
      isExpanded: true,
    );
  }
}

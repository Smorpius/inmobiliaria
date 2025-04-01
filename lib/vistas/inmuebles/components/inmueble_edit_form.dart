import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../services/inmueble_validation_service.dart';

class InmuebleEditForm extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController montoController;
  final TextEditingController estadoController;
  final String? tipoInmuebleSeleccionado;
  final String? tipoOperacionSeleccionado;
  final List<String>? tiposInmueble;
  final List<String>? tiposOperacion;
  final Map<int, String>? estadosInmueble;
  final Function(String?)? onTipoInmuebleChanged;
  final Function(String?)? onTipoOperacionChanged;
  final Function(int?)? onEstadoChanged;
  final int? estadoSeleccionado;
  final InmuebleValidationService? validationService;

  const InmuebleEditForm({
    super.key,
    required this.nombreController,
    required this.montoController,
    required this.estadoController,
    this.tipoInmuebleSeleccionado,
    this.tipoOperacionSeleccionado,
    this.tiposInmueble,
    this.tiposOperacion,
    this.estadosInmueble,
    this.onTipoInmuebleChanged,
    this.onTipoOperacionChanged,
    this.onEstadoChanged,
    this.estadoSeleccionado,
    this.validationService,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del Inmueble',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
              hintText: 'Ej: Casa en Las Flores',
            ),
            validator:
                validationService?.validarNombre ?? _validarCampoRequerido,
          ),
          const SizedBox(height: 16),

          // Tipo de inmueble (dropdown si se proporcionó la lista)
          if (tiposInmueble != null && tiposInmueble!.isNotEmpty)
            _buildTipoInmuebleDropdown(),

          if (tiposInmueble != null && tiposInmueble!.isNotEmpty)
            const SizedBox(height: 16),

          // Tipo de operación (dropdown si se proporcionó la lista)
          if (tiposOperacion != null && tiposOperacion!.isNotEmpty)
            _buildTipoOperacionDropdown(),

          if (tiposOperacion != null && tiposOperacion!.isNotEmpty)
            const SizedBox(height: 16),

          TextFormField(
            controller: montoController,
            decoration: const InputDecoration(
              labelText: 'Monto',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
              hintText: 'Ej: 1500000',
            ),
            keyboardType: TextInputType.number,
            validator:
                validationService?.validarMonto ?? _validarCampoRequerido,
          ),
          const SizedBox(height: 16),

          // Estado (dropdown si se proporcionó el mapa de estados)
          estadosInmueble != null && estadosInmueble!.isNotEmpty
              ? _buildEstadoDropdown()
              : TextFormField(
                controller: estadoController,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                  helperText:
                      '1 = Activo, 2 = Inactivo, 3 = Disponible, 4 = Vendido, 5 = Rentado, 6 = En Negociación',
                  hintText: 'Ej: 3',
                ),
                keyboardType: TextInputType.number,
              ),
        ],
      );
    } catch (e, stackTrace) {
      // Usar AppLogger para registrar errores de forma controlada
      AppLogger.error(
        'Error al renderizar formulario de edición de inmueble',
        e,
        stackTrace,
      );

      // Devolver un widget de respaldo en caso de error
      return Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error al cargar el formulario: ${e.toString().split('\n').first}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }

  // Función para crear el dropdown de tipo de inmueble
  Widget _buildTipoInmuebleDropdown() {
    return DropdownButtonFormField<String>(
      value: tipoInmuebleSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Tipo de Inmueble',
        border: OutlineInputBorder(),
      ),
      items:
          tiposInmueble!.map((String tipo) {
            return DropdownMenuItem<String>(
              value: tipo,
              child: Text(_capitalizar(tipo)),
            );
          }).toList(),
      onChanged: onTipoInmuebleChanged,
    );
  }

  // Función para crear el dropdown de tipo de operación
  Widget _buildTipoOperacionDropdown() {
    return DropdownButtonFormField<String>(
      value: tipoOperacionSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Tipo de Operación',
        border: OutlineInputBorder(),
      ),
      items:
          tiposOperacion!.map((String tipo) {
            return DropdownMenuItem<String>(
              value: tipo,
              child: Text(_capitalizar(tipo)),
            );
          }).toList(),
      onChanged: onTipoOperacionChanged,
    );
  }

  // Función para crear el dropdown de estado
  Widget _buildEstadoDropdown() {
    return DropdownButtonFormField<int>(
      value: estadoSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Estado del Inmueble',
        border: OutlineInputBorder(),
      ),
      items:
          estadosInmueble!.entries.map((entry) {
            return DropdownMenuItem<int>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
      onChanged: onEstadoChanged,
    );
  }

  // Función para validar campos requeridos como respaldo
  String? _validarCampoRequerido(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  // Función para capitalizar strings
  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return "${texto[0].toUpperCase()}${texto.substring(1)}";
  }
}

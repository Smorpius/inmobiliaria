import '../models/cliente_model.dart';
import 'package:flutter/material.dart';

class InformacionGeneralWidget extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
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
          controller: nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Inmueble',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home),
          ),
          validator: (value) => validarNombre(value),
        ),
        const SizedBox(height: 16),

        // Tipo de inmueble
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Tipo de Inmueble',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          value: tipoInmuebleSeleccionado,
          items:
              tiposInmueble.map((tipo) {
                return DropdownMenuItem<String>(
                  value: tipo,
                  child: Text(tipo[0].toUpperCase() + tipo.substring(1)),
                );
              }).toList(),
          onChanged: onTipoInmuebleChanged,
        ),
        const SizedBox(height: 16),

        // Tipo de operación
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Tipo de Operación',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.sell),
          ),
          value: tipoOperacionSeleccionado,
          items:
              tiposOperacion.map((tipo) {
                return DropdownMenuItem<String>(
                  value: tipo,
                  child: Text(tipo[0].toUpperCase() + tipo.substring(1)),
                );
              }).toList(),
          onChanged: onTipoOperacionChanged,
        ),
        const SizedBox(height: 16),

        // Precio según tipo de operación
        if (tipoOperacionSeleccionado == 'venta')
          TextFormField(
            controller: precioVentaController,
            decoration: const InputDecoration(
              labelText: 'Precio de Venta',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => validarPrecioVenta(value),
          ),

        if (tipoOperacionSeleccionado == 'renta')
          TextFormField(
            controller: precioRentaController,
            decoration: const InputDecoration(
              labelText: 'Precio de Renta',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => validarPrecioRenta(value),
          ),

        // Monto total
        TextFormField(
          controller: montoController,
          decoration: const InputDecoration(
            labelText: 'Monto Total',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.monetization_on),
          ),
          keyboardType: TextInputType.number,
          validator: (value) => validarMonto(value),
        ),
        const SizedBox(height: 16),

        // Características
        TextFormField(
          controller: caracteristicasController,
          decoration: const InputDecoration(
            labelText: 'Características',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}

class DireccionWidget extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
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
          controller: calleController,
          decoration: const InputDecoration(
            labelText: 'Calle',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          validator: (value) => validarCalle(value),
        ),
        const SizedBox(height: 16),

        // Número y Colonia
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: numeroController,
                decoration: const InputDecoration(
                  labelText: 'Número',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: coloniaController,
                decoration: const InputDecoration(
                  labelText: 'Colonia',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Ciudad
        TextFormField(
          controller: ciudadController,
          decoration: const InputDecoration(
            labelText: 'Ciudad',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
          validator: (value) => validarCiudad(value),
        ),
        const SizedBox(height: 16),

        // Estado y Código Postal
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: estadoGeograficoController,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => validarEstado(value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: codigoPostalController,
                decoration: const InputDecoration(
                  labelText: 'Código Postal',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Referencias
        TextFormField(
          controller: referenciasController,
          decoration: const InputDecoration(
            labelText: 'Referencias',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.near_me),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}

class AsignacionWidget extends StatelessWidget {
  final bool clientesLoading;
  final List<Cliente> clientesDisponibles;
  final int? clienteSeleccionado;
  final Function(int?) onClienteChanged;

  const AsignacionWidget({
    super.key,
    required this.clientesLoading,
    required this.clientesDisponibles,
    required this.clienteSeleccionado,
    required this.onClienteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asignación',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Cliente
        clientesLoading
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              value: clienteSeleccionado,
              items:
                  clientesDisponibles.map((cliente) {
                    return DropdownMenuItem<int>(
                      value: cliente.id,
                      child: Text(
                        '${cliente.nombre} ${cliente.apellidoPaterno}',
                      ),
                    );
                  }).toList(),
              onChanged: onClienteChanged,
            ),
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
  }
}

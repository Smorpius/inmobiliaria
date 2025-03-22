import 'dart:io';
import 'cliente_model.dart';
import 'package:flutter/material.dart';

class InmuebleFormState {
  // Controladores básicos
  final nombreController = TextEditingController();
  final montoController = TextEditingController();

  // Controladores para dirección
  final calleController = TextEditingController();
  final numeroController = TextEditingController();
  final coloniaController = TextEditingController();
  final ciudadController = TextEditingController();
  final estadoGeograficoController = TextEditingController();
  final codigoPostalController = TextEditingController();
  final referenciasController = TextEditingController();

  // Controladores para campos específicos
  final caracteristicasController = TextEditingController();
  final precioVentaController = TextEditingController();
  final precioRentaController = TextEditingController();

  // Nuevos controladores para campos financieros
  final costoClienteController = TextEditingController();
  final costoServiciosController = TextEditingController();
  final comisionAgenciaController = TextEditingController(); // Solo lectura
  final comisionAgenteController = TextEditingController(); // Solo lectura
  final precioVentaFinalController = TextEditingController(); // Solo lectura

  // Estado para dropdowns y selecciones
  String tipoInmuebleSeleccionado = 'casa';
  String tipoOperacionSeleccionado = 'venta';
  int? clienteSeleccionado;
  int? empleadoSeleccionado;

  // Estado del formulario
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool clientesLoading = true;

  // Datos cargados
  List<Cliente> clientesDisponibles = [];

  // Gestión de imágenes
  List<File> imagenesTemporal = [];
  int imagenPrincipalIndex = 0;

  // Constantes
  final tiposInmueble = [
    'casa',
    'departamento',
    'terreno',
    'oficina',
    'bodega',
    'otro',
  ];

  final tiposOperacion = ['venta', 'renta'];

  // Método para actualizar campos calculados
  void actualizarCamposCalculados() {
    try {
      final costoCliente = double.tryParse(costoClienteController.text) ?? 0.0;
      final costoServicios =
          double.tryParse(costoServiciosController.text) ?? 0.0;

      // Calcular comisiones
      final comisionAgencia = costoCliente * 0.30;
      final comisionAgente = costoCliente * 0.03;

      // Calcular precio final
      final precioVentaFinal =
          costoCliente + costoServicios + comisionAgencia + comisionAgente;

      // Actualizar controladores de solo lectura
      comisionAgenciaController.text = comisionAgencia.toStringAsFixed(2);
      comisionAgenteController.text = comisionAgente.toStringAsFixed(2);
      precioVentaFinalController.text = precioVentaFinal.toStringAsFixed(2);
    } catch (e) {
      // Si hay error en los cálculos, mantener los valores en 0
      comisionAgenciaController.text = '0.00';
      comisionAgenteController.text = '0.00';
      precioVentaFinalController.text = '0.00';
    }
  }

  void dispose() {
    // Liberar recursos de controladores existentes
    nombreController.dispose();
    montoController.dispose();
    calleController.dispose();
    numeroController.dispose();
    coloniaController.dispose();
    ciudadController.dispose();
    estadoGeograficoController.dispose();
    codigoPostalController.dispose();
    referenciasController.dispose();
    caracteristicasController.dispose();
    precioVentaController.dispose();
    precioRentaController.dispose();

    // Liberar recursos de nuevos controladores
    costoClienteController.dispose();
    costoServiciosController.dispose();
    comisionAgenciaController.dispose();
    comisionAgenteController.dispose();
    precioVentaFinalController.dispose();
  }
}

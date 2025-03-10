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

  void dispose() {
    // Liberar recursos de controladores
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
  }
}

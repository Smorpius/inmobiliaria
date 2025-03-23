import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';

class Inmueble {
  static final Logger _logger = Logger('InmuebleModel');

  final int? id;
  final String nombre;
  final int? idDireccion;
  final double montoTotal;
  final int? idEstado;
  final int? idCliente;
  final int? idEmpleado;
  final DateTime? fechaRegistro;

  // Campos básicos
  final String tipoInmueble; // casa, departamento, terreno, etc.
  final String tipoOperacion; // venta, renta
  final double? precioVenta;
  final double? precioRenta;
  final String? caracteristicas;

  // Campos de dirección completos
  final String? calle;
  final String? numero;
  final String? colonia;
  final String? ciudad;
  final String? estadoGeografico;
  final String? codigoPostal;
  final String? referencias;

  // Nuevos campos financieros - ahora no-nulos con valores predeterminados
  final double costoCliente; // Costo que pide el cliente por su propiedad
  final double costoServicios; // Costo de servicios de proveedores
  final double? comisionAgencia; // 30% del costo cliente (calculado)
  final double? comisionAgente; // 3% del costo cliente (calculado)
  final double? precioVentaFinal; // Suma total de todos los costos

  Inmueble({
    this.id,
    required this.nombre,
    this.idDireccion,
    required this.montoTotal,
    this.idEstado,
    this.idCliente,
    this.idEmpleado,
    this.fechaRegistro,
    this.tipoInmueble = 'casa',
    this.tipoOperacion = 'venta',
    this.precioVenta,
    this.precioRenta,
    this.caracteristicas,
    this.calle,
    this.numero,
    this.colonia,
    this.ciudad,
    this.estadoGeografico,
    this.codigoPostal,
    this.referencias,
    this.costoCliente = 0.0, // Valor predeterminado no-nulo
    this.costoServicios = 0.0, // Valor predeterminado no-nulo
    this.comisionAgencia,
    this.comisionAgente,
    this.precioVentaFinal,
  });

  // Constructor con cálculos automáticos
  factory Inmueble.conCalculos({
    int? id,
    required String nombre,
    int? idDireccion,
    required double montoTotal,
    int? idEstado,
    int? idCliente,
    int? idEmpleado,
    DateTime? fechaRegistro,
    String tipoInmueble = 'casa',
    String tipoOperacion = 'venta',
    double? precioVenta,
    double? precioRenta,
    String? caracteristicas,
    String? calle,
    String? numero,
    String? colonia,
    String? ciudad,
    String? estadoGeografico,
    String? codigoPostal,
    String? referencias,
    required double costoCliente,
    required double costoServicios,
  }) {
    // Calcular comisiones
    final comisionAgencia = costoCliente * 0.30; // 30% del costo del cliente
    final comisionAgente = costoCliente * 0.03; // 3% del costo del cliente
    final precioVentaFinal =
        costoCliente + costoServicios + comisionAgencia + comisionAgente;

    return Inmueble(
      id: id,
      nombre: nombre,
      idDireccion: idDireccion,
      montoTotal: montoTotal,
      idEstado: idEstado,
      idCliente: idCliente,
      idEmpleado: idEmpleado,
      fechaRegistro: fechaRegistro,
      tipoInmueble: tipoInmueble,
      tipoOperacion: tipoOperacion,
      precioVenta: precioVenta,
      precioRenta: precioRenta,
      caracteristicas: caracteristicas,
      calle: calle,
      numero: numero,
      colonia: colonia,
      ciudad: ciudad,
      estadoGeografico: estadoGeografico,
      codigoPostal: codigoPostal,
      referencias: referencias,
      costoCliente: costoCliente,
      costoServicios: costoServicios,
      comisionAgencia: comisionAgencia,
      comisionAgente: comisionAgente,
      precioVentaFinal: precioVentaFinal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_inmueble': id,
      'nombre_inmueble': nombre,
      'id_direccion': idDireccion,
      'monto_total': montoTotal,
      'id_estado': idEstado,
      'id_cliente': idCliente,
      'id_empleado': idEmpleado,
      'fecha_registro': fechaRegistro?.toIso8601String(),
      'tipo_inmueble': tipoInmueble,
      'tipo_operacion': tipoOperacion,
      'precio_venta': precioVenta,
      'precio_renta': precioRenta,
      'caracteristicas': caracteristicas,
      'calle': calle,
      'numero': numero,
      'colonia': colonia,
      'ciudad': ciudad,
      'estado_geografico': estadoGeografico,
      'codigo_postal': codigoPostal,
      'referencias': referencias,
      // Nuevos campos financieros
      'costo_cliente': costoCliente,
      'costo_servicios': costoServicios,
      'comision_agencia': comisionAgencia,
      'comision_agente': comisionAgente,
      'precio_venta_final': precioVentaFinal,
    };
  }

  factory Inmueble.fromMap(Map<String, dynamic> map) {
    try {
      _logger.info('Procesando inmueble ID: ${map['id_inmueble']}');
      developer.log(
        'Procesando datos del inmueble: ${map['id_inmueble']} - ${map['nombre_inmueble']}',
      );

      // Función auxiliar para convertir BLOBs a String de manera más robusta
      String? blobToString(dynamic value) {
        if (value == null) return null;
        if (value is Uint8List) return utf8.decode(value);
        if (value is String) return value;
        return value.toString();
      }

      // Función segura para convertir números
      double? parseDoubleSafely(dynamic value) {
        if (value == null) return null;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        try {
          return double.parse(value.toString());
        } catch (e) {
          return null;
        }
      }

      // Función segura para convertir enteros
      int? parseIntSafely(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        try {
          return int.parse(value.toString());
        } catch (e) {
          return null;
        }
      }

      // Extraer valores de los campos financieros con valores predeterminados
      final costoCliente = parseDoubleSafely(map['costo_cliente']) ?? 0.0;
      final costoServicios = parseDoubleSafely(map['costo_servicios']) ?? 0.0;
      final comisionAgencia = parseDoubleSafely(map['comision_agencia']);
      final comisionAgente = parseDoubleSafely(map['comision_agente']);
      final precioVentaFinal = parseDoubleSafely(map['precio_venta_final']);

      return Inmueble(
        id: parseIntSafely(map['id_inmueble']),
        nombre: map['nombre_inmueble'] ?? '',
        idDireccion: parseIntSafely(map['id_direccion']),
        montoTotal: parseDoubleSafely(map['monto_total']) ?? 0.0,
        idEstado: parseIntSafely(map['id_estado']),
        idCliente: parseIntSafely(map['id_cliente']),
        idEmpleado: parseIntSafely(map['id_empleado']),
        fechaRegistro:
            map['fecha_registro'] is DateTime
                ? map['fecha_registro']
                : map['fecha_registro'] != null
                ? DateTime.parse(map['fecha_registro'].toString())
                : null,
        tipoInmueble: map['tipo_inmueble'] ?? 'casa',
        tipoOperacion: map['tipo_operacion'] ?? 'venta',
        precioVenta: parseDoubleSafely(map['precio_venta']),
        precioRenta: parseDoubleSafely(map['precio_renta']),
        caracteristicas: blobToString(map['caracteristicas']),
        calle: blobToString(map['calle']),
        numero: blobToString(map['numero']),
        colonia: blobToString(map['colonia']),
        ciudad: blobToString(map['ciudad']),
        estadoGeografico: blobToString(map['estado_geografico']),
        codigoPostal: blobToString(map['codigo_postal']),
        referencias: blobToString(map['referencias']),
        // Campos financieros con valores predeterminados
        costoCliente: costoCliente,
        costoServicios: costoServicios,
        comisionAgencia: comisionAgencia,
        comisionAgente: comisionAgente,
        precioVentaFinal: precioVentaFinal,
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al procesar inmueble: $e', e, stackTrace);
      developer.log(
        'Error al procesar inmueble: $e',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Error al procesar inmueble: $e');
    }
  }

  // Propiedad para obtener la dirección completa
  String get direccionCompleta {
    List<String?> direccionParts = [
      calle,
      numero,
      colonia,
      ciudad,
      estadoGeografico,
      codigoPostal,
    ];

    return direccionParts
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(', ');
  }

  // Método para calcular comisiones actualizadas - ya no necesita verificar nulo
  Inmueble calcularComisiones() {
    final nuevaComisionAgencia = costoCliente * 0.30;
    final nuevaComisionAgente = costoCliente * 0.03;
    final nuevoPrecioVentaFinal =
        costoCliente +
        costoServicios +
        nuevaComisionAgencia +
        nuevaComisionAgente;

    return Inmueble(
      id: id,
      nombre: nombre,
      idDireccion: idDireccion,
      montoTotal: montoTotal,
      idEstado: idEstado,
      idCliente: idCliente,
      idEmpleado: idEmpleado,
      fechaRegistro: fechaRegistro,
      tipoInmueble: tipoInmueble,
      tipoOperacion: tipoOperacion,
      precioVenta: precioVenta,
      precioRenta: precioRenta,
      caracteristicas: caracteristicas,
      calle: calle,
      numero: numero,
      colonia: colonia,
      ciudad: ciudad,
      estadoGeografico: estadoGeografico,
      codigoPostal: codigoPostal,
      referencias: referencias,
      costoCliente: costoCliente,
      costoServicios: costoServicios,
      comisionAgencia: nuevaComisionAgencia,
      comisionAgente: nuevaComisionAgente,
      precioVentaFinal: nuevoPrecioVentaFinal,
    );
  }

  @override
  String toString() {
    return 'Inmueble{id: $id, nombre: $nombre, tipo: $tipoInmueble, operacion: $tipoOperacion, estado: $idEstado}';
  }
}

import 'package:logging/logging.dart';

class Venta {
  static final Logger _logger = Logger('VentaModel');

  final int? id;
  final int idCliente;
  final int idInmueble;
  final DateTime fechaVenta;
  final double ingreso;
  final double comisionProveedores;
  final double utilidadBruta; // Calculado: ingreso - comisionProveedores
  final double
  utilidadNeta; // Utilidad final (ya no depende de gastos adicionales)
  final int
  idEstado; // 7: venta_en_proceso, 8: venta_completada, 9: venta_cancelada

  // Propiedades derivadas de relaciones
  final String? nombreCliente;
  final String? apellidoCliente;
  final String? nombreInmueble;
  final String? tipoInmueble;
  final String? tipoOperacion;
  final String? estadoVenta;
  final String? nombreEmpleado;
  final double? precioOriginalInmueble;
  final double? margenGanancia; // Porcentaje de ganancia sobre el precio

  // En el constructor, ya no incluimos gastosAdicionales
  Venta({
    this.id,
    required this.idCliente,
    required this.idInmueble,
    required this.fechaVenta,
    required this.ingreso,
    required this.comisionProveedores,
    double? utilidadBruta,
    double? utilidadNeta,
    this.idEstado = 7, // Por defecto en proceso
    this.nombreCliente,
    this.apellidoCliente,
    this.nombreInmueble,
    this.tipoInmueble,
    this.tipoOperacion,
    this.estadoVenta,
    this.nombreEmpleado,
    this.precioOriginalInmueble,
    this.margenGanancia,
  }) : // Asignar valores calculados o proporcionados
       utilidadBruta = utilidadBruta ?? (ingreso - comisionProveedores),
       // Si se proporciona utilidadNeta, usarla, sino usar utilidadBruta
       utilidadNeta =
           utilidadNeta ?? (utilidadBruta ?? (ingreso - comisionProveedores));

  // Modifica el método fromMap para manejar valores nulos

  factory Venta.fromMap(Map<String, dynamic> map) {
    try {
      return Venta(
        id: map['id_venta'] ?? 0, // Añadir valor por defecto
        idCliente: map['id_cliente'] ?? 0, // Añadir valor por defecto
        idInmueble: map['id_inmueble'] ?? 0, // Añadir valor por defecto
        fechaVenta:
            map['fecha_venta'] is DateTime
                ? map['fecha_venta']
                : DateTime.parse(map['fecha_venta'].toString()),
        ingreso: double.parse((map['ingreso'] ?? 0).toString()),
        comisionProveedores: double.parse(
          (map['comision_proveedores'] ?? 0).toString(),
        ),
        utilidadBruta: double.parse((map['utilidad_bruta'] ?? 0).toString()),
        utilidadNeta: double.parse((map['utilidad_neta'] ?? 0).toString()),
        idEstado: map['id_estado'] ?? 7,
        nombreCliente: map['nombre_cliente'],
        apellidoCliente: map['apellido_cliente'],
        nombreInmueble: map['nombre_inmueble'],
        tipoInmueble: map['tipo_inmueble'],
        tipoOperacion: map['tipo_operacion'],
        estadoVenta: map['estado_venta'],
        nombreEmpleado: map['nombre_empleado'],
        precioOriginalInmueble:
            map['precio_original'] != null
                ? double.parse(map['precio_original'].toString())
                : null,
        margenGanancia:
            map['margen_ganancia'] != null
                ? double.parse(map['margen_ganancia'].toString())
                : null,
      );
    } catch (e) {
      _logger.severe('Error al crear Venta desde Map: $e');
      rethrow;
    }
  }
  Map<String, dynamic> toMap() {
    return {
      'id_venta': id,
      'id_cliente': idCliente,
      'id_inmueble': idInmueble,
      'fecha_venta': fechaVenta.toIso8601String().split('T')[0],
      'ingreso': ingreso,
      'comision_proveedores': comisionProveedores,
      'utilidad_bruta': utilidadBruta,
      'utilidad_neta': utilidadNeta,
      'id_estado': idEstado,
    };
  }

  // Actualiza directamente la utilidad neta sin usar gastos adicionales
  Venta actualizarUtilidadNeta(double nuevaUtilidadNeta) {
    return Venta(
      id: id,
      idCliente: idCliente,
      idInmueble: idInmueble,
      fechaVenta: fechaVenta,
      ingreso: ingreso,
      comisionProveedores: comisionProveedores,
      utilidadBruta: utilidadBruta,
      utilidadNeta: nuevaUtilidadNeta,
      idEstado: idEstado,
      nombreCliente: nombreCliente,
      apellidoCliente: apellidoCliente,
      nombreInmueble: nombreInmueble,
      tipoInmueble: tipoInmueble,
      tipoOperacion: tipoOperacion,
      estadoVenta: estadoVenta,
      nombreEmpleado: nombreEmpleado,
      precioOriginalInmueble: precioOriginalInmueble,
      margenGanancia: margenGanancia,
    );
  }

  // Cambiar el estado de la venta
  Venta conNuevoEstado(int nuevoEstado) {
    return Venta(
      id: id,
      idCliente: idCliente,
      idInmueble: idInmueble,
      fechaVenta: fechaVenta,
      ingreso: ingreso,
      comisionProveedores: comisionProveedores,
      utilidadBruta: utilidadBruta,
      utilidadNeta: utilidadNeta,
      idEstado: nuevoEstado,
      nombreCliente: nombreCliente,
      apellidoCliente: apellidoCliente,
      nombreInmueble: nombreInmueble,
      tipoInmueble: tipoInmueble,
      tipoOperacion: tipoOperacion,
      estadoVenta: estadoVenta,
      nombreEmpleado: nombreEmpleado,
      precioOriginalInmueble: precioOriginalInmueble,
      margenGanancia: margenGanancia,
    );
  }
}

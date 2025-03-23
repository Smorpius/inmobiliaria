import 'package:intl/intl.dart';

class InmuebleProveedorServicio {
  final int? id;
  final int idInmueble;
  final int idProveedor;
  final String servicioDetalle;
  final double costo;
  final double comision; // Calculada como 30% del costo
  final DateTime fechaAsignacion;
  final DateTime? fechaServicio;
  final int idEstado;
  final String? nombreProveedor;
  final String? tipoServicio;
  final String? estadoNombre;

  InmuebleProveedorServicio({
    this.id,
    required this.idInmueble,
    required this.idProveedor,
    required this.servicioDetalle,
    required this.costo,
    double? comision,
    required this.fechaAsignacion,
    this.fechaServicio,
    this.idEstado = 1,
    this.nombreProveedor,
    this.tipoServicio,
    this.estadoNombre,
  }) : comision = comision ?? (costo * 0.30);

  factory InmuebleProveedorServicio.fromMap(Map<String, dynamic> map) {
    return InmuebleProveedorServicio(
      id: map['id'],
      idInmueble: map['id_inmueble'],
      idProveedor: map['id_proveedor'],
      servicioDetalle: map['servicio_detalle'],
      costo: double.parse(map['costo'].toString()),
      comision: double.parse(map['comision'].toString()),
      fechaAsignacion: DateTime.parse(map['fecha_asignacion'].toString()),
      fechaServicio:
          map['fecha_servicio'] != null
              ? DateTime.parse(map['fecha_servicio'].toString())
              : null,
      idEstado: map['id_estado'] ?? 1,
      nombreProveedor: map['nombre_proveedor'],
      tipoServicio: map['tipo_servicio'],
      estadoNombre: map['nombre_estado'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_inmueble': idInmueble,
      'id_proveedor': idProveedor,
      'servicio_detalle': servicioDetalle,
      'costo': costo,
      'fecha_asignacion': DateFormat('yyyy-MM-dd').format(fechaAsignacion),
      'fecha_servicio':
          fechaServicio != null
              ? DateFormat('yyyy-MM-dd').format(fechaServicio!)
              : null,
      'id_estado': idEstado,
    };
  }
}

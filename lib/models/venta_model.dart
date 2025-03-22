import 'package:logging/logging.dart';

class Venta {
  static final Logger _logger = Logger('VentaModel');

  final int? id;
  final int idCliente;
  final int idInmueble;
  final DateTime fechaVenta;
  final double ingreso;
  final double comisionProveedores;
  final double utilidadBruta;
  final double utilidadNeta;
  final int idEstado;

  // Propiedades derivadas de relaciones
  final String? nombreCliente;
  final String? apellidoCliente;
  final String? nombreInmueble;
  final String? tipoInmueble;
  final String? tipoOperacion;
  final String? estadoVenta;

  Venta({
    this.id,
    required this.idCliente,
    required this.idInmueble,
    required this.fechaVenta,
    required this.ingreso,
    required this.comisionProveedores,
    required this.utilidadBruta,
    required this.utilidadNeta,
    this.idEstado = 1,
    this.nombreCliente,
    this.apellidoCliente,
    this.nombreInmueble,
    this.tipoInmueble,
    this.tipoOperacion,
    this.estadoVenta,
  });

  factory Venta.fromMap(Map<String, dynamic> map) {
    try {
      return Venta(
        id: map['id_venta'],
        idCliente: map['id_cliente'],
        idInmueble: map['id_inmueble'],
        fechaVenta:
            map['fecha_venta'] is DateTime
                ? map['fecha_venta']
                : DateTime.parse(map['fecha_venta']),
        ingreso: double.parse(map['ingreso'].toString()),
        comisionProveedores: double.parse(
          map['comision_proveedores'].toString(),
        ),
        utilidadBruta: double.parse(map['utilidad_bruta'].toString()),
        utilidadNeta: double.parse(map['utilidad_neta'].toString()),
        idEstado: map['id_estado'] ?? 1,
        nombreCliente: map['nombre_cliente'],
        apellidoCliente: map['apellido_cliente'],
        nombreInmueble: map['nombre_inmueble'],
        tipoInmueble: map['tipo_inmueble'],
        tipoOperacion: map['tipo_operacion'],
        estadoVenta: map['estado_venta'],
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
      'utilidad_neta': utilidadNeta,
      'id_estado': idEstado,
    };
  }
}

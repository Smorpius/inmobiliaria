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

  // Nuevos campos según tu base de datos
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
  });

  factory Inmueble.fromMap(Map<String, dynamic> map) {
    _logger.info('Procesando datos del inmueble: $map');

    // Manejo seguro del monto total
    double montoTotal;
    try {
      if (map['monto_total'] == null) {
        montoTotal = 0.0;
        _logger.warning('Advertencia: monto_total es nulo, usando 0.0');
      } else if (map['monto_total'] is String) {
        montoTotal = double.parse(map['monto_total']);
      } else if (map['monto_total'] is int) {
        montoTotal = (map['monto_total'] as int).toDouble();
      } else {
        montoTotal = (map['monto_total'] as double?) ?? 0.0;
      }
    } catch (e) {
      _logger.severe(
        'Error al convertir monto_total: ${map['monto_total']}, error: $e',
      );
      montoTotal = 0.0;
    }

    // Procesamiento seguro de precios
    double? precioVenta;
    try {
      if (map['precio_venta'] != null) {
        if (map['precio_venta'] is String) {
          precioVenta = double.parse(map['precio_venta']);
        } else if (map['precio_venta'] is int) {
          precioVenta = (map['precio_venta'] as int).toDouble();
        } else {
          precioVenta = map['precio_venta'] as double?;
        }
      }
    } catch (e) {
      _logger.warning(
        'Error al convertir precio_venta: ${map['precio_venta']}, error: $e',
      );
    }

    double? precioRenta;
    try {
      if (map['precio_renta'] != null) {
        if (map['precio_renta'] is String) {
          precioRenta = double.parse(map['precio_renta']);
        } else if (map['precio_renta'] is int) {
          precioRenta = (map['precio_renta'] as int).toDouble();
        } else {
          precioRenta = map['precio_renta'] as double?;
        }
      }
    } catch (e) {
      _logger.warning(
        'Error al convertir precio_renta: ${map['precio_renta']}, error: $e',
      );
    }

    // Convertir fechaRegistro con manejo seguro
    DateTime? fechaRegistro;
    try {
      if (map['fecha_registro'] != null) {
        if (map['fecha_registro'] is DateTime) {
          fechaRegistro = map['fecha_registro'] as DateTime;
        } else if (map['fecha_registro'] is String) {
          fechaRegistro = DateTime.parse(map['fecha_registro']);
        }
      }
    } catch (e) {
      _logger.severe(
        'Error al parsear fecha_registro: ${map['fecha_registro']}, error: $e',
      );
      fechaRegistro = null;
    }

    return Inmueble(
      id:
          map['id_inmueble'] is int
              ? map['id_inmueble']
              : (map['id_inmueble'] is String
                  ? int.tryParse(map['id_inmueble'])
                  : null),
      nombre: (map['nombre_inmueble'] as String?) ?? 'Sin nombre',
      idDireccion:
          map['id_direccion'] is int
              ? map['id_direccion']
              : (map['id_direccion'] is String
                  ? int.tryParse(map['id_direccion'])
                  : null),
      montoTotal: montoTotal,
      tipoInmueble: (map['tipo_inmueble'] as String?) ?? 'casa',
      tipoOperacion: (map['tipo_operacion'] as String?) ?? 'venta',
      precioVenta: precioVenta,
      precioRenta: precioRenta,
      caracteristicas: map['caracteristicas'] as String?,
      idEstado:
          map['id_estado'] is int
              ? map['id_estado']
              : (map['id_estado'] is String
                  ? int.tryParse(map['id_estado'])
                  : 3),
      idCliente:
          map['id_cliente'] is int
              ? map['id_cliente']
              : (map['id_cliente'] is String
                  ? int.tryParse(map['id_cliente'])
                  : null),
      idEmpleado:
          map['id_empleado'] is int
              ? map['id_empleado']
              : (map['id_empleado'] is String
                  ? int.tryParse(map['id_empleado'])
                  : null),
      fechaRegistro: fechaRegistro,
      // Datos de dirección
      calle: map['calle'] as String?,
      numero: map['numero'] as String?,
      colonia: map['colonia'] as String?,
      ciudad: map['ciudad'] as String?,
      estadoGeografico: map['estado_geografico'] as String?,
      codigoPostal: map['codigo_postal'] as String?,
      referencias: map['referencias'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_inmueble': id,
      'nombre_inmueble': nombre,
      'id_direccion': idDireccion,
      'monto_total': montoTotal,
      'tipo_inmueble': tipoInmueble,
      'tipo_operacion': tipoOperacion,
      'precio_venta': precioVenta,
      'precio_renta': precioRenta,
      'caracteristicas': caracteristicas,
      'id_estado': idEstado,
      'id_cliente': idCliente,
      'id_empleado': idEmpleado,
    };
  }

  // Propiedad para obtener la dirección completa
  String get direccionCompleta {
    final List<String> partes = [];

    if (calle != null && calle!.isNotEmpty) {
      String parte = calle!;
      if (numero != null && numero!.isNotEmpty) parte += ' $numero';
      partes.add(parte);
    }

    if (colonia != null && colonia!.isNotEmpty) {
      partes.add('Col. $colonia');
    }

    if (ciudad != null && ciudad!.isNotEmpty) {
      String parte = ciudad!;
      if (estadoGeografico != null && estadoGeografico!.isNotEmpty) {
        parte += ', $estadoGeografico';
      }
      partes.add(parte);
    }

    if (codigoPostal != null && codigoPostal!.isNotEmpty) {
      partes.add('C.P. $codigoPostal');
    }

    return partes.isNotEmpty ? partes.join(', ') : 'Dirección no disponible';
  }

  @override
  String toString() {
    return 'Inmueble{id: $id, nombre: $nombre, tipo: $tipoInmueble, operacion: $tipoOperacion, estado: $idEstado}';
  }
}

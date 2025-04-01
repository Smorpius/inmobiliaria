import 'package:intl/intl.dart';

class MovimientoRenta {
  final int? id;
  final int idInmueble;
  final int idCliente;
  final String tipoMovimiento; // 'ingreso' o 'egreso'
  final String concepto;
  final double monto;
  final DateTime fechaMovimiento;
  final String mesCorrespondiente; // YYYY-MM
  final String? comentarios;
  final int idEstado;
  final DateTime fechaRegistro;

  // Datos relacionales para UI
  final String? nombreCliente;
  final String? apellidoCliente;
  final String? nombreInmueble;
  final String? estadoMovimiento;

  MovimientoRenta({
    this.id,
    required this.idInmueble,
    required this.idCliente,
    required this.tipoMovimiento,
    required this.concepto,
    required this.monto,
    required this.fechaMovimiento,
    required this.mesCorrespondiente,
    this.comentarios,
    this.idEstado = 1,
    DateTime? fechaRegistro,
    this.nombreCliente,
    this.apellidoCliente,
    this.nombreInmueble,
    this.estadoMovimiento,
  }) : fechaRegistro = fechaRegistro ?? DateTime.now();

  factory MovimientoRenta.fromMap(Map<String, dynamic> map) {
    return MovimientoRenta(
      id: map['id_movimiento'],
      idInmueble: map['id_inmueble'],
      idCliente: map['id_cliente'],
      tipoMovimiento: map['tipo_movimiento'],
      concepto: map['concepto'],
      monto: double.parse(map['monto']?.toString() ?? '0'),
      fechaMovimiento:
          map['fecha_movimiento'] is DateTime
              ? map['fecha_movimiento']
              : DateTime.parse(map['fecha_movimiento']),
      mesCorrespondiente: map['mes_correspondiente'] ?? '',
      comentarios: map['comentarios'],
      idEstado: map['id_estado'] ?? 1,
      fechaRegistro:
          map['fecha_registro'] is DateTime
              ? map['fecha_registro']
              : DateTime.parse(
                map['fecha_registro'] ?? DateTime.now().toString(),
              ),
      nombreCliente: map['nombre_cliente'],
      apellidoCliente: map['apellido_cliente'],
      nombreInmueble: map['nombre_inmueble'],
      estadoMovimiento: map['nombre_estado'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_movimiento': id,
      'id_inmueble': idInmueble,
      'id_cliente': idCliente,
      'tipo_movimiento': tipoMovimiento,
      'concepto': concepto,
      'monto': monto,
      'fecha_movimiento': fechaMovimiento.toIso8601String().split('T')[0],
      'mes_correspondiente': mesCorrespondiente,
      'comentarios': comentarios,
      'id_estado': idEstado,
    };
  }

  String get nombreCompletoCliente {
    if (nombreCliente != null && apellidoCliente != null) {
      return '$nombreCliente $apellidoCliente';
    }
    return 'Cliente no especificado';
  }

  bool get esIngreso => tipoMovimiento == 'ingreso';

  String get montoFormateado {
    final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
    return formatCurrency.format(monto);
  }

  String get fechaFormateada {
    return DateFormat('dd/MM/yyyy').format(fechaMovimiento);
  }
}

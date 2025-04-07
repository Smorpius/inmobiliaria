import 'package:logging/logging.dart';

class ContratoRenta {
  static final Logger _logger = Logger('ContratoRentaModel');

  final int? id;
  final int idInmueble;
  final int idCliente;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double montoMensual;
  final String? condicionesAdicionales;
  final int idEstado;
  final DateTime? fechaRegistro;

  // Propiedades para información adicional de relaciones
  final String? nombreCliente;
  final String? apellidoCliente;
  final String? estadoRenta;

  ContratoRenta({
    this.id,
    required this.idInmueble,
    required this.idCliente,
    required this.fechaInicio,
    required this.fechaFin,
    required this.montoMensual,
    this.condicionesAdicionales,
    this.idEstado = 1, // Por defecto activo
    this.fechaRegistro,
    this.nombreCliente,
    this.apellidoCliente,
    this.estadoRenta,
  });

  // Crear desde un mapa (para deserialización)
  factory ContratoRenta.fromMap(Map<String, dynamic> map) {
    try {
      // Manejar explícitamente el campo condiciones_adicionales que puede ser un Blob
      String? condiciones;
      if (map['condiciones_adicionales'] != null) {
        // Si es un Blob o un tipo no string, convertirlo a String
        if (map['condiciones_adicionales'] is! String) {
          condiciones = map['condiciones_adicionales'].toString();
        } else {
          condiciones = map['condiciones_adicionales'];
        }
      }

      return ContratoRenta(
        id: map['id_contrato'],
        idInmueble:
            map['id_inmueble'] ?? 1, // Usar valor por defecto si es nulo
        idCliente: map['id_cliente'] ?? 1, // Usar valor por defecto si es nulo
        fechaInicio:
            map['fecha_inicio'] is DateTime
                ? map['fecha_inicio']
                : DateTime.parse(map['fecha_inicio'].toString()),
        fechaFin:
            map['fecha_fin'] is DateTime
                ? map['fecha_fin']
                : DateTime.parse(map['fecha_fin'].toString()),
        montoMensual: double.parse(map['monto_mensual'].toString()),
        condicionesAdicionales: condiciones, // Usar el valor convertido
        idEstado: map['id_estado'] ?? 1,
        fechaRegistro:
            map['fecha_registro'] != null
                ? map['fecha_registro'] is DateTime
                    ? map['fecha_registro']
                    : DateTime.parse(map['fecha_registro'].toString())
                : null,
        nombreCliente: map['nombre_cliente'],
        apellidoCliente: map['apellido_cliente'],
        estadoRenta: map['estado_renta'],
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al crear ContratoRenta desde Map: $e');
      _logger.severe(
        'Stack trace: $stackTrace',
      ); // Incluir el stacktrace para mejor diagnóstico
      _logger.severe('Map: $map'); // Loggear el mapa para ver qué datos vienen
      rethrow;
    }
  }

  // Convertir a mapa (para serialización)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id_contrato': id,
      'id_inmueble': idInmueble,
      'id_cliente': idCliente,
      'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
      'fecha_fin': fechaFin.toIso8601String().split('T')[0],
      'monto_mensual': montoMensual,
      'condiciones_adicionales': condicionesAdicionales,
      'id_estado': idEstado,
    };
  }

  // Crear una copia con cambios
  ContratoRenta copyWith({
    int? id,
    int? idInmueble,
    int? idCliente,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    double? montoMensual,
    String? condicionesAdicionales,
    int? idEstado,
    DateTime? fechaRegistro,
    String? nombreCliente,
    String? apellidoCliente,
    String? estadoRenta,
  }) {
    return ContratoRenta(
      id: id ?? this.id,
      idInmueble: idInmueble ?? this.idInmueble,
      idCliente: idCliente ?? this.idCliente,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      montoMensual: montoMensual ?? this.montoMensual,
      condicionesAdicionales:
          condicionesAdicionales ?? this.condicionesAdicionales,
      idEstado: idEstado ?? this.idEstado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      apellidoCliente: apellidoCliente ?? this.apellidoCliente,
      estadoRenta: estadoRenta ?? this.estadoRenta,
    );
  }

  // Obtener nombre completo del cliente, si está disponible
  String? get clienteNombreCompleto {
    // Primero verificamos si ambos existen
    if (nombreCliente != null && apellidoCliente != null) {
      // Si ambos tienen contenido, los concatenamos
      if (nombreCliente!.isNotEmpty && apellidoCliente!.isNotEmpty) {
        return '$nombreCliente $apellidoCliente'.trim();
      }
    }

    // Si solo uno existe y tiene contenido, lo devolvemos
    if (nombreCliente != null && nombreCliente!.isNotEmpty) {
      return nombreCliente;
    }
    if (apellidoCliente != null && apellidoCliente!.isNotEmpty) {
      return apellidoCliente;
    }

    // Si llegamos aquí, no hay información del cliente
    return 'Cliente no especificado';
  }

  /// Calcula la duración total del contrato en meses
  int get duracionMeses {
    final mesesCompletos =
        ((fechaFin.year - fechaInicio.year) * 12) +
        (fechaFin.month - fechaInicio.month);

    // Si el día final es menor que el inicial, no es un mes completo
    if (fechaFin.day < fechaInicio.day) {
      return mesesCompletos;
    } else {
      return mesesCompletos + 1;
    }
  }

  /// Calcula el monto total del contrato
  double get montoTotalContrato {
    return duracionMeses * montoMensual;
  }

  /// Verifica si el contrato está próximo a vencer (30 días o menos)
  bool get estaProximoAVencer {
    final diasRestantes = fechaFin.difference(DateTime.now()).inDays;
    return diasRestantes >= 0 && diasRestantes <= 30;
  }

  /// Verifica si el contrato está activo actualmente
  bool get estaVigente {
    final ahora = DateTime.now();
    return idEstado == 1 &&
        fechaInicio.isBefore(ahora) &&
        fechaFin.isAfter(ahora);
  }

  /// Calcula el porcentaje de avance del contrato
  double get porcentajeAvance {
    if (!estaVigente) {
      return fechaFin.isBefore(DateTime.now()) ? 100.0 : 0.0;
    }

    final diasTotales = fechaFin.difference(fechaInicio).inDays;
    final diasTranscurridos = DateTime.now().difference(fechaInicio).inDays;

    if (diasTotales <= 0) return 0.0;
    return (diasTranscurridos / diasTotales * 100).clamp(0.0, 100.0);
  }

  /// Calcula los meses ya transcurridos del contrato
  int get mesesTranscurridos {
    final ahora = DateTime.now();
    if (ahora.isBefore(fechaInicio)) return 0;

    final fechaFinal = ahora.isAfter(fechaFin) ? fechaFin : ahora;
    final meses =
        ((fechaFinal.year - fechaInicio.year) * 12) +
        (fechaFinal.month - fechaInicio.month);

    // Ajustar por días parciales
    if (fechaFinal.day < fechaInicio.day) {
      return meses;
    }
    return meses + 1;
  }

  /// Calcula la proyección de ingresos restantes del contrato
  double get ingresoProyectadoRestante {
    if (!estaVigente) return 0.0;

    final mesesRestantes = duracionMeses - mesesTranscurridos;
    return mesesRestantes > 0 ? mesesRestantes * montoMensual : 0.0;
  }

  /// Calcula el ingreso acumulado hasta la fecha
  double get ingresoAcumulado {
    return mesesTranscurridos * montoMensual;
  }

  /// Verifica si el contrato está por debajo del rendimiento esperado
  /// en base a un porcentaje mínimo esperado sobre el valor del inmueble
  bool estaDebajoRendimiento(
    double valorInmueble,
    double porcentajeAnualEsperado,
  ) {
    if (valorInmueble <= 0) return false;

    final rentaAnual = montoMensual * 12;
    final rendimientoActual = (rentaAnual / valorInmueble) * 100;

    return rendimientoActual < porcentajeAnualEsperado;
  }

  @override
  String toString() =>
      'ContratoRenta{id: $id, inmueble: $idInmueble, cliente: $clienteNombreCompleto, monto: $montoMensual}';
}

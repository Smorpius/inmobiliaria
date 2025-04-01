import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

/// Modelo que representa un pago de renta en el sistema.
///
/// Esta clase se integra con la estructura existente para manejar
/// los registros de pagos asociados a contratos de renta de inmuebles.
class PagoRenta {
  static final Logger _logger = Logger('PagoRentaModel');

  final int? id;
  final int idContrato;
  final double monto;
  final DateTime fechaPago;
  final String? comentarios;
  final int idEstado;
  final DateTime? fechaRegistro;

  // Propiedades opcionales para relaciones
  final String? nombreCliente;
  final String? apellidoCliente;
  final String? nombreInmueble;
  final int? idInmueble;
  final int? idCliente;
  final String? mesPago;

  /// Constructor principal con validaciones
  PagoRenta({
    this.id,
    required this.idContrato,
    required this.monto,
    required this.fechaPago,
    this.comentarios,
    this.idEstado = 1, // Por defecto activo
    DateTime? fechaRegistro,
    this.nombreCliente,
    this.apellidoCliente,
    this.nombreInmueble,
    this.idInmueble,
    this.idCliente,
    this.mesPago,
  }) : fechaRegistro = fechaRegistro ?? DateTime.now() {
    if (monto <= 0) {
      _logger.warning('Se creó un PagoRenta con monto menor o igual a cero');
    }
    if (fechaPago.isAfter(DateTime.now())) {
      _logger.warning('Se creó un PagoRenta con fecha futura');
    }
  }

  /// Crea una instancia desde un mapa (para deserialización de BD)
  factory PagoRenta.fromMap(Map<String, dynamic> map) {
    try {
      return PagoRenta(
        id: map['id_pago'],
        idContrato: map['id_contrato'],
        monto: double.parse(map['monto'].toString()),
        fechaPago:
            map['fecha_pago'] is DateTime
                ? map['fecha_pago']
                : DateTime.parse(map['fecha_pago'].toString()),
        comentarios: map['comentarios'],
        idEstado: map['id_estado'] ?? 1,
        fechaRegistro:
            map['fecha_registro'] != null
                ? (map['fecha_registro'] is DateTime
                    ? map['fecha_registro']
                    : DateTime.parse(map['fecha_registro'].toString()))
                : null,
        nombreCliente: map['nombre_cliente'],
        apellidoCliente: map['apellido_cliente'],
        nombreInmueble: map['nombre_inmueble'],
        idInmueble: map['id_inmueble'],
        idCliente: map['id_cliente'],
        mesPago:
            map['mes_pago'] ??
            DateFormat('MMMM yyyy', 'es_MX').format(
              map['fecha_pago'] is DateTime
                  ? map['fecha_pago']
                  : DateTime.parse(map['fecha_pago'].toString()),
            ),
      );
    } catch (e) {
      _logger.severe('Error al crear PagoRenta desde Map: $e');
      rethrow;
    }
  }

  /// Convierte la instancia a un mapa (para serialización a BD)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id_pago': id,
      'id_contrato': idContrato,
      'monto': monto,
      'fecha_pago': fechaPago.toIso8601String().split('T')[0],
      'comentarios': comentarios,
      'id_estado': idEstado,
    };
  }

  /// Crea una copia del objeto con campos actualizados
  PagoRenta copyWith({
    int? id,
    int? idContrato,
    double? monto,
    DateTime? fechaPago,
    String? comentarios,
    int? idEstado,
    DateTime? fechaRegistro,
    String? nombreCliente,
    String? apellidoCliente,
    String? nombreInmueble,
    int? idInmueble,
    int? idCliente,
    String? mesPago,
  }) {
    return PagoRenta(
      id: id ?? this.id,
      idContrato: idContrato ?? this.idContrato,
      monto: monto ?? this.monto,
      fechaPago: fechaPago ?? this.fechaPago,
      comentarios: comentarios ?? this.comentarios,
      idEstado: idEstado ?? this.idEstado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      apellidoCliente: apellidoCliente ?? this.apellidoCliente,
      nombreInmueble: nombreInmueble ?? this.nombreInmueble,
      idInmueble: idInmueble ?? this.idInmueble,
      idCliente: idCliente ?? this.idCliente,
      mesPago: mesPago ?? this.mesPago,
    );
  }

  /// Devuelve el nombre completo del cliente si está disponible
  String? get clienteNombreCompleto {
    if (nombreCliente != null || apellidoCliente != null) {
      return '$nombreCliente $apellidoCliente'.trim();
    }
    return null;
  }

  /// Devuelve el monto formateado como moneda
  String get montoFormateado {
    final formatCurrency = NumberFormat.currency(symbol: '\$', locale: 'es_MX');
    return formatCurrency.format(monto);
  }

  /// Devuelve la fecha formateada
  String get fechaFormateada {
    return DateFormat('dd/MM/yyyy').format(fechaPago);
  }

  /// Devuelve el mes y año del pago en formato legible
  String get mesPagoFormateado {
    return mesPago ?? DateFormat('MMMM yyyy', 'es_MX').format(fechaPago);
  }

  /// Verifica si el pago fue realizado a tiempo
  bool get esPagoATiempo {
    // Consideramos que el pago es a tiempo si se realiza
    // en los primeros 5 días del mes
    return fechaPago.day <= 5;
  }

  /// Calcula los días de retraso del pago respecto al inicio del mes
  int get diasRetraso {
    if (esPagoATiempo) return 0;

    // Asumimos que el pago debería realizarse el día 1 del mes
    final fechaLimite = DateTime(fechaPago.year, fechaPago.month, 5);
    return fechaPago.difference(fechaLimite).inDays;
  }

  /// Formatea el string de mes y año para mostrar de manera amigable
  String get mesPagoFormateadoBonito {
    if (mesPago == null || mesPago!.isEmpty) {
      return DateFormat('MMMM yyyy', 'es_MX').format(fechaPago);
    }

    try {
      final partes = mesPago!.split('-');
      if (partes.length == 2) {
        final fecha = DateTime(int.parse(partes[0]), int.parse(partes[1]));
        return DateFormat('MMMM yyyy', 'es_MX').format(fecha);
      }
      return mesPago!;
    } catch (e) {
      return mesPago!;
    }
  }

  /// Describe el estado del pago de manera amigable
  String get estadoPagoDescripcion {
    if (idEstado == 1) {
      return esPagoATiempo
          ? 'Pagado a tiempo'
          : 'Pagado con retraso ($diasRetraso días)';
    } else {
      return 'Anulado';
    }
  }

  /// Calcula el monto de penalización por pago tardío
  /// basado en un porcentaje diario y un máximo de penalización
  double calcularPenalizacion({
    double porcentajeDiario = 0.5,
    double penalizacionMaxima = 20.0,
  }) {
    if (esPagoATiempo) return 0.0;

    // Calcular la penalización basada en los días de retraso
    final penalizacionPorcentaje = diasRetraso * porcentajeDiario;

    // Aplicar el máximo
    final penalizacionFinal =
        penalizacionPorcentaje > penalizacionMaxima
            ? penalizacionMaxima
            : penalizacionPorcentaje;

    return (penalizacionFinal / 100) * monto;
  }

  /// Verifica si el pago corresponde a un mes específico
  bool correspondeMes(int anio, int mes) {
    if (mesPago != null) {
      final partes = mesPago!.split('-');
      if (partes.length == 2) {
        return int.parse(partes[0]) == anio && int.parse(partes[1]) == mes;
      }
    }

    // Si no tiene mes explícito, verificar por la fecha de pago
    return fechaPago.year == anio && fechaPago.month == mes;
  }

  /// Genera un comprobante simplificado de pago
  Map<String, dynamic> generarComprobante() {
    return {
      'id_pago': id,
      'fecha_pago': fechaFormateada,
      'monto': montoFormateado,
      'cliente': clienteNombreCompleto,
      'concepto': 'Pago de renta correspondiente a: $mesPagoFormateadoBonito',
      'estado': estadoPagoDescripcion,
      'fecha_registro':
          fechaRegistro != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(fechaRegistro!)
              : 'No registrada',
    };
  }

  @override
  String toString() =>
      'PagoRenta{id: $id, contrato: $idContrato, monto: $monto}';
}

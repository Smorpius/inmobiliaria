import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

/// Modelo que representa un comprobante o documento adjunto a un movimiento de renta
class ComprobanteMovimiento {
  static final Logger _logger = Logger('ComprobanteMovimientoModel');

  final int? id;
  final int idMovimiento;
  final String
  rutaArchivo; // Cambiado de rutaImagen para ser consistente con la BD
  final String tipoArchivo; // 'imagen', 'pdf', 'documento'
  final String? descripcion;
  final bool esPrincipal;
  final String tipoComprobante; // 'factura', 'recibo', 'contrato', 'otro'
  final String? numeroReferencia;
  final String? emisor;
  final String? receptor;
  final String?
  metodoPago; // 'efectivo', 'transferencia', 'cheque', 'tarjeta', 'otro'
  final DateTime? fechaEmision;
  final String? notasAdicionales;
  final DateTime fechaCarga;

  // Datos relacionados para UI
  final String? conceptoMovimiento;
  final double? montoMovimiento;
  final String? nombreCliente;
  final String? apellidoCliente;
  final String? nombreInmueble;

  ComprobanteMovimiento({
    this.id,
    required this.idMovimiento,
    required this.rutaArchivo, // Cambiado de rutaImagen
    this.tipoArchivo = 'imagen',
    this.descripcion,
    this.esPrincipal = false,
    required this.tipoComprobante,
    this.numeroReferencia,
    this.emisor,
    this.receptor,
    this.metodoPago,
    this.fechaEmision,
    this.notasAdicionales,
    DateTime? fechaCarga,
    this.conceptoMovimiento,
    this.montoMovimiento,
    this.nombreCliente,
    this.apellidoCliente,
    this.nombreInmueble,
  }) : fechaCarga = fechaCarga ?? DateTime.now() {
    // Validación: Si es factura, debe tener número de referencia
    if (tipoComprobante == 'factura' &&
        (numeroReferencia == null || numeroReferencia!.isEmpty)) {
      _logger.warning('Se creó una factura sin número de referencia');
    }

    // Validación: La fecha de emisión no debería ser futura
    if (fechaEmision != null && fechaEmision!.isAfter(DateTime.now())) {
      _logger.warning(
        'Se creó un comprobante con fecha de emisión futura: $fechaEmision',
      );
    }
  }

  /// Crea un objeto ComprobanteMovimiento desde un mapa (para deserialización desde BD)
  factory ComprobanteMovimiento.fromMap(Map<String, dynamic> map) {
    try {
      // Manejar fechas adecuadamente
      DateTime? parseFecha(dynamic fecha) {
        if (fecha == null) return null;
        if (fecha is DateTime) return fecha;
        try {
          return DateTime.parse(fecha.toString());
        } catch (e) {
          return null;
        }
      }

      return ComprobanteMovimiento(
        id: map['id_comprobante'],
        idMovimiento: map['id_movimiento'],
        rutaArchivo:
            map['ruta_archivo'] ??
            map['ruta_imagen'] ??
            '', // Manejo compatible con ambos nombres de campo
        tipoArchivo: map['tipo_archivo'] ?? 'imagen',
        descripcion: map['descripcion'],
        esPrincipal: map['es_principal'] == 1 || map['es_principal'] == true,
        tipoComprobante: map['tipo_comprobante'] ?? 'otro',
        numeroReferencia: map['numero_referencia'],
        emisor: map['emisor'],
        receptor: map['receptor'],
        metodoPago: map['metodo_pago'],
        fechaEmision: parseFecha(map['fecha_emision']),
        notasAdicionales: map['notas_adicionales'],
        fechaCarga: parseFecha(map['fecha_carga']) ?? DateTime.now(),
        conceptoMovimiento: map['concepto_movimiento'],
        montoMovimiento:
            map['monto_movimiento'] != null
                ? double.tryParse(map['monto_movimiento'].toString())
                : null,
        nombreCliente: map['nombre_cliente'],
        apellidoCliente: map['apellido_cliente'],
        nombreInmueble: map['nombre_inmueble'],
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Error al crear ComprobanteMovimiento desde Map: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Convierte el objeto a un mapa para serialización
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id_comprobante': id,
      'id_movimiento': idMovimiento,
      'ruta_archivo': rutaArchivo, // Cambiado de rutaImagen
      'tipo_archivo': tipoArchivo,
      'descripcion': descripcion,
      'es_principal': esPrincipal ? 1 : 0,
      'tipo_comprobante': tipoComprobante,
      'numero_referencia': numeroReferencia,
      'emisor': emisor,
      'receptor': receptor,
      'metodo_pago': metodoPago,
      if (fechaEmision != null)
        'fecha_emision': fechaEmision!.toIso8601String().split('T')[0],
      'notas_adicionales': notasAdicionales,
    };
  }

  /// Crea una copia de este comprobante con los campos que se especifican modificados
  ComprobanteMovimiento copyWith({
    int? id,
    int? idMovimiento,
    String? rutaArchivo, // Cambiado de rutaImagen
    String? tipoArchivo,
    String? descripcion,
    bool? esPrincipal,
    String? tipoComprobante,
    String? numeroReferencia,
    String? emisor,
    String? receptor,
    String? metodoPago,
    DateTime? fechaEmision,
    String? notasAdicionales,
    DateTime? fechaCarga,
    String? conceptoMovimiento,
    double? montoMovimiento,
    String? nombreCliente,
    String? apellidoCliente,
    String? nombreInmueble,
  }) {
    return ComprobanteMovimiento(
      id: id ?? this.id,
      idMovimiento: idMovimiento ?? this.idMovimiento,
      rutaArchivo: rutaArchivo ?? this.rutaArchivo,
      tipoArchivo: tipoArchivo ?? this.tipoArchivo,
      descripcion: descripcion ?? this.descripcion,
      esPrincipal: esPrincipal ?? this.esPrincipal,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      numeroReferencia: numeroReferencia ?? this.numeroReferencia,
      emisor: emisor ?? this.emisor,
      receptor: receptor ?? this.receptor,
      metodoPago: metodoPago ?? this.metodoPago,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      notasAdicionales: notasAdicionales ?? this.notasAdicionales,
      fechaCarga: fechaCarga ?? this.fechaCarga,
      conceptoMovimiento: conceptoMovimiento ?? this.conceptoMovimiento,
      montoMovimiento: montoMovimiento ?? this.montoMovimiento,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      apellidoCliente: apellidoCliente ?? this.apellidoCliente,
      nombreInmueble: nombreInmueble ?? this.nombreInmueble,
    );
  }

  /// Obtiene la extensión del archivo desde la ruta
  String get extension {
    final parts = rutaArchivo.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Determina si el archivo es una imagen basado en su extensión o tipo
  bool get esImagen {
    if (tipoArchivo == 'imagen') return true;
    final ext = extension;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  /// Determina si el archivo es un PDF
  bool get esPDF {
    if (tipoArchivo == 'pdf') return true;
    return extension == 'pdf';
  }

  /// Determina si es un comprobante fiscal (factura)
  bool get esComprobanteFiscal => tipoComprobante == 'factura';

  /// Obtiene el nombre completo del cliente si está disponible
  String get clienteNombreCompleto {
    if (nombreCliente != null && apellidoCliente != null) {
      return '$nombreCliente $apellidoCliente';
    }
    return 'Cliente no especificado';
  }

  /// Formatea la fecha de emisión para mostrar
  String get fechaEmisionFormateada {
    if (fechaEmision == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(fechaEmision!);
  }

  /// Formatea el método de pago para mostrar
  String get metodoPagoFormateado {
    if (metodoPago == null) return 'N/A';

    switch (metodoPago) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia bancaria';
      case 'cheque':
        return 'Cheque';
      case 'tarjeta':
        return 'Tarjeta de crédito/débito';
      case 'otro':
        return 'Otro método';
      default:
        return metodoPago!;
    }
  }

  /// Formatea el tipo de comprobante para mostrar
  String get tipoComprobanteFormateado {
    switch (tipoComprobante) {
      case 'factura':
        return 'Factura';
      case 'recibo':
        return 'Recibo';
      case 'contrato':
        return 'Contrato';
      case 'otro':
        return 'Otro documento';
      default:
        return 'Documento';
    }
  }

  /// Formatea el monto del movimiento asociado
  String get montoFormateado {
    if (montoMovimiento == null) return 'N/A';
    return NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
    ).format(montoMovimiento);
  }

  @override
  String toString() =>
      'ComprobanteMovimiento{id: $id, movimiento: $idMovimiento, tipo: $tipoComprobante}';
}

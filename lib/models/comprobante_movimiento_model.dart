import 'package:intl/intl.dart';
import 'comprobante_base_model.dart';
import 'package:logging/logging.dart';

/// Modelo que representa un comprobante o documento adjunto a un movimiento de renta
class ComprobanteMovimiento extends ComprobanteBase {
  static final Logger _logger = Logger('ComprobanteMovimientoModel');

  final int idMovimiento;
  final String tipoComprobante; // 'factura', 'recibo', 'contrato', 'otro'
  final String? numeroReferencia;
  final String? emisor;
  final String? receptor;
  final String?
  metodoPago; // 'efectivo', 'transferencia', 'cheque', 'tarjeta', 'otro'
  final DateTime? fechaEmision;
  final String? notasAdicionales;

  // Datos relacionados para UI
  final String? conceptoMovimiento;
  final double? montoMovimiento;
  final String? nombreCliente;
  final String? apellidoCliente;
  final String? nombreInmueble;

  ComprobanteMovimiento({
    super.id,
    required this.idMovimiento,
    required super.rutaArchivo,
    super.tipoArchivo = 'imagen',
    super.descripcion,
    super.esPrincipal = false,
    required this.tipoComprobante,
    this.numeroReferencia,
    this.emisor,
    this.receptor,
    this.metodoPago,
    this.fechaEmision,
    this.notasAdicionales,
    super.fechaCarga,
    this.conceptoMovimiento,
    this.montoMovimiento,
    this.nombreCliente,
    this.apellidoCliente,
    this.nombreInmueble,
  }) {
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
      // Función auxiliar para convertir Blob a String
      String? blobToString(dynamic value) {
        if (value == null) return null;
        if (value is String) return value;

        // Detectar si es un Blob del paquete MySQL de Dart
        if (value.runtimeType.toString().contains('Blob')) {
          try {
            // Intenta obtener los bytes del Blob y convertirlos a String
            final bytes = value.toBytes();
            return String.fromCharCodes(bytes);
          } catch (e) {
            _logger.warning('Error al convertir Blob a String: $e');
            return value.toString();
          }
        }
        return value.toString();
      }

      DateTime? parseFecha(dynamic fecha) {
        if (fecha == null) return null;
        if (fecha is DateTime) return fecha;
        try {
          return DateTime.parse(fecha.toString());
        } catch (e) {
          _logger.warning('Error al parsear fecha: $e');
          return null;
        }
      }

      // Obtener la ruta del archivo con manejo de diferentes nombres de campo
      String obtenerRutaArchivo() {
        String rutaArchivo = '';

        // Primero intentar con el campo esperado
        if (map.containsKey('ruta_archivo') && map['ruta_archivo'] != null) {
          rutaArchivo = blobToString(map['ruta_archivo']) ?? '';
        }
        // Luego probar con campo alternativo usado en algunas versiones
        else if (map.containsKey('ruta_imagen') && map['ruta_imagen'] != null) {
          rutaArchivo = blobToString(map['ruta_imagen']) ?? '';
        }

        // Normalizar la ruta para evitar problemas con separadores de directorios
        rutaArchivo = rutaArchivo.replaceAll('\\', '/');

        // Si la ruta ya es absoluta (Windows o Unix), dejarla tal cual
        final esAbsoluta =
            rutaArchivo.startsWith('/') ||
            RegExp(r'^[A-Za-z]:/').hasMatch(rutaArchivo);
        if (esAbsoluta) {
          return rutaArchivo;
        }

        // Si la ruta contiene un separador de directorio, dejarla tal cual
        if (rutaArchivo.contains('/')) {
          return rutaArchivo;
        }

        // Si es solo un nombre de archivo, anteponer comprobantes/
        if (rutaArchivo.isNotEmpty) {
          rutaArchivo = 'comprobantes/$rutaArchivo';
        }

        // Eliminamos cualquier duplicado de "comprobantes/comprobantes/"
        rutaArchivo = rutaArchivo.replaceAll(
          'comprobantes/comprobantes/',
          'comprobantes/',
        );

        _logger.fine('Ruta de archivo procesada: $rutaArchivo');
        return rutaArchivo;
      }

      // Obtener valor booleano manejo de diferentes formatos
      bool obtenerBooleano(dynamic valor, {bool valorPorDefecto = false}) {
        if (valor == null) return valorPorDefecto;
        if (valor is bool) return valor;
        if (valor is int) return valor == 1;
        if (valor is String) {
          return valor == '1' || valor.toLowerCase() == 'true';
        }
        return valorPorDefecto;
      }

      return ComprobanteMovimiento(
        id: map['id_comprobante'],
        idMovimiento: map['id_movimiento'],
        rutaArchivo: obtenerRutaArchivo(),
        tipoArchivo:
            blobToString(map['tipo_archivo']) ??
            (obtenerRutaArchivo().toLowerCase().endsWith('.pdf')
                ? 'pdf'
                : 'imagen'),
        descripcion: blobToString(map['descripcion']),
        esPrincipal: obtenerBooleano(map['es_principal']),
        tipoComprobante: blobToString(map['tipo_comprobante']) ?? 'otro',
        numeroReferencia: blobToString(map['numero_referencia']),
        emisor: blobToString(map['emisor']),
        receptor: blobToString(map['receptor']),
        metodoPago: blobToString(map['metodo_pago']),
        fechaEmision: parseFecha(map['fecha_emision']),
        notasAdicionales: blobToString(map['notas_adicionales']),
        fechaCarga: parseFecha(map['fecha_carga']) ?? DateTime.now(),
        conceptoMovimiento: blobToString(
          map['concepto_movimiento'] ?? map['concepto'],
        ),
        montoMovimiento:
            map['monto_movimiento'] != null
                ? double.tryParse(map['monto_movimiento'].toString())
                : map['monto'] != null
                ? double.tryParse(map['monto'].toString())
                : null,
        nombreCliente: blobToString(map['nombre_cliente']),
        apellidoCliente: blobToString(
          map['apellido_cliente'] ?? map['apellido_paterno'],
        ),
        nombreInmueble: blobToString(map['nombre_inmueble']),
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
  @override
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id_comprobante': id,
      'id_movimiento': idMovimiento,
      'ruta_archivo': rutaArchivo,
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
    String? rutaArchivo,
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

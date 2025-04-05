import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

/// Modelo que representa un contrato generado para ventas o rentas
class ContratoGenerado {
  static final Logger _logger = Logger('ContratoGeneradoModel');

  final int? id;
  final String tipoContrato; // 'venta' o 'renta'
  final int idReferencia; // ID de venta o contrato de renta
  final String rutaArchivo;
  final DateTime fechaGeneracion;
  final int version;
  final int? idUsuario;
  final bool? esUltimaVersion; // Indica si es la versión más reciente

  // Datos adicionales para la UI
  final String? nombreUsuario;

  ContratoGenerado({
    this.id,
    required this.tipoContrato,
    required this.idReferencia,
    required this.rutaArchivo,
    DateTime? fechaGeneracion,
    this.version = 1,
    this.idUsuario,
    this.nombreUsuario,
    this.esUltimaVersion,
  }) : fechaGeneracion = fechaGeneracion ?? DateTime.now() {
    if (tipoContrato != 'venta' && tipoContrato != 'renta') {
      _logger.warning(
        'Tipo de contrato inválido: $tipoContrato. Solo se permiten "venta" o "renta".',
      );
    }
  }

  /// Crea un objeto ContratoGenerado desde un mapa (para deserialización desde BD)
  factory ContratoGenerado.fromMap(Map<String, dynamic> map) {
    try {
      return ContratoGenerado(
        id: map['id_contrato_generado'],
        tipoContrato: map['tipo_contrato'] ?? 'venta',
        idReferencia: map['id_referencia'],
        rutaArchivo: map['ruta_archivo'],
        fechaGeneracion:
            map['fecha_generacion'] is DateTime
                ? map['fecha_generacion']
                : DateTime.parse(map['fecha_generacion'].toString()),
        version: map['version'] ?? 1,
        idUsuario: map['id_usuario'],
        nombreUsuario: map['nombre_usuario'],
        esUltimaVersion:
            map['es_ultima_version'] == 1 || map['es_ultima_version'] == true,
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Error al crear ContratoGenerado desde Map: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Convierte el objeto a un mapa para serialización
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id_contrato_generado': id,
      'tipo_contrato': tipoContrato,
      'id_referencia': idReferencia,
      'ruta_archivo': rutaArchivo,
      'version': version,
      if (idUsuario != null) 'id_usuario': idUsuario,
    };
  }

  /// Crea una copia de este contrato generado con los campos que se especifican modificados
  ContratoGenerado copyWith({
    int? id,
    String? tipoContrato,
    int? idReferencia,
    String? rutaArchivo,
    DateTime? fechaGeneracion,
    int? version,
    int? idUsuario,
    String? nombreUsuario,
    bool? esUltimaVersion,
  }) {
    return ContratoGenerado(
      id: id ?? this.id,
      tipoContrato: tipoContrato ?? this.tipoContrato,
      idReferencia: idReferencia ?? this.idReferencia,
      rutaArchivo: rutaArchivo ?? this.rutaArchivo,
      fechaGeneracion: fechaGeneracion ?? this.fechaGeneracion,
      version: version ?? this.version,
      idUsuario: idUsuario ?? this.idUsuario,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      esUltimaVersion: esUltimaVersion ?? this.esUltimaVersion,
    );
  }

  /// Obtiene la extensión del archivo desde la ruta
  String get extension {
    final parts = rutaArchivo.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Determina si el archivo es un PDF
  bool get esPDF => extension == 'pdf';

  /// Determina si el contrato es de venta
  bool get esContratoVenta => tipoContrato == 'venta';

  /// Determina si el contrato es de renta
  bool get esContratoRenta => tipoContrato == 'renta';

  /// Formatea la fecha de generación para mostrar
  String get fechaGeneracionFormateada {
    return DateFormat('dd/MM/yyyy HH:mm').format(fechaGeneracion);
  }

  /// Obtiene la fecha de registro formateada (alias de fechaGeneracion)
  String get fechaRegistro {
    return DateFormat('dd/MM/yyyy HH:mm').format(fechaGeneracion);
  }

  /// Genera un nombre descriptivo para el contrato
  String get nombreDescriptivo {
    final tipoStr = esContratoVenta ? 'Venta' : 'Renta';
    return 'Contrato $tipoStr v$version - $fechaGeneracionFormateada';
  }

  /// Retorna el nombre del archivo sin la ruta
  String get nombreArchivo {
    final partes = rutaArchivo.split('/');
    return partes.isNotEmpty ? partes.last : rutaArchivo;
  }

  @override
  String toString() =>
      'ContratoGenerado{id: $id, tipo: $tipoContrato, referencia: $idReferencia, version: $version}';
}

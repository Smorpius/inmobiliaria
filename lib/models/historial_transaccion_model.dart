import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

/// Enumeración para los tipos de entidades en el historial
enum TipoEntidad {
  venta,
  movimientoRenta,
  contratoRenta;

  String get valor {
    switch (this) {
      case TipoEntidad.venta:
        return 'venta';
      case TipoEntidad.movimientoRenta:
        return 'movimiento_renta';
      case TipoEntidad.contratoRenta:
        return 'contrato_renta';
    }
  }

  static TipoEntidad fromString(String valor) {
    switch (valor) {
      case 'venta':
        return TipoEntidad.venta;
      case 'movimiento_renta':
        return TipoEntidad.movimientoRenta;
      case 'contrato_renta':
        return TipoEntidad.contratoRenta;
      default:
        throw ArgumentError('Tipo de entidad no válido: $valor');
    }
  }
}

/// Modelo que representa un registro de cambio en el historial de transacciones
///
/// Este modelo se usa para implementar capacidades de auditoría en las transacciones
/// (ventas, movimientos de renta, contratos) y mantener registro de qué usuario
/// realizó cada cambio.
class HistorialTransaccion {
  static final Logger _logger = Logger('HistorialTransaccionModel');

  final int? id;
  final TipoEntidad tipoEntidad; // Ahora usando enum en vez de String
  final int
  idEntidad; // ID de la entidad afectada (id_venta, id_movimiento, id_contrato)
  final String campoModificado;
  final String? valorAnterior;
  final String? valorNuevo;
  final int? idUsuarioModificacion;
  final DateTime fechaModificacion;

  // Datos adicionales para la UI
  final String? nombreUsuario;
  final String? apellidoUsuario;

  HistorialTransaccion({
    this.id,
    required this.tipoEntidad,
    required this.idEntidad,
    required this.campoModificado,
    this.valorAnterior,
    this.valorNuevo,
    this.idUsuarioModificacion,
    DateTime? fechaModificacion,
    this.nombreUsuario,
    this.apellidoUsuario,
  }) : fechaModificacion = fechaModificacion ?? DateTime.now() {
    if (campoModificado.isEmpty) {
      _logger.warning(
        'Se creó un registro de historial sin especificar el campo modificado',
      );
    }
  }

  /// Crea un objeto HistorialTransaccion desde un mapa (para deserialización desde BD)
  factory HistorialTransaccion.fromMap(Map<String, dynamic> map) {
    try {
      final tipoEntidadString = _determinarTipoEntidad(map);
      return HistorialTransaccion(
        id: map['id_historial'],
        tipoEntidad: TipoEntidad.fromString(tipoEntidadString),
        idEntidad: _obtenerIdEntidad(map),
        campoModificado: map['campo_modificado'] ?? '',
        valorAnterior: map['valor_anterior']?.toString(),
        valorNuevo: map['valor_nuevo']?.toString(),
        idUsuarioModificacion: map['usuario_modificacion'],
        fechaModificacion:
            map['fecha_modificacion'] is DateTime
                ? map['fecha_modificacion']
                : DateTime.parse(map['fecha_modificacion'].toString()),
        nombreUsuario: map['nombre_usuario'],
        apellidoUsuario: map['apellido_usuario'],
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Error al crear HistorialTransaccion desde Map: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Determina el tipo de entidad basado en las claves presentes en el mapa
  static String _determinarTipoEntidad(Map<String, dynamic> map) {
    if (map['id_venta'] != null || map['tipoEntidad'] == 'venta') {
      return 'venta';
    } else if (map['id_movimiento'] != null ||
        map['tipoEntidad'] == 'movimiento_renta') {
      return 'movimiento_renta';
    } else if (map['id_contrato'] != null ||
        map['tipoEntidad'] == 'contrato_renta') {
      return 'contrato_renta';
    } else {
      return map['tipo_entidad'] ?? 'desconocido';
    }
  }

  /// Obtiene el ID de la entidad basado en el tipo de entidad
  static int _obtenerIdEntidad(Map<String, dynamic> map) {
    if (map['id_entidad'] != null) {
      return map['id_entidad'];
    } else if (map['id_venta'] != null) {
      return map['id_venta'];
    } else if (map['id_movimiento'] != null) {
      return map['id_movimiento'];
    } else if (map['id_contrato'] != null) {
      return map['id_contrato'];
    } else {
      throw Exception('No se pudo determinar el ID de la entidad');
    }
  }

  /// Convierte el objeto a un mapa para serialización
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id_historial': id,
      'tipo_entidad': tipoEntidad.valor,
      'id_entidad': idEntidad,
      'campo_modificado': campoModificado,
      'valor_anterior': valorAnterior,
      'valor_nuevo': valorNuevo,
      if (idUsuarioModificacion != null)
        'usuario_modificacion': idUsuarioModificacion,
    };
  }

  /// Formatea la fecha de modificación para mostrar
  String get fechaModificacionFormateada {
    return DateFormat('dd/MM/yyyy HH:mm').format(fechaModificacion);
  }

  /// Obtiene el nombre completo del usuario que realizó la modificación
  String get usuarioNombreCompleto {
    if (nombreUsuario != null) {
      if (apellidoUsuario != null) {
        return '$nombreUsuario $apellidoUsuario';
      }
      return nombreUsuario!;
    }
    return idUsuarioModificacion != null
        ? 'Usuario #$idUsuarioModificacion'
        : 'Usuario desconocido';
  }

  /// Genera una descripción legible del cambio
  String get descripcionCambio {
    final cambio = campoModificado.replaceAll('_', ' ');

    // Si tenemos valores anterior y nuevo, mostramos ambos
    if (valorAnterior != null && valorNuevo != null) {
      return 'Cambió $cambio de "$valorAnterior" a "$valorNuevo"';
    }
    // Si solo tenemos valor nuevo (creación)
    else if (valorNuevo != null) {
      return 'Estableció $cambio a "$valorNuevo"';
    }
    // Si solo tenemos valor anterior (eliminación)
    else if (valorAnterior != null) {
      return 'Eliminó $cambio (era "$valorAnterior")';
    }
    // Caso genérico
    else {
      return 'Modificó $cambio';
    }
  }

  /// Obtiene el nombre legible de la entidad
  String get nombreEntidad {
    switch (tipoEntidad) {
      case TipoEntidad.venta:
        return 'Venta';
      case TipoEntidad.movimientoRenta:
        return 'Movimiento de Renta';
      case TipoEntidad.contratoRenta:
        return 'Contrato de Renta';
    }
  }

  @override
  String toString() =>
      'HistorialTransaccion{id: $id, entidad: ${tipoEntidad.valor} #$idEntidad, campo: $campoModificado}';
}

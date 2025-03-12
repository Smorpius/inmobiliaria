import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer' as developer;
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

  Map<String, dynamic> toMap() {
    return {
      'id_inmueble': id,
      'nombre_inmueble': nombre,
      'id_direccion': idDireccion,
      'monto_total': montoTotal,
      'id_estado': idEstado,
      'id_cliente': idCliente,
      'id_empleado': idEmpleado,
      'fecha_registro': fechaRegistro?.toIso8601String(),
      'tipo_inmueble': tipoInmueble,
      'tipo_operacion': tipoOperacion,
      'precio_venta': precioVenta,
      'precio_renta': precioRenta,
      'caracteristicas': caracteristicas,
      'calle': calle,
      'numero': numero,
      'colonia': colonia,
      'ciudad': ciudad,
      'estado_geografico': estadoGeografico,
      'codigo_postal': codigoPostal,
      'referencias': referencias,
    };
  }

  // AQUÍ ESTÁ EL MÉTODO QUE FALTABA - fromMap
  factory Inmueble.fromMap(Map<String, dynamic> map) {
    try {
      _logger.info(
        'Procesando inmueble ID: ${map['id_inmueble']}',
      ); // Usando el logger
      developer.log(
        'Procesando datos del inmueble: ${map['id_inmueble']} - ${map['nombre_inmueble']}',
      );

      // Función auxiliar para convertir BLOBs a String de manera más robusta
      String? blobToString(dynamic value) {
        if (value == null) return null;

        // Si es un BLOB, convertir a String - CORREGIDO
        if (value is Uint8List) {
          try {
            return utf8.decode(value);
          } catch (e) {
            _logger.warning(
              'Error al decodificar BLOB: $e',
            ); // Usando el logger
            developer.log('Error al decodificar BLOB: $e');
            return String.fromCharCodes(value); // Alternativa de decodificación
          }
        }

        // Si ya es String, devolverlo directamente
        if (value is String) {
          return value;
        }

        // Otro caso, convertir a String de forma segura
        return value.toString();
      }

      // Función segura para convertir numeros
      double? parseDoubleSafely(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        try {
          return double.parse(value.toString());
        } catch (e) {
          _logger.warning(
            'Error al convertir a double: $value - $e',
          ); // Usando el logger
          return null;
        }
      }

      // Función segura para convertir enteros
      int? parseIntSafely(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        try {
          return int.parse(value.toString());
        } catch (e) {
          _logger.warning(
            'Error al convertir a int: $value - $e',
          ); // Usando el logger
          return null;
        }
      }

      return Inmueble(
        id: parseIntSafely(map['id_inmueble']),
        nombre: blobToString(map['nombre_inmueble']) ?? 'Sin nombre',
        idDireccion: parseIntSafely(map['id_direccion']),
        montoTotal: parseDoubleSafely(map['monto_total']) ?? 0.0,
        idEstado: parseIntSafely(map['id_estado']),
        idCliente: parseIntSafely(map['id_cliente']),
        idEmpleado: parseIntSafely(map['id_empleado']),
        fechaRegistro:
            map['fecha_registro'] != null
                ? (map['fecha_registro'] is DateTime
                    ? map['fecha_registro']
                    : DateTime.parse(map['fecha_registro'].toString()))
                : null,

        // Nuevos campos específicos - CORREGIDOS
        tipoInmueble: blobToString(map['tipo_inmueble']) ?? 'casa',
        tipoOperacion: blobToString(map['tipo_operacion']) ?? 'venta',
        precioVenta: parseDoubleSafely(map['precio_venta']),
        precioRenta: parseDoubleSafely(map['precio_renta']),
        caracteristicas: blobToString(map['caracteristicas']),

        // Campos de dirección - CORREGIDOS
        calle: blobToString(map['calle']),
        numero: blobToString(map['numero']),
        colonia: blobToString(map['colonia']),
        ciudad: blobToString(map['ciudad']),
        estadoGeografico: blobToString(map['estado_geografico']),
        codigoPostal: blobToString(map['codigo_postal']),
        referencias: blobToString(map['referencias']),
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Error al procesar inmueble: $e',
        e,
        stackTrace,
      ); // Usando el logger
      developer.log(
        'ERROR en Inmueble.fromMap: $e',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Error al procesar inmueble: $e');
    }
  }

  // Propiedad para obtener la dirección completa
  String get direccionCompleta {
    List<String?> direccionParts = [
      calle,
      numero,
      colonia,
      ciudad,
      estadoGeografico,
      codigoPostal,
    ];

    return direccionParts
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(', ');
  }

  @override
  String toString() {
    return 'Inmueble{id: $id, nombre: $nombre, tipo: $tipoInmueble, operacion: $tipoOperacion, estado: $idEstado}';
  }
}

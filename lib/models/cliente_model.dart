import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';
class Cliente {
  static final Logger _logger = Logger('Cliente');

  final int? id;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final int? idDireccion;
  final String telefono;
  final String rfc;
  final String curp;
  final String tipoCliente;
  final String? correo;
  final int? idEstado;
  final DateTime? fechaRegistro;
  final String? estadoCliente;

  // Campos completos de dirección según la nueva estructura de la DB
  final String? calle;
  final String? numero;
  final String? colonia;
  final String? ciudad;
  final String? estadoGeografico;
  final String? codigoPostal;
  final String? referencias;

  Cliente({
    this.id,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    this.idDireccion,
    required this.telefono,
    required this.rfc,
    required this.curp,
    this.tipoCliente = 'comprador',
    this.correo,
    this.idEstado,
    this.fechaRegistro,
    this.estadoCliente,
    this.calle,
    this.numero,
    this.colonia,
    this.ciudad,
    this.estadoGeografico,
    this.codigoPostal,
    this.referencias,
  });

    factory Cliente.fromMap(Map<String, dynamic> map) {
    try {
      developer.log('Procesando datos del cliente: ${map['id_cliente']} - ${map['nombre']}');
      
      // Función para convertir BLOBs a String de manera segura
      String? blobToString(dynamic value) {
        if (value == null) return null;
        
        // Si es un BLOB, convertir a String
        if (value is Uint8List) {
          return utf8.decode(value);
        }
        
        // Si ya es String, devolverlo directamente
        if (value is String) {
          return value;
        }
        
        // Otro caso, convertir a String
        return value.toString();
      }
      
      return Cliente(
        id: map['id_cliente'] is int ? map['id_cliente'] : int.tryParse(map['id_cliente'].toString()),
        nombre: map['nombre'] as String,
        apellidoPaterno: map['apellido_paterno'] as String,
        apellidoMaterno: blobToString(map['apellido_materno']),
        idDireccion: map['id_direccion'] is int ? map['id_direccion'] : int.tryParse(map['id_direccion'].toString()),
        telefono: blobToString(map['telefono_cliente']) ?? '',
        rfc: blobToString(map['rfc']) ?? '',
        curp: blobToString(map['curp']) ?? '',
        tipoCliente: blobToString(map['tipo_cliente']) ?? 'comprador',
        correo: blobToString(map['correo_cliente']),
        idEstado: map['id_estado'] is int ? map['id_estado'] : int.tryParse(map['id_estado'].toString()),
        fechaRegistro: map['fecha_registro'] != null ? 
            (map['fecha_registro'] is DateTime ? 
                map['fecha_registro'] : 
                DateTime.parse(map['fecha_registro'].toString())) : 
            null,
        
        // Campos de dirección - usando la función para manejar BLOBs
        calle: blobToString(map['calle']),
        numero: blobToString(map['numero']),
        colonia: blobToString(map['colonia']),
        ciudad: blobToString(map['ciudad']),
        estadoGeografico: blobToString(map['estado_geografico']),
        codigoPostal: blobToString(map['codigo_postal']),
        referencias: blobToString(map['referencias']),
      );
    } catch (e, stackTrace) {
      _logger.severe('Error al convertir mapa a Cliente: $e');
      developer.log('ERROR en Cliente.fromMap: $e', error: e, stackTrace: stackTrace);
      developer.log('Datos recibidos: $map');
      throw Exception('Error al convertir datos de cliente: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id_cliente': id,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'id_direccion': idDireccion,
      'telefono_cliente': telefono,
      'rfc': rfc,
      'curp': curp,
      'tipo_cliente': tipoCliente,
      'correo_cliente': correo,
      'id_estado': idEstado,
    };
  }

  // Propiedad para obtener el nombre completo
  String get nombreCompleto =>
      '$nombre $apellidoPaterno${apellidoMaterno != null ? ' $apellidoMaterno' : ''}';

  // Propiedad mejorada para obtener la dirección completa con todos los campos
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

  String get estado => estadoCliente ?? (idEstado == 1 ? 'Activo' : 'Inactivo');

  @override
  String toString() {
    return 'Cliente{id: $id, nombre: $nombreCompleto, telefono: $telefono, RFC: $rfc, CURP: $curp, tipo: $tipoCliente}';
  }
}

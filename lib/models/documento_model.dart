import 'serializable_model.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class Documento implements SerializableModel {
  final String id;
  final String nombre;
  final String rutaArchivo;
  final String tipoDocumento; // 'contrato', 'comprobante', 'reporte', etc.
  final String categoria; // 'venta', 'renta', 'movimiento', etc.
  final DateTime fechaCreacion;
  final String? descripcion;
  final bool esFavorito;

  Documento({
    required this.id,
    required this.nombre,
    required this.rutaArchivo,
    required this.tipoDocumento,
    required this.categoria,
    required this.fechaCreacion,
    this.descripcion,
    this.esFavorito = false,
  });

  // Obtener la extensión del archivo
  String get extension => path.extension(rutaArchivo).toLowerCase();

  // Verificar si es un PDF
  bool get isPdf => extension == '.pdf';

  // Verificar si es una imagen
  bool get isImage => ['.jpg', '.jpeg', '.png', '.gif'].contains(extension);

  // Obtener el icono según tipo de archivo
  IconData get icono {
    if (isPdf) return Icons.picture_as_pdf;
    if (isImage) return Icons.image;
    switch (tipoDocumento) {
      case 'contrato':
        return Icons.assignment;
      case 'comprobante':
        return Icons.receipt;
      case 'reporte':
        return Icons.analytics;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Crear copia del documento con cambios
  Documento copyWith({
    String? id,
    String? nombre,
    String? rutaArchivo,
    String? tipoDocumento,
    String? categoria,
    DateTime? fechaCreacion,
    String? descripcion,
    bool? esFavorito,
  }) {
    return Documento(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      rutaArchivo: rutaArchivo ?? this.rutaArchivo,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      categoria: categoria ?? this.categoria,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      descripcion: descripcion ?? this.descripcion,
      esFavorito: esFavorito ?? this.esFavorito,
    );
  }

  // Mapear documento a Map (implementación de SerializableModel)
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'rutaArchivo': rutaArchivo,
      'tipoDocumento': tipoDocumento,
      'categoria': categoria,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'descripcion': descripcion,
      'esFavorito': esFavorito ? 1 : 0,
    };
  }

  // Crear documento desde Map
  factory Documento.fromMap(Map<String, dynamic> map) {
    return Documento(
      id: map['id'],
      nombre: map['nombre'],
      rutaArchivo: map['rutaArchivo'],
      tipoDocumento: map['tipoDocumento'],
      categoria: map['categoria'],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      descripcion: map['descripcion'],
      esFavorito: map['esFavorito'] == 1,
    );
  }
}

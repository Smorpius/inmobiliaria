class Proveedor {
  final int? idProveedor;
  final String nombre;
  final String nombreEmpresa;
  final String nombreContacto;
  final String direccion;
  final String telefono;
  final String correo;
  final String tipoServicio;
  final int idEstado;

  Proveedor({
    this.idProveedor,
    required this.nombre,
    required this.nombreEmpresa,
    required this.nombreContacto,
    required this.direccion,
    required this.telefono,
    required this.correo,
    required this.tipoServicio,
    this.idEstado = 1,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      idProveedor: json['id_proveedor'],
      nombre: json['nombre'] ?? '',
      nombreEmpresa: json['nombre_empresa'] ?? '',
      nombreContacto: json['nombre_contacto'] ?? '',
      direccion: json['direccion'] ?? '',
      telefono: json['telefono'] ?? '',
      correo: json['correo'] ?? '',
      tipoServicio: json['tipo_servicio'] ?? '',
      idEstado: json['id_estado'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_proveedor': idProveedor,
      'nombre': nombre,
      'nombre_empresa': nombreEmpresa,
      'nombre_contacto': nombreContacto,
      'direccion': direccion,
      'telefono': telefono,
      'correo': correo,
      'tipo_servicio': tipoServicio,
      'id_estado': idEstado,
    };
  }
}
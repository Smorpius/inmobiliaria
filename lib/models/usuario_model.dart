class Usuario {
  final int? id;
  final String nombre;
  final String apellido;
  final String nombreUsuario;
  final String contrasena;
  final String? correo;
  final int? idEstado;
  final DateTime? fechaCreacion;
  final DateTime? ultimaActualizacion;

  Usuario({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.nombreUsuario,
    required this.contrasena,
    this.correo,
    this.idEstado,
    this.fechaCreacion,
    this.ultimaActualizacion,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id_usuario'],
      nombre: map['nombre'],
      apellido: map['apellido'],
      nombreUsuario: map['nombre_usuario'], // Hyphenated
      contrasena: map['contraseña_usuario'], // Use full column name
      correo: map['correo_cliente'], // From the SQL schema
      idEstado: map['id_estado'],
      fechaCreacion:
          map['fecha_creacion'] != null
              ? DateTime.parse(map['fecha_creacion'].toString())
              : null,
      ultimaActualizacion:
          map['ultima_actualizacion'] != null
              ? DateTime.parse(map['ultima_actualizacion'].toString())
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': id,
      'nombre': nombre,
      'apellido': apellido,
      'nombre_usuario': nombreUsuario,
      'contraseña_usuario': contrasena,
      'correo_cliente': correo,
      'id_estado': idEstado,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
      'ultima_actualizacion': ultimaActualizacion?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Usuario{id: $id, nombre: $nombre, apellido: $apellido, nombreUsuario: $nombreUsuario}';
  }
}

class Usuario {
  final int? id;
  final String nombre;
  final String apellido;
  final String nombreUsuario;
  final String contrasena;
  final String? correo;
  final String? imagenPerfil; // Campo nuevo para la imagen
  final int idEstado;
  final String? estadoNombre;

  Usuario({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.nombreUsuario,
    required this.contrasena,
    this.correo,
    this.imagenPerfil, // Añadido parámetro
    required this.idEstado,
    this.estadoNombre,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id_usuario'],
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      nombreUsuario: map['nombre_usuario'] ?? '',
      contrasena: '', // No mostramos la contraseña
      correo: map['correo_cliente'],
      imagenPerfil: map['imagen_perfil'], // Añadida lectura del campo
      idEstado: map['id_estado'] ?? 1,
      estadoNombre: map['estado_usuario'],
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
      'imagen_perfil': imagenPerfil, // Añadida escritura del campo
      'id_estado': idEstado,
    };
  }

  // Para mostrar estado formateado
  String get estado => estadoNombre ?? (idEstado == 1 ? 'Activo' : 'Inactivo');
}

class Usuario {
  final int? id;
  final String nombre;
  final String apellido;
  final String nombreUsuario;
  final String contrasena;
  final String? correo; // Agregado según estructura SQL

  Usuario({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.nombreUsuario,
    required this.contrasena,
    this.correo,
  });

  // Convertir de Map a Usuario (para leer desde MySQL)
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id_usuario'],
      nombre: map['nombre'],
      apellido: map['apellido'],
      nombreUsuario: map['nombre_usuario'],
      contrasena: map['contraseña_usuario'],
      correo: map['correo_cliente'],
    );
  }

  // Convertir de Usuario a Map (para guardar en MySQL)
  Map<String, dynamic> toMap() {
    return {
      'id_usuario': id,
      'nombre': nombre,
      'apellido': apellido,
      'nombre_usuario': nombreUsuario,
      'contraseña_usuario': contrasena,
      'correo_cliente': correo,
    };
  }
}

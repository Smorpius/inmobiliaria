// lib/models/usuario_model.dart
class Usuario {
  final int? id;
  final String nombre;
  final String apellido;
  final String nombreUsuario;
  final String contrasena;

  Usuario({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.nombreUsuario,
    required this.contrasena,
  });

  // Convertir de Map a Usuario (para leer desde la BD)
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id_usuario'],
      nombre: map['nombre'],
      apellido: map['apellido'],
      nombreUsuario: map['nombre_usuario'],
      contrasena: map['contraseña_usuario'],
    );
  }

  // Convertir de Usuario a Map (para guardar en la BD)
  Map<String, dynamic> toMap() {
    return {
      'id_usuario': id,
      'nombre': nombre,
      'apellido': apellido,
      'nombre_usuario': nombreUsuario,
      'contraseña_usuario': contrasena,
    };
  }

  // Para depuración
  @override
  String toString() {
    return 'Usuario{id: $id, nombre: $nombre, apellido: $apellido, nombreUsuario: $nombreUsuario}';
  }
}

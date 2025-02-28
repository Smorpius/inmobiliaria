// lib/models/administrador_model.dart
class Administrador {
  final String nombreAdmin;
  final String contrasena;

  Administrador({required this.nombreAdmin, required this.contrasena});

  // Convertir de Map a Administrador
  factory Administrador.fromMap(Map<String, dynamic> map) {
    return Administrador(
      nombreAdmin: map['NombreAdmin'],
      contrasena: map['Contraseña'],
    );
  }

  // Convertir de Administrador a Map
  Map<String, dynamic> toMap() {
    return {'NombreAdmin': nombreAdmin, 'Contraseña': contrasena};
  }

  @override
  String toString() {
    return 'Administrador{nombreAdmin: $nombreAdmin}';
  }
}

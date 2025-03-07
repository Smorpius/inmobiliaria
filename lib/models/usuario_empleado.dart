import 'usuario.dart'; // [Usuario](lib/models/usuario.dart)
import 'empleado.dart'; // [Empleado](lib/models/empleado.dart)

class UsuarioEmpleado {
  final Usuario usuario;
  final Empleado empleado;

  UsuarioEmpleado({required this.usuario, required this.empleado});

  factory UsuarioEmpleado.fromMap(Map<String, dynamic> map) {
    return UsuarioEmpleado(
      usuario: Usuario(
        id: map['id_usuario'],
        nombre: map['nombre'] ?? '',
        apellido: map['apellido_paterno'] ?? '',
        nombreUsuario: map['nombre_usuario'] ?? '',
        contrasena: '', // No mostramos la contraseña
        correo: map['correo'],
        idEstado: map['id_estado'],
      ),
      empleado: Empleado(
        id: map['id_empleado'],
        idUsuario: map['id_usuario'],
        claveSistema:
            map['clave_sistema'] ??
            '', // Cambiado de claveInterna a claveSistema
        nombre: map['nombre'] ?? '',
        apellidoPaterno: map['apellido_paterno'] ?? '',
        apellidoMaterno: map['apellido_materno'],
        correo: map['correo'],
        telefono: map['telefono'],
        direccion: map['direccion'],
        cargo: map['cargo'],
        // Usamos un valor por defecto en caso de null
        sueldoActual:
            (map['sueldo_actual'] != null)
                ? double.tryParse(map['sueldo_actual'].toString()) ?? 0.0
                : 0.0,
        // Usamos una fecha por defecto en caso de null
        fechaContratacion:
            (map['fecha_contratacion'] != null)
                ? DateTime.parse(map['fecha_contratacion'])
                : DateTime(1970),
        idEstado: map['id_estado'],
      ),
    );
  }
}

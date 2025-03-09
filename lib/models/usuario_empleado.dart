import 'usuario.dart';
import 'empleado.dart';

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
        imagenPerfil: map['imagen_perfil'], // Añadida lectura del campo
        idEstado: map['id_estado'],
      ),
      empleado: Empleado(
        id: map['id_empleado'],
        idUsuario: map['id_usuario'],
        claveSistema: map['clave_sistema'] ?? '',
        nombre: map['nombre'] ?? '',
        apellidoPaterno: map['apellido_paterno'] ?? '',
        apellidoMaterno: map['apellido_materno'],
        correo: map['correo'] ?? '',
        telefono: map['telefono'] ?? '',
        direccion: map['direccion'] ?? '',
        cargo: map['cargo'] ?? '',
        imagenEmpleado: map['imagen_empleado'], // Añadida lectura del campo
        // Manejo seguro del sueldo
        sueldoActual:
            map['sueldo_actual'] == null
                ? 0.0
                : map['sueldo_actual'] is double
                ? map['sueldo_actual']
                : double.tryParse(map['sueldo_actual'].toString()) ?? 0.0,
        // Manejo seguro de la fecha - ya convertida en el servicio
        fechaContratacion:
            map['fecha_contratacion'] is DateTime
                ? map['fecha_contratacion']
                : DateTime.now(),
        idEstado: map['id_estado'] ?? 1,
        estadoNombre: map['estado_empleado'],
      ),
    );
  }
}

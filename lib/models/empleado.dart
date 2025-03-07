class Empleado {
  final int? id;
  final int? idUsuario;
  final String claveSistema; // Cambiado de claveInterna a claveSistema
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String telefono;
  final String correo;
  final String direccion;
  final String cargo;
  final double sueldoActual;
  final DateTime fechaContratacion;
  final int idEstado;
  final String? estadoNombre; // Para mostrar el estado en texto

  Empleado({
    this.id,
    this.idUsuario,
    required this.claveSistema, // Cambiado de claveInterna a claveSistema
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.cargo,
    required this.sueldoActual,
    required this.fechaContratacion,
    required this.idEstado,
    this.estadoNombre,
  });

  factory Empleado.fromMap(Map<String, dynamic> map) {
    return Empleado(
      id: map['id_empleado'],
      idUsuario: map['id_usuario'],
      claveSistema: map['clave_sistema'], // Ya coincide con la BD, sin cambios
      nombre: map['nombre'],
      apellidoPaterno: map['apellido_paterno'],
      apellidoMaterno: map['apellido_materno'],
      telefono: map['telefono'],
      correo: map['correo'],
      direccion: map['direccion'],
      cargo: map['cargo'],
      sueldoActual:
          map['sueldo_actual'] is String
              ? double.parse(map['sueldo_actual'])
              : map['sueldo_actual'].toDouble(),
      fechaContratacion:
          map['fecha_contratacion'] is String
              ? DateTime.parse(map['fecha_contratacion'])
              : map['fecha_contratacion'],
      idEstado: map['id_estado'],
      estadoNombre: map['estado_empleado'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_empleado': id,
      'id_usuario': idUsuario,
      'clave_sistema': claveSistema, // Cambiado para usar el nuevo nombre
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'telefono': telefono,
      'correo': correo,
      'direccion': direccion,
      'cargo': cargo,
      'sueldo_actual': sueldoActual,
      'fecha_contratacion': fechaContratacion.toIso8601String(),
      'id_estado': idEstado,
    };
  }

  // Para mostrar estado formateado
  String get estado => estadoNombre ?? (idEstado == 1 ? 'Activo' : 'Inactivo');
}

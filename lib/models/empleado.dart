class Empleado {
  final int? id;
  final int? idUsuario;
  final String claveSistema;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String telefono;
  final String correo;
  final String direccion;
  final String cargo;
  final double sueldoActual;
  final DateTime fechaContratacion;
  final String? imagenEmpleado; // Campo nuevo para la imagen
  final int idEstado;
  final String? estadoNombre;

  Empleado({
    this.id,
    this.idUsuario,
    required this.claveSistema,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.cargo,
    required this.sueldoActual,
    required this.fechaContratacion,
    this.imagenEmpleado, // Añadido parámetro
    required this.idEstado,
    this.estadoNombre,
  });

  factory Empleado.fromMap(Map<String, dynamic> map) {
    // Procesamiento seguro de la fecha
    DateTime procesarFecha(dynamic valor) {
      if (valor == null) return DateTime.now();
      if (valor is DateTime) return valor;
      try {
        return DateTime.parse(valor.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return Empleado(
      id: map['id_empleado'],
      idUsuario: map['id_usuario'],
      claveSistema: map['clave_sistema'] ?? '',
      nombre: map['nombre'] ?? '',
      apellidoPaterno: map['apellido_paterno'] ?? '',
      apellidoMaterno: map['apellido_materno'],
      telefono: map['telefono'] ?? '',
      correo: map['correo'] ?? '',
      direccion: map['direccion'] ?? '',
      cargo: map['cargo'] ?? '',
      imagenEmpleado: map['imagen_empleado'], // Añadida lectura del campo
      sueldoActual:
          map['sueldo_actual'] == null
              ? 0.0
              : map['sueldo_actual'] is double
              ? map['sueldo_actual']
              : double.tryParse(map['sueldo_actual'].toString()) ?? 0.0,
      fechaContratacion: procesarFecha(map['fecha_contratacion']),
      idEstado: map['id_estado'] ?? 1,
      estadoNombre: map['estado_empleado'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_empleado': id,
      'id_usuario': idUsuario,
      'clave_sistema': claveSistema,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'telefono': telefono,
      'correo': correo,
      'direccion': direccion,
      'cargo': cargo,
      'sueldo_actual': sueldoActual,
      'fecha_contratacion': fechaContratacion.toIso8601String(),
      'imagen_empleado': imagenEmpleado, // Añadida escritura del campo
      'id_estado': idEstado,
    };
  }

  // Para mostrar estado formateado
  String get estado => estadoNombre ?? (idEstado == 1 ? 'Activo' : 'Inactivo');
}

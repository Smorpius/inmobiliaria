import '../models/usuario.dart';
import '../models/empleado.dart';
import '../models/usuario_empleado.dart';
import 'mysql_helper.dart'; // Cambiado de database_service.dart a mysql_helper.dart

class UsuarioEmpleadoService {
  final DatabaseService _db; // Usa la clase correcta de tu proyecto

  UsuarioEmpleadoService(this._db);

  Future<List<UsuarioEmpleado>> obtenerEmpleados() async {
    final conn = await _db.connection;
    final results = await conn.query('CALL LeerEmpleadosConUsuarios()');

    return results.map((row) => UsuarioEmpleado.fromMap(row.fields)).toList();
  }

  Future<UsuarioEmpleado?> obtenerEmpleadoPorId(int id) async {
    final conn = await _db.connection;
    final results = await conn.query('CALL ObtenerEmpleadoUsuario(?)', [id]);

    if (results.isNotEmpty) {
      return UsuarioEmpleado.fromMap(results.first.fields);
    }
    return null;
  }

  Future<int> crearUsuarioEmpleado(Usuario usuario, Empleado empleado) async {
    final conn = await _db.connection;

    await conn.query(
      'CALL CrearUsuarioEmpleado(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        usuario.nombre,
        usuario.apellido,
        usuario.nombreUsuario,
        usuario.contrasena,
        usuario.correo,
        empleado.claveSistema, // Corregido: claveInterna -> claveSistema
        empleado.apellidoMaterno,
        empleado.telefono,
        empleado.direccion,
        empleado.cargo,
        empleado.sueldoActual,
        empleado.fechaContratacion.toIso8601String(),
      ],
    );

    // Recuperar el ID del usuario creado
    final resultId = await conn.query('SELECT LAST_INSERT_ID() as id');
    return resultId.first['id'];
  }

  Future<void> actualizarUsuarioEmpleado(
    int idUsuario,
    int idEmpleado,
    Usuario usuario,
    Empleado empleado,
  ) async {
    final conn = await _db.connection;

    await conn.query(
      'CALL ActualizarUsuarioEmpleado(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        idUsuario,
        idEmpleado,
        usuario.nombre,
        usuario.apellido,
        usuario.nombreUsuario,
        usuario.contrasena.isNotEmpty ? usuario.contrasena : null,
        usuario.correo,
        empleado.claveSistema, // Corregido: claveInterna -> claveSistema
        empleado.apellidoMaterno,
        empleado.telefono,
        empleado.direccion,
        empleado.cargo,
        empleado.sueldoActual,
      ],
    );
  }

  Future<void> inactivarUsuarioEmpleado(int idUsuario, int idEmpleado) async {
    final conn = await _db.connection;
    await conn.query('CALL InactivarUsuarioEmpleado(?, ?)', [
      idUsuario,
      idEmpleado,
    ]);
  }
}

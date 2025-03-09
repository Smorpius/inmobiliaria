import '../models/usuario.dart';
import 'package:logging/logging.dart';
import '../services/mysql_helper.dart';

class UsuarioController {
  final DatabaseService _dbService;
  final Logger _logger = Logger('UsuarioController');

  UsuarioController({DatabaseService? dbService})
    : _dbService = dbService ?? DatabaseService();

  Future<int> insertUsuario(Usuario usuario) async {
    try {
      final conn = await _dbService.connection;
      // Corregido: Ahora incluimos los 6 parámetros esperados, incluido imagenPerfil
      var result = await conn.query('CALL CrearUsuario(?, ?, ?, ?, ?, ?)', [
        usuario.nombre,
        usuario.apellido,
        usuario.nombreUsuario,
        usuario.contrasena,
        usuario.correo,
        usuario.imagenPerfil, // Añadido el parámetro que faltaba
      ]);
      return result.insertId ?? -1;
    } catch (e) {
      _logger.severe('Error al insertar usuario: $e');
      throw Exception('No se pudo insertar el usuario: $e');
    }
  }

  Future<List<Usuario>> getUsuarios() async {
    try {
      final conn = await _dbService.connection;
      var results = await conn.query('SELECT * FROM usuarios');
      return results.map((row) => Usuario.fromMap(row.fields)).toList();
    } catch (e) {
      _logger.severe('Error al obtener usuarios: $e');
      throw Exception('No se pudieron obtener los usuarios: $e');
    }
  }

  Future<Usuario?> getUsuario(int id) async {
    try {
      final conn = await _dbService.connection;
      var results = await conn.query(
        'SELECT * FROM usuarios WHERE id_usuario = ?',
        [id],
      );
      return results.isNotEmpty ? Usuario.fromMap(results.first.fields) : null;
    } catch (e) {
      _logger.severe('Error al obtener usuario: $e');
      throw Exception('No se pudo obtener el usuario: $e');
    }
  }

  Future<bool> verificarCredenciales(String username, String password) async {
    try {
      final conn = await _dbService.connection;
      var results = await conn.query(
        'SELECT * FROM usuarios WHERE nombre_usuario = ? AND contraseña_usuario = ?',
        [username, password],
      );
      return results.isNotEmpty;
    } catch (e) {
      _logger.severe('Error al verificar credenciales: $e');
      throw Exception('Error de autenticación: $e');
    }
  }

  Future<int> updateUsuario(Usuario usuario) async {
    try {
      final conn = await _dbService.connection;
      // Asegúrate que ActualizarUsuario esté recibiendo todos los parámetros necesarios
      // Si el procedimiento también espera imagenPerfil, inclúyelo
      var result = await conn.query(
        'CALL ActualizarUsuario(?, ?, ?, ?, ?, ?, ?)', // Ajusta según tu SP
        [
          usuario.id,
          usuario.nombre,
          usuario.apellido,
          usuario.nombreUsuario,
          usuario.contrasena,
          usuario.correo,
          usuario.imagenPerfil, // Añadido por consistencia, ajusta según tu SP
        ],
      );
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al actualizar usuario: $e');
      throw Exception('No se pudo actualizar el usuario: $e');
    }
  }

  Future<int> inactivarUsuario(int id) async {
    try {
      final conn = await _dbService.connection;
      var result = await conn.query('CALL InactivarUsuario(?)', [id]);
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al inactivar usuario: $e');
      throw Exception('No se pudo inactivar el usuario: $e');
    }
  }
}

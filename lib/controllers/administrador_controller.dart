import '../services/mysql_helper.dart';
import '../models/administrador_model.dart';

class AdministradorController {
  final dbHelper = DatabaseService();

  // Verificar credenciales de administrador
  Future<bool> verificarCredenciales(
    String nombreAdmin,
    String contrasena,
  ) async {
    return await dbHelper.withConnection((conn) async {
      final results = await conn.query(
        'SELECT * FROM ADMINISTRADOR WHERE NombreAdmin = ? AND Contraseña = ?',
        [nombreAdmin, contrasena],
      );
      return results.isNotEmpty;
    });
  }

  // Obtener todos los administradores
  Future<List<Administrador>> getAdministradores() async {
    return await dbHelper.withConnection((conn) async {
      final results = await conn.query('SELECT * FROM ADMINISTRADOR');
      return results.map((row) => Administrador.fromMap(row.fields)).toList();
    });
  }

  // Insertar nuevo administrador
  Future<int> insertAdministrador(Administrador administrador) async {
    final conn = await dbHelper.connection;
    final result = await conn.query(
      'INSERT INTO ADMINISTRADOR (NombreAdmin, Contraseña) VALUES (?, ?)',
      [administrador.nombreAdmin, administrador.contrasena],
    );
    return result.affectedRows ?? 0;
  }

  // Actualizar contraseña del administrador
  Future<int> updateContrasena(
    String nombreAdmin,
    String nuevaContrasena,
  ) async {
    final conn = await dbHelper.connection;
    final result = await conn.query(
      'UPDATE ADMINISTRADOR SET Contraseña = ? WHERE NombreAdmin = ?',
      [nuevaContrasena, nombreAdmin],
    );
    return result.affectedRows ?? 0;
  }
}

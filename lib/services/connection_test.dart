import '../utils/applogger.dart';
import '../services/mysql_helper.dart';

class DatabaseConnectionTest {
  static Future<bool> testConnection() async {
    try {
      final dbService = DatabaseService();
      var conn = await dbService.connection;

      // Usar el procedimiento almacenado en lugar de consulta directa
      var results = await conn.query('CALL VerificarConexion()');

      AppLogger.info('✅ Conexión a la base de datos exitosa');

      // Extraer el resultado del procedimiento almacenado
      if (results.isNotEmpty && results.first.fields['test'] == 1) {
        AppLogger.info('Resultado de prueba: 1 (conexión verificada)');
        return true;
      } else {
        AppLogger.warning(
          'La prueba de conexión no devolvió el resultado esperado',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Error al conectar a la base de datos',
        e,
        StackTrace.current,
      );
      return false;
    }
  }
}

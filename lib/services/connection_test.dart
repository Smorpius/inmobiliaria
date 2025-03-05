import 'package:logging/logging.dart';
import '../services/mysql_helper.dart';

class DatabaseConnectionTest {
  static final Logger _logger = Logger('DatabaseConnectionTest');

  static Future<bool> testConnection() async {
    try {
      final dbService = DatabaseService();
      var conn =
          await dbService
              .connection; // Corregido: usar el getter "connection" en lugar de "getConnection"
      var results = await conn.query('SELECT 1 as test');
      _logger.info('✅ Conexión a la base de datos exitosa');
      _logger.info('Resultado de prueba: ${results.first['test']}');
      return true;
    } catch (e) {
      _logger.severe('❌ Error al conectar a la base de datos: $e');
      return false;
    }
  }
}

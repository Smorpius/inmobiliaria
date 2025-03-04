import 'package:mysql1/mysql1.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  MySqlConnection? _connection;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<MySqlConnection> get connection async {
    if (_connection == null) {
      await _connect();
    }
    return _connection!;
  }

  Future<void> _connect() async {
    final settings = ConnectionSettings(
      host: '127.0.0.1',
      port: 3306,
      user: 'root',
      password: '123456789',
      db: 'Proyecto_Prueba',
    );

    try {
      _connection = await MySqlConnection.connect(settings);
      print('Conexión a MySQL establecida');
    } catch (e) {
      print('Error de conexión a MySQL: $e');
      rethrow;
    }
  }

  Future<void> closeConnection() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }

  // Optional: Add a method to check connection
  Future<bool> isConnected() async {
    try {
      // Try a simple query to check connection
      await _connection?.query('SELECT 1');
      return true;
    } catch (e) {
      return false;
    }
  }
}

import 'package:mysql1/mysql1.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  MySqlConnection? _connection;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<MySqlConnection> get connection async {
    if (_connection == null || !(await isConnected())) {
      await _connect();
    }
    return _connection!;
  }

  Future<void> _connect() async {
    final settings = ConnectionSettings(
      host: 'localhost', // Use 'localhost' or '127.0.0.1'
      port: 3306,
      user: 'root', // Ensure this matches your MySQL user
      password: '123456789', // Replace with your actual MySQL password
      db: 'Proyecto_Prueba', // Database name from SQL script
    );

    try {
      _connection = await MySqlConnection.connect(settings);
      print('MySQL connection established');
    } catch (e) {
      print('MySQL connection error: $e');
      rethrow;
    }
  }

  Future<void> closeConnection() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }

  Future<bool> isConnected() async {
    try {
      await _connection?.query('SELECT 1');
      return true;
    } catch (e) {
      return false;
    }
  }
}

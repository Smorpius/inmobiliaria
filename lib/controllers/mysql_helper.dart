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
      host: 'localhost',
      port: 3306,
      user: 'tu_usuario',
      password: 'tu_contraseña',
      db: 'Proyecto_Prueba',
    );

    try {
      _connection = await MySqlConnection.connect(settings);
    } catch (e) {
      print('Error de conexión a MySQL: $e');
      rethrow;
    }
  }

  Future<void> closeConnection() async {
    await _connection?.close();
    _connection = null;
  }
}

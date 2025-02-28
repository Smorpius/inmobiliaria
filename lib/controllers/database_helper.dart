import 'package:path/path.dart';
import '../models/mueble_model.dart';
import 'package:sqflite/sqflite.dart';
import '../models/usuario_model.dart';
import '../models/cliente_model.dart';
import '../models/administrador_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    String path = join(await getDatabasesPath(), 'proyecto_prueba.db');
    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Usuarios (
        id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        apellido TEXT,
        nombre_usuario TEXT,
        contraseña_usuario TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Clientes (
        ID_Cliente INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_cliente TEXT,
        direccion_cliente TEXT,
        numero_telf TEXT,
        RFC TEXT,
        CURP TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE MUEBLES (
        ID_muebles INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_mueble TEXT,
        direccion TEXT,
        monto_total REAL,
        estatus_producto TEXT,
        id_cliente INTEGER,
        FOREIGN KEY (id_cliente) REFERENCES Clientes(ID_Cliente)
      )
    ''');

    await db.execute('''
      CREATE TABLE ADMINISTRADOR (
        NombreAdmin TEXT NOT NULL,
        Contraseña TEXT NOT NULL
      )
    ''');

    // Insertar administrador predeterminado
    await db.insert('ADMINISTRADOR', {
      'NombreAdmin': 'Administrador',
      'Contraseña': 'Admin@ñ5',
    });
  }
}

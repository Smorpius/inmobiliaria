import 'package:mysql1/mysql1.dart';
import '../controllers/usuario_controller.dart';
import '../controllers/administrador_controller.dart';

class AuthService {
  final UsuarioController _usuarioController;
  final AdministradorController _adminController = AdministradorController();

  AuthService(this._usuarioController);

  // Usuario actual autenticado
  String? _currentUser;
  bool _isAdmin = false;

  // Getter para verificar si hay un usuario autenticado
  bool get isAuthenticated => _currentUser != null;

  // Getter para verificar si el usuario es administrador
  bool get isAdmin => _isAdmin;

  // Getter para obtener el nombre del usuario actual
  String? get currentUser => _currentUser;

  // Iniciar sesión como usuario regular
  Future<bool> login(String username, String password) async {
    bool success = await _usuarioController.verificarCredenciales(
      username,
      password,
    );
    if (success) {
      _currentUser = username;
      _isAdmin = false;
    }
    return success;
  }

  // Iniciar sesión como administrador
  Future<bool> loginAsAdmin(String username, String password) async {
    bool success = await _adminController.verificarCredenciales(
      username,
      password,
    );
    if (success) {
      _currentUser = username;
      _isAdmin = true;
    }
    return success;
  }

  // Cerrar sesión
  void logout() {
    _currentUser = null;
    _isAdmin = false;
  }

  // Verificar si el usuario tiene permisos de administrador
  bool checkAdminPermissions() {
    return _isAdmin;
  }
}

// Para usar este servicio como singleton en toda la aplicación
final authService = AuthService(
  UsuarioController(
    MySqlConnection.connect(
          ConnectionSettings(
            host: 'localhost',
            port: 3306,
            user: 'root',
            password: '123456789',
            db: 'Proyecto_Prueba',
          ),
        )
        as MySqlConnection,
  ),
);

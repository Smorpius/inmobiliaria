import '../controllers/usuario_controller.dart';
import '../controllers/administrador_controller.dart';

class AuthService {
  final UsuarioController _usuarioController;
  final AdministradorController _adminController = AdministradorController();

  AuthService(this._usuarioController);

  String? _currentUser;
  bool _isAdmin = false;

  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _isAdmin;
  String? get currentUser => _currentUser;

  Future<bool> login(String username, String password) async {
    try {
      bool success = await _usuarioController.verificarCredenciales(
        username,
        password,
      );
      if (success) {
        _currentUser = username;
        _isAdmin = false;
      }
      return success;
    } catch (e) {
      // Log error or handle authentication failure
      return false;
    }
  }

  Future<bool> loginAsAdmin(String username, String password) async {
    try {
      bool success = await _adminController.verificarCredenciales(
        username,
        password,
      );
      if (success) {
        _currentUser = username;
        _isAdmin = true;
      }
      return success;
    } catch (e) {
      // Log error or handle authentication failure
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _isAdmin = false;
  }

  bool checkAdminPermissions() {
    return _isAdmin;
  }
}

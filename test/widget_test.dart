import 'package:flutter/material.dart';
import 'package:inmobiliaria/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inmobiliaria/services/mysql_helper.dart';
import 'package:inmobiliaria/services/auth_service.dart';
import 'package:inmobiliaria/services/usuario_service.dart';
import 'package:inmobiliaria/controllers/usuario_controller.dart';
import 'package:inmobiliaria/controllers/empleado_controller.dart';
import 'package:inmobiliaria/controllers/proveedor_controller.dart';
import 'package:inmobiliaria/services/usuario_empleado_service.dart';
import 'package:inmobiliaria/controllers/usuario_empleado_controller.dart';
import 'package:inmobiliaria/services/proveedores_service.dart' as provservice;
// Usar prefijo para resolver la ambigüedad
// Usar prefijo para el servicio de proveedores

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Crear instancia de DatabaseService usando el constructor normal
    final mysqlHelper = DatabaseService();
    final usuarioController = UsuarioController(dbService: mysqlHelper);
    final authService = AuthService(usuarioController);

    // Crear el servicio de usuario
    final usuarioService = UsuarioService(mysqlHelper);

    // Crear el servicio y controlador de usuario-empleado
    final usuarioEmpleadoService = UsuarioEmpleadoService(mysqlHelper);
    final usuarioEmpleadoController = UsuarioEmpleadoController(
      usuarioEmpleadoService,
    );

    // Crear el controlador de empleados
    final empleadoController = EmpleadoController(
      usuarioEmpleadoService,
      usuarioService,
    );

    // NUEVO: Crear el controlador de proveedores para las pruebas
    // Usa el prefijo para ser explícito sobre qué clase estamos usando
    final proveedoresService = provservice.ProveedoresService();
    final proveedorController = ProveedorController(proveedoresService);

    await tester.pumpWidget(
      MyApp(
        usuarioController: usuarioController,
        authService: authService,
        usuarioEmpleadoController: usuarioEmpleadoController,
        empleadoController: empleadoController,
        proveedorController: proveedorController, // Parámetro requerido
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
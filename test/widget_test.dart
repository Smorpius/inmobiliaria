import 'package:flutter/material.dart';
import 'package:inmobiliaria/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/services/mysql_helper.dart';
import 'package:inmobiliaria/services/auth_service.dart';
import 'package:inmobiliaria/services/usuario_service.dart';
import 'package:inmobiliaria/controllers/usuario_controller.dart';
import 'package:inmobiliaria/controllers/empleado_controller.dart';
import 'package:inmobiliaria/services/usuario_empleado_service.dart';
import 'package:inmobiliaria/controllers/usuario_empleado_controller.dart';

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

    await tester.pumpWidget(
      ProviderScope(
        child: MyApp(
          usuarioController: usuarioController,
          authService: authService,
          usuarioEmpleadoController: usuarioEmpleadoController,
          empleadoController: empleadoController,
        ),
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

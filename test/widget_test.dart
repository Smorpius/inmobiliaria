import 'package:flutter/material.dart';
import 'package:inmobiliaria/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inmobiliaria/services/mysql_helper.dart';
import 'package:inmobiliaria/services/auth_service.dart';
import 'package:inmobiliaria/controllers/usuario_controller.dart';
import 'package:inmobiliaria/services/usuario_empleado_service.dart'; // Nueva importación
import 'package:inmobiliaria/controllers/usuario_empleado_controller.dart'; // Nueva importación

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final mysqlHelper = DatabaseService();
    final usuarioController = UsuarioController(dbService: mysqlHelper);
    final authService = AuthService(usuarioController);

    // Crear el nuevo servicio y controlador requerido
    final usuarioEmpleadoService = UsuarioEmpleadoService(mysqlHelper);
    final usuarioEmpleadoController = UsuarioEmpleadoController(
      usuarioEmpleadoService,
    );

    await tester.pumpWidget(
      MyApp(
        usuarioController: usuarioController,
        authService: authService,
        usuarioEmpleadoController:
            usuarioEmpleadoController, // Añadir el nuevo controlador
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

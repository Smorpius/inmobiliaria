import 'package:flutter/material.dart';
import 'package:inmobiliaria/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inmobiliaria/services/mysql_helper.dart';
import 'package:inmobiliaria/services/auth_service.dart';
import 'package:inmobiliaria/controllers/usuario_controller.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final mysqlHelper = DatabaseService();
    final usuarioController = UsuarioController(dbService: mysqlHelper);
    final authService = AuthService(usuarioController);

    await tester.pumpWidget(
      MyApp(usuarioController: usuarioController, authService: authService),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

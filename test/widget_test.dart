import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inmobiliaria/main.dart'; // Cambiado a importación de paquete
import 'package:inmobiliaria/services/mysql_helper.dart'; // Importa la clase MySqlHelper
import 'package:inmobiliaria/controllers/usuario_controller.dart'; // Importa la clase UsuarioController
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Initialize MySQL connection
    final mysqlHelper = DatabaseService();
    final connection = await mysqlHelper.connection;

    // Pass the connection to controllers
    final usuarioController = UsuarioController(connection);

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(usuarioController: usuarioController));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

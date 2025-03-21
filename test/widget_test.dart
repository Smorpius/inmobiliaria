import 'package:flutter/material.dart';
import 'package:inmobiliaria/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/services/mysql_helper.dart';
import 'package:inmobiliaria/services/auth_service.dart';
import 'package:inmobiliaria/services/image_service.dart';
import 'package:inmobiliaria/services/usuario_service.dart';
import 'package:inmobiliaria/providers/providers_global.dart';
import 'package:inmobiliaria/controllers/usuario_controller.dart';
import 'package:inmobiliaria/controllers/empleado_controller.dart';
import 'package:inmobiliaria/services/usuario_empleado_service.dart';
import 'package:inmobiliaria/controllers/usuario_empleado_controller.dart';

void main() {
  testWidgets('Aplicación Inmobiliaria inicia correctamente', (
    WidgetTester tester,
  ) async {
    // Crear instancia de DatabaseService usando el constructor normal
    final mysqlHelper = DatabaseService();
    final imageService = ImageService();
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

    // Configurar los override de provider para las pruebas
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Sobrescribir los providers con las instancias de prueba
          databaseInitProvider.overrideWith((_) async {
            // Simular un retraso para que se muestre la pantalla de carga
            await Future.delayed(const Duration(milliseconds: 50));
            return mysqlHelper;
          }),
          imageInitProvider.overrideWith((_) async => imageService),
          // No sobreescribimos appInitializationProvider para que use el comportamiento normal

          // Sobrescribir los providers derivados
          databaseServiceProvider.overrideWithValue(mysqlHelper),
          imageServiceProvider.overrideWithValue(imageService),
          usuarioControllerProvider.overrideWithValue(usuarioController),
          authServiceProvider.overrideWithValue(authService),
          usuarioServiceProvider.overrideWithValue(usuarioService),
          usuarioEmpleadoServiceProvider.overrideWithValue(
            usuarioEmpleadoService,
          ),
          usuarioEmpleadoControllerProvider.overrideWithValue(
            usuarioEmpleadoController,
          ),
          empleadoControllerProvider.overrideWithValue(empleadoController),
        ],
        child: const MyApp(),
      ),
    );

    // Rendereamos un frame para que se vea la pantalla de carga
    await tester.pump();

    // Verificar que la aplicación ha iniciado correctamente
    expect(find.byType(MaterialApp), findsOneWidget);

    // Ahora verificamos elementos específicos que deberían estar presentes
    final loadingFinder = find.text('Inicializando aplicación...');
    final appBarFinder = find.byType(AppBar);

    // Verificar que al menos aparece la pantalla de carga o algún elemento de la aplicación ya iniciada
    expect(
      loadingFinder.evaluate().isNotEmpty || appBarFinder.evaluate().isNotEmpty,
      true,
      reason:
          'La aplicación debería mostrar una pantalla de carga o la aplicación iniciada',
    );
  });
}

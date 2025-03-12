import 'mysql_helper.dart';
import '../models/usuario.dart';
import '../models/empleado.dart';
import 'dart:developer' as developer;
import '../models/usuario_empleado.dart';

class UsuarioEmpleadoService {
  final DatabaseService _db;

  UsuarioEmpleadoService(this._db);

  // NUEVO: Método para liberar conexión y forzar reconexión limpia
  Future<void> liberarConexion() async {
    try {
      developer.log('Liberando conexión para permitir refresco');
      await _db.reiniciarConexion();
    } catch (e) {
      developer.log('Error al liberar conexión: $e', error: e);
    }
  }

  // Método para verificar la conexión a la base de datos (CORREGIDO)
  Future<bool> verificarConexion() async {
    try {
      developer.log('Verificando conexión a la base de datos');
      final conn = await _db.connection;

      // Intentar primero con una consulta principal
      try {
        final results = await conn.query('SELECT 1 as test');

        if (results.isEmpty) {
          // Intentar una consulta diferente como plan B
          developer.log(
            'Consulta principal devolvió resultados vacíos, intentando alternativa',
          );
          try {
            final altResults = await conn.query('SHOW TABLES');
            developer.log(
              'Prueba de conexión alternativa: ${altResults.isNotEmpty}',
            );
            return altResults.isNotEmpty;
          } catch (tableE) {
            developer.log(
              'Error en consulta alternativa: $tableE, intentando método final',
            );
            try {
              await conn.query('SELECT 1');
              developer.log('Conexión verificada con método final');
              return true;
            } catch (finalE) {
              developer.log('Todos los métodos de verificación fallaron');
              return false;
            }
          }
        }

        var testValue = results.first.fields['test'];
        developer.log('Resultado de prueba de conexión: $testValue');
        return testValue == 1;
      } catch (innerE) {
        developer.log(
          'Error en consulta de prueba: $innerE, intentando alternativa',
        );
        try {
          await conn.query('SELECT 1');
          developer.log('Conexión verificada con método alternativo');
          return true;
        } catch (_) {
          return false;
        }
      }
    } catch (e) {
      developer.log(
        'Error al verificar conexión a la base de datos: $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }

  // Verificar si un nombre de usuario ya existe
  Future<bool> nombreUsuarioExiste(String nombreUsuario) async {
    try {
      developer.log(
        'Verificando si existe el nombre de usuario: $nombreUsuario',
      );
      final conn = await _db.connection;

      final results = await conn.query(
        'SELECT COUNT(*) as count FROM usuarios WHERE nombre_usuario = ?',
        [nombreUsuario],
      );

      if (results.isEmpty) {
        developer.log(
          'No se obtuvieron resultados al verificar nombre de usuario',
        );
        return false;
      }

      int count = results.first.fields['count'] as int;
      developer.log('Nombre usuario "$nombreUsuario" existe: ${count > 0}');
      return count > 0;
    } catch (e) {
      developer.log(
        'Error al verificar existencia de nombre de usuario: $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      throw Exception('Error al verificar nombre de usuario: $e');
    }
  }

  // NUEVO MÉTODO: Verificar si un nombre de usuario ya existe, excluyendo el usuario con el ID especificado
  Future<bool> nombreUsuarioExisteExcluyendoId(
    String nombreUsuario,
    int idExcluir,
  ) async {
    try {
      developer.log(
        'Verificando si existe el nombre de usuario: $nombreUsuario (excluyendo ID: $idExcluir)',
      );
      final conn = await _db.connection;

      // Consulta que excluye el ID especificado
      final results = await conn.query(
        'SELECT COUNT(*) as count FROM usuarios WHERE nombre_usuario = ? AND id_usuario <> ?',
        [nombreUsuario, idExcluir],
      );

      if (results.isEmpty) {
        developer.log(
          'No se obtuvieron resultados al verificar nombre de usuario excluyendo ID',
        );
        return false;
      }

      int count = results.first.fields['count'] as int;
      developer.log(
        'Nombre usuario "$nombreUsuario" existe (excluyendo ID $idExcluir): ${count > 0}',
      );
      return count > 0;
    } catch (e) {
      developer.log(
        'Error al verificar existencia de nombre de usuario excluyendo ID: $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      // En caso de error, es más seguro retornar false que lanzar una excepción
      // para permitir que el flujo de edición continúe
      return false;
    }
  }

  // Método mejorado para obtener empleados con reintentos y opción de refresco
  Future<List<UsuarioEmpleado>> obtenerEmpleados({
    bool forzarRefresco = false,
  }) async {
    try {
      developer.log(
        'Iniciando obtenerEmpleados() ${forzarRefresco ? "con refresco forzado" : ""}',
      );
      final conn = await _db.connection;

      if (forzarRefresco) {
        developer.log('Esperando para estabilización por refresco forzado...');
        await Future.delayed(const Duration(milliseconds: 1000));
      } else if (_db.reconectadoRecientemente) {
        developer.log(
          'Detectada reconexión reciente, esperando estabilización...',
        );
        await Future.delayed(const Duration(milliseconds: 1500));
      }

      int intentos = 0;
      List<UsuarioEmpleado> empleados = [];
      Exception? lastError;

      while (intentos < 3) {
        try {
          final results =
              forzarRefresco
                  ? await conn.query('SELECT * FROM v_empleados_usuarios')
                  : await conn.query('CALL LeerEmpleadosConUsuarios()');

          developer.log(
            '${forzarRefresco ? "Consulta directa" : "Procedimiento"} devolvió ${results.length} resultados',
          );

          if (results.isEmpty) {
            developer.log('No se encontraron empleados');
            return [];
          }

          for (var row in results) {
            try {
              var datos = Map<String, dynamic>.from(row.fields);

              if (datos['fecha_contratacion'] != null) {
                var fechaValue = datos['fecha_contratacion'];
                if (fechaValue is! DateTime) {
                  try {
                    datos['fecha_contratacion'] = DateTime.parse(
                      fechaValue.toString(),
                    );
                    developer.log(
                      'Fecha convertida exitosamente: ${datos['fecha_contratacion']}',
                    );
                  } catch (e) {
                    developer.log('Error al convertir fecha: $e', error: e);
                    datos['fecha_contratacion'] = DateTime.now();
                  }
                }
              } else {
                datos['fecha_contratacion'] = DateTime.now();
              }

              empleados.add(UsuarioEmpleado.fromMap(datos));
            } catch (e) {
              developer.log('Error al convertir empleado: $e', error: e);
              developer.log('Datos de la fila: ${row.fields}');
            }
          }

          developer.log('Retornando ${empleados.length} empleados procesados');
          return empleados;
        } catch (e) {
          intentos++;
          lastError = Exception('Error al ejecutar la consulta: $e');
          developer.log(
            'Error en obtenerEmpleados() (intento $intentos/3): $e',
            error: e,
          );

          if (intentos >= 3) break;

          int espera = forzarRefresco ? 800 * intentos : 500 * intentos;
          await Future.delayed(Duration(milliseconds: espera));
          developer.log('Reintentando obtener empleados (intento $intentos)');
        }
      }

      throw lastError ??
          Exception('Error al obtener empleados después de múltiples intentos');
    } catch (e) {
      developer.log(
        'Error en obtenerEmpleados(): $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      throw Exception('Error al obtener empleados: $e');
    }
  }

  // Método para obtener empleados con garantía de datos frescos
  Future<List<UsuarioEmpleado>> obtenerEmpleadosRefrescados() async {
    try {
      developer.log(
        'Iniciando obtenerEmpleadosRefrescados para garantizar datos frescos',
      );
      await liberarConexion();
      await Future.delayed(const Duration(milliseconds: 500));

      List<UsuarioEmpleado> empleados = await obtenerEmpleados(
        forzarRefresco: true,
      );
      developer.log(
        'Datos refrescados obtenidos: ${empleados.length} empleados',
      );
      return empleados;
    } catch (e) {
      developer.log('Error al refrescar empleados: $e', error: e);
      throw Exception('Error al refrescar lista de empleados: $e');
    }
  }

  Future<UsuarioEmpleado?> obtenerEmpleadoPorId(int id) async {
    try {
      developer.log('Iniciando obtenerEmpleadoPorId con ID: $id');
      final conn = await _db.connection;

      if (_db.reconectadoRecientemente) {
        developer.log(
          'Detectada reconexión reciente, esperando estabilización...',
        );
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      final results = await conn.query('CALL ObtenerEmpleadoUsuario(?)', [id]);

      if (results.isEmpty || results.first.isEmpty) {
        developer.log('No se encontró empleado con ID: $id');
        return null;
      }

      developer.log('Empleado encontrado, convirtiendo datos');
      try {
        var datos = Map<String, dynamic>.from(results.first.fields);

        if (datos['fecha_contratacion'] != null) {
          var fechaValue = datos['fecha_contratacion'];
          if (fechaValue is! DateTime) {
            try {
              datos['fecha_contratacion'] = DateTime.parse(
                fechaValue.toString(),
              );
              developer.log(
                'Fecha convertida exitosamente: ${datos['fecha_contratacion']}',
              );
            } catch (e) {
              developer.log('Error al convertir fecha: $e', error: e);
              datos['fecha_contratacion'] = DateTime.now();
            }
          }
        } else {
          datos['fecha_contratacion'] = DateTime.now();
        }

        return UsuarioEmpleado.fromMap(datos);
      } catch (e) {
        developer.log('Error al convertir datos del empleado: $e', error: e);
        developer.log('Datos recibidos: ${results.first.fields}');
        throw Exception('Error al procesar datos del empleado: $e');
      }
    } catch (e) {
      developer.log(
        'Error en obtenerEmpleadoPorId(): $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      throw Exception('Error al obtener empleado #$id: $e');
    }
  }

  // MÉTODO CORREGIDO: Agregar parámetro contrasena
  Future<int> crearUsuarioEmpleado(
    Usuario usuario,
    Empleado empleado,
    String contrasena,
  ) async {
    try {
      developer.log(
        'Iniciando crearUsuarioEmpleado para: ${usuario.nombre} ${usuario.apellido}',
      );

      if (await nombreUsuarioExiste(usuario.nombreUsuario)) {
        throw Exception('El nombre de usuario ya existe');
      }

      final conn = await _db.connection;
      final correoContacto = empleado.correo;

      developer.log('Ejecutando CrearUsuarioEmpleado con parámetros');
      await conn.query(
        'CALL CrearUsuarioEmpleado(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          usuario.nombre,
          usuario.apellido,
          usuario.nombreUsuario,
          contrasena, // Usar el parámetro contrasena en lugar de usuario.contrasena
          usuario.correo,
          usuario.imagenPerfil,
          empleado.claveSistema,
          empleado.apellidoMaterno,
          empleado.telefono,
          empleado.direccion,
          empleado.cargo,
          empleado.sueldoActual,
          empleado.fechaContratacion.toIso8601String(),
          correoContacto,
          empleado.imagenEmpleado,
        ],
      );

      developer.log('Obteniendo ID del usuario creado');
      try {
        final resultId = await conn.query('SELECT LAST_INSERT_ID() as id');
        if (resultId.isEmpty) {
          developer.log(
            'No se pudo obtener el ID del usuario creado (resultados vacíos)',
          );
          try {
            final altResult = await conn.query(
              'SELECT MAX(id_usuario) as id FROM usuarios',
            );
            if (altResult.isNotEmpty && altResult.first.fields['id'] != null) {
              int id = altResult.first.fields['id'] as int;
              developer.log('Usuario empleado creado con ID alternativo: $id');
              return id;
            }
          } catch (e) {
            developer.log('Error al obtener ID alternativo: $e');
          }
          return -1;
        }

        if (resultId.first.fields['id'] == null) {
          developer.log(
            'No se pudo obtener el ID del usuario creado (valor null)',
          );
          return -1;
        }

        int id = resultId.first.fields['id'] as int;
        developer.log('Usuario empleado creado con ID: $id');
        return id;
      } catch (e) {
        developer.log(
          'Error al obtener el ID del usuario creado: $e',
          error: e,
        );
        return -1;
      }
    } catch (e) {
      developer.log(
        'Error en crearUsuarioEmpleado(): $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      throw Exception('Error al crear usuario empleado: $e');
    }
  }

  Future<void> actualizarUsuarioEmpleado(
    int idUsuario,
    int idEmpleado,
    Usuario usuario,
    Empleado empleado,
  ) async {
    try {
      developer.log(
        'Iniciando actualizarUsuarioEmpleado para usuario #$idUsuario, empleado #$idEmpleado',
      );
      final conn = await _db.connection;

      developer.log('Ejecutando ActualizarUsuarioEmpleado con parámetros');
      await conn.query(
        'CALL ActualizarUsuarioEmpleado(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          idUsuario,
          idEmpleado,
          usuario.nombre,
          usuario.apellido,
          usuario.nombreUsuario,
          usuario.contrasena.isNotEmpty ? usuario.contrasena : null,
          usuario.correo,
          usuario.imagenPerfil,
          empleado.claveSistema,
          empleado.apellidoMaterno,
          empleado.telefono,
          empleado.direccion,
          empleado.cargo,
          empleado.sueldoActual,
          empleado.imagenEmpleado,
        ],
      );
      developer.log('Usuario empleado actualizado exitosamente');
    } catch (e) {
      developer.log(
        'Error en actualizarUsuarioEmpleado(): $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      throw Exception('Error al actualizar usuario empleado: $e');
    }
  }

  Future<void> inactivarUsuarioEmpleado(int idUsuario, int idEmpleado) async {
    try {
      developer.log(
        'Iniciando inactivarUsuarioEmpleado para usuario #$idUsuario, empleado #$idEmpleado',
      );
      final conn = await _db.connection;
      developer.log('Ejecutando InactivarUsuarioEmpleado');
      await conn.query('CALL InactivarUsuarioEmpleado(?, ?)', [
        idUsuario,
        idEmpleado,
      ]);
      developer.log('Usuario empleado inactivado exitosamente');
    } catch (e) {
      developer.log(
        'Error en inactivarUsuarioEmpleado(): $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      throw Exception('Error al inactivar usuario empleado: $e');
    }
  }

  Future<void> reactivarUsuarioEmpleado(int idUsuario, int idEmpleado) async {
    try {
      developer.log(
        'Iniciando reactivarUsuarioEmpleado para usuario #$idUsuario, empleado #$idEmpleado',
      );
      final conn = await _db.connection;

      if (_db.reconectadoRecientemente) {
        developer.log(
          'Detectada reconexión reciente, esperando estabilización...',
        );
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      developer.log('Ejecutando ReactivarUsuarioEmpleado');
      await conn.query('CALL ReactivarUsuarioEmpleado(?, ?)', [
        idUsuario,
        idEmpleado,
      ]);
      developer.log('Usuario empleado reactivado exitosamente');
    } catch (e) {
      developer.log(
        'Error en reactivarUsuarioEmpleado(): $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      throw Exception('Error al reactivar usuario empleado: $e');
    }
  }
}

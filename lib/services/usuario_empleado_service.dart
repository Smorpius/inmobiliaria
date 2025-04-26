import 'mysql_helper.dart';
import '../models/usuario.dart';
import '../models/empleado.dart';
import '../utils/applogger.dart';
import '../models/usuario_empleado.dart';

class UsuarioEmpleadoService {
  final DatabaseService _db;
  bool _procesandoError = false; // Control para evitar logs duplicados

  UsuarioEmpleadoService(this._db);

  // Método para liberar conexión y forzar reconexión limpia
  Future<void> liberarConexion() async {
    try {
      AppLogger.info('Liberando conexión para permitir refresco');
      await _db.reiniciarConexion();
    } catch (e) {
      AppLogger.error('Error al liberar conexión', e, StackTrace.current);
    }
  }

  // Método para verificar la conexión a la base de datos usando procedimiento almacenado
  Future<bool> verificarConexion() async {
    try {
      AppLogger.info('Verificando conexión a la base de datos');
      return await _db.withConnection((conn) async {
        try {
          // Usar el procedimiento almacenado para verificar conexión
          final results = await conn.query('CALL VerificarConexion()');

          if (results.isEmpty) {
            AppLogger.warning(
              'Procedimiento devolvió resultados vacíos, intentando alternativa',
            );
            try {
              // Intento alternativo solo en caso de emergencia
              await conn.query('SELECT 1 as test');
              AppLogger.info('Conexión verificada con método alternativo');
              return true;
            } catch (_) {
              return false;
            }
          }

          var testValue = results.first.fields['test'];
          AppLogger.info('Resultado de prueba de conexión: $testValue');
          return testValue == 1;
        } catch (e) {
          AppLogger.warning('Error en procedimiento de verificación: $e');
          return false;
        }
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al verificar conexión a la base de datos',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return false;
    }
  }

  // Verificar si un nombre de usuario ya existe usando procedimiento almacenado
  Future<bool> nombreUsuarioExiste(String nombreUsuario) async {
    try {
      AppLogger.info(
        'Verificando si existe el nombre de usuario: $nombreUsuario',
      );

      return await _db.withConnection((conn) async {
        // Usar procedimiento almacenado con variable de salida
        await conn.query('CALL VerificarNombreUsuarioExiste(?, @existe)', [
          nombreUsuario,
        ]);

        // Obtener el valor de salida
        final resultadoQuery = await conn.query('SELECT @existe as existe');

        if (resultadoQuery.isEmpty) {
          AppLogger.warning(
            'No se obtuvieron resultados al verificar nombre de usuario',
          );
          return false;
        }

        final existe = resultadoQuery.first.fields['existe'] == 1;
        AppLogger.info('Nombre usuario "$nombreUsuario" existe: $existe');
        return existe;
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al verificar existencia de nombre de usuario',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return false; // En caso de error, es más seguro devolver false
    }
  }

  // Verificar si un nombre de usuario ya existe excluyendo un ID
  Future<bool> nombreUsuarioExisteExcluyendoId(
    String nombreUsuario,
    int idExcluir,
  ) async {
    try {
      AppLogger.info(
        'Verificando si existe el nombre de usuario: $nombreUsuario (excluyendo ID: $idExcluir)',
      );

      return await _db.withConnection((conn) async {
        // Usar procedimiento almacenado con variable de salida
        await conn.query(
          'CALL VerificarNombreUsuarioExisteExcluyendoId(?, ?, @existe)',
          [nombreUsuario, idExcluir],
        );

        // Obtener el valor de salida
        final resultadoQuery = await conn.query('SELECT @existe as existe');

        if (resultadoQuery.isEmpty) {
          AppLogger.warning(
            'No se obtuvieron resultados al verificar nombre de usuario excluyendo ID',
          );
          return false;
        }

        final existe = resultadoQuery.first.fields['existe'] == 1;
        AppLogger.info(
          'Nombre usuario "$nombreUsuario" existe (excluyendo ID $idExcluir): $existe',
        );
        return existe;
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error al verificar existencia de nombre de usuario excluyendo ID',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      return false; // En caso de error, es más seguro devolver false
    }
  }

  // Método para obtener empleados con reintentos y opción de refresco
  Future<List<UsuarioEmpleado>> obtenerEmpleados({
    bool forzarRefresco = false,
  }) async {
    try {
      AppLogger.info(
        '[Service] Obteniendo empleados (forzarRefresco=$forzarRefresco)',
      );

      return await _db.withConnection((conn) async {
        AppLogger.info('[Service] Ejecutando CALL LeerEmpleadosConUsuarios()');
        final results = await conn.query('CALL LeerEmpleadosConUsuarios()');
        AppLogger.info(
          '[Service] Query ejecutada. Número de filas: ${results.length}',
        );

        if (results.isEmpty) {
          AppLogger.info('[Service] No se encontraron empleados en la BD.');
          return [];
        }

        // Procesar los resultados
        final List<UsuarioEmpleado> usuariosEmpleados = [];
        int index = 0;
        for (var row in results) {
          AppLogger.debug(
            '[Service] Procesando fila ${index++}: ${row.fields}',
          );
          try {
            // Crear objetos Usuario y Empleado a partir de los datos
            final usuario = Usuario(
              id: row.fields['id_usuario'] as int,
              nombre: row.fields['nombre'] as String,
              apellido:
                  row.fields['apellido_paterno']
                      as String, // Asumiendo que apellido_paterno es el apellido principal en Usuario
              nombreUsuario: row.fields['nombre_usuario'] as String,
              contrasena: '', // No se carga la contraseña por seguridad
              correo:
                  row.fields['correo_cliente']
                      as String?, // Ajustar si el nombre del campo es diferente
              imagenPerfil: row.fields['imagen_perfil'] as String?,
              idEstado:
                  row.fields['usuario_estado']
                      as int, // Asegúrate que este campo exista en el SP
            );

            final empleado = Empleado(
              id: row.fields['id_empleado'] as int,
              idUsuario: row.fields['id_usuario'] as int,
              claveSistema: row.fields['clave_sistema'] as String,
              nombre: row.fields['nombre'] as String, // Nombre del empleado
              apellidoPaterno: row.fields['apellido_paterno'] as String,
              apellidoMaterno: row.fields['apellido_materno'] as String?,
              telefono: row.fields['telefono'] as String,
              correo: row.fields['correo'] as String, // Correo del empleado
              direccion: row.fields['direccion'] as String,
              cargo: row.fields['cargo'] as String,
              sueldoActual: double.parse(
                row.fields['sueldo_actual'].toString(),
              ),
              fechaContratacion: row.fields['fecha_contratacion'] as DateTime,
              imagenEmpleado: row.fields['imagen_empleado'] as String?,
              idEstado: row.fields['id_estado'] as int, // Estado del empleado
            );

            // Agregar el par Usuario-Empleado a la lista
            usuariosEmpleados.add(
              UsuarioEmpleado(usuario: usuario, empleado: empleado),
            );
            AppLogger.debug(
              '[Service] Fila ${index - 1} mapeada correctamente.',
            );
          } catch (e, s) {
            AppLogger.warning(
              '[Service] Error al procesar datos de empleado ID:${row.fields['id_empleado']}: $e\nStackTrace: $s',
            );
          }
        }

        AppLogger.info(
          '[Service] ${usuariosEmpleados.length} empleados mapeados con éxito.',
        );
        return usuariosEmpleados;
      });
    } catch (e, s) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('[Service] Error al obtener empleados', e, s);
        _procesandoError = false;
      }
      throw Exception('Error al obtener empleados: $e');
    }
  }

  // Método para obtener empleados con garantía de datos frescos
  Future<List<UsuarioEmpleado>> obtenerEmpleadosRefrescados() async {
    try {
      AppLogger.info(
        'Iniciando obtenerEmpleadosRefrescados para garantizar datos frescos',
      );
      await liberarConexion();
      await Future.delayed(const Duration(milliseconds: 500));

      List<UsuarioEmpleado> empleados = await obtenerEmpleados(
        forzarRefresco: true,
      );
      AppLogger.info(
        'Datos refrescados obtenidos: ${empleados.length} empleados',
      );
      return empleados;
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error al refrescar empleados', e, StackTrace.current);
        _procesandoError = false;
      }
      throw Exception('Error al refrescar lista de empleados: $e');
    }
  }

  Future<UsuarioEmpleado?> obtenerEmpleadoPorId(int id) async {
    try {
      AppLogger.info('Iniciando obtenerEmpleadoPorId con ID: $id');

      return await _db.withConnection((conn) async {
        if (_db.reconectadoRecientemente) {
          AppLogger.info(
            'Detectada reconexión reciente, esperando estabilización...',
          );
          await Future.delayed(const Duration(milliseconds: 1000));
        }

        // Usar procedimiento almacenado para obtener empleado por ID
        final results = await conn.query('CALL ObtenerEmpleadoUsuario(?)', [
          id,
        ]);

        if (results.isEmpty || results.first.isEmpty) {
          AppLogger.info('No se encontró empleado con ID: $id');
          return null;
        }

        AppLogger.info('Empleado encontrado, convirtiendo datos');
        try {
          var datos = Map<String, dynamic>.from(results.first.fields);

          if (datos['fecha_contratacion'] != null) {
            var fechaValue = datos['fecha_contratacion'];
            if (fechaValue is! DateTime) {
              try {
                datos['fecha_contratacion'] = DateTime.parse(
                  fechaValue.toString(),
                );
                AppLogger.info(
                  'Fecha convertida exitosamente: ${datos['fecha_contratacion']}',
                );
              } catch (e) {
                AppLogger.warning('Error al convertir fecha: $e');
                datos['fecha_contratacion'] = DateTime.now();
              }
            }
          } else {
            datos['fecha_contratacion'] = DateTime.now();
          }

          return UsuarioEmpleado.fromMap(datos);
        } catch (e) {
          AppLogger.error(
            'Error al convertir datos del empleado',
            e,
            StackTrace.current,
          );
          AppLogger.debug('Datos recibidos: ${results.first.fields}');
          throw Exception('Error al procesar datos del empleado: $e');
        }
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error en obtenerEmpleadoPorId()',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      throw Exception('Error al obtener empleado #$id: $e');
    }
  }

  Future<int> crearUsuarioEmpleado(
    Usuario usuario,
    Empleado empleado,
    String contrasena,
  ) async {
    try {
      AppLogger.info(
        'Iniciando CrearUsuarioEmpleado para ${usuario.nombreUsuario}',
      );

      return await _db.withConnection((conn) async {
        final correoContacto = empleado.correo;

        await conn.query('START TRANSACTION');
        try {
          AppLogger.info('Ejecutando CrearUsuarioEmpleado con parámetros');

          // Primero, preparar los valores de salida
          await conn.query('SET @id_usuario = 0, @id_empleado = 0');

          // Llamar al procedimiento con los parámetros de entrada y salida
          await conn.query(
            'CALL CrearUsuarioEmpleado(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @id_usuario, @id_empleado)',
            [
              usuario.nombre,
              usuario.apellido,
              usuario.nombreUsuario,
              contrasena,
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

          // Obtener los valores de salida
          final idResult = await conn.query('SELECT @id_usuario as id_usuario');

          if (idResult.isEmpty || idResult.first.fields['id_usuario'] == null) {
            await conn.query('ROLLBACK');
            throw Exception('No se pudo obtener el ID del usuario creado');
          }

          final idNuevoUsuario = idResult.first.fields['id_usuario'] as int;
          await conn.query('COMMIT');
          AppLogger.info('Usuario-Empleado creado con ID: $idNuevoUsuario');

          return idNuevoUsuario;
        } catch (e) {
          await conn.query('ROLLBACK');
          rethrow;
        }
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error en crearUsuarioEmpleado()',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
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
      AppLogger.info(
        'Iniciando actualizarUsuarioEmpleado para usuario #$idUsuario, empleado #$idEmpleado',
      );

      await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          AppLogger.info('Ejecutando ActualizarUsuarioEmpleado con parámetros');
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

          await conn.query('COMMIT');
          AppLogger.info('Usuario empleado actualizado exitosamente');
        } catch (e) {
          await conn.query('ROLLBACK');
          rethrow;
        }
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error en actualizarUsuarioEmpleado()',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      throw Exception('Error al actualizar usuario empleado: $e');
    }
  }

  Future<void> inactivarUsuarioEmpleado(int idUsuario, int idEmpleado) async {
    try {
      AppLogger.info(
        'Iniciando inactivarUsuarioEmpleado para usuario #$idUsuario, empleado #$idEmpleado',
      );

      await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          AppLogger.info('Ejecutando InactivarUsuarioEmpleado');
          await conn.query('CALL InactivarUsuarioEmpleado(?, ?)', [
            idUsuario,
            idEmpleado,
          ]);

          await conn.query('COMMIT');
          AppLogger.info('Usuario empleado inactivado exitosamente');
        } catch (e) {
          await conn.query('ROLLBACK');
          rethrow;
        }
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error en inactivarUsuarioEmpleado()',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      throw Exception('Error al inactivar usuario empleado: $e');
    }
  }

  Future<void> reactivarUsuarioEmpleado(int idUsuario, int idEmpleado) async {
    try {
      AppLogger.info(
        'Iniciando reactivarUsuarioEmpleado para usuario #$idUsuario, empleado #$idEmpleado',
      );

      await _db.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          if (_db.reconectadoRecientemente) {
            AppLogger.info(
              'Detectada reconexión reciente, esperando estabilización...',
            );
            await Future.delayed(const Duration(milliseconds: 1000));
          }

          AppLogger.info('Ejecutando ReactivarUsuarioEmpleado');
          await conn.query('CALL ReactivarUsuarioEmpleado(?, ?)', [
            idUsuario,
            idEmpleado,
          ]);

          await conn.query('COMMIT');
          AppLogger.info('Usuario empleado reactivado exitosamente');
        } catch (e) {
          await conn.query('ROLLBACK');
          rethrow;
        }
      });
    } catch (e) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error(
          'Error en reactivarUsuarioEmpleado()',
          e,
          StackTrace.current,
        );
        _procesandoError = false;
      }
      throw Exception('Error al reactivar usuario empleado: $e');
    }
  }
}

import 'dart:io';
import '../utils/applogger.dart';
import '../services/mysql_helper.dart';
import 'package:path/path.dart' as path;
import '../models/resumen_renta_model.dart';
import '../models/movimiento_renta_model.dart';
import 'package:path_provider/path_provider.dart';
import '../models/comprobante_movimiento_model.dart';

/// Clase de excepción personalizada para errores de movimientos de renta
class MovimientoRentaException implements Exception {
  final String mensaje;
  final dynamic errorOriginal;
  final StackTrace stackTrace;
  final String? codigoError;

  /// Categoría del error para procesar adecuadamente en capas superiores
  final ErrorCategoria categoria;

  /// Constructor para excepciones de MovimientoRenta
  MovimientoRentaException(
    this.mensaje, {
    this.errorOriginal,
    required this.stackTrace,
    this.codigoError,
    this.categoria = ErrorCategoria.general,
  });

  @override
  String toString() {
    return mensaje;
  }

  /// Obtiene los detalles completos del error para logging
  Map<String, dynamic> detallesCompletos() {
    return {
      'mensaje': mensaje,
      'categoria': categoria.toString(),
      'codigo_error': codigoError,
      'error_original': errorOriginal?.toString(),
    };
  }
}

/// Enumeración para categorizar errores
enum ErrorCategoria {
  conexion,
  baseDatos,
  validacion,
  autorizacion,
  noEncontrado,
  general,
}

class MovimientosRentaService {
  final DatabaseService _db;
  final Map<String, DateTime> _ultimosErrores =
      {}; // Para control de logs duplicados
  static const Duration _intervaloMinimoLogs = Duration(seconds: 3);

  // Extensiones válidas para comprobantes
  static const List<String> _extensionesValidasComprobantes = [
    '.jpg',
    '.jpeg',
    '.png',
    '.pdf',
  ];
  static const int _tamanoMaximoComprobante = 10 * 1024 * 1024; // 10MB

  MovimientosRentaService(this._db);

  /// Registra un nuevo movimiento de renta usando el procedimiento almacenado
  Future<int> registrarMovimiento(MovimientoRenta movimiento) async {
    return await _db.withConnection((conn) async {
      await conn.query('START TRANSACTION');
      try {
        AppLogger.info(
          'Registrando movimiento para inmueble: ${movimiento.idInmueble}',
        );

        // Validaciones básicas antes de interactuar con la BD
        _validarMovimiento(movimiento);

        await conn.query(
          'CALL RegistrarMovimientoRenta(?, ?, ?, ?, ?, ?, ?, @id_movimiento_out)',
          [
            movimiento.idInmueble,
            movimiento.idCliente,
            movimiento.tipoMovimiento,
            movimiento.concepto,
            movimiento.monto,
            movimiento.fechaMovimiento.toIso8601String().split('T')[0],
            movimiento.comentarios,
          ],
        );

        // Validación más robusta del resultado
        final result = await conn.query('SELECT @id_movimiento_out as id');
        if (result.isEmpty) {
          await conn.query('ROLLBACK');
          throw MovimientoRentaException(
            'No se obtuvieron resultados al registrar el movimiento',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.baseDatos,
            codigoError: 'RESULTADO_VACIO',
          );
        }

        final idRow = result.first;
        if (!idRow.fields.containsKey('id') || idRow['id'] == null) {
          await conn.query('ROLLBACK');
          throw MovimientoRentaException(
            'No se pudo obtener el ID del movimiento registrado',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.baseDatos,
            codigoError: 'ID_NO_GENERADO',
          );
        }

        final idMovimiento = idRow['id'];
        // Validar que el ID sea un entero y mayor que 0
        if (idMovimiento is! int || idMovimiento <= 0) {
          await conn.query('ROLLBACK');
          throw MovimientoRentaException(
            'El ID del movimiento generado no es válido: $idMovimiento',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.baseDatos,
            codigoError: 'ID_INVALIDO',
          );
        }

        await conn.query('COMMIT');
        AppLogger.info('Movimiento registrado con ID: $idMovimiento');
        return idMovimiento;
      } catch (e, stackTrace) {
        await _ejecutarRollbackSeguro(conn);

        // Si ya es una excepción personalizada, propagarla
        if (e is MovimientoRentaException) {
          _registrarError(
            'Error controlado al registrar movimiento',
            e,
            stackTrace,
          );
          rethrow;
        }

        // Clasificar y enriquecer el error
        final errorEnriquecido = _enriquecerError(
          e,
          stackTrace,
          'Error al registrar movimiento de renta',
          errorContexto: {
            'idInmueble': movimiento.idInmueble,
            'idCliente': movimiento.idCliente,
            'monto': movimiento.monto,
            'tipo': movimiento.tipoMovimiento,
          },
        );

        throw errorEnriquecido;
      }
    });
  }

  /// Agrega un comprobante a un movimiento
  Future<int> agregarComprobante(ComprobanteMovimiento comprobante) async {
    return await _db.withConnection((conn) async {
      await conn.query('START TRANSACTION');
      try {
        AppLogger.info(
          'Agregando comprobante para movimiento: ${comprobante.idMovimiento}',
        );

        // Validaciones básicas
        _validarComprobante(comprobante);

        await conn.query(
          'CALL AgregarComprobanteMovimiento(?, ?, ?, ?, @id_comprobante_out)',
          [
            comprobante.idMovimiento,
            comprobante.rutaImagen,
            comprobante.descripcion,
            comprobante.esPrincipal ? 1 : 0,
          ],
        );

        // Validación más robusta del resultado
        final result = await conn.query('SELECT @id_comprobante_out as id');
        if (result.isEmpty) {
          await conn.query('ROLLBACK');
          throw MovimientoRentaException(
            'No se obtuvieron resultados al registrar el comprobante',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.baseDatos,
            codigoError: 'RESULTADO_VACIO',
          );
        }

        final idRow = result.first;
        if (!idRow.fields.containsKey('id') || idRow['id'] == null) {
          await conn.query('ROLLBACK');
          throw MovimientoRentaException(
            'No se pudo obtener el ID del comprobante registrado',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.baseDatos,
            codigoError: 'ID_COMPROBANTE_NO_GENERADO',
          );
        }

        final idComprobante = idRow['id'];
        // Validar que el ID sea un entero y mayor que 0
        if (idComprobante is! int || idComprobante <= 0) {
          await conn.query('ROLLBACK');
          throw MovimientoRentaException(
            'El ID del comprobante generado no es válido: $idComprobante',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.baseDatos,
            codigoError: 'ID_INVALIDO',
          );
        }

        await conn.query('COMMIT');
        AppLogger.info('Comprobante registrado con ID: $idComprobante');
        return idComprobante;
      } catch (e, stackTrace) {
        await _ejecutarRollbackSeguro(conn);

        if (e is MovimientoRentaException) {
          _registrarError(
            'Error controlado al agregar comprobante',
            e,
            stackTrace,
          );
          rethrow;
        }

        final errorEnriquecido = _enriquecerError(
          e,
          stackTrace,
          'Error al registrar comprobante',
          errorContexto: {
            'idMovimiento': comprobante.idMovimiento,
            'rutaImagen': comprobante.rutaImagen,
          },
        );

        throw errorEnriquecido;
      }
    });
  }

  /// Obtiene los movimientos de un inmueble con manejo de errores mejorado
  Future<List<MovimientoRenta>> obtenerMovimientosPorInmueble(
    int idInmueble,
  ) async {
    return await _db.withConnection((conn) async {
      try {
        if (idInmueble <= 0) {
          throw MovimientoRentaException(
            'ID de inmueble inválido: debe ser mayor a cero',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.validacion,
            codigoError: 'ID_INMUEBLE_INVALIDO',
          );
        }

        AppLogger.info('Obteniendo movimientos para inmueble: $idInmueble');

        final results = await conn.query(
          'CALL ObtenerMovimientosPorInmueble(?)',
          [idInmueble],
        );

        // Validación sin comparación innecesaria con null
        if (results.isEmpty) {
          AppLogger.info(
            'No se encontraron movimientos para el inmueble: $idInmueble',
          );
          return [];
        }

        // Procesar resultados con manejo de errores por elemento
        final movimientos = <MovimientoRenta>[];
        int errores = 0;

        for (var row in results) {
          try {
            // Validar que el row tenga los campos mínimos necesarios
            final campos = row.fields;
            // Eliminada comparación de campos con null
            if (!_validarCamposMovimiento(campos)) {
              errores++;
              AppLogger.warning(
                'Fila con datos incompletos para el movimiento: ${row.toString()}',
              );
              continue;
            }

            movimientos.add(MovimientoRenta.fromMap(campos));
          } catch (itemError) {
            errores++;
            // Registrar error en elemento individual pero continuar con los demás
            AppLogger.warning(
              'Error al procesar uno de los movimientos: ${itemError.toString().split('\n').first}',
            );
          }
        }

        if (errores > 0) {
          AppLogger.warning(
            'Se omitieron $errores registros con formato inválido',
          );
        }

        AppLogger.info('Movimientos obtenidos: ${movimientos.length}');
        return movimientos;
      } catch (e, stackTrace) {
        if (e is MovimientoRentaException) {
          _registrarError(
            'Error controlado al obtener movimientos',
            e,
            stackTrace,
          );
          rethrow;
        }

        final errorEnriquecido = _enriquecerError(
          e,
          stackTrace,
          'Error al obtener movimientos',
          errorContexto: {'idInmueble': idInmueble},
        );

        throw errorEnriquecido;
      }
    });
  }

  /// Obtiene los comprobantes de un movimiento
  Future<List<ComprobanteMovimiento>> obtenerComprobantes(
    int idMovimiento,
  ) async {
    return await _db.withConnection((conn) async {
      try {
        if (idMovimiento <= 0) {
          throw MovimientoRentaException(
            'ID de movimiento inválido: debe ser mayor a cero',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.validacion,
          );
        }

        AppLogger.info(
          'Obteniendo comprobantes para movimiento: $idMovimiento',
        );

        final results = await conn.query(
          'CALL ObtenerComprobantesPorMovimiento(?)',
          [idMovimiento],
        );

        // Validación sin comparación innecesaria con null
        if (results.isEmpty) {
          AppLogger.info(
            'No se encontraron comprobantes para el movimiento: $idMovimiento',
          );
          return [];
        }

        // Procesar resultados con manejo de errores por elemento
        final comprobantes = <ComprobanteMovimiento>[];
        int errores = 0;

        for (var row in results) {
          try {
            // Validar que el row tenga los campos mínimos necesarios
            final campos = row.fields;
            // Eliminada comparación de campos con null
            if (!_validarCamposComprobante(campos)) {
              errores++;
              AppLogger.warning(
                'Fila con datos incompletos para el comprobante: ${row.toString()}',
              );
              continue;
            }

            comprobantes.add(ComprobanteMovimiento.fromMap(campos));
          } catch (itemError) {
            errores++;
            // Registrar error en elemento individual pero continuar con los demás
            AppLogger.warning(
              'Error al procesar uno de los comprobantes: ${itemError.toString()}',
            );
          }
        }

        if (errores > 0) {
          AppLogger.warning(
            'Se omitieron $errores comprobantes con formato inválido',
          );
        }

        AppLogger.info('Comprobantes obtenidos: ${comprobantes.length}');
        return comprobantes;
      } catch (e, stackTrace) {
        if (e is MovimientoRentaException) {
          _registrarError(
            'Error controlado al obtener comprobantes',
            e,
            stackTrace,
          );
          rethrow;
        }

        final errorEnriquecido = _enriquecerError(
          e,
          stackTrace,
          'Error al obtener comprobantes',
          errorContexto: {'idMovimiento': idMovimiento},
        );

        throw errorEnriquecido;
      }
    });
  }

  /// Obtiene resumen de movimientos por mes con validación robusta de resultados
  Future<ResumenRenta> obtenerResumenMovimientos(
    int idInmueble,
    int anio,
    int mes,
  ) async {
    return await _db.withConnection((conn) async {
      try {
        // Validaciones básicas para evitar errores de procedimiento
        if (idInmueble <= 0) {
          throw MovimientoRentaException(
            'ID de inmueble inválido: debe ser mayor a cero',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.validacion,
          );
        }

        if (anio < 2000 || anio > 2100) {
          throw MovimientoRentaException(
            'Año fuera de rango válido (2000-2100)',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.validacion,
          );
        }

        if (mes < 1 || mes > 12) {
          throw MovimientoRentaException(
            'Mes inválido (debe estar entre 1 y 12)',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.validacion,
          );
        }

        AppLogger.info(
          'Obteniendo resumen para inmueble: $idInmueble, $mes/$anio',
        );

        final resultados = await conn.query(
          'CALL ObtenerResumenMovimientosRenta(?, ?, ?)',
          [idInmueble, anio, mes],
        );

        // Validación del resultado del procedimiento almacenado
        if (resultados.isEmpty) {
          throw MovimientoRentaException(
            'Resultado vacío al obtener resumen de movimientos para inmueble $idInmueble',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.baseDatos,
            codigoError: 'RESULTADO_VACIO',
          );
        }

        // El procedimiento podría devolver conjuntos vacíos, lo que es válido
        double totalIngresos = 0;
        double totalEgresos = 0;
        List<MovimientoRenta> movimientos = [];

        // Procesar conjunto de resultados para ingresos (debería ser el primer resultSet)
        if (!_procesarConjuntoIngresos(resultados, (monto) {
          totalIngresos += monto;
        })) {
          AppLogger.warning(
            'No se pudieron procesar los ingresos, usando valor por defecto 0',
          );
        }

        // Procesar conjunto de resultados para egresos (debería ser el segundo resultSet)
        if (!_procesarConjuntoEgresos(resultados, (monto) {
          totalEgresos += monto;
        })) {
          AppLogger.warning(
            'No se pudieron procesar los egresos, usando valor por defecto 0',
          );
        }

        // Procesar conjunto de resultados para movimientos (debería ser el tercer resultSet)
        movimientos = _procesarConjuntoMovimientos(resultados);

        // Validación de consistencia: la suma de ingresos y egresos debería coincidir con los totales de movimientos
        _validarConsistenciaTotales(totalIngresos, totalEgresos, movimientos);

        // Crear el modelo de resumen con los datos procesados
        return ResumenRenta(
          totalIngresos: totalIngresos,
          totalEgresos: totalEgresos,
          movimientos: movimientos,
          fechaResumen: DateTime.now(),
          idInmueble: idInmueble,
          // Estos datos podrían ser extraídos del primer movimiento si está disponible
          nombreInmueble:
              movimientos.isNotEmpty ? movimientos.first.nombreInmueble : null,
        );
      } catch (e, stackTrace) {
        if (e is MovimientoRentaException) {
          _registrarError('Error controlado al obtener resumen', e, stackTrace);
          rethrow;
        }

        final errorEnriquecido = _enriquecerError(
          e,
          stackTrace,
          'Error al obtener resumen',
          errorContexto: {'idInmueble': idInmueble, 'periodo': '$mes/$anio'},
        );

        throw errorEnriquecido;
      }
    });
  }

  /// Obtiene movimientos de todos los inmuebles en un periodo específico
  Future<List<MovimientoRenta>> obtenerMovimientosPorPeriodo(
    String periodoStr,
  ) async {
    return await _db.withConnection((conn) async {
      try {
        // Validar formato del periodo (YYYY-MM)
        final regExp = RegExp(r'^\d{4}-\d{2}$');
        if (!regExp.hasMatch(periodoStr)) {
          throw MovimientoRentaException(
            'Formato de periodo inválido. Debe ser YYYY-MM',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.validacion,
          );
        }

        AppLogger.info('Obteniendo movimientos para el periodo: $periodoStr');

        final results = await conn.query(
          'SELECT mr.*, c.nombre AS nombre_cliente, c.apellido_paterno AS apellido_cliente, '
          'i.nombre_inmueble, e.nombre_estado '
          'FROM movimientos_renta mr '
          'JOIN clientes c ON mr.id_cliente = c.id_cliente '
          'JOIN inmuebles i ON mr.id_inmueble = i.id_inmueble '
          'JOIN estados e ON mr.id_estado = e.id_estado '
          'WHERE mr.mes_correspondiente = ? '
          'ORDER BY mr.fecha_movimiento DESC',
          [periodoStr],
        );

        // Validación robusta del resultado
        if (results.isEmpty) {
          AppLogger.info(
            'No se encontraron movimientos para el periodo: $periodoStr',
          );
          return [];
        }

        // Procesar resultados con manejo de errores por elemento
        final movimientos = <MovimientoRenta>[];
        int errores = 0;

        for (var row in results) {
          try {
            // Validar que el row tenga los campos mínimos necesarios
            final campos = row.fields;
            if (!_validarCamposMovimiento(campos)) {
              errores++;
              AppLogger.warning(
                'Fila con datos incompletos para el movimiento: ${row.toString()}',
              );
              continue;
            }

            movimientos.add(MovimientoRenta.fromMap(campos));
          } catch (itemError) {
            errores++;
            AppLogger.warning(
              'Error al procesar uno de los movimientos por periodo: $itemError',
            );
          }
        }

        if (errores > 0) {
          AppLogger.warning(
            'Se omitieron $errores registros con formato inválido',
          );
        }

        AppLogger.info(
          'Movimientos obtenidos para el periodo $periodoStr: ${movimientos.length}',
        );
        return movimientos;
      } catch (e, stackTrace) {
        if (e is MovimientoRentaException) {
          _registrarError(
            'Error controlado al obtener movimientos por periodo',
            e,
            stackTrace,
          );
          rethrow;
        }

        final errorEnriquecido = _enriquecerError(
          e,
          stackTrace,
          'Error al obtener movimientos por periodo',
          errorContexto: {'periodo': periodoStr},
        );

        throw errorEnriquecido;
      }
    });
  }

  /// Elimina un movimiento
  Future<bool> eliminarMovimiento(int idMovimiento) async {
    return await _db.withConnection((conn) async {
      await conn.query('START TRANSACTION');
      try {
        if (idMovimiento <= 0) {
          throw MovimientoRentaException(
            'ID de movimiento inválido: debe ser mayor a cero',
            stackTrace: StackTrace.current,
            categoria: ErrorCategoria.validacion,
          );
        }

        AppLogger.info('Eliminando movimiento: $idMovimiento');

        await conn.query('CALL EliminarMovimientoRenta(?)', [idMovimiento]);

        await conn.query('COMMIT');
        AppLogger.info('Movimiento eliminado correctamente');
        return true;
      } catch (e, stackTrace) {
        await _ejecutarRollbackSeguro(conn);

        if (e is MovimientoRentaException) {
          _registrarError(
            'Error controlado al eliminar movimiento',
            e,
            stackTrace,
          );
          rethrow;
        }

        final errorEnriquecido = _enriquecerError(
          e,
          stackTrace,
          'Error al eliminar movimiento',
          errorContexto: {'idMovimiento': idMovimiento},
        );

        throw errorEnriquecido;
      }
    });
  }

  /// Verifica si un archivo de imagen existe físicamente
  Future<bool> verificarExistenciaComprobante(String rutaImagen) async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final imagePath = path.join(baseDir.path, rutaImagen);
      final file = File(imagePath);

      // Verificar si el archivo existe
      if (!await file.exists()) {
        AppLogger.warning('El archivo de comprobante no existe: $rutaImagen');
        return false;
      }

      // Verificar tamaño mínimo para asegurar que no está corrupto
      final fileSize = await file.length();
      if (fileSize < 100) {
        // Menos de 100 bytes es probablemente un archivo vacío o corrupto
        AppLogger.warning(
          'El archivo de comprobante parece estar vacío o corrupto: $rutaImagen',
        );
        return false;
      }

      // Verificar que no exceda el tamaño máximo
      if (fileSize > _tamanoMaximoComprobante) {
        AppLogger.warning(
          'El archivo de comprobante excede el tamaño máximo permitido: $rutaImagen',
        );
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.warning(
        'Error al verificar existencia física del comprobante: $e',
      );
      return false;
    }
  }

  /// Valida un comprobante antes de procesarlo
  Future<void> validarComprobanteCompleto(
    ComprobanteMovimiento comprobante,
  ) async {
    // Primero realizar validaciones básicas
    _validarComprobante(comprobante);

    // Luego verificar existencia física del archivo
    final existeFisicamente = await verificarExistenciaComprobante(
      comprobante.rutaImagen,
    );
    if (!existeFisicamente) {
      throw MovimientoRentaException(
        'El archivo del comprobante no existe o no es accesible',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
        codigoError: 'ARCHIVO_NO_EXISTE',
      );
    }
  }

  // ============ MÉTODOS AUXILIARES PRIVADOS ============

  /// Ejecuta ROLLBACK de forma segura, capturando errores
  Future<void> _ejecutarRollbackSeguro(dynamic conn) async {
    try {
      await conn.query('ROLLBACK');
    } catch (rollbackError) {
      AppLogger.warning('Error al ejecutar ROLLBACK: $rollbackError');
    }
  }

  /// Valida los campos mínimos necesarios para crear un MovimientoRenta
  bool _validarCamposMovimiento(Map<String, dynamic> campos) {
    // Verificar campos obligatorios para crear un MovimientoRenta
    final camposObligatorios = [
      'id_movimiento',
      'id_inmueble',
      'id_cliente',
      'tipo_movimiento',
      'concepto',
      'monto',
      'fecha_movimiento',
    ];

    for (var campo in camposObligatorios) {
      if (!campos.containsKey(campo) || campos[campo] == null) {
        return false;
      }
    }

    // Validar tipo de datos para campos críticos
    if (campos['id_movimiento'] is! int ||
        campos['id_inmueble'] is! int ||
        campos['id_cliente'] is! int) {
      return false;
    }

    // Validar que el monto sea convertible a double
    try {
      if (campos['monto'] is! double) {
        double.parse(campos['monto'].toString());
      }
    } catch (_) {
      return false;
    }

    return true;
  }

  /// Valida los campos mínimos necesarios para crear un ComprobanteMovimiento
  bool _validarCamposComprobante(Map<String, dynamic> campos) {
    // Verificar campos obligatorios para crear un ComprobanteMovimiento
    final camposObligatorios = [
      'id_comprobante',
      'id_movimiento',
      'ruta_imagen',
    ];

    for (var campo in camposObligatorios) {
      if (!campos.containsKey(campo) || campos[campo] == null) {
        return false;
      }
    }

    // Validar tipo de datos para campos críticos
    if (campos['id_comprobante'] is! int || campos['id_movimiento'] is! int) {
      return false;
    }

    return true;
  }

  /// Registra errores de forma controlada evitando duplicados
  void _registrarError(
    String mensaje,
    dynamic error,
    StackTrace stackTrace, {
    Map<String, dynamic>? contexto,
  }) {
    final ahora = DateTime.now();
    final errorKey = error.toString().hashCode.toString();

    // Evitar logs duplicados o demasiado frecuentes
    if (_ultimosErrores.containsKey(errorKey) &&
        ahora.difference(_ultimosErrores[errorKey]!) < _intervaloMinimoLogs) {
      return;
    }

    _ultimosErrores[errorKey] = ahora;

    try {
      // Extraer información detallada para el log
      final detallesLog = '$mensaje: ${error.toString()}';

      // Si es una excepción personalizada, añadir información de categoría
      if (error is MovimientoRentaException) {
        final detallesExtra =
            'Categoría: ${error.categoria}, Código: ${error.codigoError ?? "N/A"}';
        AppLogger.error('$detallesLog ($detallesExtra)', error, stackTrace);
      } else {
        // Para otros tipos de errores, registrar normalmente
        AppLogger.error(detallesLog, error, stackTrace);
      }

      // Si hay contexto adicional, registrarlo como info
      if (contexto != null && contexto.isNotEmpty) {
        final contextoStr = contexto.entries
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
        AppLogger.info('Contexto del error: $contextoStr');
      }

      // Limpiar entradas antiguas del mapa
      _limpiarRegistrosAntiguos();
    } catch (logError) {
      // Si falla el logging, usar un método más simple
      AppLogger.error('$mensaje: ${error.toString()}', error, stackTrace);
    }
  }

  /// Limpia registros antiguos de errores para evitar memory leaks
  void _limpiarRegistrosAntiguos() {
    final ahora = DateTime.now();
    final entradaAntiguas =
        _ultimosErrores.entries
            .where(
              (entry) =>
                  ahora.difference(entry.value) > const Duration(minutes: 10),
            )
            .map((entry) => entry.key)
            .toList();

    for (final key in entradaAntiguas) {
      _ultimosErrores.remove(key);
    }

    // Limitar tamaño del mapa
    if (_ultimosErrores.length > 20) {
      final antiguaEntrada =
          _ultimosErrores.entries
              .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
              .key;
      _ultimosErrores.remove(antiguaEntrada);
    }
  }

  /// Valida un comprobante antes de procesarlo
  void _validarComprobante(ComprobanteMovimiento comprobante) {
    if (comprobante.idMovimiento <= 0) {
      throw MovimientoRentaException(
        'ID de movimiento inválido',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
      );
    }

    if (comprobante.rutaImagen.trim().isEmpty) {
      throw MovimientoRentaException(
        'La ruta del comprobante es obligatoria',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
      );
    }

    // Validar que la imagen tenga una extensión válida
    final extension = path.extension(comprobante.rutaImagen).toLowerCase();
    final tieneExtensionValida = _extensionesValidasComprobantes.contains(
      extension,
    );

    if (!tieneExtensionValida) {
      throw MovimientoRentaException(
        'El formato del comprobante no es válido. Formatos permitidos: ${_extensionesValidasComprobantes.join(", ")}',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
      );
    }

    // Validar descripción
    if (comprobante.descripcion != null &&
        comprobante.descripcion!.isNotEmpty &&
        comprobante.descripcion!.length < 3) {
      throw MovimientoRentaException(
        'La descripción debe tener al menos 3 caracteres',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
      );
    }

    // Validar longitud máxima de descripción si existe
    if (comprobante.descripcion != null &&
        comprobante.descripcion!.length > 150) {
      throw MovimientoRentaException(
        'La descripción es demasiado larga (máximo 150 caracteres)',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
      );
    }
  }

  /// Enriquece el error con información adicional y lo categoriza
  MovimientoRentaException _enriquecerError(
    dynamic error,
    StackTrace stackTrace,
    String mensajeBase, {
    Map<String, dynamic>? errorContexto,
  }) {
    final mensajeError = error.toString().toLowerCase();

    // Detectar y categorizar diferentes tipos de errores
    if (mensajeError.contains('connection') ||
        mensajeError.contains('socket') ||
        mensajeError.contains('timeout') ||
        mensajeError.contains('closed')) {
      _registrarError(
        'Error de conexión',
        error,
        stackTrace,
        contexto: errorContexto,
      );
      return MovimientoRentaException(
        'Error de conexión con la base de datos. Intente nuevamente más tarde.',
        errorOriginal: error,
        stackTrace: stackTrace,
        categoria: ErrorCategoria.conexion,
        codigoError: 'CONNECTION_ERROR',
      );
    }

    if (mensajeError.contains('denied') ||
        mensajeError.contains('access') ||
        mensajeError.contains('permission')) {
      _registrarError(
        'Error de permisos',
        error,
        stackTrace,
        contexto: errorContexto,
      );
      return MovimientoRentaException(
        'No tiene permisos para realizar esta operación.',
        errorOriginal: error,
        stackTrace: stackTrace,
        categoria: ErrorCategoria.autorizacion,
        codigoError: 'PERMISSION_ERROR',
      );
    }

    if (mensajeError.contains('no data found') ||
        mensajeError.contains('not found') ||
        mensajeError.contains('no existe') ||
        mensajeError.contains('no encontr')) {
      _registrarError(
        'Recurso no encontrado',
        error,
        stackTrace,
        contexto: errorContexto,
      );
      return MovimientoRentaException(
        'El recurso solicitado no existe o ha sido eliminado.',
        errorOriginal: error,
        stackTrace: stackTrace,
        categoria: ErrorCategoria.noEncontrado,
        codigoError: 'NOT_FOUND',
      );
    }

    if (mensajeError.contains('duplicate') ||
        mensajeError.contains('constraint') ||
        mensajeError.contains('violation') ||
        mensajeError.contains('integrity')) {
      _registrarError(
        'Error de integridad',
        error,
        stackTrace,
        contexto: errorContexto,
      );
      return MovimientoRentaException(
        'La operación viola restricciones de la base de datos. Puede existir un registro duplicado.',
        errorOriginal: error,
        stackTrace: stackTrace,
        categoria: ErrorCategoria.baseDatos,
        codigoError: 'INTEGRITY_ERROR',
      );
    }

    // Error general (no categorizado)
    _registrarError(mensajeBase, error, stackTrace, contexto: errorContexto);
    return MovimientoRentaException(
      '$mensajeBase. Contacte al administrador del sistema.',
      errorOriginal: error,
      stackTrace: stackTrace,
      categoria: ErrorCategoria.general,
    );
  }

  /// Procesa el conjunto de resultados para ingresos
  bool _procesarConjuntoIngresos(
    dynamic resultados,
    void Function(double monto) acumular,
  ) {
    try {
      if (resultados.isEmpty) {
        return false;
      }

      // El primer resultado debería ser el conjunto de ingresos
      final ingresos = resultados.first;
      if (ingresos.isEmpty) {
        return false;
      }

      int errores = 0;
      for (var row in ingresos) {
        try {
          if (!row.fields.containsKey('monto') || row['monto'] == null) {
            errores++;
            continue;
          }

          final montoRaw = row['monto'];
          double monto;

          if (montoRaw is double) {
            monto = montoRaw;
          } else if (montoRaw is int) {
            monto = montoRaw.toDouble();
          } else if (montoRaw is String) {
            monto = double.tryParse(montoRaw) ?? 0.0;
          } else {
            errores++;
            continue;
          }

          acumular(monto);
        } catch (parseError) {
          errores++;
          AppLogger.warning('Error al procesar monto de ingreso: $parseError');
        }
      }

      if (errores > 0 && errores == ingresos.length) {
        // Si todos los elementos tuvieron error, consideramos que falló el procesamiento
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.warning('Error al procesar conjunto de ingresos: $e');
      return false;
    }
  }

  /// Procesa el conjunto de resultados para egresos
  bool _procesarConjuntoEgresos(
    dynamic resultados,
    void Function(double monto) acumular,
  ) {
    try {
      if (resultados.length <= 1) {
        return false;
      }

      // El segundo resultado debería ser el conjunto de egresos
      final egresos = resultados.elementAt(1);
      if (egresos.isEmpty) {
        return false;
      }

      int errores = 0;
      for (var row in egresos) {
        try {
          if (!row.fields.containsKey('monto') || row['monto'] == null) {
            errores++;
            continue;
          }

          final montoRaw = row['monto'];
          double monto;

          if (montoRaw is double) {
            monto = montoRaw;
          } else if (montoRaw is int) {
            monto = montoRaw.toDouble();
          } else if (montoRaw is String) {
            monto = double.tryParse(montoRaw) ?? 0.0;
          } else {
            errores++;
            continue;
          }

          acumular(monto);
        } catch (parseError) {
          errores++;
          AppLogger.warning('Error al procesar monto de egreso: $parseError');
        }
      }

      if (errores > 0 && errores == egresos.length) {
        // Si todos los elementos tuvieron error, consideramos que falló el procesamiento
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.warning('Error al procesar conjunto de egresos: $e');
      return false;
    }
  }

  /// Procesa el conjunto de resultados para movimientos completos
  List<MovimientoRenta> _procesarConjuntoMovimientos(dynamic resultados) {
    final movimientos = <MovimientoRenta>[];

    try {
      if (resultados.length <= 2) {
        return movimientos;
      }

      // El tercer resultado debería ser el conjunto de movimientos
      final movimientosData = resultados.elementAt(2);
      if (movimientosData.isEmpty) {
        return movimientos;
      }

      for (var row in movimientosData) {
        try {
          // Validar que el row tenga los campos mínimos necesarios
          if (!_validarCamposMovimiento(row.fields)) {
            AppLogger.warning(
              'Fila con datos incompletos para el movimiento: ${row.toString()}',
            );
            continue;
          }

          movimientos.add(MovimientoRenta.fromMap(row.fields));
        } catch (parseError) {
          AppLogger.warning(
            'Error al procesar movimiento en resumen: $parseError',
          );
        }
      }
    } catch (e) {
      AppLogger.warning(
        'Error al procesar conjunto de movimientos detallados: $e',
      );
    }

    return movimientos;
  }

  /// Valida la consistencia de los totales calculados con los movimientos procesados
  void _validarConsistenciaTotales(
    double totalIngresos,
    double totalEgresos,
    List<MovimientoRenta> movimientos,
  ) {
    try {
      if (movimientos.isEmpty) {
        return; // No hay datos para validar
      }

      // Calcular totales basados en los movimientos procesados
      double ingresosCalculados = 0.0;
      double egresosCalculados = 0.0;

      for (var mov in movimientos) {
        if (mov.esIngreso) {
          ingresosCalculados += mov.monto;
        } else {
          egresosCalculados += mov.monto;
        }
      }

      // Comparar con un margen de error por posibles problemas de precisión
      const double margenError = 0.01;
      final diferenciaIngresos = (totalIngresos - ingresosCalculados).abs();
      final diferenciaEgresos = (totalEgresos - egresosCalculados).abs();

      if (diferenciaIngresos > margenError || diferenciaEgresos > margenError) {
        AppLogger.warning(
          'Inconsistencia detectada en totales de resumen: '
          'Ingresos reportados: $totalIngresos vs calculados: $ingresosCalculados, '
          'Egresos reportados: $totalEgresos vs calculados: $egresosCalculados',
        );
      }
    } catch (e) {
      AppLogger.warning('Error al validar consistencia de totales: $e');
    }
  }

  /// Valida un movimiento antes de procesarlo
  void _validarMovimiento(MovimientoRenta movimiento) {
    if (movimiento.idInmueble <= 0) {
      throw MovimientoRentaException(
        'El ID del inmueble es inválido',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
        codigoError: 'INMUEBLE_INVALIDO',
      );
    }

    if (movimiento.idCliente <= 0) {
      throw MovimientoRentaException(
        'El ID del cliente es inválido',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
        codigoError: 'CLIENTE_INVALIDO',
      );
    }

    if (movimiento.tipoMovimiento != 'ingreso' &&
        movimiento.tipoMovimiento != 'egreso') {
      throw MovimientoRentaException(
        'Tipo de movimiento inválido. Debe ser "ingreso" o "egreso"',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
        codigoError: 'TIPO_MOVIMIENTO_INVALIDO',
      );
    }

    if (movimiento.monto <= 0) {
      throw MovimientoRentaException(
        'El monto debe ser mayor a cero',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
        codigoError: 'MONTO_INVALIDO',
      );
    }

    // Adicional: validar montos extremadamente altos que podrían ser errores de digitación
    if (movimiento.monto > 1000000) {
      throw MovimientoRentaException(
        'El monto parece excesivamente alto. Verifique el valor ingresado.',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
        codigoError: 'MONTO_SOSPECHOSO',
      );
    }

    if (movimiento.concepto.trim().isEmpty) {
      throw MovimientoRentaException(
        'El concepto no puede estar vacío',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
        codigoError: 'CONCEPTO_VACIO',
      );
    }

    // Validar longitud mínima del concepto para asegurar descripciones significativas
    if (movimiento.concepto.trim().length < 3) {
      throw MovimientoRentaException(
        'El concepto debe tener al menos 3 caracteres',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
        codigoError: 'CONCEPTO_MUY_CORTO',
      );
    }

    // Validaciones mejoradas para fechas
    final hoy = DateTime.now();
    final limiteAntiguedad = DateTime(hoy.year - 2, hoy.month, hoy.day);

    if (movimiento.fechaMovimiento.isAfter(hoy)) {
      throw MovimientoRentaException(
        'La fecha del movimiento no puede ser futura',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
        codigoError: 'FECHA_FUTURA',
      );
    }

    // Evitar registros con fechas excesivamente antiguas
    if (movimiento.fechaMovimiento.isBefore(limiteAntiguedad)) {
      throw MovimientoRentaException(
        'La fecha del movimiento es demasiado antigua (más de 2 años)',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
        codigoError: 'FECHA_MUY_ANTIGUA',
      );
    }

    // Formato estándar YYYY-MM para el mes correspondiente
    final regexMes = RegExp(r'^\d{4}-\d{2}$');
    if (movimiento.mesCorrespondiente.isEmpty ||
        !regexMes.hasMatch(movimiento.mesCorrespondiente)) {
      throw MovimientoRentaException(
        'El mes correspondiente debe tener formato YYYY-MM',
        stackTrace: StackTrace.current,
        categoria: ErrorCategoria.validacion,
        codigoError: 'FORMATO_MES_INVALIDO',
      );
    }

    // Validar coherencia entre mesCorrespondiente y fechaMovimiento
    final anioCorrecto = movimiento.mesCorrespondiente.substring(0, 4);
    final mesCorrecto = movimiento.mesCorrespondiente.substring(5, 7);

    if (anioCorrecto != movimiento.fechaMovimiento.year.toString() ||
        mesCorrecto !=
            movimiento.fechaMovimiento.month.toString().padLeft(2, '0')) {
      AppLogger.warning(
        'El mes correspondiente (${movimiento.mesCorrespondiente}) no coincide con '
        'la fecha del movimiento (${movimiento.fechaMovimiento.year}-'
        '${movimiento.fechaMovimiento.month.toString().padLeft(2, '0')})',
      );
    }

    // Si es egreso, validar que tenga un concepto bien definido
    if (movimiento.tipoMovimiento == 'egreso' &&
        !_esConceptoEgresoValido(movimiento.concepto)) {
      AppLogger.warning(
        'El concepto del egreso no especifica claramente el tipo de gasto: "${movimiento.concepto}"',
      );
    }
  }

  /// Valida si el concepto de un egreso está bien definido
  bool _esConceptoEgresoValido(String concepto) {
    final conceptoLower = concepto.toLowerCase();

    // Lista de términos que indican categorías específicas de gastos
    final List<String> terminos = [
      'mantenimiento',
      'reparación',
      'reparacion',
      'servicio',
      'agua',
      'luz',
      'electricidad',
      'gas',
      'internet',
      'teléfono',
      'telefono',
      'impuesto',
      'predial',
      'municipal',
      'limpieza',
      'administración',
      'administracion',
      'comisión',
      'comision',
    ];

    // Verificar si al menos uno de los términos aparece en el concepto
    return terminos.any((termino) => conceptoLower.contains(termino));
  }
}

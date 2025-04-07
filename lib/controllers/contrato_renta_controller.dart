import '../utils/applogger.dart';
import '../services/mysql_helper.dart';
import '../models/contrato_renta_model.dart';

class ContratoRentaController {
  final DatabaseService dbHelper;
  bool _procesandoError = false;

  ContratoRentaController({DatabaseService? dbService})
    : dbHelper = dbService ?? DatabaseService();

  /// Registra un nuevo contrato de renta y actualiza el estado del inmueble
  Future<int> registrarContrato(ContratoRenta contrato) async {
    return _ejecutarOperacion('registrar contrato de renta', () async {
      if (contrato.idInmueble <= 0) {
        throw Exception('El ID del inmueble es inválido');
      }
      if (contrato.idCliente <= 0) {
        throw Exception('El ID del cliente es inválido');
      }
      if (contrato.montoMensual <= 0) {
        throw Exception('El monto mensual debe ser mayor a cero');
      }
      if (contrato.fechaInicio.isAfter(contrato.fechaFin)) {
        throw Exception(
          'La fecha de inicio no puede ser posterior a la fecha de fin',
        );
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          final fechaInicioStr =
              contrato.fechaInicio.toIso8601String().split('T')[0];
          final fechaFinStr = contrato.fechaFin.toIso8601String().split('T')[0];

          // Ejecutamos primero el procedimiento con la variable OUT
          await conn.query(
            'CALL RegistrarContratoRenta(?, ?, ?, ?, ?, ?, @id_contrato_out)',
            [
              contrato.idInmueble,
              contrato.idCliente,
              fechaInicioStr,
              fechaFinStr,
              contrato.montoMensual,
              contrato.condicionesAdicionales ?? '',
            ],
          );

          // Luego consultamos el valor de la variable de salida
          final result = await conn.query('SELECT @id_contrato_out as id');

          // Verificamos que tenemos resultado y que contiene un ID
          if (result.isEmpty || result.first.fields['id'] == null) {
            throw Exception('No se pudo obtener el ID del contrato registrado');
          }

          final idContrato = result.first.fields['id'] as int;
          await conn.query('COMMIT');

          AppLogger.info('Contrato registrado con ID: $idContrato');
          return idContrato;
        } catch (e, stackTrace) {
          await conn.query('ROLLBACK');
          AppLogger.error(
            'Error al registrar contrato de renta',
            e,
            stackTrace,
          );

          // Proporciona un mensaje más específico según el error
          final mensajeOriginal = e.toString().toLowerCase();
          if (mensajeOriginal.contains('ya existe un contrato activo')) {
            throw Exception(
              'Este inmueble ya tiene un contrato de renta activo',
            );
          } else if (mensajeOriginal.contains('foreign key')) {
            throw Exception('El cliente o inmueble especificado no existe');
          }

          throw Exception('Error al registrar contrato de renta: $e');
        }
      });
    });
  }

  /// Cambia el estado de un contrato de renta (activo=1, finalizado=2)
  Future<bool> cambiarEstadoContrato(int idContrato, int nuevoEstado) async {
    return _ejecutarOperacion('cambiar estado de contrato', () async {
      if (idContrato <= 0) {
        throw Exception('ID de contrato inválido');
      }

      if (![1, 2].contains(nuevoEstado)) {
        throw Exception(
          'Estado no válido. Solo se permite 1 (activo) o 2 (finalizado)',
        );
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          await conn.query('CALL ActualizarEstadoContratoRenta(?, ?)', [
            idContrato,
            nuevoEstado,
          ]);
          await conn.query('COMMIT');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          throw Exception('Error al cambiar estado del contrato: $e');
        }
      });
    });
  }

  /// Obtiene contratos próximos a vencer en los próximos X días
  Future<List<ContratoRenta>> obtenerContratosProximosAVencer({
    int diasLimite = 30,
  }) async {
    return _ejecutarOperacion('obtener contratos próximos a vencer', () async {
      final contratos = await obtenerContratos();
      final ahora = DateTime.now();
      final fechaLimite = ahora.add(Duration(days: diasLimite));

      return contratos
          .where(
            (c) =>
                c.idEstado == 1 && // Solo contratos activos
                c.fechaFin.isAfter(ahora) &&
                c.fechaFin.isBefore(fechaLimite),
          )
          .toList();
    });
  }

  /// Renueva un contrato existente
  Future<int> renovarContrato(
    int idContratoOriginal,
    DateTime nuevaFechaInicio,
    DateTime nuevaFechaFin,
    double nuevoMontoMensual,
    String? nuevasCondiciones,
  ) async {
    return _ejecutarOperacion('renovar contrato', () async {
      // Validaciones
      if (idContratoOriginal <= 0) {
        throw Exception('ID de contrato original inválido');
      }

      if (nuevaFechaInicio.isAfter(nuevaFechaFin)) {
        throw Exception(
          'La fecha de inicio no puede ser posterior a la fecha de fin',
        );
      }

      if (nuevoMontoMensual <= 0) {
        throw Exception('El monto mensual debe ser mayor a cero');
      }

      // Obtener contrato original para verificar datos
      final contratos = await obtenerContratos();
      final contratoOriginal = contratos.firstWhere(
        (c) => c.id == idContratoOriginal,
        orElse: () => throw Exception('Contrato original no encontrado'),
      );

      // Finalizar contrato actual si está activo
      if (contratoOriginal.idEstado == 1) {
        await cambiarEstadoContrato(idContratoOriginal, 2); // 2 = finalizado
      }

      // Crear nuevo contrato con los datos actualizados
      final nuevoContrato = ContratoRenta(
        idInmueble: contratoOriginal.idInmueble,
        idCliente: contratoOriginal.idCliente,
        fechaInicio: nuevaFechaInicio,
        fechaFin: nuevaFechaFin,
        montoMensual: nuevoMontoMensual,
        condicionesAdicionales:
            nuevasCondiciones ?? contratoOriginal.condicionesAdicionales,
      );

      // Registrar el nuevo contrato
      return await registrarContrato(nuevoContrato);
    });
  }

  /// Obtiene el historial completo de un inmueble
  Future<List<ContratoRenta>> obtenerHistorialInmueble(int idInmueble) async {
    return _ejecutarOperacion(
      'obtener historial de contratos por inmueble',
      () async {
        if (idInmueble <= 0) {
          throw Exception('ID de inmueble inválido');
        }

        final contratos = await obtenerContratos();
        return contratos.where((c) => c.idInmueble == idInmueble).toList();
      },
    );
  }

  /// Obtiene contratos por cliente
  Future<List<ContratoRenta>> obtenerContratosPorCliente(int idCliente) async {
    return _ejecutarOperacion('obtener contratos por cliente', () async {
      if (idCliente <= 0) {
        throw Exception('ID de cliente inválido');
      }

      final contratos = await obtenerContratos();
      return contratos.where((c) => c.idCliente == idCliente).toList();
    });
  }

  /// Obtiene todos los contratos de renta
  Future<List<ContratoRenta>> obtenerContratos() async {
    return _ejecutarOperacion('obtener todos los contratos', () async {
      return await dbHelper.withConnection((conn) async {
        final results = await conn.query('CALL ObtenerContratos()');

        return results.map((row) {
          return ContratoRenta.fromMap(row.fields);
        }).toList();
      });
    });
  }

  /// Obtiene un contrato específico por su ID
  Future<ContratoRenta?> obtenerContratoPorId(int idContrato) async {
    return _ejecutarOperacion('obtener contrato por id', () async {
      try {
        if (idContrato <= 0) {
          throw Exception('ID de contrato inválido');
        }

        return await dbHelper.withConnection((conn) async {
          final results = await conn.query('CALL ObtenerContratoPorId(?)', [
            idContrato,
          ]);

          if (results.isEmpty || results.first.isEmpty) {
            return null;
          }

          return ContratoRenta.fromMap(results.first.fields);
        });
      } catch (e, stackTrace) {
        AppLogger.error('Error al obtener contrato por ID', e, stackTrace);
        return null;
      }
    });
  }

  /// Método auxiliar para ejecutar operaciones con manejo de errores consistente
  Future<T> _ejecutarOperacion<T>(
    String descripcion,
    Future<T> Function() operacion,
  ) async {
    try {
      AppLogger.info('Iniciando operación: $descripcion');
      final resultado = await operacion();
      AppLogger.info('Operación completada: $descripcion');
      return resultado;
    } catch (e, stackTrace) {
      if (!_procesandoError) {
        _procesandoError = true;
        AppLogger.error('Error en operación "$descripcion"', e, stackTrace);
        _procesandoError = false;
      }
      throw Exception('Error en $descripcion: $e');
    }
  }

  /// Libera recursos cuando el controlador ya no se necesita
  void dispose() {
    AppLogger.info('Liberando recursos de ContratoRentaController');
  }
}

/// Libera recursos cuando el controlador ya no se necesita
void dispose() {
  AppLogger.info('Liberando recursos de ContratoRentaController');
}

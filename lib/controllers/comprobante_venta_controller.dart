import '../utils/applogger.dart';
import '../services/mysql_helper.dart';
import '../models/comprobante_venta_model.dart';

/// Controlador para gestionar los comprobantes de venta en la base de datos
class ComprobanteVentaController {
  final DatabaseService dbHelper;
  bool _procesandoError = false;

  ComprobanteVentaController({DatabaseService? dbService})
    : dbHelper = dbService ?? DatabaseService();

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

  /// Obtiene los comprobantes asociados a una venta usando el procedimiento almacenado
  Future<List<ComprobanteVenta>> obtenerComprobantesPorVenta(
    int idVenta,
  ) async {
    return _ejecutarOperacion('obtener comprobantes por venta', () async {
      if (idVenta <= 0) {
        throw Exception('ID de venta inválido');
      }

      return await dbHelper.withConnection((conn) async {
        final results = await conn.query(
          'CALL ObtenerComprobantesPorVenta(?)',
          [idVenta],
        );

        if (results.isEmpty) {
          return [];
        }

        return results
            .map((row) => ComprobanteVenta.fromMap(row.fields))
            .toList();
      });
    });
  }

  /// Agrega un nuevo comprobante a una venta usando el procedimiento almacenado
  Future<int> agregarComprobante(ComprobanteVenta comprobante) async {
    return _ejecutarOperacion('agregar comprobante de venta', () async {
      if (comprobante.idVenta <= 0) {
        throw Exception('ID de venta inválido');
      }

      if (comprobante.rutaArchivo.isEmpty) {
        throw Exception('La ruta del archivo no puede estar vacía');
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // El procedimiento devuelve el ID del comprobante en una variable OUT
          await conn.query(
            'CALL AgregarComprobanteVenta(?, ?, ?, ?, ?, @id_comprobante_out)',
            [
              comprobante.idVenta,
              comprobante.rutaArchivo,
              comprobante.tipoArchivo,
              comprobante.descripcion ?? '',
              comprobante.esPrincipal ? 1 : 0,
            ],
          );

          // Recuperar el ID generado
          final result = await conn.query('SELECT @id_comprobante_out as id');
          final idComprobante = result.first.fields['id'] as int;

          await conn.query('COMMIT');
          AppLogger.info(
            'Comprobante de venta registrado con ID: $idComprobante',
          );
          return idComprobante;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error(
            'Error al agregar comprobante de venta',
            e,
            StackTrace.current,
          );
          throw Exception('Error al agregar comprobante de venta: $e');
        }
      });
    });
  }

  /// Actualiza un comprobante de venta usando el procedimiento almacenado
  Future<bool> actualizarComprobante(ComprobanteVenta comprobante) async {
    return _ejecutarOperacion('actualizar comprobante de venta', () async {
      if (comprobante.id == null || comprobante.id! <= 0) {
        throw Exception('ID de comprobante inválido');
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Ejecutar el procedimiento de actualización
          await conn.query('CALL ActualizarComprobanteVenta(?, ?, ?, ?)', [
            comprobante.id!,
            comprobante.descripcion ?? '',
            comprobante.esPrincipal ? 1 : 0,
            comprobante.tipoArchivo,
          ]);

          await conn.query('COMMIT');
          AppLogger.info('Comprobante de venta actualizado: ${comprobante.id}');
          return true;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error(
            'Error al actualizar comprobante de venta',
            e,
            StackTrace.current,
          );
          throw Exception('Error al actualizar comprobante de venta: $e');
        }
      });
    });
  }

  /// Elimina un comprobante de venta usando el procedimiento almacenado
  Future<bool> eliminarComprobante(int idComprobante) async {
    return _ejecutarOperacion('eliminar comprobante de venta', () async {
      if (idComprobante <= 0) {
        throw Exception('ID de comprobante inválido');
      }

      return await dbHelper.withConnection((conn) async {
        await conn.query('START TRANSACTION');
        try {
          // Ejecutar el procedimiento de eliminación
          await conn.query('CALL EliminarComprobanteVenta(?, @afectados)', [
            idComprobante,
          ]);

          // Recuperar filas afectadas
          final result = await conn.query('SELECT @afectados as filas');
          final filasAfectadas = result.first.fields['filas'] as int? ?? 0;

          await conn.query('COMMIT');

          AppLogger.info(
            'Comprobante de venta eliminado: $idComprobante. Filas afectadas: $filasAfectadas',
          );
          return filasAfectadas > 0;
        } catch (e) {
          await conn.query('ROLLBACK');
          AppLogger.error(
            'Error al eliminar comprobante de venta',
            e,
            StackTrace.current,
          );
          throw Exception('Error al eliminar comprobante de venta: $e');
        }
      });
    });
  }

  /// Libera recursos cuando el controlador ya no se necesita
  void dispose() {
    AppLogger.info('Liberando recursos de ComprobanteVentaController');
  }
}

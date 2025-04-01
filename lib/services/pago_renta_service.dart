import '../utils/applogger.dart';
import '../services/mysql_helper.dart';
import '../models/pago_renta_model.dart';

class PagoRentaService {
  final DatabaseService _db;

  PagoRentaService(this._db);

  /// Registra un nuevo pago de renta
  Future<int> registrarPago(PagoRenta pago) async {
    return await _db.withConnection((conn) async {
      await conn.query('START TRANSACTION');
      try {
        final result = await conn
            .query('CALL RegistrarPagoRenta(?, ?, ?, ?, @id_pago_out)', [
              pago.idContrato,
              pago.monto,
              pago.fechaPago.toIso8601String().split('T')[0],
              pago.comentarios,
            ]);

        final idPago = result.first['id_pago_out'] as int;
        await conn.query('COMMIT');
        AppLogger.info('Pago registrado con ID: $idPago');
        return idPago;
      } catch (e, stackTrace) {
        await conn.query('ROLLBACK');
        AppLogger.error('Error al registrar pago de renta', e, stackTrace);
        throw Exception('Error al registrar pago de renta: $e');
      }
    });
  }

  /// Obtiene los pagos realizados para un contrato específico
  Future<List<PagoRenta>> obtenerPagosPorContrato(int idContrato) async {
    return await _db.withConnection((conn) async {
      try {
        final results = await conn.query('CALL ObtenerPagosPorContrato(?)', [
          idContrato,
        ]);

        return results.map((row) => PagoRenta.fromMap(row.fields)).toList();
      } catch (e, stackTrace) {
        AppLogger.error('Error al obtener pagos de renta', e, stackTrace);
        throw Exception('Error al obtener pagos de renta: $e');
      }
    });
  }
}

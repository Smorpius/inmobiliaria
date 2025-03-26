import '../models/venta_model.dart';
import 'dart:developer' as developer;
import '../services/mysql_helper.dart';
import '../models/venta_reporte_model.dart';

class VentasService {
  final DatabaseService _db;

  VentasService(this._db);

  /// Obtiene todas las ventas
  Future<List<Venta>> obtenerVentas() async {
    try {
      final conn = await _db.connection;
      final result = await conn.query('CALL ObtenerVentas()');

      return result.map((row) {
        final map = <String, dynamic>{};
        for (var field in row.fields.keys) {
          map[field] = row[field];
        }
        return Venta.fromMap(map);
      }).toList();
    } catch (e) {
      developer.log('Error al obtener ventas: $e', error: e);
      rethrow;
    }
  }

  /// Obtiene una venta por su ID
  Future<Venta?> obtenerVentaPorId(int idVenta) async {
    try {
      final conn = await _db.connection;
      final result = await conn.query(
        'SELECT * FROM ventas v '
        'JOIN clientes c ON v.id_cliente = c.id_cliente '
        'JOIN inmuebles i ON v.id_inmueble = i.id_inmueble '
        'JOIN estados e ON v.id_estado = e.id_estado '
        'LEFT JOIN empleados em ON i.id_empleado = em.id_empleado '
        'WHERE v.id_venta = ?',
        [idVenta],
      );

      if (result.isEmpty) {
        return null;
      }

      final map = <String, dynamic>{};
      for (var field in result.first.fields.keys) {
        map[field] = result.first[field];
      }
      return Venta.fromMap(map);
    } catch (e) {
      developer.log('Error al obtener venta por ID: $e', error: e);
      rethrow;
    }
  }

  /// Crea una nueva venta
  Future<int> crearVenta(Venta venta) async {
    try {
      final conn = await _db.connection;

      // Reinicia la variable de salida
      await conn.query('SET @p_id_venta_out = 0');

      // Llamada al procedimiento almacenado
      await conn.query('CALL CrearVenta(?, ?, ?, ?, ?, ?, @p_id_venta_out)', [
        venta.idCliente,
        venta.idInmueble,
        venta.fechaVenta.toIso8601String().split('T')[0],
        venta.ingreso,
        venta.comisionProveedores,
        venta.utilidadNeta,
      ]);

      // Obtener el ID de la venta creada
      final result = await conn.query('SELECT @p_id_venta_out AS id');
      if (result.isEmpty || result.first['id'] == null) {
        throw Exception('No se pudo obtener el ID de la venta creada');
      }

      return result.first['id'] as int;
    } catch (e) {
      developer.log('Error al crear venta: $e', error: e);
      rethrow;
    }
  }

  /// Actualiza la utilidad de una venta
  Future<bool> actualizarUtilidadVenta(
    int idVenta,
    double gastosAdicionales,
    int usuarioModificacion,
  ) async {
    try {
      final conn = await _db.connection;
      await conn.query('CALL ActualizarUtilidadVenta(?, ?, ?)', [
        idVenta,
        gastosAdicionales,
        usuarioModificacion,
      ]);
      return true;
    } catch (e) {
      developer.log('Error al actualizar utilidad de venta: $e', error: e);
      rethrow;
    }
  }

  /// Cambiar estado de una venta
  Future<bool> cambiarEstadoVenta(
    int idVenta,
    int nuevoEstado,
    int usuarioModificacion,
  ) async {
    try {
      final conn = await _db.connection;
      await conn.query('CALL CambiarEstadoVenta(?, ?, ?)', [
        idVenta,
        nuevoEstado,
        usuarioModificacion,
      ]);
      return true;
    } catch (e) {
      developer.log('Error al cambiar estado de la venta: $e', error: e);
      rethrow;
    }
  }

  // Modifica el método obtenerEstadisticasVentas para manejar correctamente los resultados

  Future<VentaReporte> obtenerEstadisticasVentas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      final conn = await _db.connection;

      // Verificar que haya resultados antes de acceder a ellos
      final estadisticasResult = await conn
          .query('CALL ObtenerEstadisticasVentas(?, ?)', [
            fechaInicio?.toIso8601String().split('T')[0],
            fechaFin?.toIso8601String().split('T')[0],
          ]);

      // Crear datos por defecto si no hay resultados
      final Map<String, dynamic> estadisticas =
          estadisticasResult.isNotEmpty && estadisticasResult.first.isNotEmpty
              ? estadisticasResult.first.fields
              : {
                'total_ventas': 0,
                'ingreso_total': 0.0,
                'utilidad_total': 0.0,
                'margen_promedio': 0.0,
                'fecha_inicio':
                    fechaInicio?.toIso8601String().split('T')[0] ??
                    DateTime(2000, 1, 1).toIso8601String().split('T')[0],
                'fecha_fin':
                    fechaFin?.toIso8601String().split('T')[0] ??
                    DateTime.now().toIso8601String().split('T')[0],
              };

      // Manejar posible error en el procedimiento de rentabilidad
      final rentabilidadResult = await conn
          .query('CALL AnalisisRentabilidadPorTipo()')
          .catchError((e) {
            developer.log(
              'Error al obtener análisis de rentabilidad: $e',
              error: e,
            );
            throw e; // Re-throw to handle in the outer try-catch
          });

      // Transformar datos de rentabilidad por tipo
      final ventasPorTipo = <String, double>{};
      for (var row in rentabilidadResult) {
        if (row['tipo_inmueble'] != null && row['total_ventas'] != null) {
          ventasPorTipo[row['tipo_inmueble'].toString()] = double.parse(
            row['total_ventas'].toString(),
          );
        }
      }

      // Obtener ventas mensuales para gráficos con manejo de errores
      final ventasMensualesResult = await conn
          .query(
            'SELECT YEAR(fecha_venta) as anio, MONTH(fecha_venta) as mes, '
            'COUNT(*) as total, SUM(ingreso) as ingreso, SUM(utilidad_neta) as utilidad '
            'FROM ventas '
            'WHERE fecha_venta BETWEEN ? AND ? '
            'GROUP BY YEAR(fecha_venta), MONTH(fecha_venta) '
            'ORDER BY anio, mes',
            [
              fechaInicio?.toIso8601String().split('T')[0] ?? '2000-01-01',
              fechaFin?.toIso8601String().split('T')[0] ??
                  DateTime.now().toIso8601String().split('T')[0],
            ],
          )
          .catchError((e) {
            developer.log('Error al obtener ventas mensuales: $e', error: e);
            throw e; // Re-throw the error to be caught by the outer try-catch
          });

      final ventasMensuales = <Map<String, dynamic>>[];
      for (var row in ventasMensualesResult) {
        if (row['anio'] != null && row['mes'] != null) {
          ventasMensuales.add({
            'anio': row['anio'],
            'mes': row['mes'],
            'total': row['total'] ?? 0,
            'ingreso': double.parse((row['ingreso'] ?? 0).toString()),
            'utilidad': double.parse((row['utilidad'] ?? 0).toString()),
          });
        }
      }

      return VentaReporte(
        fechaInicio: fechaInicio ?? DateTime(2000, 1, 1),
        fechaFin: fechaFin ?? DateTime.now(),
        totalVentas: int.parse(estadisticas['total_ventas']?.toString() ?? '0'),
        ingresoTotal: double.parse(
          estadisticas['ingreso_total']?.toString() ?? '0',
        ),
        utilidadTotal: double.parse(
          estadisticas['utilidad_total']?.toString() ?? '0',
        ),
        margenPromedio: double.parse(
          estadisticas['margen_promedio']?.toString() ?? '0',
        ),
        ventasPorTipo: ventasPorTipo,
        ventasMensuales: ventasMensuales,
      );
    } catch (e) {
      developer.log('Error al obtener estadísticas de ventas: $e', error: e);
      // Devolver un objeto vacío en caso de error
      return VentaReporte(
        fechaInicio: fechaInicio ?? DateTime(2000, 1, 1),
        fechaFin: fechaFin ?? DateTime.now(),
        totalVentas: 0,
        ingresoTotal: 0,
        utilidadTotal: 0,
        margenPromedio: 0,
        ventasPorTipo: {},
        ventasMensuales: [],
      );
    }
  }
}

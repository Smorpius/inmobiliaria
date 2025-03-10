import 'dart:async';
import 'package:logging/logging.dart';
import '../models/inmueble_model.dart';
import '../services/mysql_helper.dart';
import '../models/inmueble_imagen.dart';

class InmuebleController {
  final DatabaseService dbHelper;
  final Logger _logger = Logger('InmuebleController');

  InmuebleController({DatabaseService? dbService})
    : dbHelper = dbService ?? DatabaseService();

  Future<List<Inmueble>> getInmuebles() async {
    try {
      _logger.info('Iniciando consulta de inmuebles...');
      final db = await dbHelper.connection;

      final results = await db.query('''
        SELECT 
          i.*,
          d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
          d.codigo_postal, d.referencias,
          e.nombre_estado AS estado_inmueble
        FROM inmuebles i
        LEFT JOIN direcciones d ON i.id_direccion = d.id_direccion
        LEFT JOIN estados e ON i.id_estado = e.id_estado
        ORDER BY i.fecha_registro DESC
      ''');

      _logger.info('Resultados obtenidos: ${results.length} inmuebles');

      if (results.isNotEmpty) {
        _logger.info('Primer registro: ${results.first.fields}');
      }

      final List<Inmueble> inmuebles = [];

      for (var row in results) {
        try {
          final inmueble = Inmueble.fromMap(row.fields);
          inmuebles.add(inmueble);
          _logger.fine('Inmueble procesado: $inmueble');
        } catch (e) {
          _logger.warning(
            'Error procesando inmueble: ${row.fields}, error: $e',
          );
        }
      }

      _logger.info('Inmuebles procesados: ${inmuebles.length}');
      return inmuebles;
    } catch (e) {
      _logger.severe('Error al obtener inmuebles: $e');
      throw Exception('Error al obtener inmuebles: $e');
    }
  }

  Future<int> insertInmueble(Inmueble inmueble) async {
    try {
      _logger.info('Insertando inmueble: $inmueble');
      final db = await dbHelper.connection;

      // Usar el procedimiento almacenado CrearInmueble
      final result = await db.query(
        'CALL CrearInmueble(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          inmueble.nombre,
          inmueble.calle ?? '',
          inmueble.numero ?? '',
          inmueble.colonia ?? '',
          inmueble.ciudad ?? '',
          inmueble.estadoGeografico ?? '',
          inmueble.codigoPostal ?? '',
          inmueble.referencias ?? '',
          inmueble.montoTotal,
          inmueble.tipoInmueble,
          inmueble.tipoOperacion,
          inmueble.precioVenta,
          inmueble.precioRenta,
          inmueble.idEstado ?? 3, // 3 = disponible por defecto
          inmueble.idCliente,
          inmueble.idEmpleado,
          inmueble.caracteristicas,
        ],
      );

      _logger.info(
        'Inmueble insertado: ID=${result.insertId}, Filas afectadas=${result.affectedRows}',
      );
      return result.insertId ?? -1;
    } catch (e) {
      _logger.severe('Error al insertar inmueble: $e');
      throw Exception('Error al insertar inmueble: $e');
    }
  }

  Future<int> updateInmueble(Inmueble inmueble) async {
    try {
      if (inmueble.id == null) {
        throw Exception('No se puede actualizar un inmueble sin ID');
      }

      _logger.info('Actualizando inmueble: $inmueble');
      final db = await dbHelper.connection;

      // Usar el procedimiento almacenado ActualizarInmueble
      final result = await db.query(
        'CALL ActualizarInmueble(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          inmueble.id,
          inmueble.nombre,
          inmueble.calle ?? '',
          inmueble.numero ?? '',
          inmueble.colonia ?? '',
          inmueble.ciudad ?? '',
          inmueble.estadoGeografico ?? '',
          inmueble.codigoPostal ?? '',
          inmueble.referencias ?? '',
          inmueble.montoTotal,
          inmueble.tipoInmueble,
          inmueble.tipoOperacion,
          inmueble.precioVenta,
          inmueble.precioRenta,
          inmueble.idEstado ?? 3,
          inmueble.idCliente,
          inmueble.idEmpleado,
          inmueble.caracteristicas,
        ],
      );

      _logger.info(
        'Inmueble actualizado: ID=${inmueble.id}, Filas afectadas=${result.affectedRows}',
      );
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al actualizar inmueble: $e');
      throw Exception('Error al actualizar inmueble: $e');
    }
  }

  Future<int> deleteInmueble(int id) async {
    try {
      _logger.info('Eliminando inmueble con ID: $id');
      final db = await dbHelper.connection;

      // Primero obtener el id_direccion para eliminar después
      final direccionQuery = await db.query(
        'SELECT id_direccion FROM inmuebles WHERE id_inmueble = ?',
        [id],
      );

      int? idDireccion;
      if (direccionQuery.isNotEmpty) {
        idDireccion = direccionQuery.first.fields['id_direccion'] as int?;
      }

      // Eliminar primero los registros relacionados
      await db.query(
        'DELETE FROM inmuebles_clientes_interesados WHERE id_inmueble = ?',
        [id],
      );

      await db.query('DELETE FROM inmuebles_imagenes WHERE id_inmueble = ?', [
        id,
      ]);

      // Luego eliminar el inmueble
      final result = await db.query(
        'DELETE FROM inmuebles WHERE id_inmueble = ?',
        [id],
      );

      // Finalmente eliminar la dirección si existe
      if (idDireccion != null) {
        await db.query('DELETE FROM direcciones WHERE id_direccion = ?', [
          idDireccion,
        ]);
      }

      _logger.info(
        'Inmueble eliminado: ID=$id, Filas afectadas=${result.affectedRows}',
      );
      return result.affectedRows ?? 0;
    } catch (e) {
      _logger.severe('Error al eliminar inmueble: $e');
      throw Exception('Error al eliminar inmueble: $e');
    }
  }

  Future<bool> verificarExistenciaInmueble(int id) async {
    try {
      _logger.info('Verificando existencia del inmueble con ID: $id');
      final db = await dbHelper.connection;

      final result = await db.query(
        'SELECT COUNT(*) as count FROM inmuebles WHERE id_inmueble = ?',
        [id],
      );

      final int count = result.first.fields['count'] as int;
      _logger.info('¿Inmueble $id existe? ${count > 0}');
      return count > 0;
    } catch (e) {
      _logger.warning('Error al verificar existencia de inmueble: $e');
      return false;
    }
  }

  // Método para buscar inmuebles por criterios
  Future<List<Inmueble>> buscarInmuebles({
    String? tipo,
    String? operacion,
    double? precioMin,
    double? precioMax,
    String? ciudad,
    int? idEstado,
  }) async {
    try {
      _logger.info('Buscando inmuebles con criterios específicos');
      final db = await dbHelper.connection;

      String query = '''
        SELECT 
          i.*,
          d.calle, d.numero, d.colonia, d.ciudad, d.estado_geografico,
          d.codigo_postal, d.referencias,
          e.nombre_estado AS estado_inmueble
        FROM inmuebles i
        LEFT JOIN direcciones d ON i.id_direccion = d.id_direccion
        LEFT JOIN estados e ON i.id_estado = e.id_estado
        WHERE 1=1
      ''';

      List<Object> params = [];

      if (tipo != null && tipo.isNotEmpty) {
        query += ' AND i.tipo_inmueble = ?';
        params.add(tipo);
      }

      if (operacion != null && operacion.isNotEmpty) {
        query += ' AND i.tipo_operacion = ?';
        params.add(operacion);
      }

      if (precioMin != null) {
        query += ' AND i.monto_total >= ?';
        params.add(precioMin);
      }

      if (precioMax != null) {
        query += ' AND i.monto_total <= ?';
        params.add(precioMax);
      }

      if (ciudad != null && ciudad.isNotEmpty) {
        query += ' AND d.ciudad LIKE ?';
        params.add('%$ciudad%');
      }

      if (idEstado != null) {
        query += ' AND i.id_estado = ?';
        params.add(idEstado);
      }

      query += ' ORDER BY i.fecha_registro DESC';

      final results = await db.query(query, params);

      final List<Inmueble> inmuebles = [];
      for (var row in results) {
        try {
          inmuebles.add(Inmueble.fromMap(row.fields));
        } catch (e) {
          _logger.warning('Error procesando inmueble en búsqueda: $e');
        }
      }

      return inmuebles;
    } catch (e) {
      _logger.severe('Error al buscar inmuebles: $e');
      throw Exception('Error en la búsqueda de inmuebles: $e');
    }
  }

  // Método para obtener los clientes interesados en un inmueble
  Future<List<Map<String, dynamic>>> getClientesInteresados(
    int idInmueble,
  ) async {
    try {
      _logger.info('Obteniendo clientes interesados en inmueble: $idInmueble');
      final db = await dbHelper.connection;

      final results = await db.query(
        '''
        SELECT 
          ci.id, ci.id_inmueble, ci.id_cliente, ci.fecha_interes, ci.comentarios,
          c.nombre, c.apellido_paterno, c.apellido_materno, c.telefono_cliente, c.correo_cliente
        FROM inmuebles_clientes_interesados ci
        JOIN clientes c ON ci.id_cliente = c.id_cliente
        WHERE ci.id_inmueble = ?
        ORDER BY ci.fecha_interes DESC
      ''',
        [idInmueble],
      );

      return results.map((row) => row.fields).toList();
    } catch (e) {
      _logger.severe('Error al obtener clientes interesados: $e');
      throw Exception('Error al obtener clientes interesados: $e');
    }
  }

  // Método para registrar un cliente interesado
  Future<int> registrarClienteInteresado(
    int idInmueble,
    int idCliente,
    String? comentarios,
  ) async {
    try {
      _logger.info(
        'Registrando cliente $idCliente interesado en inmueble $idInmueble',
      );
      final db = await dbHelper.connection;

      final result = await db.query(
        '''
        INSERT INTO inmuebles_clientes_interesados (id_inmueble, id_cliente, comentarios)
        VALUES (?, ?, ?)
        ''',
        [idInmueble, idCliente, comentarios],
      );

      return result.insertId ?? -1;
    } catch (e) {
      _logger.severe('Error al registrar cliente interesado: $e');
      throw Exception('Error al registrar cliente interesado: $e');
    }
  }

  // NUEVOS MÉTODOS PARA GESTIÓN DE IMÁGENES

  // Obtener imágenes de un inmueble
  Future<List<InmuebleImagen>> getImagenesInmueble(int idInmueble) async {
    try {
      _logger.info('Obteniendo imágenes del inmueble: $idInmueble');
      final db = await dbHelper.connection;

      final results = await db.query(
        '''
        SELECT * FROM inmuebles_imagenes 
        WHERE id_inmueble = ? 
        ORDER BY es_principal DESC, fecha_carga DESC
        ''',
        [idInmueble],
      );

      return results.map((row) => InmuebleImagen.fromMap(row.fields)).toList();
    } catch (e) {
      _logger.severe('Error al obtener imágenes del inmueble: $e');
      throw Exception('Error al obtener imágenes del inmueble: $e');
    }
  }

  // Obtener la imagen principal de un inmueble
  Future<InmuebleImagen?> getImagenPrincipal(int idInmueble) async {
    try {
      _logger.info('Obteniendo imagen principal del inmueble: $idInmueble');
      final db = await dbHelper.connection;

      final results = await db.query(
        '''
        SELECT * FROM inmuebles_imagenes 
        WHERE id_inmueble = ? AND es_principal = 1
        LIMIT 1
        ''',
        [idInmueble],
      );

      if (results.isEmpty) return null;
      return InmuebleImagen.fromMap(results.first.fields);
    } catch (e) {
      _logger.severe('Error al obtener imagen principal: $e');
      throw Exception('Error al obtener imagen principal: $e');
    }
  }

  // Agregar imagen a un inmueble
  Future<int> agregarImagenInmueble(InmuebleImagen imagen) async {
    try {
      _logger.info('Agregando imagen al inmueble: ${imagen.idInmueble}');
      final db = await dbHelper.connection;

      // Si la imagen es principal, primero desmarcar otras como principal
      if (imagen.esPrincipal) {
        await db.query(
          'UPDATE inmuebles_imagenes SET es_principal = 0 WHERE id_inmueble = ?',
          [imagen.idInmueble],
        );
      }

      final result = await db.query(
        '''
        INSERT INTO inmuebles_imagenes 
        (id_inmueble, ruta_imagen, descripcion, es_principal, fecha_carga) 
        VALUES (?, ?, ?, ?, NOW())
        ''',
        [
          imagen.idInmueble,
          imagen.rutaImagen,
          imagen.descripcion,
          imagen.esPrincipal ? 1 : 0,
        ],
      );

      return result.insertId ?? -1;
    } catch (e) {
      _logger.severe('Error al agregar imagen al inmueble: $e');
      throw Exception('Error al agregar imagen al inmueble: $e');
    }
  }

  // Marcar imagen como principal
  Future<bool> marcarImagenComoPrincipal(int idImagen, int idInmueble) async {
    try {
      _logger.info(
        'Marcando imagen $idImagen como principal para inmueble $idInmueble',
      );
      final db = await dbHelper.connection;

      // Primero desmarcar todas las imágenes del inmueble
      await db.query(
        'UPDATE inmuebles_imagenes SET es_principal = 0 WHERE id_inmueble = ?',
        [idInmueble],
      );

      // Luego marcar la imagen seleccionada como principal
      final result = await db.query(
        'UPDATE inmuebles_imagenes SET es_principal = 1 WHERE id_imagen = ? AND id_inmueble = ?',
        [idImagen, idInmueble],
      );

      _logger.info(
        'Imagen actualizada como principal: ${result.affectedRows} filas',
      );
      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      _logger.severe('Error al marcar imagen como principal: $e');
      throw Exception('Error al marcar imagen como principal: $e');
    }
  }

  // Eliminar imagen
  Future<bool> eliminarImagenInmueble(int idImagen) async {
    try {
      _logger.info('Eliminando imagen con ID: $idImagen');
      final db = await dbHelper.connection;

      // Verificar si es imagen principal antes de eliminar
      final checkResult = await db.query(
        'SELECT es_principal, id_inmueble FROM inmuebles_imagenes WHERE id_imagen = ?',
        [idImagen],
      );

      if (checkResult.isEmpty) {
        _logger.warning('No se encontró la imagen a eliminar: $idImagen');
        return false;
      }

      final bool esPrincipal = checkResult.first.fields['es_principal'] == 1;
      final int idInmueble = checkResult.first.fields['id_inmueble'] as int;

      // Eliminar la imagen
      final result = await db.query(
        'DELETE FROM inmuebles_imagenes WHERE id_imagen = ?',
        [idImagen],
      );

      // Si era la imagen principal, asignar otra como principal si existe
      if (esPrincipal) {
        final restantes = await db.query(
          'SELECT id_imagen FROM inmuebles_imagenes WHERE id_inmueble = ? LIMIT 1',
          [idInmueble],
        );

        if (restantes.isNotEmpty) {
          await marcarImagenComoPrincipal(
            restantes.first.fields['id_imagen'] as int,
            idInmueble,
          );
        }
      }

      _logger.info('Imagen eliminada: ${result.affectedRows} filas');
      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      _logger.severe('Error al eliminar imagen: $e');
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  // Actualizar descripción de imagen
  Future<bool> actualizarDescripcionImagen(
    int idImagen,
    String nuevaDescripcion,
  ) async {
    try {
      _logger.info('Actualizando descripción de imagen: $idImagen');
      final db = await dbHelper.connection;

      final result = await db.query(
        'UPDATE inmuebles_imagenes SET descripcion = ? WHERE id_imagen = ?',
        [nuevaDescripcion, idImagen],
      );

      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      _logger.severe('Error al actualizar descripción de imagen: $e');
      throw Exception('Error al actualizar descripción de imagen: $e');
    }
  }
}

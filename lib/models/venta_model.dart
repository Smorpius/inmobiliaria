import 'package:logging/logging.dart';

class Venta {
  static final Logger _logger = Logger('VentaModel');

  final int? id;
  final int idCliente;
  final int idInmueble;
  final DateTime fechaVenta;
  final double ingreso;
  final double comisionProveedores;
  final double utilidadBruta; // Calculado: ingreso - comisionProveedores
  final double utilidadNeta; // Utilidad final considerando gastos adicionales
  final int
  idEstado; // 7: venta_en_proceso, 8: venta_completada, 9: venta_cancelada

  // Propiedades derivadas de relaciones
  final String? nombreCliente;
  final String? apellidoCliente;
  final String? nombreInmueble;
  final String? tipoInmueble;
  final String? tipoOperacion;
  final String? estadoVenta;
  final String? nombreEmpleado;
  final double? precioOriginalInmueble;
  final double? margenGanancia;

  /// Constructor principal con validaciones mejoradas
  Venta({
    this.id,
    required this.idCliente,
    required this.idInmueble,
    required this.fechaVenta,
    required this.ingreso,
    required this.comisionProveedores,
    double? utilidadBruta,
    double? utilidadNeta,
    this.idEstado = 7, // Por defecto en proceso
    this.nombreCliente,
    this.apellidoCliente,
    this.nombreInmueble,
    this.tipoInmueble,
    this.tipoOperacion,
    this.estadoVenta,
    this.nombreEmpleado,
    this.precioOriginalInmueble,
    this.margenGanancia,
  }) : // Calcular utilidad bruta siempre como ingreso - comisión
       utilidadBruta = utilidadBruta ?? (ingreso - comisionProveedores),
       // Si se proporciona utilidadNeta, usarla, sino usar utilidadBruta
       utilidadNeta =
           utilidadNeta ?? (utilidadBruta ?? (ingreso - comisionProveedores)) {
    // Invariantes básicos que deben cumplirse
    if (idCliente <= 0) {
      _logger.severe(
        'Se creó una Venta con ID de cliente inválido: $idCliente',
      );
    }

    if (idInmueble <= 0) {
      _logger.severe(
        'Se creó una Venta con ID de inmueble inválido: $idInmueble',
      );
    }

    if (ingreso <= 0) {
      _logger.warning('Se creó una Venta con ingreso no positivo: $ingreso');
    }

    if (comisionProveedores < 0) {
      _logger.warning(
        'Se creó una Venta con comisión negativa: $comisionProveedores',
      );
    }

    final utilidadBrutaCalculada = ingreso - comisionProveedores;
    if (this.utilidadBruta != utilidadBrutaCalculada) {
      _logger.warning(
        'Inconsistencia en utilidad bruta: esperado $utilidadBrutaCalculada, '
        'encontrado ${this.utilidadBruta}',
      );
    }

    if (this.utilidadNeta > this.utilidadBruta) {
      _logger.warning(
        'La utilidad neta (${this.utilidadNeta}) es mayor que la bruta '
        '(${this.utilidadBruta}), lo que indica un posible error',
      );
    }

    if (fechaVenta.isAfter(DateTime.now())) {
      _logger.warning('Se creó una Venta con fecha futura: $fechaVenta');
    }

    if (![7, 8, 9].contains(idEstado)) {
      _logger.warning('Se creó una Venta con estado inválido: $idEstado');
    }
  }

  /// Crea una instancia de Venta a partir de un mapa de datos con manejo robusto de errores
  factory Venta.fromMap(Map<String, dynamic> map) {
    try {
      // Verificar campos obligatorios
      if (map['id_cliente'] == null) {
        throw Exception('El campo id_cliente es obligatorio');
      }
      if (map['id_inmueble'] == null) {
        throw Exception('El campo id_inmueble es obligatorio');
      }
      if (map['fecha_venta'] == null) {
        throw Exception('El campo fecha_venta es obligatorio');
      }
      if (map['ingreso'] == null) {
        throw Exception('El campo ingreso es obligatorio');
      }

      // Convertir valores con manejo seguro de errores
      final int idCliente = int.parse(map['id_cliente'].toString());
      final int idInmueble = int.parse(map['id_inmueble'].toString());
      final double ingreso = double.parse(map['ingreso'].toString());

      // Calcular comisión de proveedores si no está presente
      final double comisionProveedores =
          map['comision_proveedores'] != null
              ? double.parse(map['comision_proveedores'].toString())
              : 0.0;

      // Calcular o recuperar utilidad bruta
      final double? utilidadBruta =
          map['utilidad_bruta'] != null
              ? double.parse(map['utilidad_bruta'].toString())
              : null; // Será calculado en el constructor

      // Determinar utilidad neta
      double? utilidadNeta;
      if (map['utilidad_neta'] != null) {
        utilidadNeta = double.parse(map['utilidad_neta'].toString());
      } else if (utilidadBruta != null) {
        // Si no hay utilidad neta pero sí bruta, inicialmente iguales
        utilidadNeta = utilidadBruta;
      }

      // Garantizar que el estado sea válido
      int idEstado = 7; // Valor predeterminado
      if (map['id_estado'] != null) {
        idEstado = int.parse(map['id_estado'].toString());
        if (![7, 8, 9].contains(idEstado)) {
          _logger.warning(
            'Estado de venta inválido: $idEstado, usando 7 (en proceso)',
          );
          idEstado = 7;
        }
      }

      // Convertir fecha con manejo de errores
      DateTime fechaVenta;
      try {
        fechaVenta =
            map['fecha_venta'] is DateTime
                ? map['fecha_venta']
                : DateTime.parse(map['fecha_venta'].toString());
      } catch (e) {
        _logger.warning('Error al parsear fecha de venta: $e');
        fechaVenta = DateTime.now(); // Usar fecha actual como fallback
      }

      // Crear instancia
      return Venta(
        id: map['id_venta'],
        idCliente: idCliente,
        idInmueble: idInmueble,
        fechaVenta: fechaVenta,
        ingreso: ingreso,
        comisionProveedores: comisionProveedores,
        utilidadBruta: utilidadBruta,
        utilidadNeta: utilidadNeta,
        idEstado: idEstado,
        nombreCliente: map['nombre_cliente'],
        apellidoCliente: map['apellido_cliente'],
        nombreInmueble: map['nombre_inmueble'],
        tipoInmueble: map['tipo_inmueble'],
        tipoOperacion: map['tipo_operacion'],
        estadoVenta: map['estado_venta'],
        nombreEmpleado: map['nombre_empleado'],
        precioOriginalInmueble:
            map['precio_original'] != null
                ? double.parse(map['precio_original'].toString())
                : null,
        margenGanancia:
            map['margen_ganancia'] != null
                ? double.parse(map['margen_ganancia'].toString())
                : null,
      );
    } catch (e) {
      _logger.severe('Error al crear Venta desde Map: $e');
      rethrow;
    }
  }

  /// Convierte la instancia de Venta a un mapa para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id_venta': id,
      'id_cliente': idCliente,
      'id_inmueble': idInmueble,
      'fecha_venta': fechaVenta.toIso8601String().split('T')[0],
      'ingreso': ingreso,
      'comision_proveedores': comisionProveedores,
      'utilidad_bruta': utilidadBruta,
      'utilidad_neta': utilidadNeta,
      'id_estado': idEstado,
    };
  }

  /// Actualiza la utilidad neta sin modificar otras propiedades
  Venta actualizarUtilidadNeta(double nuevaUtilidadNeta) {
    // Validación de invariantes
    if (nuevaUtilidadNeta > utilidadBruta) {
      _logger.warning(
        'La utilidad neta ($nuevaUtilidadNeta) no debería ser mayor que la utilidad bruta ($utilidadBruta)',
      );
      // Limitar la utilidad neta a la bruta para mantener la consistencia
      nuevaUtilidadNeta = utilidadBruta;
    }

    return Venta(
      id: id,
      idCliente: idCliente,
      idInmueble: idInmueble,
      fechaVenta: fechaVenta,
      ingreso: ingreso,
      comisionProveedores: comisionProveedores,
      utilidadBruta: utilidadBruta,
      utilidadNeta: nuevaUtilidadNeta,
      idEstado: idEstado,
      nombreCliente: nombreCliente,
      apellidoCliente: apellidoCliente,
      nombreInmueble: nombreInmueble,
      tipoInmueble: tipoInmueble,
      tipoOperacion: tipoOperacion,
      estadoVenta: estadoVenta,
      nombreEmpleado: nombreEmpleado,
      precioOriginalInmueble: precioOriginalInmueble,
      margenGanancia: margenGanancia,
    );
  }

  /// Crea una nueva instancia con un estado diferente
  Venta conNuevoEstado(int nuevoEstado) {
    if (![7, 8, 9].contains(nuevoEstado)) {
      _logger.warning(
        'Estado no válido: $nuevoEstado. Debe ser 7 (en proceso), 8 (completada) o 9 (cancelada)',
      );
      // Mantener el estado actual en vez de permitir uno inválido
      nuevoEstado = idEstado;
    }

    return Venta(
      id: id,
      idCliente: idCliente,
      idInmueble: idInmueble,
      fechaVenta: fechaVenta,
      ingreso: ingreso,
      comisionProveedores: comisionProveedores,
      utilidadBruta: utilidadBruta,
      utilidadNeta: utilidadNeta,
      idEstado: nuevoEstado,
      nombreCliente: nombreCliente,
      apellidoCliente: apellidoCliente,
      nombreInmueble: nombreInmueble,
      tipoInmueble: tipoInmueble,
      tipoOperacion: tipoOperacion,
      estadoVenta: estadoVenta,
      nombreEmpleado: nombreEmpleado,
      precioOriginalInmueble: precioOriginalInmueble,
      margenGanancia: margenGanancia,
    );
  }

  /// Calcula los gastos adicionales como la diferencia entre utilidad bruta y neta
  double get gastosAdicionales => utilidadBruta - utilidadNeta;

  /// Determina si la venta es rentable (utilidad neta positiva)
  bool get esRentable => utilidadNeta > 0;

  /// Calcula el porcentaje de rentabilidad sobre el ingreso total
  double get porcentajeRentabilidad =>
      ingreso > 0 ? (utilidadNeta / ingreso) * 100 : 0;

  /// Genera una representación en cadena para depuración
  @override
  String toString() {
    return 'Venta{id: $id, cliente: $nombreCliente $apellidoCliente, inmueble: $nombreInmueble, ingreso: $ingreso, utilidadNeta: $utilidadNeta}';
  }

  /// Obtiene el nombre completo del cliente si está disponible
  String? get clienteNombreCompleto {
    if (nombreCliente != null || apellidoCliente != null) {
      return '$nombreCliente $apellidoCliente'.trim();
    }
    return null;
  }
}

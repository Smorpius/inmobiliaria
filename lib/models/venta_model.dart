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
           utilidadNeta ?? (utilidadBruta ?? (ingreso - comisionProveedores));

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

      // Calcular comisión de proveedores si no está presente
      final comisionProveedores =
          map['comision_proveedores'] != null
              ? double.parse(map['comision_proveedores'].toString())
              : 0.0;

      // Crear instancia
      return Venta(
        id: map['id_venta'],
        idCliente: map['id_cliente'],
        idInmueble: map['id_inmueble'],
        fechaVenta:
            map['fecha_venta'] is DateTime
                ? map['fecha_venta']
                : DateTime.parse(map['fecha_venta'].toString()),
        ingreso: double.parse(map['ingreso'].toString()),
        comisionProveedores: comisionProveedores,
        utilidadBruta:
            map['utilidad_bruta'] != null
                ? double.parse(map['utilidad_bruta'].toString())
                : null, // Permitir cálculo automático
        utilidadNeta:
            map['utilidad_neta'] != null
                ? double.parse(map['utilidad_neta'].toString())
                : null, // Permitir cálculo automático
        idEstado: map['id_estado'] ?? 7,
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
    if (nuevaUtilidadNeta > utilidadBruta) {
      _logger.warning(
        'La utilidad neta no debería ser mayor que la utilidad bruta',
      );
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
      _logger.warning('Estado no válido: $nuevoEstado');
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

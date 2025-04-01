import '../utils/applogger.dart';

class InmuebleValidationService {
  // Control para evitar mensajes de error duplicados
  bool _procesandoError = false;
  final Map<String, DateTime> _ultimasValidaciones = {};
  static const Duration _tiempoEntreValidaciones = Duration(seconds: 5);

  /// Valida el nombre del inmueble
  String? validarNombre(String? value) {
    try {
      if (value == null || value.isEmpty) {
        _registrarError('nombre_vacio', 'Nombre de inmueble vacío');
        return 'Por favor ingrese un nombre';
      }
      if (value.length < 3) {
        _registrarError('nombre_corto', 'Nombre de inmueble demasiado corto');
        return 'El nombre debe tener al menos 3 caracteres';
      }
      return null;
    } catch (e) {
      _manejarExcepcion('validarNombre', e);
      return 'Error al validar el nombre';
    }
  }

  /// Valida el precio de venta según el tipo de operación
  String? validarPrecioVenta(String? value, String tipoOperacion) {
    try {
      if ((tipoOperacion == 'venta' || tipoOperacion == 'ambos') &&
          (value == null || value.isEmpty)) {
        _registrarError('precio_venta_vacio', 'Precio de venta vacío');
        return 'Por favor ingrese el precio de venta';
      }
      if (value != null && value.isNotEmpty) {
        try {
          final precio = double.parse(value);
          if (precio <= 0) {
            _registrarError(
              'precio_venta_negativo',
              'Precio de venta negativo o cero',
            );
            return 'El precio debe ser mayor a cero';
          }
        } catch (e) {
          _registrarError(
            'precio_venta_formato',
            'Formato inválido de precio de venta',
          );
          return 'El formato del precio es inválido';
        }
      }
      return null;
    } catch (e) {
      _manejarExcepcion('validarPrecioVenta', e);
      return 'Error al validar el precio de venta';
    }
  }

  /// Valida el precio de renta según el tipo de operación
  String? validarPrecioRenta(String? value, String tipoOperacion) {
    try {
      if ((tipoOperacion == 'renta' || tipoOperacion == 'ambos') &&
          (value == null || value.isEmpty)) {
        _registrarError('precio_renta_vacio', 'Precio de renta vacío');
        return 'Por favor ingrese el precio de renta';
      }
      if (value != null && value.isNotEmpty) {
        try {
          final precio = double.parse(value);
          if (precio <= 0) {
            _registrarError(
              'precio_renta_negativo',
              'Precio de renta negativo o cero',
            );
            return 'El precio debe ser mayor a cero';
          }
        } catch (e) {
          _registrarError(
            'precio_renta_formato',
            'Formato inválido de precio de renta',
          );
          return 'El formato del precio es inválido';
        }
      }
      return null;
    } catch (e) {
      _manejarExcepcion('validarPrecioRenta', e);
      return 'Error al validar el precio de renta';
    }
  }

  /// Valida el monto total del inmueble
  String? validarMonto(String? value) {
    try {
      if (value == null || value.isEmpty) {
        _registrarError('monto_vacio', 'Monto de inmueble vacío');
        return 'Por favor ingrese un monto';
      }
      try {
        final monto = double.parse(value);
        if (monto <= 0) {
          _registrarError('monto_negativo', 'Monto negativo o cero');
          return 'El monto debe ser mayor a cero';
        }
      } catch (e) {
        _registrarError('monto_formato', 'Formato inválido de monto');
        return 'El formato del monto es inválido';
      }
      return null;
    } catch (e) {
      _manejarExcepcion('validarMonto', e);
      return 'Error al validar el monto';
    }
  }

  /// Valida la calle del inmueble
  String? validarCalle(String? value) {
    try {
      if (value == null || value.isEmpty) {
        _registrarError('calle_vacia', 'Calle de inmueble vacía');
        return 'Por favor ingrese la calle';
      }
      return null;
    } catch (e) {
      _manejarExcepcion('validarCalle', e);
      return 'Error al validar la calle';
    }
  }

  /// Valida la ciudad del inmueble
  String? validarCiudad(String? value) {
    try {
      if (value == null || value.isEmpty) {
        _registrarError('ciudad_vacia', 'Ciudad de inmueble vacía');
        return 'Por favor ingrese la ciudad';
      }
      return null;
    } catch (e) {
      _manejarExcepcion('validarCiudad', e);
      return 'Error al validar la ciudad';
    }
  }

  /// Valida el estado del inmueble
  String? validarEstado(String? value) {
    try {
      if (value == null || value.isEmpty) {
        _registrarError('estado_vacio', 'Estado de inmueble vacío');
        return 'Por favor ingrese el estado';
      }
      return null;
    } catch (e) {
      _manejarExcepcion('validarEstado', e);
      return 'Error al validar el estado';
    }
  }

  /// Valida el código postal (opcional)
  String? validarCodigoPostal(String? value) {
    try {
      if (value != null && value.isNotEmpty) {
        // Validar formato de código postal (5 dígitos para México)
        if (!RegExp(r'^\d{5}$').hasMatch(value)) {
          _registrarError(
            'codigo_postal_formato',
            'Formato inválido de código postal',
          );
          return 'El código postal debe tener 5 dígitos';
        }
      }
      return null;
    } catch (e) {
      _manejarExcepcion('validarCodigoPostal', e);
      return 'Error al validar el código postal';
    }
  }

  /// Valida las características del inmueble
  String? validarCaracteristicas(String? value, {bool requerido = false}) {
    try {
      if (requerido && (value == null || value.isEmpty)) {
        _registrarError(
          'caracteristicas_vacias',
          'Características de inmueble vacías',
        );
        return 'Por favor ingrese las características del inmueble';
      }
      return null;
    } catch (e) {
      _manejarExcepcion('validarCaracteristicas', e);
      return 'Error al validar las características';
    }
  }

  /// Registra un error de validación usando AppLogger con control anti-duplicados
  void _registrarError(String codigo, String mensaje) {
    final ahora = DateTime.now();
    final ultimaValidacion = _ultimasValidaciones[codigo];

    if (ultimaValidacion == null ||
        ahora.difference(ultimaValidacion) > _tiempoEntreValidaciones) {
      _ultimasValidaciones[codigo] = ahora;
      AppLogger.warning('Validación fallida: $mensaje [código: $codigo]');
    }
  }

  /// Maneja excepciones inesperadas durante la validación
  void _manejarExcepcion(String metodo, dynamic error) {
    if (!_procesandoError) {
      _procesandoError = true;
      AppLogger.error(
        'Error inesperado en InmuebleValidationService.$metodo',
        error,
        StackTrace.current,
      );
      _procesandoError = false;
    }
  }

  /// Limpia el registro de validaciones previas
  void limpiarHistorialValidaciones() {
    _ultimasValidaciones.clear();
  }
}

class InmuebleValidationService {
  String? validarNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un nombre';
    }
    return null;
  }

  String? validarPrecioVenta(String? value, String tipoOperacion) {
    if (tipoOperacion == 'venta' && (value == null || value.isEmpty)) {
      return 'Por favor ingrese el precio de venta';
    }
    return null;
  }

  String? validarPrecioRenta(String? value, String tipoOperacion) {
    if (tipoOperacion == 'renta' && (value == null || value.isEmpty)) {
      return 'Por favor ingrese el precio de renta';
    }
    return null;
  }

  String? validarMonto(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un monto';
    }
    try {
      double.parse(value);
    } catch (e) {
      return 'El formato del monto es inválido';
    }
    return null;
  }

  String? validarCalle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese la calle';
    }
    return null;
  }

  String? validarCiudad(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese la ciudad';
    }
    return null;
  }

  String? validarEstado(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese el estado';
    }
    return null;
  }
}

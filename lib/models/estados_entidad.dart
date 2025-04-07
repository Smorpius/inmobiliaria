/// Clase que centraliza todos los códigos de estado para entidades del sistema
///
/// Esta clase contiene constantes para todos los estados utilizados en las tablas
/// y proporciona métodos para obtener nombres legibles de cada estado.
class EstadosEntidad {
  // Estados generales
  static const int activo = 1;
  static const int inactivo = 2;

  // Estados de inmueble
  static const int disponible = 3;
  static const int vendido = 4;
  static const int rentado = 5;
  static const int enNegociacion = 6;

  // Estados de venta
  static const int ventaEnProceso = 7;
  static const int ventaCompletada = 8;
  static const int ventaCancelada = 9;

  /// Obtiene el nombre legible de un estado según su ID
  static String obtenerNombre(int idEstado) {
    switch (idEstado) {
      case activo:
        return 'Activo';
      case inactivo:
        return 'Inactivo';
      case disponible:
        return 'Disponible';
      case vendido:
        return 'Vendido';
      case rentado:
        return 'Rentado';
      case enNegociacion:
        return 'En negociación';
      case ventaEnProceso:
        return 'Venta en proceso';
      case ventaCompletada:
        return 'Venta completada';
      case ventaCancelada:
        return 'Venta cancelada';
      default:
        return 'Desconocido';
    }
  }

  /// Obtiene la descripción detallada de un estado
  static String obtenerDescripcion(int idEstado) {
    switch (idEstado) {
      case activo:
        return 'El registro está activo y puede ser utilizado normalmente.';
      case inactivo:
        return 'El registro está inactivo y no debe utilizarse.';
      case disponible:
        return 'El inmueble está disponible para venta o renta.';
      case vendido:
        return 'El inmueble ha sido vendido.';
      case rentado:
        return 'El inmueble está actualmente en renta.';
      case enNegociacion:
        return 'El inmueble está en proceso de negociación con cliente(s).';
      case ventaEnProceso:
        return 'La venta está en proceso de completarse.';
      case ventaCompletada:
        return 'La venta ha sido completada exitosamente.';
      case ventaCancelada:
        return 'La venta fue cancelada.';
      default:
        return 'Estado sin descripción disponible.';
    }
  }

  /// Verifica si un estado es un estado "activo" (utilizable)
  static bool esEstadoActivo(int idEstado) {
    return idEstado == activo ||
        idEstado == disponible ||
        idEstado == enNegociacion ||
        idEstado == ventaEnProceso;
  }

  /// Verifica si el inmueble está disponible para operaciones
  static bool inmuebleDisponible(int idEstado) {
    return idEstado == disponible || idEstado == enNegociacion;
  }
}

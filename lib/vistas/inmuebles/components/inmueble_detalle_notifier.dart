import '../../../utils/applogger.dart';
import '../../../models/inmueble_model.dart';
import '../../../providers/providers_global.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier para manejar el estado de los detalles de un inmueble
/// con manejo optimizado de errores y comunicación con la base de datos
class InmuebleDetalleNotifier extends StateNotifier<AsyncValue<Inmueble>> {
  final Ref _ref;
  final int inmuebleId;

  // Control para evitar logs duplicados con tiempo mínimo entre logs
  bool _procesandoError = false;
  DateTime? _ultimoErrorRegistrado;
  static const Duration _minTiempoEntreErrores = Duration(seconds: 5);

  // Control para evitar operaciones concurrentes
  bool _cargando = false;
  bool _actualizando = false;

  // Indicador de si el notifier sigue activo
  bool _disposed = false;

  InmuebleDetalleNotifier(this._ref, this.inmuebleId)
    : super(const AsyncValue.loading()) {
    cargarInmueble();
  }

  /// Registra error controlando duplicados por tiempo
  void _registrarError(String mensaje, Object error, StackTrace stackTrace) {
    if (_procesandoError) return;

    final ahora = DateTime.now();
    if (_ultimoErrorRegistrado != null &&
        ahora.difference(_ultimoErrorRegistrado!) < _minTiempoEntreErrores) {
      return; // Evitar registro de errores muy frecuentes
    }

    _procesandoError = true;
    _ultimoErrorRegistrado = ahora;
    AppLogger.error(mensaje, error, stackTrace);
    _procesandoError = false;
  }

  /// Carga los datos del inmueble desde el controlador utilizando procedimientos almacenados
  Future<void> cargarInmueble() async {
    if (_disposed) return;

    if (_cargando) {
      AppLogger.info(
        'Ya se está cargando el inmueble $inmuebleId, evitando operación duplicada',
      );
      return;
    }

    try {
      _cargando = true;
      if (!_disposed) state = const AsyncValue.loading();

      final inmuebleController = _ref.read(inmuebleControllerProvider);

      // Primera estrategia: Verificar existencia usando procedimiento almacenado
      try {
        // VerificarExistenciaInmueble procedimiento almacenado
        final existe = await inmuebleController.verificarExistenciaInmueble(
          inmuebleId,
        );

        if (!existe) {
          throw Exception('Inmueble no encontrado');
        }

        // ObtenerInmuebles procedimiento almacenado
        final inmuebles = await inmuebleController.getInmuebles();

        if (_disposed) return;

        // Buscar el inmueble específico
        final inmueble = inmuebles.firstWhere(
          (i) => i.id == inmuebleId,
          orElse: () => throw Exception('Inmueble no encontrado'),
        );

        if (!_disposed) {
          state = AsyncValue.data(inmueble);
          AppLogger.info('Inmueble $inmuebleId cargado exitosamente');
        }

        return;
      } catch (e) {
        // Si falla el primer método, intentar enfoque alternativo
        AppLogger.warning(
          'Error al cargar inmueble específico, intentando método alternativo',
        );

        if (_disposed) return;

        final inmuebles = await inmuebleController.getInmuebles();

        final inmueble = inmuebles.firstWhere(
          (inmueble) => inmueble.id == inmuebleId,
          orElse:
              () =>
                  throw Exception('Inmueble no encontrado en la base de datos'),
        );

        if (!_disposed) {
          state = AsyncValue.data(inmueble);
          AppLogger.info(
            'Inmueble $inmuebleId cargado exitosamente (método alternativo)',
          );
        }
      }
    } catch (e, stack) {
      _registrarError('Error al cargar inmueble $inmuebleId', e, stack);

      // Determinar si es un error de conexión
      final esErrorConexion =
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('mysql') ||
          e.toString().toLowerCase().contains('timeout');

      if (!_disposed) {
        if (esErrorConexion) {
          state = AsyncValue.error(
            Exception(
              'Error de conexión con la base de datos. Intente nuevamente.',
            ),
            stack,
          );
        } else {
          state = AsyncValue.error(e, stack);
        }
      }
    } finally {
      _cargando = false;
    }
  }

  /// Actualiza el estado del inmueble (Disponible, Vendido, Rentado, etc)
  /// usando el procedimiento almacenado ActualizarInmueble
  Future<void> actualizarEstado(int nuevoEstado) async {
    if (_disposed) return;

    // Evitar operaciones duplicadas
    if (_actualizando) {
      AppLogger.warning(
        'Ya hay una actualización en proceso para inmueble $inmuebleId',
      );
      return;
    }

    // Guardar el estado actual para poder revertir en caso de error
    final estadoAnterior = state;

    try {
      _actualizando = true;

      // Verificar estado actual antes de continuar
      if (state is! AsyncData<Inmueble>) {
        throw Exception(
          'No se puede actualizar un inmueble que no está cargado',
        );
      }

      final inmuebleActual = (state as AsyncData<Inmueble>).value;

      // Verificar que estemos cambiando efectivamente el estado
      if (inmuebleActual.idEstado == nuevoEstado) {
        AppLogger.info(
          'El inmueble ya está en el estado $nuevoEstado, no se realizarán cambios',
        );
        return;
      }

      // Crear copia actualizada del inmueble para actualización optimista
      final inmuebleActualizado = Inmueble(
        id: inmuebleActual.id,
        nombre: inmuebleActual.nombre,
        idDireccion: inmuebleActual.idDireccion,
        montoTotal: inmuebleActual.montoTotal,
        idEstado: nuevoEstado, // Actualizar el estado
        idCliente: inmuebleActual.idCliente,
        idEmpleado: inmuebleActual.idEmpleado,
        tipoInmueble: inmuebleActual.tipoInmueble,
        tipoOperacion: inmuebleActual.tipoOperacion,
        precioVenta: inmuebleActual.precioVenta,
        precioRenta: inmuebleActual.precioRenta,
        caracteristicas: inmuebleActual.caracteristicas,
        calle: inmuebleActual.calle,
        numero: inmuebleActual.numero,
        colonia: inmuebleActual.colonia,
        ciudad: inmuebleActual.ciudad,
        estadoGeografico: inmuebleActual.estadoGeografico,
        codigoPostal: inmuebleActual.codigoPostal,
        referencias: inmuebleActual.referencias,
        fechaRegistro: inmuebleActual.fechaRegistro,
        costoCliente: inmuebleActual.costoCliente,
        costoServicios: inmuebleActual.costoServicios,
      );

      // Actualización optimista: actualizar la UI inmediatamente
      if (!_disposed) {
        state = AsyncValue.data(inmuebleActualizado);
      }

      AppLogger.info(
        'Actualizando estado del inmueble $inmuebleId de ${inmuebleActual.idEstado} a $nuevoEstado',
      );

      // Actualizar en la base de datos usando el controlador que utiliza ActualizarInmueble
      final inmuebleController = _ref.read(inmuebleControllerProvider);
      await inmuebleController.updateInmueble(inmuebleActualizado);

      if (_disposed) return;

      // Recargar desde la base de datos para asegurar consistencia
      await Future.delayed(const Duration(milliseconds: 300));
      await cargarInmueble();

      AppLogger.info(
        'Estado del inmueble $inmuebleId actualizado correctamente a $nuevoEstado',
      );
    } catch (e, stack) {
      _registrarError(
        'Error al actualizar estado del inmueble $inmuebleId',
        e,
        stack,
      );

      // En caso de error, restaurar el estado anterior
      if (!_disposed) {
        state = estadoAnterior;

        // Determinar tipo de error para mensaje más específico
        final esErrorConexion =
            e.toString().toLowerCase().contains('connection') ||
            e.toString().toLowerCase().contains('socket') ||
            e.toString().toLowerCase().contains('mysql') ||
            e.toString().toLowerCase().contains('timeout');

        if (esErrorConexion) {
          state = AsyncValue.error(
            Exception(
              'Error de conexión con la base de datos. Intente nuevamente.',
            ),
            stack,
          );
        } else {
          state = AsyncValue.error(e, stack);
        }
      }

      // Re-lanzar el error para manejarlo en la UI
      rethrow;
    } finally {
      _actualizando = false;
    }
  }

  /// Recarga los datos del inmueble con control para evitar operaciones duplicadas
  Future<void> refrescarInmueble() async {
    if (_disposed) return;

    if (_cargando) {
      AppLogger.info(
        'Ya se está recargando el inmueble, evitando operación duplicada',
      );
      return;
    }

    AppLogger.info('Refrescando inmueble $inmuebleId');
    await cargarInmueble();
  }

  @override
  void dispose() {
    AppLogger.info(
      'Liberando recursos de InmuebleDetalleNotifier para inmueble $inmuebleId',
    );
    _disposed = true;
    super.dispose();
  }
}

/// Provider para acceder a los detalles de un inmueble por su ID
final inmuebleDetalleProvider = StateNotifierProvider.family<
  InmuebleDetalleNotifier,
  AsyncValue<Inmueble>,
  int
>((ref, inmuebleId) => InmuebleDetalleNotifier(ref, inmuebleId));

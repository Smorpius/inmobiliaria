import 'package:synchronized/synchronized.dart';
import 'package:inmobiliaria/utils/applogger.dart';

class CircuitBreaker {
  final String name;
  final Duration resetTimeout;
  final int failureThreshold;
  final void Function()? onCircuitOpen;

  bool _isOpen = false;
  int _failureCount = 0;
  DateTime? _openTime;
  final Lock _lock = Lock(); // Usamos Lock de la biblioteca synchronized

  CircuitBreaker({
    required this.name,
    this.resetTimeout = const Duration(minutes: 1),
    this.failureThreshold = 5,
    this.onCircuitOpen,
  }) {
    if (failureThreshold <= 0) {
      throw ArgumentError('failureThreshold debe ser mayor a 0');
    }
    if (resetTimeout <= Duration.zero) {
      throw ArgumentError('resetTimeout debe ser mayor a 0');
    }
  }

  /// Ejecuta una operación bajo el control del Circuit Breaker.
  Future<T> execute<T>(Future<T> Function() operation) async {
    return _lock.synchronized(() async {
      if (_isOpen) {
        if (_shouldReset()) {
          _resetCircuit();
        } else {
          AppLogger.warning(
            'CircuitBreaker [$name]: intento de ejecución mientras el circuito está abierto',
          );
          throw CircuitBreakerException('Circuito abierto para $name');
        }
      }

      try {
        final result = await operation();
        _resetFailures();
        return result;
      } catch (e) {
        _registerFailure();
        rethrow;
      }
    });
  }

  /// Verifica si el circuito debe cerrarse después del tiempo de enfriamiento.
  bool _shouldReset() {
    return _openTime != null &&
        DateTime.now().difference(_openTime!) > resetTimeout;
  }

  /// Resetea el estado del circuito a cerrado.
  void _resetCircuit() {
    _isOpen = false;
    _failureCount = 0;
    _openTime = null;
    AppLogger.info(
      'CircuitBreaker [$name]: circuito cerrado después del reset',
    );
  }

  /// Registra un fallo y abre el circuito si se supera el umbral.
  void _registerFailure() {
    _failureCount++;
    AppLogger.warning(
      'CircuitBreaker [$name]: fallo registrado ($_failureCount/$failureThreshold)',
    );

    if (_failureCount >= failureThreshold) {
      _openCircuit();
    }
  }

  /// Abre el circuito y ejecuta el callback opcional.
  void _openCircuit() {
    _isOpen = true;
    _openTime = DateTime.now();
    AppLogger.warning(
      'CircuitBreaker [$name]: circuito abierto por $_failureCount fallos consecutivos',
    );
    if (onCircuitOpen != null) {
      onCircuitOpen!();
    }
  }

  /// Resetea el contador de fallos.
  void _resetFailures() {
    if (_failureCount > 0) {
      AppLogger.info('CircuitBreaker [$name]: contador de fallos reseteado');
    }
    _failureCount = 0;
  }

  /// Devuelve el estado actual del circuito.
  bool get isOpen => _isOpen;

  /// Devuelve el número actual de fallos registrados.
  int get failureCount => _failureCount;

  /// Devuelve el tiempo restante para el reset del circuito.
  Duration? get timeUntilReset {
    if (!_isOpen || _openTime == null) return null;
    final elapsed = DateTime.now().difference(_openTime!);
    return resetTimeout - elapsed;
  }
}

class CircuitBreakerException implements Exception {
  final String message;
  CircuitBreakerException(this.message);

  @override
  String toString() => 'CircuitBreakerException: $message';
}

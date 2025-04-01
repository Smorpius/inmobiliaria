import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../models/cliente_model.dart';
import '../../../providers/cliente_providers.dart';
import '../../../vistas/clientes/vista_clientes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClienteAsociadoInfo extends ConsumerStatefulWidget {
  final int idInmueble;
  final int idCliente;
  final bool isInactivo;
  final VoidCallback onClienteDesasociado;

  const ClienteAsociadoInfo({
    super.key,
    required this.idInmueble,
    required this.idCliente,
    required this.isInactivo,
    required this.onClienteDesasociado,
  });

  @override
  ConsumerState<ClienteAsociadoInfo> createState() =>
      _ClienteAsociadoInfoState();
}

class _ClienteAsociadoInfoState extends ConsumerState<ClienteAsociadoInfo> {
  bool _isLoading = false;

  // Control para evitar múltiples operaciones simultáneas
  bool _operacionEnProgreso = false;

  // Control para evitar logs duplicados
  static final Map<String, DateTime> _ultimosErrores = {};
  static const Duration _intervaloMinimo = Duration(minutes: 1);

  @override
  Widget build(BuildContext context) {
    // Observamos el estado del cliente por ID usando el provider family
    final clienteAsyncValue = ref.watch(clientePorIdProvider(widget.idCliente));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: clienteAsyncValue.when(
        data: (cliente) {
          if (cliente == null) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text('Cliente no encontrado'),
            );
          }

          return _buildClienteInfo(cliente);
        },
        loading:
            () =>
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
        error: (error, stack) {
          // Registrar el error de forma controlada
          _registrarError(
            'error_carga_cliente',
            'Error al cargar cliente: ${widget.idCliente}',
            error,
            stack,
          );
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error al cargar información del cliente',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${_formatErrorMessage(error)}',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed:
                      () => ref.refresh(clientePorIdProvider(widget.idCliente)),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClienteInfo(Cliente cliente) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cliente propietario',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (!widget.isInactivo)
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Cambiar'),
                onPressed:
                    _operacionEnProgreso
                        ? null
                        : () => _mostrarDialogoCambiarCliente(context),
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con avatar y nombre
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          widget.isInactivo ? Colors.grey : Colors.teal,
                      foregroundColor: Colors.white,
                      child: Text(
                        cliente.nombre.isNotEmpty
                            ? cliente.nombre.substring(0, 1).toUpperCase()
                            : "?",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente.nombreCompleto,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTipoCliente(cliente.tipoCliente),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Información de contacto
                _buildInfoRow(Icons.phone, 'Teléfono', cliente.telefono),
                const SizedBox(height: 8),
                if (cliente.correo != null && cliente.correo!.isNotEmpty)
                  _buildInfoRow(Icons.email, 'Correo', cliente.correo!),

                const SizedBox(height: 16),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver detalles'),
                      onPressed:
                          _operacionEnProgreso
                              ? null
                              : () => _verDetallesCliente(cliente),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!widget.isInactivo)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.link_off, size: 18),
                        label: const Text('Desasociar'),
                        onPressed:
                            _isLoading || _operacionEnProgreso
                                ? null
                                : () => _desasociarCliente(widget.idInmueble),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.teal),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            Text(value, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  String _formatTipoCliente(String tipo) {
    switch (tipo) {
      case 'comprador':
        return 'Comprador';
      case 'arrendatario':
        return 'Arrendatario';
      case 'ambos':
        return 'Comprador y Arrendatario';
      default:
        return tipo;
    }
  }

  void _verDetallesCliente(Cliente cliente) {
    try {
      // Obtener el controlador a través del provider
      ref.read(clienteControllerProvider);
      AppLogger.info('Navegando a detalle del cliente ID: ${cliente.id}');

      // Navegar a la pantalla de detalles del cliente
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VistaClientes(clienteInicial: cliente),
        ),
      );
    } catch (e, stack) {
      _registrarError(
        'ver_detalle_cliente',
        'Error al navegar a detalle de cliente',
        e,
        stack,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo abrir detalle del cliente: ${_formatErrorMessage(e)}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _mostrarDialogoCambiarCliente(BuildContext context) async {
    // Esta funcionalidad está pendiente de implementación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Método optimizado para desasociar un cliente con control de operaciones concurrentes
  Future<void> _desasociarCliente(int idInmueble) async {
    // Evitar múltiples operaciones simultáneas
    if (_operacionEnProgreso || _isLoading) {
      AppLogger.warning(
        'Operación de desasociación ya en progreso, ignorando nueva solicitud',
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Desasociar cliente'),
            content: const Text(
              '¿Está seguro que desea desasociar este cliente del inmueble?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Desasociar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    // Marcar operación como en progreso
    _setOperacionEnProgreso(true);

    try {
      // Obtener controlador a través del provider
      final clienteController = ref.read(clienteControllerProvider);
      AppLogger.info('Desasociando cliente del inmueble ID: $idInmueble');

      // Desasociar el cliente del inmueble - este método debe usar withConnection internamente
      final resultado = await clienteController.desasignarInmuebleDeCliente(
        idInmueble,
      );

      if (!mounted) return;

      // Mostrar resultado según el éxito o fracaso de la operación
      if (resultado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente desasociado correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Invalidar el provider para forzar recarga
        ref.invalidate(clientePorIdProvider(widget.idCliente));

        // Notificar al padre para que actualice la UI
        widget.onClienteDesasociado();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo desasociar el cliente. El inmueble no estaba asociado a ningún cliente.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e, stack) {
      _registrarError(
        'desasociar_cliente',
        'Error al desasociar cliente del inmueble: $idInmueble',
        e,
        stack,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al desasociar cliente: ${_formatErrorMessage(e)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Garantizar que se restablezca el estado
      _setOperacionEnProgreso(false);
    }
  }

  // Método para establecer estado de operación con setState
  void _setOperacionEnProgreso(bool enProgreso) {
    if (mounted) {
      setState(() {
        _isLoading = enProgreso;
        _operacionEnProgreso = enProgreso;
      });
    }
  }

  // Método para formatear mensajes de error de forma amigable
  String _formatErrorMessage(dynamic error) {
    final message = error.toString();

    // Si el mensaje es demasiado largo, cortarlo
    if (message.length > 100) {
      return '${message.substring(0, 100)}...';
    }

    // Si contiene información sensible de conexión, mostrar mensaje genérico
    if (message.contains('connection') ||
        message.contains('socket') ||
        message.contains('MySQL')) {
      return 'Error de conexión a la base de datos';
    }

    return message.split('\n').first;
  }

  // Método para registrar errores evitando duplicados
  void _registrarError(
    String codigo,
    String mensaje,
    dynamic error,
    StackTrace stack,
  ) {
    final ahora = DateTime.now();
    final errorKey = '$codigo:${error.hashCode}';

    // Evitar logs duplicados en tiempo cercano
    if (_ultimosErrores.containsKey(errorKey)) {
      final ultimoRegistro = _ultimosErrores[errorKey]!;
      if (ahora.difference(ultimoRegistro) < _intervaloMinimo) {
        return; // Omitir log duplicado
      }
    }

    // Actualizar registro de último error
    _ultimosErrores[errorKey] = ahora;

    // Limpiar entradas antiguas para evitar memory leaks
    if (_ultimosErrores.length > 20) {
      final keysToRemove = _ultimosErrores.entries
          .toList()
          .sublist(0, _ultimosErrores.length - 10)
          .map((e) => e.key);
      for (var key in keysToRemove) {
        _ultimosErrores.remove(key);
      }
    }

    // Registrar el error
    AppLogger.error(mensaje, error, stack);
  }
}

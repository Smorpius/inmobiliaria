import 'components/detail_row.dart';
import 'package:flutter/material.dart';
import 'components/inmueble_header.dart';
import 'components/inmueble_basic_info.dart';
import 'components/inmueble_price_info.dart';
import 'components/inmueble_address_info.dart';
import 'components/cliente_asociado_info.dart';
import 'components/inmueble_action_buttons.dart';
import 'components/inmueble_detalle_notifier.dart';
import 'components/inmueble_operation_buttons.dart';
import 'components/clientes_interesados_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/models/inmueble_model.dart';
import 'package:inmobiliaria/widgets/async_value_widget.dart';
import 'package:inmobiliaria/providers/cliente_providers.dart';
import 'package:inmobiliaria/widgets/inmueble_financiero_info.dart';
import 'package:inmobiliaria/models/clientes_interesados_state.dart';
import 'package:inmobiliaria/widgets/inmueble_imagenes_section.dart';
import 'package:inmobiliaria/vistas/ventas/registrar_venta_screen.dart';

class InmuebleDetailScreen extends ConsumerWidget {
  // Constantes para los estados del inmueble usando lowerCamelCase
  static const int estadoNoDisponible = 2;
  static const int estadoDisponible = 3;
  static const int estadoVendido = 4;
  static const int estadoRentado = 5;
  static const int estadoEnNegociacion = 6;

  // Mapeo de estados a nombres para facilitar acceso
  static const Map<int, String> nombresEstados = {
    estadoNoDisponible: 'No Disponible',
    estadoDisponible: 'Disponible',
    estadoVendido: 'Vendido',
    estadoRentado: 'Rentado',
    estadoEnNegociacion: 'En Negociación',
  };

  // Mapeo de estados a colores
  static const Map<int, Color> coloresEstados = {
    estadoNoDisponible: Colors.red,
    estadoDisponible: Colors.green,
    estadoVendido: Colors.blue,
    estadoRentado: Colors.orange,
    estadoEnNegociacion: Colors.purple,
  };

  final Inmueble inmuebleInicial;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isInactivo;
  final String? botonEstadoTexto;
  final Color? botonEstadoColor;

  const InmuebleDetailScreen({
    super.key,
    required this.inmuebleInicial,
    required this.onEdit,
    required this.onDelete,
    this.isInactivo = false,
    this.botonEstadoTexto,
    this.botonEstadoColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inmuebleAsync =
        inmuebleInicial.id != null
            ? ref.watch(inmuebleDetalleProvider(inmuebleInicial.id!))
            : AsyncValue.data(inmuebleInicial);

    return Scaffold(
      appBar: AppBar(
        title: Text(inmuebleInicial.nombre),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar información',
            onPressed: () {
              if (inmuebleInicial.id != null) {
                ref.invalidate(inmuebleDetalleProvider(inmuebleInicial.id!));
              }
            },
          ),
        ],
      ),
      body: AsyncValueWidget<Inmueble>(
        value: inmuebleAsync,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        errorWidget:
            (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar detalles: $error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (inmuebleInicial.id != null) {
                        ref.invalidate(
                          inmuebleDetalleProvider(inmuebleInicial.id!),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
        data: (inmueble) {
          final currentIsInactivo =
              inmueble.idEstado == estadoNoDisponible || isInactivo;
          final isInNegotiation = inmueble.idEstado == estadoEnNegociacion;

          final textoBotonEstado =
              botonEstadoTexto ??
              (currentIsInactivo
                  ? 'Marcar Disponible'
                  : 'Marcar No Disponible');

          final colorBotonEstado =
              botonEstadoColor ??
              (currentIsInactivo ? Colors.green : Colors.red);

          return Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 4,
            color: currentIsInactivo ? Colors.grey.shade50 : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado con nombre del inmueble
                  InmuebleHeader(
                    inmueble: inmueble,
                    isInactivo: currentIsInactivo,
                  ),

                  // Sección de imágenes del inmueble
                  if (inmueble.id != null)
                    InmuebleImagenesSection(
                      inmuebleId: inmueble.id!,
                      isInactivo: currentIsInactivo,
                    ),

                  const Divider(height: 40),

                  // Información básica del inmueble
                  InmuebleBasicInfo(
                    inmueble: inmueble,
                    isInactivo: currentIsInactivo,
                  ),

                  // Información de precios
                  InmueblePriceInfo(
                    inmueble: inmueble,
                    isInactivo: currentIsInactivo,
                  ),

                  // Información financiera si está disponible
                  if (inmueble.costoCliente != null ||
                      inmueble.costoServicios != null)
                    InmuebleFinancieroInfo(
                      inmueble: inmueble,
                      isInactivo: currentIsInactivo,
                    ),

                  const Divider(height: 40),

                  // Dirección completa y sus componentes
                  InmuebleAddressInfo(
                    inmueble: inmueble,
                    isInactivo: currentIsInactivo,
                  ),

                  // Características del inmueble si existen
                  if (inmueble.caracteristicas != null &&
                      inmueble.caracteristicas!.isNotEmpty)
                    DetailRow(
                      label: 'Características',
                      value: inmueble.caracteristicas!,
                      icon: Icons.list_alt,
                      isInactivo: currentIsInactivo,
                    ),

                  const Divider(height: 40),

                  // Información del cliente asociado
                  if (inmueble.idCliente != null && inmueble.id != null)
                    ClienteAsociadoInfo(
                      idInmueble: inmueble.id!,
                      idCliente: inmueble.idCliente!,
                      isInactivo: currentIsInactivo,
                      onClienteDesasociado: () {
                        // Recargar el detalle del inmueble
                        if (inmueble.id != null) {
                          ref.invalidate(inmuebleDetalleProvider(inmueble.id!));
                        }
                      },
                    ),

                  // ID de empleado responsable
                  if (inmueble.idEmpleado != null)
                    DetailRow(
                      label: 'Empleado responsable',
                      value: 'ID: ${inmueble.idEmpleado}',
                      icon: Icons.person,
                      isInactivo: currentIsInactivo,
                    ),

                  // Clientes interesados
                  if (inmueble.id != null)
                    ClientesInteresadosSection(
                      idInmueble: inmueble.id!,
                      isInactivo: currentIsInactivo,
                    ),

                  const SizedBox(height: 24),

                  // Botones de operación específicos (vender/rentar/servicio)
                  if (inmueble.id != null && !currentIsInactivo)
                    InmuebleOperationButtons(
                      inmueble: inmueble,
                      isInNegotiation: isInNegotiation,
                      onOperationSelected:
                          (operationType) => _iniciarOperacion(
                            context,
                            ref,
                            inmueble,
                            operationType,
                          ),
                      onFinishProcess:
                          isInNegotiation
                              ? () => _finalizarProceso(context, ref, inmueble)
                              : null,
                    ),

                  if (inmueble.id != null && !currentIsInactivo)
                    const SizedBox(height: 24),

                  // Botones de acción generales
                  InmuebleActionButtons(
                    onEdit: onEdit,
                    onDelete: onDelete,
                    isInactivo: currentIsInactivo,
                    deleteButtonText: textoBotonEstado,
                    deleteButtonColor: colorBotonEstado,
                    showAddClienteInteresado:
                        !currentIsInactivo && inmueble.id != null,
                    onAddClienteInteresado:
                        inmueble.id != null
                            ? () => _mostrarDialogoAgregarClienteInteresado(
                                  context,
                                  ref,
                                  inmueble.id!,
                                )
                            : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Método mejorado para verificar si una transición de estado es válida
  bool _esTransicionValida(int estadoActual, int nuevoEstado) {
    // Definir las transiciones válidas en una estructura de datos
    final Map<int, List<int>> transicionesValidas = {
      estadoDisponible: [estadoNoDisponible, estadoEnNegociacion],
      estadoNoDisponible: [estadoDisponible],
      estadoEnNegociacion: [estadoDisponible, estadoVendido, estadoRentado],
      estadoVendido: [estadoDisponible],
      estadoRentado: [estadoDisponible],
    };
    
    // Verificar si la transición está en la lista de transiciones válidas
    return transicionesValidas.containsKey(estadoActual) && 
           transicionesValidas[estadoActual]!.contains(nuevoEstado);
  }

  // Método para mostrar diálogo para agregar cliente interesado
  Future<void> _mostrarDialogoAgregarClienteInteresado(
    BuildContext context,
    WidgetRef ref,
    int idInmueble,
  ) async {
    // Mostrar el diálogo de selección de cliente
    final clientesAsyncValue = ref.watch(clientesProvider);
    
    if (clientesAsyncValue is AsyncLoading) {
      return; // Evitar mostrar diálogo si aún está cargando
    }
    
    if (clientesAsyncValue is AsyncError) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar clientes: ${clientesAsyncValue.error}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final clientes = clientesAsyncValue.value ?? [];
    
    if (clientes.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay clientes disponibles para agregar como interesados'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Variables para el diálogo
    int? clienteSeleccionado;
    final comentariosController = TextEditingController();
    
    final resultado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar Cliente Interesado'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Seleccione un cliente:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: clienteSeleccionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Seleccionar cliente'),
                      items: clientes.map((cliente) {
                        final nombreCompleto = '${cliente.nombre} ${cliente.apellidoPaterno} ${cliente.apellidoMaterno ?? ''}';
                        return DropdownMenuItem<int>(
                          value: cliente.id,
                          child: Text(nombreCompleto.trim()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          clienteSeleccionado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Comentarios (opcional):'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: comentariosController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Agregar comentarios sobre el interés del cliente...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: clienteSeleccionado == null
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    // Procesar el resultado del diálogo
    if (resultado == true && clienteSeleccionado != null && context.mounted) {
      try {
        // Registrar el cliente interesado
        final notifier = ref.read(clientesInteresadosStateProvider(idInmueble).notifier);
        final success = await notifier.registrarClienteInteresado(
          clienteSeleccionado!,
          comentariosController.text.isEmpty ? null : comentariosController.text,
        );

        if (!context.mounted) return;
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente agregado como interesado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo agregar el cliente como interesado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar cliente interesado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    // Liberar recursos
    comentariosController.dispose();
  }

  // Método para iniciar una operación (venta/renta/servicio)
  Future<void> _iniciarOperacion(
    BuildContext context,
    WidgetRef ref,
    Inmueble inmueble,
    String operationType,
  ) async {
    if (inmueble.id == null) return;

    // Verificar si el inmueble ya está en el estado correcto
    if (inmueble.idEstado == estadoEnNegociacion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El inmueble ya está en negociación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Verificar si el estado actual permite la transición
    if (!_esTransicionValida(
      inmueble.idEstado ?? estadoDisponible,
      estadoEnNegociacion,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se puede iniciar $operationType desde el estado actual: ${nombresEstados[inmueble.idEstado]}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        String operationTitle = '';
        String operationMessage = '';

        switch (operationType) {
          case 'venta':
            operationTitle = 'Iniciar venta';
            operationMessage =
                '¿Desea iniciar el proceso de venta para este inmueble? El inmueble pasará a estado "En negociación".';
            break;
          case 'renta':
            operationTitle = 'Iniciar renta';
            operationMessage =
                '¿Desea iniciar el proceso de renta para este inmueble? El inmueble pasará a estado "En negociación".';
            break;
          case 'servicio':
            operationTitle = 'Agregar servicio';
            operationMessage =
                '¿Desea agregar un servicio para este inmueble? El inmueble pasará a estado "En negociación".';
            break;
          default:
            operationTitle = 'Iniciar operación';
            operationMessage =
                '¿Confirma que desea iniciar esta operación? El inmueble pasará a estado "En negociación".';
        }

        return AlertDialog(
          title: Text(operationTitle),
          content: Text(operationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      // Cambiar estado a "En negociación"
      if (inmueble.id != null) {
        final notifier = ref.read(
          inmuebleDetalleProvider(inmueble.id!).notifier,
        );
        await notifier.actualizarEstado(estadoEnNegociacion);

        // Verificar si el contexto todavía está montado
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Inmueble en proceso de ${operationType == 'servicio' ? 'servicio' : operationType}',
            ),
            backgroundColor: Colors.blue,
          ),
        );

        // Si es venta, podríamos navegar a la pantalla de registro de venta
        if (operationType == 'venta') {
          // Verificar si el contexto todavía está montado
          if (!context.mounted) return;

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrarVentaScreen(inmueble: inmueble),
            ),
          );
          
          if (result == true && inmueble.id != null && context.mounted) {
            ref.invalidate(inmuebleDetalleProvider(inmueble.id!));
          }
        }
      }
    } catch (e) {
      // Verificar si el contexto todavía está montado
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cambiar estado de ${inmueble.nombre} a $operationType: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para finalizar el proceso de negociación
  Future<void> _finalizarProceso(
    BuildContext context,
    WidgetRef ref,
    Inmueble inmueble,
  ) async {
    if (inmueble.id == null) return;

    // Verificar que estamos en estado de negociación
    if (inmueble.idEstado != estadoEnNegociacion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo se puede finalizar el proceso cuando el inmueble está en negociación',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Evaluar qué estados finales son válidos según el tipo de operación
    List<int> estadosFinalesPermitidos = [
      estadoDisponible,
    ]; // Siempre se puede volver a disponible
    
    String tipoOperacion = inmueble.tipoOperacion;

    if (tipoOperacion == 'venta' || tipoOperacion == 'ambos') {
      estadosFinalesPermitidos.add(estadoVendido);
    }

    if (tipoOperacion == 'renta' || tipoOperacion == 'ambos') {
      estadosFinalesPermitidos.add(estadoRentado);
    }

    // Mostrar diálogo con opciones para finalizar el proceso
    final estadoFinal = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Finalizar proceso'),
          content: const Text('Seleccione el estado final del inmueble:'),
          actions: [
            // Botón para cancelar
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            // Botón para marcar como vendido
            if (estadosFinalesPermitidos.contains(estadoVendido))
              ElevatedButton.icon(
                icon: const Icon(Icons.sell, size: 18),
                label: const Text('Vendido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(estadoVendido),
              ),
            // Botón para marcar como rentado
            if (estadosFinalesPermitidos.contains(estadoRentado))
              ElevatedButton.icon(
                icon: const Icon(Icons.home, size: 18),
                label: const Text('Rentado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(estadoRentado),
              ),
            // Botón para volver a disponible
            ElevatedButton.icon(
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Disponible'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(estadoDisponible),
            ),
          ],
        );
      },
    );

    // Si no se seleccionó ningún estado, salir
    if (estadoFinal == null) return;

    // Verificar que la opción seleccionada es válida
    if (!estadosFinalesPermitidos.contains(estadoFinal)) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: No se puede cambiar a ${nombresEstados[estadoFinal]} con tipo de operación "$tipoOperacion"',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Cambiar al estado seleccionado
      if (inmueble.id != null) {
        final notifier = ref.read(
          inmuebleDetalleProvider(inmueble.id!).notifier,
        );
        await notifier.actualizarEstado(estadoFinal);

        // Verificar si el contexto todavía está montado
        if (!context.mounted) return;

        // Mostrar mensaje según el estado seleccionado
        String mensaje;
        switch (estadoFinal) {
          case estadoVendido:
            mensaje = 'Inmueble marcado como Vendido';
            break;
          case estadoRentado:
            mensaje = 'Inmueble marcado como Rentado';
            break;
          case estadoDisponible:
            mensaje = 'Inmueble marcado como Disponible';
            break;
          default:
            mensaje = 'Estado del inmueble actualizado';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: coloresEstados[estadoFinal] ?? Colors.blue,
          ),
        );
      }
    } catch (e) {
      // Verificar si el contexto todavía está montado
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al finalizar proceso: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
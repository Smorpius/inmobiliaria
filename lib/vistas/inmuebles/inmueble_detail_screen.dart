import 'components/detail_row.dart';
import 'package:flutter/material.dart';
import 'components/inmueble_header.dart';
import '../../models/inmueble_model.dart';
import 'components/inmueble_basic_info.dart';
import 'components/inmueble_price_info.dart';
import '../../widgets/async_value_widget.dart';
import 'components/inmueble_address_info.dart';
import 'components/cliente_asociado_info.dart';
import 'components/inmueble_action_buttons.dart';
import 'components/inmueble_detalle_notifier.dart';
import 'components/inmueble_operation_buttons.dart';
import 'components/clientes_interesados_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/widgets/inmueble_financiero_info.dart';
import 'package:inmobiliaria/widgets/inmueble_imagenes_section.dart';
import 'package:inmobiliaria/vistas/ventas/registrar_venta_screen.dart';

class InmuebleDetailScreen extends ConsumerWidget {
  final Inmueble inmuebleInicial;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isInactivo;
  // Parámetros para el botón de estado
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
    // Si el inmueble tiene ID, usamos el StateNotifierProvider para su gestión,
    // de lo contrario usamos el inmueble inicial
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
          final currentIsInactivo = inmueble.idEstado == 2 || isInactivo;
          final isInNegotiation =
              inmueble.idEstado == 6; // Estado de negociación

          // Determinar el texto del botón usando el valor proporcionado o un valor predeterminado
          final textoBotonEstado =
              botonEstadoTexto ??
              (currentIsInactivo
                  ? 'Marcar Disponible'
                  : 'Marcar No Disponible');

          // Determinar el color del botón usando el valor proporcionado o un valor predeterminado
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
                    // Pasar los valores personalizados
                    deleteButtonText: textoBotonEstado,
                    deleteButtonColor: colorBotonEstado,
                    // Mostrar botón de cliente interesado si es necesario
                    showAddClienteInteresado:
                        !currentIsInactivo && inmueble.id != null,
                    onAddClienteInteresado:
                        inmueble.id != null
                            ? () {
                              // Implementar la función para agregar cliente interesado
                            }
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

  // Método para iniciar una operación (venta/renta/servicio)
  Future<void> _iniciarOperacion(
    BuildContext context,
    WidgetRef ref,
    Inmueble inmueble,
    String operationType,
  ) async {
    if (inmueble.id == null) return;

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
      // Cambiar estado a "En negociación" (id=6)
      if (inmueble.id != null) {
        final notifier = ref.read(
          inmuebleDetalleProvider(inmueble.id!).notifier,
        );
        await notifier.actualizarEstado(6); // Cambiar a estado "En negociación"

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

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrarVentaScreen(inmueble: inmueble),
            ),
          ).then((value) {
            if (value == true && inmueble.id != null) {
              ref.invalidate(inmuebleDetalleProvider(inmueble.id!));
            }
          });
        }
      }
    } catch (e) {
      // Verificar si el contexto todavía está montado
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: $e'),
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
            if (inmueble.tipoOperacion == 'venta' ||
                inmueble.tipoOperacion == 'ambos')
              ElevatedButton.icon(
                icon: const Icon(Icons.sell, size: 18),
                label: const Text('Vendido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    () => Navigator.of(context).pop(4), // Estado 4 = Vendido
              ),
            // Botón para marcar como rentado
            if (inmueble.tipoOperacion == 'renta' ||
                inmueble.tipoOperacion == 'ambos')
              ElevatedButton.icon(
                icon: const Icon(Icons.home, size: 18),
                label: const Text('Rentado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    () => Navigator.of(context).pop(5), // Estado 5 = Rentado
              ),
            // Botón para volver a disponible
            ElevatedButton.icon(
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Disponible'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  () => Navigator.of(context).pop(3), // Estado 3 = Disponible
            ),
          ],
        );
      },
    );

    // Si no se seleccionó ningún estado, salir
    if (estadoFinal == null) return;

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
        String mensaje = '';
        Color color = Colors.blue;

        switch (estadoFinal) {
          case 3:
            mensaje = 'Inmueble marcado como Disponible';
            color = Colors.green;
            break;
          case 4:
            mensaje = 'Inmueble marcado como Vendido';
            color = Colors.blue;
            break;
          case 5:
            mensaje = 'Inmueble marcado como Rentado';
            color = Colors.orange;
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: color),
        );
      }
    } catch (e) {
      // Verificar si el contexto todavía está montado
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

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
import 'components/clientes_interesados_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmobiliaria/widgets/inmueble_imagenes_section.dart';

class InmuebleDetailScreen extends ConsumerWidget {
  final Inmueble inmuebleInicial;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isInactivo;

  const InmuebleDetailScreen({
    super.key,
    required this.inmuebleInicial,
    required this.onEdit,
    required this.onDelete,
    this.isInactivo = false,
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
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: InmuebleImagenesSection(
                        inmuebleId: inmueble.id!,
                        isInactivo: currentIsInactivo,
                      ),
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
                      icon: Icons.badge,
                      isInactivo: currentIsInactivo,
                    ),

                  // Sección de clientes interesados
                  if (inmueble.id != null && inmueble.idEstado == 6)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: ClientesInteresadosSection(
                        idInmueble: inmueble.id!,
                        isInactivo: currentIsInactivo,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Botones de acción
                  InmuebleActionButtons(
                    onEdit: onEdit,
                    onDelete: onDelete,
                    isInactivo: currentIsInactivo,
                    showAddClienteInteresado: false,
                    onAddClienteInteresado: null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

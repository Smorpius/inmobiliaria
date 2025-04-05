import 'dart:io';
import 'package:flutter/material.dart';
import '../models/contrato_generado_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/contratos_generados_provider.dart';

/// Widget para mostrar los contratos generados (para venta o renta)
class ContratosGeneradosWidget extends ConsumerWidget {
  final String tipoContrato; // 'venta' o 'renta'
  final int idReferencia; // ID de la venta o contrato de renta
  final bool esSoloLectura;
  final VoidCallback? onGenerarNuevo;

  const ContratosGeneradosWidget({
    super.key,
    required this.tipoContrato,
    required this.idReferencia,
    this.esSoloLectura = false,
    this.onGenerarNuevo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contratosProvider =
        tipoContrato == 'venta'
            ? contratosGeneradosVentaProvider(idReferencia)
            : contratosGeneradosRentaProvider(idReferencia);

    final contratosAsyncValue = ref.watch(contratosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Documentos de Contrato',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (!esSoloLectura && onGenerarNuevo != null)
                ElevatedButton(
                  onPressed: onGenerarNuevo,
                  child: const Text('Generar Nuevo Contrato'),
                ),
            ],
          ),
        ),
        Expanded(
          child: contratosAsyncValue.when(
            data: (contratos) {
              if (contratos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay documentos de contrato registrados',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      if (!esSoloLectura && onGenerarNuevo != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: ElevatedButton(
                            onPressed: onGenerarNuevo,
                            child: const Text('Generar Contrato'),
                          ),
                        ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: contratos.length,
                itemBuilder: (context, index) {
                  final contrato = contratos[index];
                  return _ContratoGeneradoItem(
                    contrato: contrato,
                    onVer: () => _abrirContrato(context, contrato),
                    onEliminar:
                        esSoloLectura
                            ? null
                            : () => _confirmarEliminarContrato(
                              context,
                              ref,
                              contrato,
                            ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar contratos: $error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final _ = ref.refresh(contratosProvider);
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _abrirContrato(
    BuildContext context,
    ContratoGenerado contrato,
  ) async {
    // Verificar si el archivo existe
    final file = File(contrato.rutaArchivo);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El archivo del contrato no se encuentra en el sistema',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Aquí se implementaría la lógica para abrir el documento
    // Esto podría usar plugins como url_launcher, flutter_pdfview, etc.

    // Por ahora mostramos un diálogo simulando la apertura
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Contrato ${contrato.version}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ruta: ${contrato.rutaArchivo}'),
                const SizedBox(height: 8),
                Text(
                  'Registrado por: ${contrato.nombreUsuario ?? 'Usuario desconocido'}',
                ),
                const SizedBox(height: 8),
                Text('Fecha: ${contrato.fechaRegistro}'),
                const SizedBox(height: 16),
                const Text(
                  'Para implementar la visualización del documento, '
                  'se recomienda usar flutter_pdfview u otro plugin compatible.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Future<void> _confirmarEliminarContrato(
    BuildContext context,
    WidgetRef ref,
    ContratoGenerado contrato,
  ) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar contrato'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este contrato? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmacion == true) {
      final service = ref.read(contratoGeneradoServiceProvider);

      try {
        // Ensure null safety by checking for valid id
        final int contratoId = contrato.id ?? 0;
        if (contratoId <= 0) {
          throw Exception('ID de contrato inválido');
        }

        final eliminado = await service.eliminarContrato(contratoId);

        // No usar context después de una operación asíncrona sin verificar que esté montado
        if (!context.mounted) return;

        if (eliminado) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contrato eliminado correctamente')),
          );
          // Refrescar la lista de contratos
          if (tipoContrato == 'venta') {
            final _ = ref.refresh(
              contratosGeneradosVentaProvider(idReferencia),
            );
          } else {
            final _ = ref.refresh(
              contratosGeneradosRentaProvider(idReferencia),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo eliminar el contrato'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar contrato: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ContratoGeneradoItem extends StatelessWidget {
  final ContratoGenerado contrato;
  final VoidCallback onVer;
  final VoidCallback? onEliminar;

  const _ContratoGeneradoItem({
    required this.contrato,
    required this.onVer,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final bool esPDF = contrato.rutaArchivo.toLowerCase().endsWith('.pdf');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          esPDF ? Icons.picture_as_pdf : Icons.insert_drive_file,
          color: esPDF ? Colors.red : Colors.blue,
          size: 36,
        ),
        title: Text('Versión ${contrato.version}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fecha: ${contrato.fechaRegistro}'),
            Text(
              'Registrado por: ${contrato.nombreUsuario ?? 'Usuario desconocido'}',
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contrato.esUltimaVersion ?? false)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Tooltip(
                  message: 'Última versión',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Actual',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: onVer,
              tooltip: 'Ver contrato',
            ),
            if (onEliminar != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onEliminar,
                tooltip: 'Eliminar contrato',
                color: Colors.red,
              ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onVer,
      ),
    );
  }
}

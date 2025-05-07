import 'dart:io';
import '../../utils/applogger.dart';
import '../../utils/responsive.dart';
import 'widgets/documento_card.dart';
import 'package:flutter/material.dart';
import 'documento_detalle_screen.dart';
import '../../models/documento_model.dart';
import 'widgets/filtro_documentos_widget.dart';
import '../../providers/documento_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_colors.dart'; // Importamos la paleta de colores

class DocumentosScreen extends ConsumerStatefulWidget {
  const DocumentosScreen({super.key});

  @override
  ConsumerState<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends ConsumerState<DocumentosScreen> {
  DocumentoFiltro _filtro = DocumentoFiltro();
  bool _mostrarFiltros = false;

  @override
  Widget build(BuildContext context) {
    final documentosAsync = ref.watch(documentosProvider);
    final documentosFiltrados = ref.watch(documentosFiltradosProvider(_filtro));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos'),
        backgroundColor: AppColors.claro, // Usar AppColors
        foregroundColor: AppColors.primario, // Usar AppColors
        actions: [
          IconButton(
            icon: Icon(
              _mostrarFiltros ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() {
                _mostrarFiltros = !_mostrarFiltros;
              });
            },
            tooltip: _mostrarFiltros ? 'Ocultar filtros' : 'Mostrar filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Capturar el resultado devuelto y usarlo o ignorarlo explícitamente
              final _ = ref.refresh(documentosProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Actualizando documentos...')),
              );
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sección de filtros (expandible)
          if (_mostrarFiltros)
            FiltroDocumentosWidget(
              filtro: _filtro,
              onFiltroChanged: (nuevoFiltro) {
                setState(() {
                  _filtro = nuevoFiltro;
                });
              },
            ),

          // Resultados
          Expanded(
            child: documentosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar documentos',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          onPressed: () => ref.refresh(documentosProvider),
                        ),
                      ],
                    ),
                  ),
              data: (documentos) {
                if (documentos.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay documentos disponibles',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Agrega documentos con el botón + abajo',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (documentosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay resultados para esta búsqueda',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.clear),
                          label: const Text('Limpiar filtros'),
                          onPressed: () {
                            setState(() {
                              _filtro = DocumentoFiltro();
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }

                return _buildDocumentosGrid(documentosFiltrados);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _seleccionarDocumento,
        backgroundColor: AppColors.primario, // Usar AppColors
        child: const Icon(Icons.add, color: AppColors.claro), // Usar AppColors
      ),
    );
  }

  Widget _buildDocumentosGrid(List<Documento> documentos) {
    final responsive = Responsive.of(context);
    final crossAxisCount =
        responsive.isDesktop
            ? 4
            : responsive.isTablet
            ? 3
            : 2;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: documentos.length,
        itemBuilder: (context, index) {
          final documento = documentos[index];
          return DocumentoCard(
            documento: documento,
            onTap: () => _abrirDocumento(documento),
            onDelete: () => _confirmarEliminarDocumento(documento),
          );
        },
      ),
    );
  }

  Future<void> _seleccionarDocumento() async {
    try {
      final typeGroup = XTypeGroup(
        label: 'Documentos',
        extensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        final File fileIO = File(file.path);
        final filename = file.name;

        final tipoDocumento = await _mostrarDialogoTipoDocumento();
        if (tipoDocumento == null) return;

        final categoria = await _mostrarDialogoCategoria(tipoDocumento);
        if (categoria == null) return;

        final descripcion = await _mostrarDialogoDescripcion();
        if (descripcion == null) return;

        // Mostrar indicador de carga
        if (!mounted) return;
        _mostrarCargando(context);

        // Subir documento
        final documento = await ref
            .read(documentoServiceProvider)
            .subirDocumento(
              archivo: fileIO,
              tipoDocumento: tipoDocumento,
              categoria: categoria,
              descripcion: descripcion.isEmpty ? null : descripcion,
              nombrePersonalizado: filename,
            );

        // Cerrar diálogo de carga
        if (!mounted) return;
        Navigator.of(context).pop();

        if (documento != null) {
          // Refrescar lista de documentos
          final _ = ref.refresh(documentosProvider);

          // Mostrar mensaje de éxito
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento subido correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Mostrar mensaje de error
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al subir el documento'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stack) {
      AppLogger.error('Error al seleccionar documento', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarCargando(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Subiendo documento...'),
              ],
            ),
          ),
    );
  }

  Future<String?> _mostrarDialogoTipoDocumento() {
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tipo de documento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: const Text('Contrato'),
                  onTap: () => Navigator.of(context).pop('contrato'),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Comprobante'),
                  onTap: () => Navigator.of(context).pop('comprobante'),
                ),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Reporte'),
                  onTap: () => Navigator.of(context).pop('reporte'),
                ),
                ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: const Text('Otro'),
                  onTap: () => Navigator.of(context).pop('documento'),
                ),
              ],
            ),
          ),
    );
  }

  Future<String?> _mostrarDialogoCategoria(String tipoDocumento) {
    late final List<Map<String, String>> opciones;

    if (tipoDocumento == 'contrato') {
      opciones = [
        {'id': 'venta', 'nombre': 'Venta'},
        {'id': 'renta', 'nombre': 'Renta'},
      ];
    } else if (tipoDocumento == 'comprobante') {
      opciones = [
        {'id': 'venta', 'nombre': 'Venta'},
        {'id': 'renta', 'nombre': 'Renta'},
        {'id': 'movimiento', 'nombre': 'Movimiento'},
      ];
    } else if (tipoDocumento == 'reporte') {
      opciones = [
        {'id': 'estadística', 'nombre': 'Estadística'},
        {'id': 'venta', 'nombre': 'Ventas'},
        {'id': 'renta', 'nombre': 'Rentas'},
      ];
    } else {
      opciones = [
        {'id': 'general', 'nombre': 'General'},
      ];
    }

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Categoría'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    opciones.map((opcion) {
                      return ListTile(
                        title: Text(opcion['nombre']!),
                        onTap: () => Navigator.of(context).pop(opcion['id']),
                      );
                    }).toList(),
              ),
            ),
          ),
    );
  }

  Future<String?> _mostrarDialogoDescripcion() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Descripción (opcional)'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Ingresa una descripción para el documento',
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
  }

  void _abrirDocumento(Documento documento) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentoDetalleScreen(documento: documento),
      ),
    );
  }

  Future<void> _confirmarEliminarDocumento(Documento documento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Estás seguro de que deseas eliminar "${documento.nombre}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmar == true && mounted) {
      try {
        final resultado = await ref
            .read(documentoServiceProvider)
            .eliminarDocumento(documento);

        if (resultado && mounted) {
          // Refrescar lista de documentos
          final _ = ref.refresh(documentosProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

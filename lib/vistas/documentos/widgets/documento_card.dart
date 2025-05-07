import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import '../../../utils/archivo_utils.dart';
import '../../../models/documento_model.dart';
import '../../../utils/app_colors.dart'; // Importamos la paleta de colores

class DocumentoCard extends StatefulWidget {
  final Documento documento;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const DocumentoCard({
    super.key,
    required this.documento,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<DocumentoCard> createState() => _DocumentoCardState();
}

class _DocumentoCardState extends State<DocumentoCard> {
  bool _isHovering = false;
  File? _archivoLocal;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarArchivoPreview();
  }

  Future<void> _cargarArchivoPreview() async {
    try {
      setState(() => _cargando = true);
      final rutaCompleta = await ArchivoUtils.obtenerRutaCompleta(
        widget.documento.rutaArchivo,
      );
      final archivo = File(rutaCompleta);

      if (await archivo.exists()) {
        setState(() {
          _archivoLocal = archivo;
          _cargando = false;
        });
      } else {
        setState(() => _cargando = false);
      }
    } catch (e) {
      AppLogger.warning('Error al cargar preview: ${e.toString()}');
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: _isHovering ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Vista previa o icono
                  Expanded(flex: 3, child: _buildPreview()),

                  // Información del documento
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.documento.nombre,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.oscuro, // Usar AppColors
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy',
                            ).format(widget.documento.fechaCreacion),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.withAlpha(
                                AppColors.oscuro,
                                180,
                              ), // Usar AppColors con alpha
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              _buildTipoChip(),
                              const Spacer(),
                              if (widget.documento.extension.isNotEmpty)
                                Text(
                                  widget.documento.extension
                                      .toUpperCase()
                                      .substring(1),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.primario, // Usar AppColors
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isHovering && widget.onDelete != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.withAlpha(
                        AppColors.oscuro,
                        140,
                      ), // Usar AppColors con alpha
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.claro, // Usar AppColors
                      ),
                      iconSize: 20,
                      onPressed: widget.onDelete,
                      tooltip: 'Eliminar documento',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_cargando) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primario, // Usar AppColors
        ),
      );
    }

    if (widget.documento.isImage && _archivoLocal != null) {
      return Container(
        color: AppColors.withAlpha(
          AppColors.grisClaro,
          100,
        ), // Usar AppColors con alpha
        child: Image.file(
          _archivoLocal!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildIconPreview(),
        ),
      );
    }

    return _buildIconPreview();
  }

  Widget _buildIconPreview() {
    final Color color = _getColorForDocumentType(
      widget.documento.tipoDocumento,
    );

    return Container(
      color: AppColors.withAlpha(
        color,
        25,
      ), // Usar AppColors.withAlpha en lugar de withAlpha directo
      child: Center(
        child: Icon(widget.documento.icono, size: 48, color: color),
      ),
    );
  }

  Widget _buildTipoChip() {
    final Map<String, Color> tipoColores = {
      'contrato': AppColors.info, // Usar AppColors
      'comprobante': AppColors.exito, // Usar AppColors
      'reporte': AppColors.advertencia, // Usar AppColors
    };

    final color =
        tipoColores[widget.documento.tipoDocumento] ??
        AppColors.grisClaro; // Usar AppColors

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.withAlpha(color, 25), // Usar AppColors.withAlpha
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        widget.documento.tipoDocumento.capitalize(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColorForDocumentType(String tipo) {
    switch (tipo) {
      case 'contrato':
        return AppColors.info; // Usar AppColors
      case 'comprobante':
        return AppColors.exito; // Usar AppColors
      case 'reporte':
        return AppColors.advertencia; // Usar AppColors
      default:
        return AppColors.grisClaro; // Usar AppColors
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

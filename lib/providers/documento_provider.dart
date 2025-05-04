import '../models/documento_model.dart';
import '../services/documento_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final documentoServiceProvider = Provider<DocumentoService>((ref) {
  return DocumentoService();
});

final documentosProvider = FutureProvider<List<Documento>>((ref) async {
  final documentoService = ref.read(documentoServiceProvider);
  return await documentoService.obtenerDocumentos();
});

final documentosFiltradosProvider =
    Provider.family<List<Documento>, DocumentoFiltro>((ref, filtro) {
      final documentosAsync = ref.watch(documentosProvider);

      return documentosAsync.when(
        loading: () => [],
        error: (_, __) => [],
        data: (documentos) {
          if (filtro.isEmpty) return documentos;

          return documentos.where((doc) {
            // Filtrar por búsqueda
            if (filtro.terminoBusqueda.isNotEmpty) {
              final termino = filtro.terminoBusqueda.toLowerCase();
              if (!doc.nombre.toLowerCase().contains(termino) &&
                  !(doc.descripcion?.toLowerCase().contains(termino) ??
                      false)) {
                return false;
              }
            }

            // Filtrar por tipo
            if (filtro.tipoDocumento != null &&
                doc.tipoDocumento != filtro.tipoDocumento) {
              return false;
            }

            // Filtrar por categoría
            if (filtro.categoria != null && doc.categoria != filtro.categoria) {
              return false;
            }

            // Filtrar favoritos
            if (filtro.soloFavoritos && !doc.esFavorito) {
              return false;
            }

            return true;
          }).toList();
        },
      );
    });

class DocumentoFiltro {
  final String terminoBusqueda;
  final String? tipoDocumento;
  final String? categoria;
  final bool soloFavoritos;

  DocumentoFiltro({
    this.terminoBusqueda = '',
    this.tipoDocumento,
    this.categoria,
    this.soloFavoritos = false,
  });

  bool get isEmpty =>
      terminoBusqueda.isEmpty &&
      tipoDocumento == null &&
      categoria == null &&
      !soloFavoritos;

  DocumentoFiltro copyWith({
    String? terminoBusqueda,
    String? tipoDocumento,
    String? categoria,
    bool? soloFavoritos,
  }) {
    return DocumentoFiltro(
      terminoBusqueda: terminoBusqueda ?? this.terminoBusqueda,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      categoria: categoria ?? this.categoria,
      soloFavoritos: soloFavoritos ?? this.soloFavoritos,
    );
  }
}

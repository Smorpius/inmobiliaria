import 'package:flutter/material.dart';
import '../../../models/inmueble_model.dart';

/// Widget que muestra la información principal del inmueble en forma de cabecera
///
/// Muestra un avatar, nombre del inmueble y, si está inactivo, un indicador visual.
class InmuebleHeader extends StatelessWidget {
  final Inmueble inmueble;
  final bool isInactivo;

  const InmuebleHeader({
    super.key,
    required this.inmueble,
    required this.isInactivo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 16),
          _buildTitulo(),
          if (isInactivo) _buildIndicadorInactivo(),
        ],
      ),
    );
  }

  /// Construye el avatar con el ícono del inmueble
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundColor:
          isInactivo ? Colors.grey.shade300 : Colors.indigo.shade100,
      child: Icon(
        Icons.home,
        size: 40,
        color: isInactivo ? Colors.grey : Colors.indigo,
      ),
    );
  }

  /// Construye el título con el nombre del inmueble
  Widget _buildTitulo() {
    return Text(
      inmueble.nombre,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        decoration: isInactivo ? TextDecoration.lineThrough : null,
        color: isInactivo ? Colors.grey.shade700 : null,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Construye el indicador de inmueble no disponible
  Widget _buildIndicadorInactivo() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'NO DISPONIBLE',
        style: TextStyle(
          color: Colors.red.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

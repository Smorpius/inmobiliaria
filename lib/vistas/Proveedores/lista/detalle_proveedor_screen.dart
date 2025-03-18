import 'package:flutter/material.dart';
import '../../../models/proveedor.dart';
import '../nuevo_proveedor_screen.dart';
import '../../../utils/dialog_helper.dart';
import '../../../controllers/proveedor_controller.dart';

class DetalleProveedorScreen extends StatefulWidget {
  final Proveedor proveedor;
  final ProveedorController controller;

  const DetalleProveedorScreen({
    super.key,
    required this.proveedor,
    required this.controller,
  });

  @override
  State<DetalleProveedorScreen> createState() => _DetalleProveedorScreenState();
}

class _DetalleProveedorScreenState extends State<DetalleProveedorScreen> {
  late Proveedor proveedor;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    proveedor = widget.proveedor;
  }

  Future<void> _editarProveedor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NuevoProveedorScreen(
              controller: widget.controller,
              proveedorEditar: proveedor,
            ),
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await widget.controller.cargarProveedores();

        // Obtener el proveedor actualizado
        final proveedores = await widget.controller.proveedores.first;
        final proveedorActualizado = proveedores.firstWhere(
          (p) => p.idProveedor == proveedor.idProveedor,
          orElse: () => proveedor,
        );

        setState(() {
          proveedor = proveedorActualizado;
          _isLoading = false;
        });

        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proveedor actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Mostrar mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmarCambiarEstado() async {
    final bool isActivo = proveedor.idEstado == 1;
    final titulo = isActivo ? '¿Inactivar proveedor?' : '¿Reactivar proveedor?';
    final mensaje =
        isActivo
            ? 'El proveedor ya no aparecerá en las listas de proveedores activos.'
            : 'El proveedor volverá a aparecer como activo en el sistema.';
    final textoBoton = isActivo ? 'Inactivar' : 'Reactivar';
    final estilo = TextStyle(color: isActivo ? Colors.red : Colors.green);

    final confirmar = await DialogHelper.confirmarAccion(
      context,
      titulo,
      mensaje,
      textoBoton,
      estilo,
    );

    if (confirmar) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (isActivo) {
          await widget.controller.inactivarProveedor(proveedor.idProveedor!);
        } else {
          await widget.controller.reactivarProveedor(proveedor.idProveedor!);
        }

        // Actualizar el proveedor después de cambiar estado
        await widget.controller.cargarProveedores();
        final proveedores = await widget.controller.proveedores.first;
        final proveedorActualizado = proveedores.firstWhere(
          (p) => p.idProveedor == proveedor.idProveedor,
        );

        setState(() {
          proveedor = proveedorActualizado;
          _isLoading = false;
        });

        if (mounted) {
          final mensaje =
              isActivo
                  ? 'Proveedor inactivado correctamente'
                  : 'Proveedor reactivado correctamente';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al procesar: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Proveedor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editarProveedor,
            tooltip: 'Editar proveedor',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const Divider(height: 30),
                    _buildInfoSection(),
                    const Divider(height: 30),
                    _buildContactoSection(),
                    const Divider(height: 30),
                    _buildServicioSection(),
                    const SizedBox(height: 30),
                    _buildAccionesSection(),
                  ],
                ),
              ),
    );
  }

  Widget _buildHeader() {
    final bool isActive = proveedor.idEstado == 1;

    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor:
              isActive ? Colors.blue.shade100 : Colors.grey.shade300,
          child: Icon(
            Icons.business,
            size: 40,
            color: isActive ? Colors.blue : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                proveedor.nombreEmpresa,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    color: isActive ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información General',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildInfoItem('Nombre', proveedor.nombre),
        _buildInfoItem('Nombre de la Empresa', proveedor.nombreEmpresa),
        _buildInfoItem('Dirección', proveedor.direccion),
      ],
    );
  }

  Widget _buildContactoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de Contacto',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildInfoItem('Nombre del Contacto', proveedor.nombreContacto),
        _buildInfoItem('Teléfono', proveedor.telefono, icon: Icons.phone),
        _buildInfoItem('Correo', proveedor.correo, icon: Icons.email),
      ],
    );
  }

  Widget _buildServicioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Servicio', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildInfoItem(
          'Tipo de Servicio',
          proveedor.tipoServicio,
          icon: Icons.category,
        ),
      ],
    );
  }

  Widget _buildAccionesSection() {
    final bool isActive = proveedor.idEstado == 1;

    return Center(
      child: ElevatedButton.icon(
        onPressed: _confirmarCambiarEstado,
        icon: Icon(isActive ? Icons.cancel : Icons.check_circle),
        label: Text(isActive ? 'Inactivar Proveedor' : 'Reactivar Proveedor'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'No especificado',
              style: TextStyle(
                color: value.isNotEmpty ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

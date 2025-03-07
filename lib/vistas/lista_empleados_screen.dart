import '../widgets/app_scaffold.dart';
import 'detalle_empleado_screen.dart';
import 'package:flutter/material.dart';
import '../models/usuario_empleado.dart';
import '../controllers/usuario_empleado_controller.dart';

class ListaEmpleadosScreen extends StatefulWidget {
  final UsuarioEmpleadoController controller;

  const ListaEmpleadosScreen({super.key, required this.controller});

  @override
  State<ListaEmpleadosScreen> createState() => _ListaEmpleadosScreenState();
}

class _ListaEmpleadosScreenState extends State<ListaEmpleadosScreen> {
  List<UsuarioEmpleado> _empleados = [];
  bool _isLoading = false;
  bool _mostrarInactivos = false;

  @override
  void initState() {
    super.initState();
    _cargarEmpleados();
  }

  Future<void> _cargarEmpleados() async {
    setState(() => _isLoading = true);

    try {
      // Ajuste: se elimina la asignación con 'final empleados = ...'
      // si la función cargarEmpleados() retorna void.
      // Si el controlador guarda la lista internamente, se puede recuperar así:
      await widget.controller.cargarEmpleados();

      if (mounted) {
        setState(() {
          // Suponiendo que el controlador exponga los empleados cargados
          // en una propiedad pública llamada 'empleados'.
          _empleados = widget.controller.empleados as List<UsuarioEmpleado>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar empleados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final empleadosFiltrados =
        _mostrarInactivos
            ? _empleados
            : _empleados.where((e) => e.empleado.idEstado == 1).toList();

    return AppScaffold(
      title: 'Gestión de Empleados',
      currentRoute: '/empleados',
      actions: [
        Row(
          children: [
            const Text(
              "Mostrar inactivos",
              style: TextStyle(color: Colors.teal),
            ),
            Switch(
              value: _mostrarInactivos,
              onChanged: (value) {
                setState(() {
                  _mostrarInactivos = value;
                });
              },
              activeColor: Colors.teal,
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _cargarEmpleados,
          tooltip: 'Actualizar',
        ),
      ],
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : empleadosFiltrados.isEmpty
              ? _buildEmptyState()
              : _buildEmpleadosList(empleadosFiltrados),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _mostrarInactivos
                ? "No hay empleados registrados"
                : "No hay empleados activos",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _agregarEmpleado,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Registrar Nuevo Empleado'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpleadosList(List<UsuarioEmpleado> empleados) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: empleados.length,
          itemBuilder: (context, index) {
            final item = empleados[index];
            final empleado = item.empleado;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      empleado.idEstado == 1
                          ? Colors.teal.withAlpha(51)
                          : Colors.red.withAlpha(51),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor:
                      empleado.idEstado == 1 ? Colors.teal : Colors.grey,
                  child: Text(
                    empleado.nombre.isNotEmpty
                        ? empleado.nombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  '${empleado.nombre} ${empleado.apellidoPaterno}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Cargo: ${empleado.cargo}'),
                    Text(
                      'Clave: ${empleado.claveSistema}',
                    ), // Cambiado de claveInterna a claveSistema
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(
                        empleado.idEstado == 1 ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          color:
                              empleado.idEstado == 1
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor:
                          empleado.idEstado == 1
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _verDetallesEmpleado(item),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _agregarEmpleado,
            backgroundColor: Colors.teal,
            tooltip: 'Agregar empleado',
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _verDetallesEmpleado(UsuarioEmpleado empleadoUsuario) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DetalleEmpleadoScreen(
              controller: widget.controller,
              idEmpleado: empleadoUsuario.empleado.id!,
            ),
      ),
    );

    if (result == true && mounted) {
      _cargarEmpleados();
    }
  }

  void _agregarEmpleado() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DetalleEmpleadoScreen(controller: widget.controller),
      ),
    );

    if (result == true && mounted) {
      _cargarEmpleados();
    }
  }
}

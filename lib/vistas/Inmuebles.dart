import 'vista_agregar_inmueble.dart';
import 'package:flutter/material.dart';
import '../models/inmueble_model.dart';
import '../controllers/inmueble_controller.dart';

class InmueblesApp extends StatelessWidget {
  const InmueblesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final InmuebleController _inmuebleController = InmuebleController();
  List<Inmueble> _inmuebles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarInmuebles();
  }

  Future<void> _cargarInmuebles() async {
    setState(() => _isLoading = true);
    try {
      final inmuebles = await _inmuebleController.getInmuebles();
      if (!mounted) return; // Verificación después de la operación asíncrona
      setState(() {
        _inmuebles = inmuebles;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inmuebles'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarInmuebles,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AgregarInmuebleScreen()),
          );
          if (!mounted) return; // Verificación tras la navegación asíncrona
          if (result == true) {
            _cargarInmuebles();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarInmuebles,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_inmuebles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay inmuebles registrados', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Pulse el botón + para agregar un inmueble'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: _buildInmueblesGrid(),
    );
  }

  Widget _buildInmueblesGrid() {
    final crossAxisCount = _calculateCrossAxisCount(context);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: _inmuebles.length,
      itemBuilder: (context, index) {
        final inmueble = _inmuebles[index];
        return _buildInmuebleCard(inmueble);
      },
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 1;
    } else if (screenWidth < 900) {
      return 2;
    } else {
      return 3;
    }
  }

  Widget _buildInmuebleCard(Inmueble inmueble) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InmuebleDetailScreen(inmueble: inmueble),
          ),
        ).then((result) {
          if (result == true) {
            _cargarInmuebles();
          }
        });
      },
      child: Card(
        color: Colors.grey[100],
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Área de imagen
            Container(
              margin: const EdgeInsets.all(8),
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Center(
                child: Icon(
                  Icons.home,
                  size: 80,
                  color: Colors.grey[700],
                ),
              ),
            ),
            // Información del inmueble
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inmueble.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha: ${inmueble.fechaRegistro?.toLocal().toString().split(' ')[0] ?? 'No disponible'}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Precio: \$${inmueble.montoTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditInmuebleScreen(inmueble: inmueble),
                      ),
                    ).then((result) {
                      if (result == true) {
                        _cargarInmuebles();
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InmuebleDetailScreen extends StatelessWidget {
  final Inmueble inmueble;

  const InmuebleDetailScreen({super.key, required this.inmueble});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(inmueble.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditInmuebleScreen(inmueble: inmueble),
                ),
              );
              if (!Navigator.of(context).mounted) return;
              if (result == true) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del inmueble
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.home, size: 100, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            // Información general
            const Text(
              'Información General',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Nombre:', inmueble.nombre),
            _buildInfoRow('Precio:', '\$${inmueble.montoTotal.toStringAsFixed(2)}'),
            _buildInfoRow('ID Cliente:', inmueble.idCliente?.toString() ?? 'No asignado'),
            _buildInfoRow('Estado:', inmueble.idEstado?.toString() ?? 'No definido'),
            _buildInfoRow(
              'Fecha de registro:',
              inmueble.fechaRegistro?.toLocal().toString().split(' ')[0] ?? 'No disponible',
            ),
            const SizedBox(height: 24),
            // Dirección (simulada, ya que no se incluye en el modelo actual)
            const Text(
              'Dirección',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('ID Dirección:', inmueble.idDireccion?.toString() ?? 'No asignada'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class EditInmuebleScreen extends StatefulWidget {
  final Inmueble inmueble;

  const EditInmuebleScreen({super.key, required this.inmueble});

  @override
  State<EditInmuebleScreen> createState() => EditInmuebleScreenState();
}

class EditInmuebleScreenState extends State<EditInmuebleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _montoController;
  late TextEditingController _estadoController;

  final InmuebleController _inmuebleController = InmuebleController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.inmueble.nombre);
    _montoController = TextEditingController(text: widget.inmueble.montoTotal.toString());
    _estadoController = TextEditingController(text: widget.inmueble.idEstado?.toString() ?? '1');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Inmueble')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildEditForm(),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el nombre del inmueble';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _montoController,
            decoration: const InputDecoration(
              labelText: 'Monto',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el monto';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _estadoController,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
              helperText: '1 = Activo, 2 = Inactivo',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _actualizarInmueble,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ACTUALIZAR', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _eliminarInmueble,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ELIMINAR', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _actualizarInmueble() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final inmuebleActualizado = Inmueble(
        id: widget.inmueble.id,
        nombre: _nombreController.text,
        montoTotal: double.tryParse(_montoController.text) ?? 0,
        idEstado: int.tryParse(_estadoController.text) ?? 1,
        idCliente: widget.inmueble.idCliente,
        fechaRegistro: widget.inmueble.fechaRegistro,
        idDireccion: widget.inmueble.idDireccion,
      );

      await _inmuebleController.updateInmueble(inmuebleActualizado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inmueble actualizado correctamente')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar inmueble: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _eliminarInmueble() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar inmueble'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar este inmueble? '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        if (widget.inmueble.id != null) {
          await _inmuebleController.deleteInmueble(widget.inmueble.id!);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inmueble eliminado correctamente')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar inmueble: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
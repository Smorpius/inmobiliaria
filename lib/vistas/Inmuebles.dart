import 'package:flutter/material.dart';
import '../models/inmueble_model.dart';
import '../controllers/inmueble_controller.dart';
import '../controllers/cliente_controller.dart'; // Importación para el selector de clientes

class InmueblesApp extends StatelessWidget {
  const InmueblesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
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

  @override
  void initState() {
    super.initState();
    _cargarInmuebles();
  }

  Future<void> _cargarInmuebles() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final inmuebles = await _inmuebleController.getInmuebles();
      if (!mounted) return;

      setState(() {
        _inmuebles = inmuebles;
        _isLoading = false;
      });

      // Debug: imprime los inmuebles para verificar que se están cargando
      print('Se cargaron ${inmuebles.length} inmuebles');
      for (var i = 0; i < inmuebles.length; i++) {
        print('Inmueble $i: ${inmuebles[i].nombre}, ID: ${inmuebles[i].id}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      print('Error al cargar inmuebles: $e'); // Debug
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar inmuebles: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inmobiliaria',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarInmuebles,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _inmuebles.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No hay inmuebles disponibles',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                      onPressed: _cargarInmuebles,
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: Text(
                        'Propiedades disponibles',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // Ajustado para verse mejor
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.9,
                            ),
                        itemCount: _inmuebles.length,
                        itemBuilder: (context, index) {
                          final inmueble = _inmuebles[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => InmuebleDetailScreen(
                                        inmueble: inmueble,
                                      ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 140,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.teal[300]!,
                                          Colors.teal[600]!,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.home,
                                        size: 64,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          inmueble.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID Dir: ${inmueble.idDireccion ?? "N/A"}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${inmueble.montoTotal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[800],
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () async {
                                                final result =
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                EditInmuebleScreen(
                                                                  inmueble:
                                                                      inmueble,
                                                                ),
                                                      ),
                                                    );
                                                // Si hay un resultado positivo, recargamos los inmuebles
                                                if (result == true) {
                                                  await _cargarInmuebles();
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Usar async/await para esperar el resultado de la navegación
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddInmuebleScreen()),
          );
          // Si result es true, significa que se agregó un inmueble exitosamente
          if (result == true) {
            await _cargarInmuebles();
          }
        },
        label: const Text('Nuevo'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
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
      appBar: AppBar(title: Text(inmueble.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inmueble.nombre,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('ID Dirección: ${inmueble.idDireccion ?? "No asignada"}'),
            const SizedBox(height: 8),
            Text('Precio: \$${inmueble.montoTotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
              'Estado: ${inmueble.idEstado == 1 ? "Disponible" : "Vendido"}',
            ),
            const SizedBox(height: 8),
            Text('Cliente ID: ${inmueble.idCliente ?? "Sin asignar"}'),
            const SizedBox(height: 16),
            if (inmueble.fechaRegistro != null)
              Text(
                'Fecha de registro: ${_formatDate(inmueble.fechaRegistro!)}',
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class AddInmuebleScreen extends StatefulWidget {
  const AddInmuebleScreen({super.key});

  @override
  State<AddInmuebleScreen> createState() => AddInmuebleScreenState();
}

class AddInmuebleScreenState extends State<AddInmuebleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _calleController = TextEditingController();
  final _numeroController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _estadoController = TextEditingController(
    text: '1',
  ); // Valor inicial aquí
  final _codigoPostalController = TextEditingController();
  final _montoController = TextEditingController();

  // Nueva implementación para selector de clientes
  final ClienteController _clienteController = ClienteController();
  List<Map<String, dynamic>> _clientesDisponibles = [];
  int? _clienteSeleccionado;
  bool _clientesLoading = true;

  final InmuebleController _inmuebleController = InmuebleController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    try {
      print("Cargando clientes...");
      final clientes = await _clienteController.getClientes();

      if (!mounted) return;

      setState(() {
        _clientesDisponibles =
            clientes.map((c) => {'id': c.id, 'nombre': c.nombre}).toList();
        _clientesLoading = false;
      });
      print("Se cargaron ${clientes.length} clientes");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _clientesLoading = false;
      });

      print("Error al cargar clientes: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar clientes: $e')));
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _calleController.dispose();
    _numeroController.dispose();
    _ciudadController.dispose();
    _estadoController.dispose();
    _codigoPostalController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Inmueble')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Inmueble',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el nombre del inmueble';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _calleController,
                        decoration: const InputDecoration(labelText: 'Calle'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la calle';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _numeroController,
                        decoration: const InputDecoration(labelText: 'Número'),
                      ),
                      TextFormField(
                        controller: _ciudadController,
                        decoration: const InputDecoration(labelText: 'Ciudad'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la ciudad';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _estadoController,
                        decoration: const InputDecoration(
                          labelText: 'ID Estado (1=Activo, 2=Inactivo)',
                        ),
                        keyboardType: TextInputType.number,
                        // NO initialValue aquí porque ya usamos controller
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el ID de estado';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _codigoPostalController,
                        decoration: const InputDecoration(
                          labelText: 'Código Postal',
                        ),
                      ),
                      TextFormField(
                        controller: _montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto Total',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el monto total';
                          }
                          try {
                            double.parse(value);
                          } catch (e) {
                            return 'Ingrese un valor numérico válido';
                          }
                          return null;
                        },
                      ),
                      // Reemplazo del campo de texto por un selector desplegable
                      const SizedBox(height: 8),
                      _clientesLoading
                          ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Cliente (opcional)',
                              hintText: 'Seleccione un cliente',
                              border: OutlineInputBorder(),
                            ),
                            value: _clienteSeleccionado,
                            items:
                                _clientesDisponibles.map((cliente) {
                                  return DropdownMenuItem<int>(
                                    value: cliente['id'],
                                    child: Text(cliente['nombre']),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _clienteSeleccionado = value;
                              });
                            },
                          ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _guardarInmueble,
                        child: const Text('Agregar Inmueble'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _guardarInmueble() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        print("Guardando inmueble con datos:");
        print("Nombre: ${_nombreController.text}");
        print("Calle: ${_calleController.text}");
        print("Número: ${_numeroController.text}");
        print("Ciudad: ${_ciudadController.text}");
        print("Estado: ${_estadoController.text}");
        print("CP: ${_codigoPostalController.text}");
        print("Monto: ${_montoController.text}");
        print("Cliente: $_clienteSeleccionado");

        // Usar el procedimiento almacenado para crear el inmueble con el cliente seleccionado
        await _inmuebleController.insertInmuebleUsingStoredProc(
          _nombreController.text,
          _calleController.text,
          _numeroController.text,
          _ciudadController.text,
          int.tryParse(_estadoController.text) ?? 1,
          _codigoPostalController.text,
          double.parse(_montoController.text),
          'disponible', // Estatus por defecto
          _clienteSeleccionado, // Usar el ID seleccionado del dropdown
        );

        print("Inmueble guardado exitosamente");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inmueble agregado correctamente')),
        );

        Navigator.pop(
          context,
          true,
        ); // Retornar true para indicar que se agregó correctamente
      } catch (e) {
        print("Error al guardar inmueble: $e");

        if (!mounted) return;

        // Mensaje de error más amigable
        String errorMessage = e.toString();
        if (errorMessage.contains('foreign key constraint fails')) {
          errorMessage =
              'El cliente seleccionado no existe o hay un problema con la referencia';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar inmueble: $errorMessage')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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
  late TextEditingController _idDireccionController;
  late TextEditingController _montoController;
  late TextEditingController _estadoController;

  // Nueva implementación para selector de clientes
  final ClienteController _clienteController = ClienteController();
  List<Map<String, dynamic>> _clientesDisponibles = [];
  int? _clienteSeleccionado;
  bool _clientesLoading = true;

  final InmuebleController _inmuebleController = InmuebleController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.inmueble.nombre);
    _idDireccionController = TextEditingController(
      text: widget.inmueble.idDireccion?.toString() ?? '',
    );
    _montoController = TextEditingController(
      text: widget.inmueble.montoTotal.toString(),
    );
    _estadoController = TextEditingController(
      text: widget.inmueble.idEstado?.toString() ?? '1',
    );

    // Inicializamos el cliente seleccionado
    _clienteSeleccionado = widget.inmueble.idCliente;

    // Cargamos los clientes disponibles
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    try {
      final clientes = await _clienteController.getClientes();

      if (!mounted) return;

      setState(() {
        _clientesDisponibles =
            clientes
                .map(
                  (c) => {
                    'id': c.id,
                    'nombre': c.nombre, // Solo nombre
                  },
                )
                .toList();
        _clientesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _clientesLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar clientes: $e')));
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _idDireccionController.dispose();
    _montoController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Inmueble')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Inmueble',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el nombre del inmueble';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _idDireccionController,
                        decoration: const InputDecoration(
                          labelText: 'ID Dirección',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: _montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto Total',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el monto total';
                          }
                          try {
                            double.parse(value);
                          } catch (e) {
                            return 'Ingrese un valor numérico válido';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _estadoController,
                        decoration: const InputDecoration(
                          labelText: 'Estado (1=Activo, 2=Inactivo)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el estado';
                          }
                          return null;
                        },
                      ),
                      // Reemplazo del campo de texto por un selector desplegable
                      const SizedBox(height: 8),
                      _clientesLoading
                          ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : DropdownButtonFormField<int?>(
                            decoration: const InputDecoration(
                              labelText: 'Cliente (opcional)',
                              hintText: 'Seleccione un cliente',
                              border: OutlineInputBorder(),
                            ),
                            value: _clienteSeleccionado,
                            items: [
                              // Opción para deseleccionar
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Sin cliente asignado'),
                              ),
                              // Opciones de clientes (sin .toList() innecesario)
                              ..._clientesDisponibles.map((cliente) {
                                return DropdownMenuItem<int?>(
                                  value: cliente['id'],
                                  child: Text(cliente['nombre']),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _clienteSeleccionado = value;
                              });
                            },
                          ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _actualizarInmueble,
                        child: const Text('Actualizar Inmueble'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _eliminarInmueble,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Eliminar Inmueble'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _actualizarInmueble() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final inmueble = Inmueble(
          id: widget.inmueble.id,
          nombre: _nombreController.text,
          idDireccion:
              _idDireccionController.text.isNotEmpty
                  ? int.parse(_idDireccionController.text)
                  : null,
          montoTotal: double.parse(_montoController.text),
          idEstado: int.parse(_estadoController.text),
          idCliente:
              _clienteSeleccionado, // Usar el cliente seleccionado del dropdown
          fechaRegistro: widget.inmueble.fechaRegistro,
        );

        await _inmuebleController.updateInmueble(inmueble);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inmueble actualizado correctamente')),
        );

        Navigator.pop(context, true); // Retornar true para indicar éxito
      } catch (e) {
        if (!mounted) return;

        // Mensaje de error más amigable
        String errorMessage = e.toString();
        if (errorMessage.contains('foreign key constraint fails')) {
          errorMessage =
              'El cliente seleccionado no existe o hay un problema con la referencia';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar inmueble: $errorMessage'),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
            '¿Estás seguro de que deseas eliminar este inmueble? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _inmuebleController.deleteInmueble(widget.inmueble.id!);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inmueble eliminado correctamente')),
        );

        Navigator.pop(context, true); // Retornar true para indicar éxito
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar inmueble: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}

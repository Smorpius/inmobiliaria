import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen());
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inmobiliaria')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => InmuebleDetailScreen(
                          title: 'Casa $index',
                          address: 'Dirección: Tampico',
                          price: 'Precio: 1,200,000',
                        ),
                  ),
                );
              },
              child: Card(
                color: Colors.grey[300],

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      // padding: EdgeInsets.all(20),
                      margin: EdgeInsets.all(8),
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        //ponerle color al borde
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Casa $index',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Dirección: Tampico'),
                          Text('Precio: 1,200,000'),
                          IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EditInmuebleScreen(
                                        title: 'Casa $index',
                                        address: 'Dirección: Tampico',
                                        price: 'Precio: 1,200,000',
                                      ),
                                ),
                              );
                            },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddInmuebleScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class InmuebleDetailScreen extends StatelessWidget {
  final String title;
  final String address;
  final String price;

  InmuebleDetailScreen({
    required this.title,
    required this.address,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(address),
            SizedBox(height: 8),
            Text(price),
          ],
        ),
      ),
    );
  }
}

class AddInmuebleScreen extends StatefulWidget {
  @override
  _AddInmuebleScreenState createState() => _AddInmuebleScreenState();
}

class _AddInmuebleScreenState extends State<AddInmuebleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _calleController = TextEditingController();
  final _numeroController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _estadoController = TextEditingController();
  final _codigoPostalController = TextEditingController();
  final _montoController = TextEditingController();
  final _clienteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agregar Inmueble')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(labelText: 'Nombre del Inmueble'),
              ),
              TextFormField(
                controller: _calleController,
                decoration: InputDecoration(labelText: 'Calle'),
              ),
              TextFormField(
                controller: _numeroController,
                decoration: InputDecoration(labelText: 'Número'),
              ),
              TextFormField(
                controller: _ciudadController,
                decoration: InputDecoration(labelText: 'Ciudad'),
              ),
              TextFormField(
                controller: _estadoController,
                decoration: InputDecoration(labelText: 'Estado'),
              ),
              TextFormField(
                controller: _codigoPostalController,
                decoration: InputDecoration(labelText: 'Código Postal'),
              ),
              TextFormField(
                controller: _montoController,
                decoration: InputDecoration(labelText: 'Monto Total'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _clienteController,
                decoration: InputDecoration(labelText: 'ID Cliente'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: () {}, child: Text('Agregar Inmueble')),
            ],
          ),
        ),
      ),
    );
  }
}

class EditInmuebleScreen extends StatefulWidget {
  final String title;
  final String address;
  final String price;

  EditInmuebleScreen({
    required this.title,
    required this.address,
    required this.price,
  });

  @override
  _EditInmuebleScreenState createState() => _EditInmuebleScreenState();
}

class _EditInmuebleScreenState extends State<EditInmuebleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _calleController;
  late TextEditingController _numeroController;
  late TextEditingController _ciudadController;
  late TextEditingController _estadoController;
  late TextEditingController _codigoPostalController;
  late TextEditingController _montoController;
  late TextEditingController _clienteController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.title);
    _calleController = TextEditingController(text: widget.address);
    _numeroController = TextEditingController();
    _ciudadController = TextEditingController();
    _estadoController = TextEditingController();
    _codigoPostalController = TextEditingController();
    _montoController = TextEditingController(text: widget.price);
    _clienteController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Inmueble')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(labelText: 'Nombre del Inmueble'),
              ),
              TextFormField(
                controller: _calleController,
                decoration: InputDecoration(labelText: 'Calle'),
              ),
              TextFormField(
                controller: _numeroController,
                decoration: InputDecoration(labelText: 'Número'),
              ),
              TextFormField(
                controller: _ciudadController,
                decoration: InputDecoration(labelText: 'Ciudad'),
              ),
              TextFormField(
                controller: _estadoController,
                decoration: InputDecoration(labelText: 'Estado'),
              ),
              TextFormField(
                controller: _codigoPostalController,
                decoration: InputDecoration(labelText: 'Código Postal'),
              ),
              TextFormField(
                controller: _montoController,
                decoration: InputDecoration(labelText: 'Monto Total'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _clienteController,
                decoration: InputDecoration(labelText: 'ID Cliente'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                child: Text('Actualizar Inmueble'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

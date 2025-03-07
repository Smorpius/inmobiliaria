import 'package:intl/intl.dart';
import '../../models/usuario.dart';
import '../../models/empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/app_scaffold.dart';
import '../../controllers/usuario_empleado_controller.dart';

class DetalleEmpleadoScreen extends StatefulWidget {
  final UsuarioEmpleadoController controller;
  final int? idEmpleado; // Null para nuevo empleado

  const DetalleEmpleadoScreen({
    super.key,
    required this.controller,
    this.idEmpleado,
  });

  @override
  State<DetalleEmpleadoScreen> createState() => _DetalleEmpleadoScreenState();
}

class _DetalleEmpleadoScreenState extends State<DetalleEmpleadoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditando = false;

  // Datos de usuario
  final _usuarioNombreController = TextEditingController();
  final _usuarioApellidoController = TextEditingController();
  final _usuarioNombreUsuarioController = TextEditingController();
  final _usuarioContrasenaController = TextEditingController();
  final _usuarioCorreoController = TextEditingController();

  // Datos de empleado
  final _claveSistemaController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _cargoController = TextEditingController();
  final _sueldoController = TextEditingController();
  DateTime? _fechaContratacion;

  Usuario? _usuarioActual;
  Empleado? _empleadoActual;

  @override
  void initState() {
    super.initState();
    _isEditando = widget.idEmpleado != null;
    if (_isEditando) {
      _cargarDatosEmpleado();
    } else {
      _fechaContratacion = DateTime.now();
    }
  }

  Future<void> _cargarDatosEmpleado() async {
    setState(() => _isLoading = true);
    try {
      final empleadoUsuario = await widget.controller.obtenerEmpleado(
        widget.idEmpleado!,
      );

      if (!mounted) {
        return; // Verificación de mounted después de operación asíncrona
      }

      if (empleadoUsuario != null) {
        _usuarioActual = empleadoUsuario.usuario;
        _empleadoActual = empleadoUsuario.empleado;

        _usuarioNombreController.text = _usuarioActual!.nombre;
        _usuarioApellidoController.text = _usuarioActual!.apellido;
        _usuarioNombreUsuarioController.text = _usuarioActual!.nombreUsuario;
        _usuarioCorreoController.text = _usuarioActual!.correo ?? '';

        _claveSistemaController.text = _empleadoActual!.claveSistema;
        _apellidoMaternoController.text =
            _empleadoActual!.apellidoMaterno ?? '';
        _telefonoController.text = _empleadoActual!.telefono;
        _direccionController.text = _empleadoActual!.direccion;
        _cargoController.text = _empleadoActual!.cargo;
        _sueldoController.text = _empleadoActual!.sueldoActual.toString();
        _fechaContratacion = _empleadoActual!.fechaContratacion;
      } else {
        _mostrarError('No se encontró el empleado solicitado');
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al cargar datos: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _guardarEmpleado() async {
    if (!_formKey.currentState!.validate() || _fechaContratacion == null) {
      _mostrarError('Por favor complete todos los campos requeridos');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final usuario = Usuario(
        id: _isEditando ? _usuarioActual!.id : null,
        nombre: _usuarioNombreController.text.trim(),
        apellido: _usuarioApellidoController.text.trim(),
        nombreUsuario: _usuarioNombreUsuarioController.text.trim(),
        contrasena: _usuarioContrasenaController.text.trim(),
        correo: _usuarioCorreoController.text.trim(),
      );

      final empleado = Empleado(
        id: _isEditando ? _empleadoActual!.id : null,
        idUsuario: _isEditando ? _empleadoActual!.idUsuario : null,
        claveSistema: _claveSistemaController.text.trim(),
        nombre: _usuarioNombreController.text.trim(),
        apellidoPaterno: _usuarioApellidoController.text.trim(),
        apellidoMaterno: _apellidoMaternoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        correo: _usuarioCorreoController.text.trim(),
        direccion: _direccionController.text.trim(),
        cargo: _cargoController.text.trim(),
        sueldoActual: double.parse(_sueldoController.text.trim()),
        fechaContratacion: _fechaContratacion!,
        idEstado: _isEditando ? _empleadoActual!.idEstado : 1,
      );

      if (_isEditando) {
        await widget.controller.actualizarEmpleado(
          _usuarioActual!.id!,
          _empleadoActual!.id!,
          usuario,
          empleado,
        );
        if (mounted) {
          _mostrarExito('Empleado actualizado correctamente');
          Navigator.pop(context, true);
        }
      } else {
        final id = await widget.controller.crearEmpleado(usuario, empleado);
        if (mounted) {
          _mostrarExito('Empleado creado correctamente con ID: $id');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al guardar: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaContratacion ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (fechaSeleccionada != null && mounted) {
      setState(() {
        _fechaContratacion = fechaSeleccionada;
      });
    }
  }

  @override
  void dispose() {
    _usuarioNombreController.dispose();
    _usuarioApellidoController.dispose();
    _usuarioNombreUsuarioController.dispose();
    _usuarioContrasenaController.dispose();
    _usuarioCorreoController.dispose();
    _claveSistemaController.dispose();
    _apellidoMaternoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _cargoController.dispose();
    _sueldoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditando ? 'Editar Empleado' : 'Nuevo Empleado',
      currentRoute: '/empleados',
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera con avatar
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.teal,
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              // Se pueden agregar datos adicionales del empleado
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información de Usuario',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          const SizedBox(height: 10),

                          // Nombre y Apellido
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _usuarioNombreController,
                                  decoration: _getInputDecoration(
                                    'Nombre',
                                    Icons.person,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingrese el nombre';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _usuarioApellidoController,
                                  decoration: _getInputDecoration(
                                    'Apellido Paterno',
                                    Icons.person_outline,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingrese el apellido paterno';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Usuario y Contraseña
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _usuarioNombreUsuarioController,
                                  decoration: _getInputDecoration(
                                    'Nombre de Usuario',
                                    Icons.account_circle,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingrese el nombre de usuario';
                                    }
                                    return null;
                                  },
                                  enabled: !_isEditando,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _usuarioContrasenaController,
                                  decoration: _getInputDecoration(
                                    _isEditando
                                        ? 'Nueva Contraseña (opcional)'
                                        : 'Contraseña',
                                    Icons.lock,
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (!_isEditando &&
                                        (value == null || value.isEmpty)) {
                                      return 'Ingrese la contraseña';
                                    } else if (value != null &&
                                        value.isNotEmpty &&
                                        value.length < 6) {
                                      return 'Mínimo 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Correo
                          TextFormField(
                            controller: _usuarioCorreoController,
                            decoration: _getInputDecoration(
                              'Correo electrónico',
                              Icons.email,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese el correo electrónico';
                              } else if (!_isValidEmail(value)) {
                                return 'Correo electrónico inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),

                          const Text(
                            'Información Laboral',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          const SizedBox(height: 10),

                          // Clave sistema y Apellido Materno
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _claveSistemaController,
                                  decoration: _getInputDecoration(
                                    'Clave Sistema',
                                    Icons.badge,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingrese la clave del sistema';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _apellidoMaternoController,
                                  decoration: _getInputDecoration(
                                    'Apellido Materno',
                                    Icons.person_outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Teléfono (con validación mejorada)
                          TextFormField(
                            controller: _telefonoController,
                            decoration: _getInputDecoration(
                              'Teléfono',
                              Icons.phone,
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                              _TelefonoInputFormatter(),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese el teléfono';
                              }
                              // Eliminar guiones o espacios para validar solo dígitos
                              String numeroLimpio = value.replaceAll(
                                RegExp(r'[-\s]'),
                                '',
                              );
                              if (numeroLimpio.length < 10) {
                                return 'El teléfono debe tener 10 dígitos';
                              }
                              if (!RegExp(r'^\d+$').hasMatch(numeroLimpio)) {
                                return 'El teléfono debe contener solo números';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Dirección
                          TextFormField(
                            controller: _direccionController,
                            decoration: _getInputDecoration(
                              'Dirección',
                              Icons.home,
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese la dirección';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Cargo
                          TextFormField(
                            controller: _cargoController,
                            decoration: _getInputDecoration(
                              'Cargo',
                              Icons.work,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese el cargo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Sueldo (con validación mejorada)
                          TextFormField(
                            controller: _sueldoController,
                            decoration: _getInputDecoration(
                              'Sueldo',
                              Icons.money,
                            ),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese el sueldo';
                              }

                              try {
                                double sueldo = double.parse(value);
                                if (sueldo <= 0) {
                                  return 'El sueldo debe ser mayor a 0';
                                }
                                if (sueldo > 1000000) {
                                  return 'El sueldo parece muy alto, verifique';
                                }
                              } catch (e) {
                                return 'Ingrese un valor numérico válido';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Fecha de contratación
                          InkWell(
                            onTap: () => _seleccionarFecha(context),
                            child: InputDecorator(
                              decoration: _getInputDecoration(
                                'Fecha de Contratación',
                                Icons.calendar_today,
                              ),
                              child: Text(
                                _fechaContratacion != null
                                    ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_fechaContratacion!)
                                    : 'Seleccione una fecha',
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Botones
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancelar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _guardarEmpleado,
                                icon: const Icon(Icons.save),
                                label: Text(
                                  _isEditando ? 'Actualizar' : 'Guardar',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                ),
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
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}

// Clase para formatear el teléfono mientras se escribe
class _TelefonoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si el usuario está eliminando caracteres, permitirlo sin formatear
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    // Limpiar el texto de formatos
    final String cleanText = newValue.text.replaceAll(RegExp(r'[-\s]'), '');

    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Aplicar formato: XXX-XXX-XXXX
    String formattedText = cleanText;
    if (cleanText.length > 3) {
      formattedText = '${cleanText.substring(0, 3)}-${cleanText.substring(3)}';
    }
    if (cleanText.length > 6) {
      formattedText =
          '${formattedText.substring(0, 7)}-${formattedText.substring(7)}';
    }

    // Limitar a 10 dígitos (12 caracteres con guiones)
    if (cleanText.length > 10) {
      formattedText = formattedText.substring(0, 12);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

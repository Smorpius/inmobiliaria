import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/applogger.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import '../../../services/pdf_service.dart';
import '../../../models/inmueble_model.dart';
import '../../../services/directory_service.dart';
import '../../../providers/cliente_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/contrato_generado_controller.dart';

class ContratoGeneratorScreen extends ConsumerStatefulWidget {
  final Inmueble inmueble;
  final String tipoContrato; // 'venta' o 'renta'

  const ContratoGeneratorScreen({
    super.key,
    required this.inmueble,
    required this.tipoContrato,
  });

  @override
  ConsumerState<ContratoGeneratorScreen> createState() =>
      _ContratoGeneratorScreenState();
}

class _ContratoGeneratorScreenState
    extends ConsumerState<ContratoGeneratorScreen> {
  bool _generandoContrato = false;
  bool _contratoGenerado = false;
  String? _rutaContrato;

  // Datos adicionales para el contrato
  final _formKey = GlobalKey<FormState>();
  final _duracionRentaController = TextEditingController();
  final _montoMensualController = TextEditingController();
  final _observacionesController = TextEditingController();

  DateTime _fechaContrato = DateTime.now();
  String _tipoMoneda = 'MXN';

  @override
  void initState() {
    super.initState();
    // Pre-llenar campos si es una renta
    if (widget.tipoContrato == 'renta' && widget.inmueble.precioRenta != null) {
      _montoMensualController.text = widget.inmueble.precioRenta.toString();
    } else if (widget.inmueble.precioVenta != null) {
      _montoMensualController.text = widget.inmueble.precioVenta.toString();
    }

    _duracionRentaController.text = widget.tipoContrato == 'venta' ? '1' : '12';
  }

  @override
  void dispose() {
    _duracionRentaController.dispose();
    _montoMensualController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clienteAsyncValue = ref.watch(
      clientePorIdProvider(widget.inmueble.idCliente ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Generar contrato de ${widget.tipoContrato == 'venta' ? 'venta' : 'renta'}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _contratoGenerado
                ? _buildContratoGenerado()
                : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contrato de ${widget.tipoContrato == 'venta' ? 'Compraventa' : 'Arrendamiento'}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Propiedad: ${widget.inmueble.nombre}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Divider(height: 24),
                              // Cliente asociado
                              clienteAsyncValue.when(
                                data: (cliente) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cliente:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${cliente?.nombre ?? 'N/A'} ${cliente?.apellidoPaterno ?? ''} ${cliente?.apellidoMaterno ?? ''}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      if (cliente?.telefono != null &&
                                          cliente!.telefono.isNotEmpty)
                                        Text(
                                          'Tel: ${cliente.telefono}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                                loading:
                                    () => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                error:
                                    (error, _) => Text(
                                      'Error al cargar cliente: ${error.toString().split('\n').first}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detalles del contrato',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Fecha del contrato
                              GestureDetector(
                                onTap: () => _seleccionarFecha(context),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Fecha del contrato',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.calendar_today),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_fechaContrato),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Duración (meses)
                              TextFormField(
                                controller: _duracionRentaController,
                                decoration: InputDecoration(
                                  labelText:
                                      widget.tipoContrato == 'renta'
                                          ? 'Duración (meses)'
                                          : 'Plazo de pago (meses)',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.timelapse),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Este campo es requerido';
                                  }
                                  try {
                                    final duracion = int.parse(value);
                                    if (duracion < 1) {
                                      return 'Debe ser al menos 1 mes';
                                    }
                                  } catch (e) {
                                    return 'Debe ser un número entero';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Monto
                              TextFormField(
                                controller: _montoMensualController,
                                decoration: InputDecoration(
                                  labelText:
                                      widget.tipoContrato == 'renta'
                                          ? 'Monto mensual'
                                          : 'Precio de venta',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.attach_money),
                                  prefixText:
                                      _tipoMoneda == 'MXN' ? '\$ ' : '€ ',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Este campo es requerido';
                                  }
                                  try {
                                    final monto = double.parse(value);
                                    if (monto <= 0) {
                                      return 'El monto debe ser mayor a cero';
                                    }
                                  } catch (e) {
                                    return 'Debe ser un número válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Tipo de moneda
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de moneda',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.currency_exchange),
                                ),
                                value: _tipoMoneda,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'MXN',
                                    child: Text('Peso Mexicano (MXN)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'USD',
                                    child: Text('Dólar Estadounidense (USD)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'EUR',
                                    child: Text('Euro (EUR)'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _tipoMoneda = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              // Observaciones
                              TextFormField(
                                controller: _observacionesController,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Observaciones o cláusulas especiales',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.comment),
                                ),
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed:
                              _generandoContrato ? null : _generarContrato,
                          icon:
                              _generandoContrato
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.description),
                          label: Text(
                            _generandoContrato
                                ? 'Generando contrato...'
                                : 'Generar contrato',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildContratoGenerado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.green.shade400, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                const Text(
                  '¡Contrato generado correctamente!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'El contrato de ${widget.tipoContrato == 'venta' ? 'compraventa' : 'arrendamiento'} ha sido guardado en su dispositivo.',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _abrirContrato,
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver contrato'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Finalizar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaContrato,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (fechaSeleccionada != null && fechaSeleccionada != _fechaContrato) {
      setState(() {
        _fechaContrato = fechaSeleccionada;
      });
    }
  }

  Future<void> _generarContrato() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Verificar que haya un cliente asociado
    if (widget.inmueble.idCliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede generar contrato sin un cliente asociado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _generandoContrato = true;
    });

    try {
      // Obtenemos los datos del cliente
      final clienteAsyncValue = ref.read(
        clientePorIdProvider(widget.inmueble.idCliente!),
      );
      final cliente = clienteAsyncValue.value;

      if (cliente == null) {
        throw Exception('No se pudo obtener la información del cliente');
      }

      // Crear PDF
      final pdf = pw.Document();

      // Datos para el contrato
      final montoMensual = double.parse(_montoMensualController.text);
      final duracionMeses = int.parse(_duracionRentaController.text);

      // Generar contenido PDF según el tipo de contrato
      if (widget.tipoContrato == 'renta') {
        await _generarContratoRenta(pdf, cliente, montoMensual, duracionMeses);
      } else {
        await _generarContratoVenta(pdf, cliente, montoMensual);
      }

      // Guardar PDF usando PdfService
      final nombreBase =
          'contrato_${widget.tipoContrato}_${widget.inmueble.id}';
      final String rutaRelativaGuardada = await PdfService.guardarContratoPDF(
        pdf,
        nombreBase,
        widget.tipoContrato, // 'venta' o 'renta'
      );
      AppLogger.info(
        'Contrato guardado por PdfService en ruta relativa: $rutaRelativaGuardada',
      );

      // Guardar referencia del contrato en BD
      int idReferencia =
          widget.inmueble.id ?? 1; // Usando el ID del inmueble como referencia
      await ref
          .read(contratoGeneradoControllerProvider)
          .registrarContrato(
            tipoContrato: widget.tipoContrato,
            idReferencia: idReferencia,
            rutaArchivo:
                rutaRelativaGuardada, // Usar la ruta relativa devuelta por PdfService
            idUsuario:
                1, // Usuario actual, idealmente se obtendría de un servicio de autenticación
          );

      setState(() {
        _contratoGenerado = true;
        _rutaContrato = rutaRelativaGuardada; // Guardar la ruta relativa
        _generandoContrato = false;
      });
    } catch (e, stack) {
      AppLogger.error('Error al generar contrato', e, stack);
      if (mounted) {
        setState(() {
          _generandoContrato = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al generar contrato: ${e.toString().split('\n').first}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _abrirContrato() async {
    try {
      if (_rutaContrato != null) {
        // --- INICIO CAMBIO ---
        // Determinar el tipo de directorio basado en la ruta relativa almacenada
        String dirType;
        if (_rutaContrato!.contains(DirectoryService.contratosRentaDir)) {
          dirType = 'contratos_renta';
        } else if (_rutaContrato!.contains(
          DirectoryService.contratosVentaDir,
        )) {
          dirType = 'contratos_venta';
        } else {
          // Fallback si la ruta no contiene los directorios esperados (podría ser una ruta antigua/temporal)
          AppLogger.warning(
            'Ruta relativa no estándar: $_rutaContrato. Intentando abrir directamente.',
          );
          await OpenFile.open(_rutaContrato!);
          return;
        }

        // Obtener la ruta absoluta usando DirectoryService
        final String nombreArchivo = path.basename(_rutaContrato!);
        final String rutaAbsoluta = await DirectoryService.getFullPath(
          nombreArchivo,
          dirType,
        );
        AppLogger.info('Abriendo contrato desde ruta absoluta: $rutaAbsoluta');

        final result = await OpenFile.open(rutaAbsoluta);
        if (result.type != ResultType.done) {
          throw Exception('No se pudo abrir el archivo: ${result.message}');
        }
        // --- FIN CAMBIO ---
      } else {
        AppLogger.warning('Intento de abrir contrato con ruta nula.');
        throw Exception('La ruta del contrato no está disponible.');
      }
    } catch (e, stack) {
      AppLogger.error('Error al abrir contrato', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al abrir el archivo: ${e.toString().split('\n').first}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generarContratoRenta(
    pw.Document pdf,
    dynamic cliente,
    double montoMensual,
    int duracionMeses,
  ) async {
    final formatoCurrency = NumberFormat.currency(
      locale: 'es_MX',
      symbol:
          _tipoMoneda == 'MXN' ? '\$' : (_tipoMoneda == 'USD' ? 'USD' : '€'),
    );

    // Fecha formateada para el contrato
    final fechaFormateada = DateFormat(
      'dd de MMMM de yyyy',
      'es_MX',
    ).format(_fechaContrato);

    // Dirección completa del inmueble
    final direccionCompleta =
        '${widget.inmueble.calle ?? ''} ${widget.inmueble.numero ?? ''}, '
        '${widget.inmueble.colonia ?? ''}, ${widget.inmueble.ciudad ?? ''}, '
        '${widget.inmueble.estadoGeografico ?? ''}, C.P. ${widget.inmueble.codigoPostal ?? ''}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'CONTRATO DE ARRENDAMIENTO',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text('INMOBILIARIA XYZ', style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),
              ],
            ),
        footer:
            (pw.Context context) => pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ),
        build:
            (pw.Context context) => [
              pw.Paragraph(
                text:
                    'En la ciudad de ${widget.inmueble.ciudad ?? 'N/A'}, a $fechaFormateada, '
                    'se celebra el presente contrato de arrendamiento entre:',
              ),
              pw.SizedBox(height: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ARRENDADOR:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'INMOBILIARIA XYZ, representada legalmente en este acto.',
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'ARRENDATARIO:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '${cliente.nombre} ${cliente.apellidoPaterno} ${cliente.apellidoMaterno ?? ''}',
                  ),
                  pw.Text('Teléfono: ${cliente.telefono ?? 'N/A'}'),
                  pw.Text('Correo: ${cliente.correo ?? 'N/A'}'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'INMUEBLE OBJETO DEL CONTRATO:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(widget.inmueble.nombre),
                  pw.Text(direccionCompleta),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'CLÁUSULAS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),
              pw.Paragraph(
                text:
                    'PRIMERA: El arrendador da en arrendamiento al arrendatario el inmueble antes descrito, '
                    'el cual será destinado exclusivamente para uso habitacional.',
              ),
              pw.SizedBox(height: 5),
              pw.Paragraph(
                text:
                    'SEGUNDA: El término del presente contrato es de $duracionMeses meses, comenzando el día '
                    '$fechaFormateada y terminando el día ${DateFormat('dd de MMMM de yyyy', 'es_MX').format(_fechaContrato.add(Duration(days: 30 * duracionMeses)))}.',
              ),
              pw.SizedBox(height: 5),
              pw.Paragraph(
                text:
                    'TERCERA: El arrendatario se obliga a pagar al arrendador por concepto de renta mensual la '
                    'cantidad de ${formatoCurrency.format(montoMensual)}, pagaderos los primeros 5 días de cada mes.',
              ),
              pw.SizedBox(height: 5),
              pw.Paragraph(
                text:
                    'CUARTA: El arrendatario recibe el inmueble en perfectas condiciones de uso, '
                    'obligándose a devolverlo en el mismo estado al finalizar el contrato.',
              ),
              pw.SizedBox(height: 5),
              pw.Paragraph(
                text:
                    'QUINTA: El arrendatario no podrá subarrendar ni ceder en forma alguna el inmueble '
                    'sin consentimiento previo y por escrito del arrendador.',
              ),
              pw.SizedBox(height: 15),
              if (_observacionesController.text.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'OBSERVACIONES ADICIONALES:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(_observacionesController.text),
                    pw.SizedBox(height: 15),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 150, child: pw.Divider(thickness: 1)),
                      pw.Text('EL ARRENDADOR'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 150, child: pw.Divider(thickness: 1)),
                      pw.Text('EL ARRENDATARIO'),
                      pw.Text(
                        '${cliente.nombre} ${cliente.apellidoPaterno}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ],
      ),
    );
  }

  Future<void> _generarContratoVenta(
    pw.Document pdf,
    dynamic cliente,
    double montoTotal,
  ) async {
    final formatoCurrency = NumberFormat.currency(
      locale: 'es_MX',
      symbol:
          _tipoMoneda == 'MXN' ? '\$' : (_tipoMoneda == 'USD' ? 'USD' : '€'),
    );

    // Fecha formateada para el contrato
    final fechaFormateada = DateFormat(
      'dd de MMMM de yyyy',
      'es_MX',
    ).format(_fechaContrato);

    // Dirección completa del inmueble
    final direccionCompleta =
        '${widget.inmueble.calle ?? ''} ${widget.inmueble.numero ?? ''}, '
        '${widget.inmueble.colonia ?? ''}, ${widget.inmueble.ciudad ?? ''}, '
        '${widget.inmueble.estadoGeografico ?? ''}, C.P. ${widget.inmueble.codigoPostal ?? ''}';

    final duracionMeses = int.parse(_duracionRentaController.text);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'CONTRATO DE COMPRAVENTA',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text('INMOBILIARIA XYZ', style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),
              ],
            ),
        footer:
            (pw.Context context) => pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ),
        build:
            (pw.Context context) => [
              pw.Paragraph(
                text:
                    'En la ciudad de ${widget.inmueble.ciudad ?? 'N/A'}, a $fechaFormateada, '
                    'se celebra el presente contrato de compraventa entre:',
              ),
              pw.SizedBox(height: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'VENDEDOR:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'INMOBILIARIA XYZ, representada legalmente en este acto.',
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'COMPRADOR:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '${cliente.nombre} ${cliente.apellidoPaterno} ${cliente.apellidoMaterno ?? ''}',
                  ),
                  pw.Text('Teléfono: ${cliente.telefono ?? 'N/A'}'),
                  pw.Text('Correo: ${cliente.correo ?? 'N/A'}'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'INMUEBLE OBJETO DE LA COMPRAVENTA:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(widget.inmueble.nombre),
                  pw.Text(direccionCompleta),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'CLÁUSULAS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),
              pw.Paragraph(
                text:
                    'PRIMERA: El vendedor vende y transmite la propiedad del inmueble antes descrito '
                    'al comprador, quien lo adquiere para sí.',
              ),
              pw.SizedBox(height: 5),
              pw.Paragraph(
                text:
                    'SEGUNDA: El precio pactado por el inmueble objeto de este contrato es de '
                    '${formatoCurrency.format(montoTotal)}, que el comprador pagará al vendedor en un '
                    'plazo de $duracionMeses ${duracionMeses == 1 ? 'mes' : 'meses'}.',
              ),
              pw.SizedBox(height: 5),
              pw.Paragraph(
                text:
                    'TERCERA: El vendedor garantiza que el inmueble se encuentra libre de gravámenes, '
                    'hipotecas y responsabilidad fiscal a la fecha de este contrato.',
              ),
              pw.SizedBox(height: 5),
              pw.Paragraph(
                text:
                    'CUARTA: El comprador recibe el inmueble a su entera satisfacción, en el estado '
                    'físico en que se encuentra, manifestando conocerlo perfectamente.',
              ),
              pw.SizedBox(height: 5),
              pw.Paragraph(
                text:
                    'QUINTA: Los gastos, honorarios, derechos e impuestos derivados de este contrato '
                    'serán cubiertos por el comprador, excepto el impuesto sobre la renta que será a '
                    'cargo del vendedor.',
              ),
              pw.SizedBox(height: 15),
              if (_observacionesController.text.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'OBSERVACIONES ADICIONALES:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(_observacionesController.text),
                    pw.SizedBox(height: 15),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 150, child: pw.Divider(thickness: 1)),
                      pw.Text('EL VENDEDOR'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 150, child: pw.Divider(thickness: 1)),
                      pw.Text('EL COMPRADOR'),
                      pw.Text(
                        '${cliente.nombre} ${cliente.apellidoPaterno}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';

class VentaFormPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  const VentaFormPage({
    super.key,
    required this.firstName,
    this.emailUser,
    this.inventarioId,
  });

  @override
  State<VentaFormPage> createState() => _VentaFormPageState();
}

class _VentaFormPageState extends State<VentaFormPage> {
  // --- Selecciones del usuario ---
  String? _calzadoId;
  int? _tallaSeleccionada;
  String? _colorSeleccionado;
  int? _tacoSeleccionado;
  String? _plataformaSeleccionada; // 🔹 String para Bajo, Mediano, Alto

  // --- Flags del calzado seleccionado ---
  bool _tipoTieneTaco = false;
  bool _tipoTienePlataforma = false;
  bool _tipoTieneColores = false;

  // --- Stock y cantidad ---
  int _stockDisponible = 0;
  int _cantidadVenta = 0;
  double _precioVentaTotal = 0.0;
  bool _cargandoStock = false;

  // --- Opciones disponibles según filtros ---
  List<int> _tallasDisponibles = [];
  List<String> _coloresDisponibles = [];
  List<int> _tacosDisponibles = [];
  List<String> _plataformasDisponibles = []; // 🔹 Nueva lista para cascada

  bool _errorTalla = false;
  bool _errorColor = false;
  bool _errorPlataforma = false;

  final Map<String, String?> _iconCache = {};
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

  String? _metodoPagoSeleccionado;
  String? _lugarVentaSeleccionado;

  final List<String> _metodosPago = ['Efectivo', 'Yape', 'Plin', 'POS'];
  final List<String> _lugaresVenta = ['Tienda', 'Live'];

  @override
  void initState() {
    super.initState();
    _calcularStockTotal();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------
  // CALCULOS DE STOCK (CASCADA)
  // -------------------------------------------------------

  Future<void> _calcularStockTotal() async {
    setState(() => _cargandoStock = true);
    try {
      final calzadosSnap = await FirebaseFirestore.instance
          .collection('calzado')
          .where('id_inventario', isEqualTo: widget.inventarioId)
          .get();

      if (calzadosSnap.docs.isEmpty) {
        setState(() {
          _stockDisponible = 0;
          _cargandoStock = false;
        });
        return;
      }

      final calzadoIds = calzadosSnap.docs.map((d) => d.id).toList();
      int total = 0;

      for (final calzadoId in calzadoIds) {
        final filasSnap = await FirebaseFirestore.instance
            .collection('fila_inventario')
            .where('calzado_id', isEqualTo: calzadoId)
            .get();

        for (final fila in filasSnap.docs) {
          total += (fila['cantidad'] ?? 0) as int;
        }
      }

      setState(() {
        _stockDisponible = total;
        _cargandoStock = false;
      });
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorCalzado(String calzadoId) async {
    setState(() => _cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: calzadoId)
          .get();

      int total = 0;
      final Set<int> tallasSet = {};

      for (final fila in filasSnap.docs) {
        total += (fila['cantidad'] ?? 0) as int;
        final subfilasSnap = await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .get();

        for (final sub in subfilasSnap.docs) {
          final talla = sub['talla'] ?? 0;
          if (talla > 0) tallasSet.add(talla as int);
        }
      }

      setState(() {
        _stockDisponible = total;
        _tallasDisponibles = tallasSet.toList()..sort();
        _tallaSeleccionada = null;
        _colorSeleccionado = null;
        _tacoSeleccionado = null;
        _plataformaSeleccionada = null;
        _coloresDisponibles = [];
        _tacosDisponibles = [];
        _plataformasDisponibles = [];
        _cargandoStock = false;
      });
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorTalla(int talla) async {
    if (_tallasDisponibles.contains(talla)) {
      _errorTalla = false;
    } else {
      setState(() {
        _errorTalla = true;
        _tallaSeleccionada = null;
      });
      _mostrarSnack('Talla no disponible, seleccione otra.');
      return;
    }

    if (_calzadoId == null) return;
    setState(() => _cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      int total = 0;
      final Set<String> coloresSet = {};

      for (final fila in filasSnap.docs) {
        final subfilasSnap = await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: talla)
            .get();

        for (final sub in subfilasSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
          if (_tipoTieneColores) {
            final color = sub['colores']?.toString() ?? '';
            if (color.isNotEmpty) coloresSet.add(color);
          }
        }
      }

      setState(() {
        _stockDisponible = total;
        _coloresDisponibles = coloresSet.toList()..sort();
        _colorSeleccionado = null;
        _tacoSeleccionado = null;
        _plataformaSeleccionada = null;
        _cargandoStock = false;
      });

      if (!_tipoTieneColores) {
        _cargarSiguientePaso(talla: talla);
      }
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorColor(String color) async {
    if (_coloresDisponibles.contains(color)) {
      _errorColor = false;
    } else {
      setState(() {
        _errorColor = true;
        _colorSeleccionado = null;
      });
      _mostrarSnack('Color no disponible.');
      return;
    }

    if (_calzadoId == null || _tallaSeleccionada == null) return;
    setState(() => _cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      int total = 0;
      final Set<int> tacosSet = {};

      for (final fila in filasSnap.docs) {
        final subfilasSnap = await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: _tallaSeleccionada)
            .where('colores', isEqualTo: color)
            .get();

        for (final sub in subfilasSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
          final taco = sub['taco'] ?? 0;
          if (_tipoTieneTaco && taco > 0) tacosSet.add(taco as int);
        }
      }

      setState(() {
        _stockDisponible = total;
        _tacosDisponibles = tacosSet.toList()..sort();
        _tacoSeleccionado = null;
        _plataformaSeleccionada = null;
        _cargandoStock = false;
      });

      if (!_tipoTieneTaco) {
        _cargarSiguientePaso(talla: _tallaSeleccionada, color: color);
      }
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorTaco(int taco) async {
    setState(() => _cargandoStock = true);
    try {
      int total = 0;
      final Set<String> platSet = {};
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      for (final fila in filasSnap.docs) {
        Query q = FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: _tallaSeleccionada)
            .where('taco', isEqualTo: taco);

        if (_tipoTieneColores) {
          q = q.where('colores', isEqualTo: _colorSeleccionado);
        }

        final subSnap = await q.get();
        for (final sub in subSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
          if (_tipoTienePlataforma) {
            final p = sub['plataforma']?.toString() ?? '';
            if (p.isNotEmpty) platSet.add(p);
          }
        }
      }

      setState(() {
        _stockDisponible = total;
        _plataformasDisponibles = platSet.toList()..sort();
        _tacoSeleccionado = taco;
        _plataformaSeleccionada = null;
        _cargandoStock = false;
      });

      if (!_tipoTienePlataforma) {
        _cantidadVenta = 0;
        _cantidadController.clear();
      }
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  // 🔹 Método para saltar pasos y cargar opciones de plataforma
  Future<void> _cargarSiguientePaso(
      {int? talla, String? color, int? taco}) async {
    final Set<String> platSet = {};
    final filasSnap = await FirebaseFirestore.instance
        .collection('fila_inventario')
        .where('calzado_id', isEqualTo: _calzadoId)
        .get();

    for (final fila in filasSnap.docs) {
      Query q = FirebaseFirestore.instance
          .collection('subfila_inventario')
          .where('fila_inventario_id', isEqualTo: fila.id)
          .where('talla', isEqualTo: talla ?? _tallaSeleccionada);

      if (_tipoTieneColores) {
        q = q.where('colores', isEqualTo: color ?? _colorSeleccionado);
      }
      if (_tipoTieneTaco) {
        q = q.where('taco', isEqualTo: taco ?? _tacoSeleccionado ?? 0);
      }

      final subSnap = await q.get();
      for (final sub in subSnap.docs) {
        if (_tipoTienePlataforma) {
          final p = sub['plataforma']?.toString() ?? '';
          if (p.isNotEmpty) platSet.add(p);
        }
      }
    }
    setState(() => _plataformasDisponibles = platSet.toList()..sort());
  }

  Future<void> _calcularStockFinal(String plataforma) async {
    print('Calculando stock para plataforma: $plataforma');
    if (_plataformasDisponibles.contains(plataforma)) {
      _errorPlataforma = false;
    } else {
      setState(() {
        _errorPlataforma = true;
        _plataformaSeleccionada = null;
      });
      _mostrarSnack('Plataforma no disponible, seleccione otra.');
      return;
    }

    if (_calzadoId == null || _tallaSeleccionada == null) return;
    setState(() => _cargandoStock = true);
    try {
      int total = 0;
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      for (final fila in filasSnap.docs) {
        Query q = FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: _tallaSeleccionada)
            .where('plataforma', isEqualTo: plataforma);

        if (_tipoTieneColores) {
          q = q.where('colores', isEqualTo: _colorSeleccionado);
        }
        if (_tipoTieneTaco) {
          q = q.where('taco', isEqualTo: _tacoSeleccionado ?? 0);
        }

        final subSnap = await q.get();
        for (final sub in subSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
        }
      }
      setState(() {
        _stockDisponible = total;
        _cargandoStock = false;
      });
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  // -------------------------------------------------------
  // UI HELPERS
  // -------------------------------------------------------

  void _mostrarSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool get _puedeVender {
    if (_calzadoId == null || _tallaSeleccionada == null) return false;
    if (_tipoTieneColores && _colorSeleccionado == null) return false;
    if (_tipoTieneTaco && _tacoSeleccionado == null) return false;
    if (_tipoTienePlataforma && _plataformaSeleccionada == null) return false;
    if (_metodoPagoSeleccionado == null) return false;
    if (_lugarVentaSeleccionado == null) return false;
    if (_cantidadVenta <= 0 ||
        _stockDisponible <= 0 ||
        _cantidadVenta > _stockDisponible) return false;
    if (_precioVentaTotal <= 0) return false;
    return true;
  }

  String? get _mensajeBloqueo {
    if (_calzadoId == null || _tallaSeleccionada == null) return null;
    if (_stockDisponible == 0) return 'Sin stock disponible';
    if (_cantidadVenta > 0 && _cantidadVenta > _stockDisponible) {
      return 'No hay suficiente stock (disponible: $_stockDisponible)';
    }
    return null;
  }

  // ... (Métodos _realizarVenta, _obtenerIconoTipo, etc. se mantienen con la lógica de String en plataforma)

  Future<void> _realizarVenta() async {
    if (!_puedeVender) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const SplashScreen02());
    try {
      final db = FirebaseFirestore.instance;
      final ventaMap = {
        'calzado_id': _calzadoId,
        'talla': _tallaSeleccionada,
        'colores': _tipoTieneColores ? _colorSeleccionado : '',
        'taco': _tipoTieneTaco ? _tacoSeleccionado ?? 0 : 0,
        'plataforma': _tipoTienePlataforma ? _plataformaSeleccionada : '',
        'cantidad': _cantidadVenta,
        'precio_venta_total': _precioVentaTotal,
        'metodo_pago': _metodoPagoSeleccionado, // 🔹 Nuevo
        'lugar_venta': _lugarVentaSeleccionado, // 🔹 Nuevo
        'fecha_venta': Timestamp.now(),
        'usuario_creacion': widget.firstName ?? 'anon',
      };

      final ventaRef = await db.collection('venta').add(ventaMap);
      await db.collection('fila_venta').add({
        ...ventaMap,
        'id_inventario': widget.inventarioId,
        'venta_id': ventaRef.id,
        'fecha_creacion': Timestamp.now(),
        'email_user': widget.emailUser ?? 'anon',
      });

      // Descuento en inventario
      int cantidadPorDescontar = _cantidadVenta;
      final filasSnap = await db
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      for (final fila in filasSnap.docs) {
        if (cantidadPorDescontar <= 0) break;
        Query subQuery = db
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: _tallaSeleccionada);

        if (_tipoTieneColores) {
          subQuery = subQuery.where('colores', isEqualTo: _colorSeleccionado);
        }
        if (_tipoTieneTaco) {
          subQuery = subQuery.where('taco', isEqualTo: _tacoSeleccionado);
        }
        if (_tipoTienePlataforma) {
          subQuery =
              subQuery.where('plataforma', isEqualTo: _plataformaSeleccionada);
        }

        final subfilasSnap = await subQuery.get();
        for (final subDoc in subfilasSnap.docs) {
          if (cantidadPorDescontar <= 0) break;
          final cantActual = (subDoc['cantidad'] ?? 0) as int;
          final desc = cantidadPorDescontar > cantActual
              ? cantActual
              : cantidadPorDescontar;
          cantidadPorDescontar -= desc;

          if (cantActual - desc <= 0) {
            await subDoc.reference.delete();
          } else {
            await subDoc.reference.update({'cantidad': cantActual - desc});
          }
          await fila.reference
              .update({'cantidad': FieldValue.increment(-desc)});
        }
      }

      if (Navigator.canPop(context)) Navigator.pop(context);
      _mostrarSnack('Venta registrada correctamente');
      Navigator.pop(context, true);
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _mostrarSnack('Error: $e');
    }
  }

  // -------------------------------------------------------
  // UI COMPONENTS
  // -------------------------------------------------------

  Widget _buildDropdownCalzado(List<QueryDocumentSnapshot> calzados) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
          labelText: 'Seleccionar código', border: OutlineInputBorder()),
      value: _calzadoId,
      items: calzados.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DropdownMenuItem<String>(
          value: doc.id,
          child: FutureBuilder<String?>(
            future: _obtenerIconoTipo(data['tipo_calzado_id'] ?? ''),
            builder: (context, iconSnapshot) {
              final icono = iconSnapshot.data;
              return Row(children: [
                if (icono != null) Image.asset(icono, width: 32, height: 32),
                const SizedBox(width: 8),
                Text(data['nombre'] ?? ''),
              ]);
            },
          ),
        );
      }).toList(),
      onChanged: (v) async {
        if (v == null) return;
        final doc =
            await FirebaseFirestore.instance.collection('calzado').doc(v).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _tipoTieneTaco = data['taco'] ?? false;
            _tipoTienePlataforma = data['plataforma'] ?? false;
            _tipoTieneColores = data['colores'] ?? false;
            _calzadoId = v;
            _errorTalla = false;
            _errorColor = false;
            _errorPlataforma = false;
          });
        }
        await _calcularStockPorCalzado(v);
      },
    );
  }

  Widget _buildDropdownTalla() {
    if (_calzadoId == null || _tallasDisponibles.isEmpty || _errorTalla) {
      _errorTalla = false;
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
            labelText: 'Seleccionar talla', border: OutlineInputBorder()),
        value: _tallaSeleccionada,
        items: _tallasDisponibles
            .map((t) => DropdownMenuItem(value: t, child: Text(t.toString())))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _tallaSeleccionada = v;
            _cantidadVenta = 0;
          });
          _calcularStockPorTalla(v);
        },
      ),
    );
  }

  Widget _buildDropdownColor() {
    if (!_tipoTieneColores || _coloresDisponibles.isEmpty || _errorColor) {
      _errorColor = false;
      return const SizedBox();
    }

    if (_colorSeleccionado != null &&
        !_coloresDisponibles.contains(_colorSeleccionado)) {
      _colorSeleccionado = null;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
            labelText: 'Seleccionar color',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.palette)),
        value: _colorSeleccionado,
        items: _coloresDisponibles
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _colorSeleccionado = v;
            _cantidadVenta = 0;
          });
          _calcularStockPorColor(v);
        },
      ),
    );
  }

  Widget _buildDropdownTaco() {
    if (!_tipoTieneTaco || _tacosDisponibles.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
            labelText: 'Seleccionar taco (cm)', border: OutlineInputBorder()),
        value: _tacoSeleccionado,
        items: _tacosDisponibles
            .map((t) => DropdownMenuItem(value: t, child: Text('$t cm')))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          _calcularStockPorTaco(v);
        },
      ),
    );
  }

  Widget _buildDropdownPlataforma() {
    if (!_tipoTienePlataforma ||
        _plataformasDisponibles.isEmpty ||
        _errorPlataforma) {
      _errorPlataforma = false;
      return const SizedBox();
    }

    if (_plataformaSeleccionada != null &&
        !_plataformasDisponibles.contains(_plataformaSeleccionada)) {
      _plataformaSeleccionada = null;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Seleccionar plataforma',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.layers_outlined),
        ),
        value: _plataformaSeleccionada,
        items: _plataformasDisponibles
            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _plataformaSeleccionada = v;
            _cantidadVenta = 0;
            _cantidadController.clear();
          });
          _calcularStockFinal(v);
        },
      ),
    );
  }

  Future<String?> _obtenerIconoTipo(String id) async {
    if (_iconCache.containsKey(id)) return _iconCache[id];
    final snap = await FirebaseFirestore.instance
        .collection('tipo_calzado')
        .doc(id)
        .get();
    _iconCache[id] = snap.data()?['icono'];
    return _iconCache[id];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain('Nueva Venta'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStockLabel(),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('calzado')
                    .where('id_inventario', isEqualTo: widget.inventarioId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return _buildDropdownCalzado(snapshot.data!.docs);
                },
              ),
              _buildDropdownTalla(),
              _buildDropdownColor(),
              _buildDropdownTaco(),
              _buildDropdownPlataforma(),
              _buildCantidadYPrecio(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _puedeVender ? Colors.green.shade600 : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Registrar venta'),
                  onPressed: _puedeVender ? _realizarVenta : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _stockDisponible > 0 ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
            color: _stockDisponible > 0
                ? Colors.green.shade300
                : Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Stock disponible:'),
          _cargandoStock
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text('$_stockDisponible unidades',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildMetodoYLugar() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            // Dropdown Metodo de Pago
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Método de Pago',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                value: _metodoPagoSeleccionado,
                items: _metodosPago
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _metodoPagoSeleccionado = v),
              ),
            ),
            const SizedBox(width: 10),
            // Dropdown Lugar de Venta
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Lugar de Venta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                value: _lugarVentaSeleccionado,
                items: _lugaresVenta
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _lugarVentaSeleccionado = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCantidadYPrecio() {
    final bool camposListos = _tallaSeleccionada != null &&
        (!_tipoTieneColores || _colorSeleccionado != null) &&
        (!_tipoTieneTaco || _tacoSeleccionado != null) &&
        (!_tipoTienePlataforma || _plataformaSeleccionada != null);

    if (!camposListos) return const SizedBox();

    return Column(children: [
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: TextFormField(
          controller: _cantidadController,
          decoration: const InputDecoration(
              labelText: 'Cantidad', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            setState(() {
              _cantidadVenta = int.tryParse(v) ?? 0;

              if (_cantidadVenta <= 0) {
                // 🔹 SI ES CERO O BORRAN, LIMPIEZA TOTAL: esto lo deja vacío en la pantalla
                _precioController.clear();
              }
            });
          },
        )),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _precioController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              // 🔹 Bloquea cualquier cosa que no sea número o punto decimal (máx 2 decimales)
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Precio Total',
              border: OutlineInputBorder(),
              prefixText: 'S/ ',
              // 🔹 Usamos hintText para que el usuario sepa qué escribir sin tener un valor real
              hintText: 'Ingrese monto',
            ),
            onChanged: (v) {
              setState(() {
                // 🔹 Solo parseamos si hay texto, si no, se queda en 0.0 interno para la lógica
                if (v.isEmpty) {
                  _precioVentaTotal = 0.0;
                } else {
                  _precioVentaTotal = double.tryParse(v) ?? 0.0;
                }
              });
            },
          ),
        ),
      ]),

      // 🔹 AQUÍ AGREGAMOS LOS NUEVOS SELECTORES
      _buildMetodoYLugar(),

      if (_mensajeBloqueo != null)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_mensajeBloqueo!,
                style: const TextStyle(color: Colors.orange))),
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? _colorSeleccionado; // 🔥 Agregado
  int? _tacoSeleccionado;
  bool? _plataformaSeleccionada = false;

  // --- Flags del calzado seleccionado ---
  bool _tipoTieneTaco = false;
  bool _tipoTienePlataforma = false;
  bool _tipoTieneColores = false; // 🔥 Agregado
  double _precioBaseFirestore = 0.0;

  // --- Stock y cantidad ---
  int _stockDisponible = 0;
  int _cantidadVenta = 0;
  double _precioVentaTotal = 0.0;
  bool _cargandoStock = false;

  // --- Opciones disponibles según filtros ---
  List<int> _tallasDisponibles = [];
  List<String> _coloresDisponibles = []; // 🔥 Agregado
  List<int> _tacosDisponibles = [];

  bool _errorTalla = false;

  final Map<String, String?> _iconCache = {};
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

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
        _colorSeleccionado = null; // Reset cascada
        _tacoSeleccionado = null;
        _plataformaSeleccionada = false;
        _coloresDisponibles = [];
        _tacosDisponibles = [];
        _cargandoStock = false;
      });
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorTalla(int talla) async {
    if (_tallasDisponibles.contains(_tallaSeleccionada)) {
      print('''Talla seleccionada es válida: $_tallaSeleccionada''');
    } else {
      print('''Talla seleccionada es invalida: $_tallaSeleccionada''');
      setState(() {
        _errorTalla = true;
        _tallaSeleccionada = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontraron tallas disponibles para este calzado, vuelve a seleccionar la talla',
          ),
        ),
      );
      return;
    }
    if (_calzadoId == null) return;
    setState(() => _cargandoStock = true,);
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
        _plataformaSeleccionada = false;
        _tacosDisponibles = [];
        _cargandoStock = false;
      });

      // Si no tiene colores, saltar a cargar tacos directamente
      if (!_tipoTieneColores) {
        _cargarTacosDirecto(talla);
      }
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  // 🔥 NUEVO: Método para continuar cascada despues de Color
  Future<void> _calcularStockPorColor(String color) async {
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
        _plataformaSeleccionada = false;
        _cargandoStock = false;
      });
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  // Auxiliar si el calzado no maneja colores
  Future<void> _cargarTacosDirecto(int talla) async {
    final Set<int> tacosSet = {};
    final filasSnap = await FirebaseFirestore.instance
        .collection('fila_inventario')
        .where('calzado_id', isEqualTo: _calzadoId).get();

    for (final fila in filasSnap.docs) {
      final subSnap = await FirebaseFirestore.instance
          .collection('subfila_inventario')
          .where('fila_inventario_id', isEqualTo: fila.id)
          .where('talla', isEqualTo: talla).get();
      for (final sub in subSnap.docs) {
        final taco = sub['taco'] ?? 0;
        if (_tipoTieneTaco && taco > 0) tacosSet.add(taco as int);
      }
    }
    setState(() => _tacosDisponibles = tacosSet.toList()..sort());
  }

  Future<void> _calcularStockPorTaco(int taco) async {
    if (_calzadoId == null || _tallaSeleccionada == null) return;
    setState(() => _cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      int total = 0;
      for (final fila in filasSnap.docs) {
        Query q = FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: _tallaSeleccionada)
            .where('taco', isEqualTo: taco)
            .where('plataforma', isEqualTo: false);
        
        if (_tipoTieneColores && _colorSeleccionado != null) {
          q = q.where('colores', isEqualTo: _colorSeleccionado);
        }

        final subfilasSnap = await q.get();
        for (final sub in subfilasSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
        }
      }

      setState(() {
        _stockDisponible = total;
        _plataformaSeleccionada = false;
        _cargandoStock = false;
      });
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _calcularStockCompleto() async {
    if (_calzadoId == null || _tallaSeleccionada == null) return;
    setState(() => _cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      int total = 0;
      for (final fila in filasSnap.docs) {
        Query q = FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: _tallaSeleccionada);

        if (_tipoTieneColores && _colorSeleccionado != null) q = q.where('colores', isEqualTo: _colorSeleccionado);
        if (_tipoTieneTaco && _tacoSeleccionado != null) q = q.where('taco', isEqualTo: _tacoSeleccionado);
        if (_tipoTienePlataforma) q = q.where('plataforma', isEqualTo: _plataformaSeleccionada);

        final subfilasSnap = await q.get();
        for (final sub in subfilasSnap.docs) {
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
  // VALIDACION Y GUARDADO
  // -------------------------------------------------------

  bool get _puedeVender {
    if (_calzadoId == null) return false;
    if (_tallaSeleccionada == null) return false;
    if (_tipoTieneColores && _colorSeleccionado == null) return false;
    if (_cantidadVenta <= 0 || _stockDisponible <= 0 || _cantidadVenta > _stockDisponible) return false;
    if (_precioVentaTotal <= 0) return false;
    return true;
  }

  String? get _mensajeBloqueo {
    if (_calzadoId == null || _tallaSeleccionada == null) return null;
    if (_stockDisponible == 0) return 'Sin stock disponible para esta seleccion';
    if (_cantidadVenta > 0 && _cantidadVenta > _stockDisponible) return 'No hay suficiente stock (disponible: $_stockDisponible)';
    return null;
  }

  void _mostrarSplashScreen() {
    showDialog(context: context, barrierDismissible: false, useRootNavigator: true, builder: (_) => const SplashScreen02());
  }

  void _ocultarSplashScreen() {
    if (Navigator.of(context, rootNavigator: true).canPop()) Navigator.of(context, rootNavigator: true).pop();
  }

  Future<String?> _obtenerIconoTipo(String tipoCalzadoId) async {
    if (_iconCache.containsKey(tipoCalzadoId)) return _iconCache[tipoCalzadoId];
    final tipoSnap = await FirebaseFirestore.instance.collection('tipo_calzado').doc(tipoCalzadoId).get();
    String? icono = tipoSnap.data()?['icono']?.toString();
    _iconCache[tipoCalzadoId] = icono;
    return icono;
  }

  Future<void> _realizarVenta() async {
    if (!_puedeVender) return;
    _mostrarSplashScreen();
    try {
      final db = FirebaseFirestore.instance;
      final ventaRef = await db.collection('venta').add({
        'calzado_id': _calzadoId,
        'talla': _tallaSeleccionada,
        'colores': _tipoTieneColores ? _colorSeleccionado : '', // 🔥 Guardar color
        'taco': _tipoTieneTaco ? _tacoSeleccionado ?? 0 : 0,
        'plataforma': _tipoTienePlataforma ? _plataformaSeleccionada : false,
        'cantidad': _cantidadVenta,
        'precio_venta_total': _precioVentaTotal,
        'fecha_venta': Timestamp.now(),
        'usuario_creacion': widget.firstName ?? 'anon',
      });

      await db.collection('fila_venta').add({
        'id_inventario': widget.inventarioId,
        'venta_id': ventaRef.id,
        'calzado_id': _calzadoId,
        'talla': _tallaSeleccionada,
        'colores': _tipoTieneColores ? _colorSeleccionado : '', // 🔥 Guardar color
        'taco': _tipoTieneTaco ? _tacoSeleccionado ?? 0 : 0,
        'plataforma': _tipoTienePlataforma ? _plataformaSeleccionada : false,
        'cantidad': _cantidadVenta,
        'precio_venta_total': _precioVentaTotal,
        'fecha_creacion': Timestamp.now(),
        'usuario_creacion': widget.firstName ?? 'anon',
        'email_user': widget.emailUser ?? 'anon',
      });

      // Descuento inventario
      // --- Descuento de inventario en cascada (Subfila y Fila) ---
int cantidadPorDescontar = _cantidadVenta;
final filasSnap = await db.collection('fila_inventario')
    .where('calzado_id', isEqualTo: _calzadoId)
    .get();

for (final fila in filasSnap.docs) {
  if (cantidadPorDescontar <= 0) break;

  Query subQuery = db.collection('subfila_inventario')
      .where('fila_inventario_id', isEqualTo: fila.id)
      .where('talla', isEqualTo: _tallaSeleccionada);
  
  if (_tipoTieneColores) subQuery = subQuery.where('colores', isEqualTo: _colorSeleccionado);
  if (_tipoTieneTaco && _tacoSeleccionado != null) subQuery = subQuery.where('taco', isEqualTo: _tacoSeleccionado);
  if (_tipoTienePlataforma) subQuery = subQuery.where('plataforma', isEqualTo: _plataformaSeleccionada);

  final subfilasSnap = await subQuery.get();

  for (final subDoc in subfilasSnap.docs) {
    if (cantidadPorDescontar <= 0) break;

    final cantidadActualSub = (subDoc['cantidad'] ?? 0) as int;
    final descuento = cantidadPorDescontar > cantidadActualSub ? cantidadActualSub : cantidadPorDescontar;
    
    cantidadPorDescontar -= descuento;

    // 1. ACTUALIZAR SUBFILA (Talla/Color/Taco específico)
    if (cantidadActualSub - descuento <= 0) {
      await subDoc.reference.delete();
    } else {
      await subDoc.reference.update({
        'cantidad': cantidadActualSub - descuento
      });
    }

    // 2. ACTUALIZAR FILA (Nivel General - LO QUE FALTABA)
    // Usamos increment con valor negativo para restar directamente en la DB
    await fila.reference.update({
      'cantidad': FieldValue.increment(-descuento)
    });
  }

  // 3. LIMPIEZA DE FILA (Opcional)
  // Si después de los descuentos la fila quedó en 0 o menos, la eliminamos
  final filaActualizada = await fila.reference.get();
  if ((filaActualizada.data()?['cantidad'] ?? 0) <= 0) {
    await fila.reference.delete();
  }
}
      _ocultarSplashScreen();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta registrada correctamente')));
      Navigator.pop(context, true);
    } catch (e) {
      _ocultarSplashScreen();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _actualizarPrecioSugerido() {
    setState(() {
      _precioVentaTotal = _precioBaseFirestore * _cantidadVenta;
      _precioController.text = _precioVentaTotal.toString();
    });
  }

  // -------------------------------------------------------
  // UI COMPONENTS
  // -------------------------------------------------------

  Widget _buildDropdownCalzado(List<QueryDocumentSnapshot> calzados) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Seleccionar código', border: OutlineInputBorder()),
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
        final doc = await FirebaseFirestore.instance.collection('calzado').doc(v).get();
        if (doc.exists) {
          final data = doc.data()!;
          _tipoTieneTaco = data['taco'] ?? false;
          _tipoTienePlataforma = data['plataforma'] ?? false;
          _tipoTieneColores = data['colores'] ?? false; // 🔥 Flag de colores
          _precioBaseFirestore = (data['precio'] ?? 0).toDouble();
        }
        setState(() {
          _calzadoId = v;
          _cantidadVenta = 0;
          _cantidadController.clear();
          _precioController.clear();
        });
        await _calcularStockPorCalzado(v);
      },
    );
  }

  Widget _buildDropdownTalla() {
    if (_calzadoId == null || _tallasDisponibles.isEmpty || _errorTalla) {
      _errorTalla = false; // 🔥 resetear flag de error para que al seleccionar otro calzado no se quede bloqueado
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: 'Seleccionar talla', border: OutlineInputBorder()),
        value: _tallaSeleccionada,
        items: _tallasDisponibles.map((t) => DropdownMenuItem<int>(value: t, child: Text(t.toString()))).toList(),
        onChanged: (v) async {
          if (v == null) return;
          setState(() {
            _tallaSeleccionada = v;
            _cantidadVenta = 0;
            _cantidadController.clear();
          });
          await _calcularStockPorTalla(v);
        },
      ),
    );
  }

  // 🔥 NUEVO: UI Dropdown Color
  Widget _buildDropdownColor() {
    if (!_tipoTieneColores || _tallaSeleccionada == null || _coloresDisponibles.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Seleccionar color', border: OutlineInputBorder(), prefixIcon: Icon(Icons.palette)),
        value: _colorSeleccionado,
        items: _coloresDisponibles.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
        onChanged: (v) async {
          if (v == null) return;
          setState(() {
            _colorSeleccionado = v;
            _cantidadVenta = 0;
            _cantidadController.clear();
          });
          await _calcularStockPorColor(v);
        },
      ),
    );
  }

  Widget _buildDropdownTaco() {
    if (!_tipoTieneTaco || _tallaSeleccionada == null || (_tipoTieneColores && _colorSeleccionado == null) || _tacosDisponibles.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: 'Seleccionar taco (cm)', border: OutlineInputBorder()),
        value: _tacoSeleccionado,
        items: _tacosDisponibles.map((t) => DropdownMenuItem<int>(value: t, child: Text('$t cm'))).toList(),
        onChanged: (v) async {
          if (v == null) return;
          setState(() {
            _tacoSeleccionado = v;
            _cantidadVenta = 0;
            _cantidadController.clear();
          });
          await _calcularStockPorTaco(v);
        },
      ),
    );
  }

  Widget _buildCheckboxPlataforma() {
    final mostrar = _tipoTienePlataforma && _tallaSeleccionada != null && 
                  (!_tipoTieneColores || _colorSeleccionado != null) &&
                  (!_tipoTieneTaco || _tacoSeleccionado != null);
    if (!mostrar) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: [
        const Text('Con plataforma'),
        Checkbox(
          value: _plataformaSeleccionada,
          onChanged: (v) async {
            setState(() {
              _plataformaSeleccionada = v ?? false;
              _cantidadVenta = 0;
              _cantidadController.clear();
            });
            await _calcularStockCompleto();
          },
        ),
      ]),
    );
  }

  // ... (Resto de métodos UI: _buildStockLabel, _buildCantidadYPrecio, build Scaffold se mantienen igual)
  
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
                stream: FirebaseFirestore.instance.collection('calzado')
                    .where('id_inventario', isEqualTo: widget.inventarioId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return _buildDropdownCalzado(snapshot.data!.docs);
                },
              ),
              _buildDropdownTalla(),
              _buildDropdownColor(), // 🔥 Insertado en la cascada
              _buildDropdownTaco(),
              _buildCheckboxPlataforma(),
              _buildCantidadYPrecio(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _puedeVender ? Colors.green.shade600 : Colors.grey,
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

  // --- Métodos de UI que faltaban copiar ---
  Widget _buildStockLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _stockDisponible > 0 ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(color: _stockDisponible > 0 ? Colors.green.shade300 : Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Stock disponible:'),
          _cargandoStock 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text('$_stockDisponible unidades', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildCantidadYPrecio() {
    if (_tallaSeleccionada == null || (_tipoTieneColores && _colorSeleccionado == null)
                                   || (_tipoTieneTaco && _tacoSeleccionado == null)) return const SizedBox();
    return Column(children: [
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextFormField(
          controller: _cantidadController,
          decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (v) { _cantidadVenta = int.tryParse(v) ?? 0; _actualizarPrecioSugerido(); },
        )),
        const SizedBox(width: 10),
        Expanded(child: TextFormField(
          controller: _precioController,
          decoration: const InputDecoration(labelText: 'Precio Total', border: OutlineInputBorder(), prefixText: 'S/ '),
          keyboardType: TextInputType.number,
          onChanged: (v) => setState(() => _precioVentaTotal = double.tryParse(v) ?? 0.0),
        )),
      ]),
      if (_mensajeBloqueo != null) Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(_mensajeBloqueo!, style: const TextStyle(color: Colors.orange)),
      )
    ]);
  }
}
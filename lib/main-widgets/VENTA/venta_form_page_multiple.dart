import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';

// Modelo para manejar cada fila de venta independiente
class VentaItem {
  String? calzadoId;
  int? tallaSeleccionada;
  int? tacoSeleccionado;
  bool plataformaSeleccionada = false;
  int stockDisponible = 0;
  int cantidadVenta = 0;
  bool cargandoStock = false;
  List<int> tallasDisponibles = [];
  List<int> tacosDisponibles = [];
  bool tipoTieneTaco = false;
  bool tipoTienePlataforma = false;
  bool bloqueandoTalla = false;
  bool errorTalla = false; // 🔥 Flag de error por item
  final TextEditingController cantidadController = TextEditingController();

  void dispose() {
    cantidadController.dispose();
  }
}

class VentaFormPageMultiple extends StatefulWidget {
  final String? firstName;
  const VentaFormPageMultiple({super.key, required this.firstName});

  @override
  State<VentaFormPageMultiple> createState() => _VentaFormPageMultipleState();
}

class _VentaFormPageMultipleState extends State<VentaFormPageMultiple> {
  final List<VentaItem> _itemsVenta = [];
  final Map<String, String?> _iconCache = {};

  @override
  void initState() {
    super.initState();
    _agregarNuevoItem();
  }

  @override
  void dispose() {
    for (var item in _itemsVenta) {
      item.dispose();
    }
    super.dispose();
  }

  void _agregarNuevoItem() {
    setState(() {
      _itemsVenta.add(VentaItem());
    });
  }

  void _eliminarItem(int index) {
    if (_itemsVenta.length > 1) {
      setState(() {
        _itemsVenta[index].dispose();
        _itemsVenta.removeAt(index);
      });
    }
  }

  bool _esCombinacionDuplicada(int indexActual) {
    var actual = _itemsVenta[indexActual];
    if (actual.calzadoId == null || actual.tallaSeleccionada == null) return false;

    for (int i = 0; i < _itemsVenta.length; i++) {
      if (i == indexActual) continue;
      var item = _itemsVenta[i];
      if (item.calzadoId == actual.calzadoId &&
          item.tallaSeleccionada == actual.tallaSeleccionada &&
          item.tacoSeleccionado == actual.tacoSeleccionado &&
          item.plataformaSeleccionada == actual.plataformaSeleccionada) {
        return true;
      }
    }
    return false;
  }

  // -------------------------------------------------------
  // CALCULOS DE STOCK (CON TU LOGICA DE TALLA INTEGRADA)
  // -------------------------------------------------------

  Future<void> _calcularStockPorCalzado(int index, String calzadoId) async {
    setState(() => _itemsVenta[index].cargandoStock = true);
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
        var item = _itemsVenta[index];
        item.stockDisponible = total;
        item.tallasDisponibles = tallasSet.toList()..sort();
        item.tallaSeleccionada = null;
        item.tacoSeleccionado = null;
        item.plataformaSeleccionada = false;
        item.tacosDisponibles = [];
        item.cargandoStock = false;
        item.errorTalla = false; // Reset error al cambiar calzado
      });
    } catch (e) {
      setState(() => _itemsVenta[index].cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorTalla(int index, int talla) async {
    var item = _itemsVenta[index];
    print('''Calculando stock por talla: $talla''');

    // --- TU LÓGICA DE VALIDACIÓN ---
    if (item.tallasDisponibles.contains(talla)) {
      print('''Talla seleccionada es válida: $talla''');
    } else {
      print('''Talla seleccionada es invalida: $talla''');
      setState(() {
        item.errorTalla = true;
        item.tallaSeleccionada = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontraron tallas disponibles para este calzado, vuelve a seleccionar la talla'),
        ),
      );
      return;
    }
    // -------------------------------

    if (item.calzadoId == null) return;
    
    setState(() => item.cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: item.calzadoId)
          .get();

      int total = 0;
      final Set<int> tacosSet = {};

      for (final fila in filasSnap.docs) {
        final subfilasSnap = await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: talla)
            .get();

        for (final sub in subfilasSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
          final taco = sub['taco'] ?? 0;
          if (item.tipoTieneTaco && taco > 0) tacosSet.add(taco as int);
        }
      }

      setState(() {
        item.stockDisponible = total;
        item.tacosDisponibles = tacosSet.toList()..sort();
        item.tacoSeleccionado = null;
        item.plataformaSeleccionada = false;
        item.cargandoStock = false;
      });

      if (_esCombinacionDuplicada(index)) {
        _notificarDuplicado(index);
      }
    } catch (e) {
      setState(() => item.cargandoStock = false);
    }
  }

  Future<void> _calcularStockCompleto(int index) async {
    var item = _itemsVenta[index];
    if (item.calzadoId == null || item.tallaSeleccionada == null) return;
    
    setState(() => item.cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: item.calzadoId)
          .get();

      int total = 0;
      for (final fila in filasSnap.docs) {
        Query subQuery = FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: item.tallaSeleccionada);

        if (item.tipoTieneTaco && item.tacoSeleccionado != null) {
          subQuery = subQuery.where('taco', isEqualTo: item.tacoSeleccionado);
        }
        if (item.tipoTienePlataforma) {
          subQuery = subQuery.where('plataforma', isEqualTo: item.plataformaSeleccionada);
        }

        final subfilasSnap = await subQuery.get();
        for (final sub in subfilasSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
        }
      }

      setState(() {
        item.stockDisponible = total;
        item.cargandoStock = false;
      });

      if (_esCombinacionDuplicada(index)) {
        _notificarDuplicado(index);
      }
    } catch (e) {
      setState(() => item.cargandoStock = false);
    }
  }

  void _notificarDuplicado(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esta combinación ya está en la lista de venta.')),
    );
    setState(() {
      _itemsVenta[index].tallaSeleccionada = null;
      _itemsVenta[index].cantidadVenta = 0;
      _itemsVenta[index].cantidadController.clear();
    });
  }

  // -------------------------------------------------------
  // GUARDAR VENTA (MULTI)
  // -------------------------------------------------------

  Future<void> _realizarVenta() async {
    if (!_itemsVenta.every((i) => i.calzadoId != null && i.tallaSeleccionada != null && i.cantidadVenta > 0 && i.cantidadVenta <= i.stockDisponible)) return;
    _mostrarSplashScreen();

    try {
      final db = FirebaseFirestore.instance;

      for (var item in _itemsVenta) {
        final ventaRef = await db.collection('venta').add({
          'calzado_id': item.calzadoId,
          'talla': item.tallaSeleccionada,
          'taco': item.tipoTieneTaco ? item.tacoSeleccionado ?? 0 : 0,
          'plataforma': item.tipoTienePlataforma ? item.plataformaSeleccionada : false,
          'cantidad': item.cantidadVenta,
          'fecha_venta': Timestamp.now(),
          'usuario_creacion': widget.firstName ?? 'anon',
        });

        await db.collection('fila_venta').add({
          'venta_id': ventaRef.id,
          'calzado_id': item.calzadoId,
          'talla': item.tallaSeleccionada,
          'taco': item.tipoTieneTaco ? item.tacoSeleccionado ?? 0 : 0,
          'plataforma': item.tipoTienePlataforma ? item.plataformaSeleccionada : false,
          'cantidad': item.cantidadVenta,
          'fecha_creacion': Timestamp.now(),
          'usuario_creacion': widget.firstName ?? 'anon',
        });

        int cantidadPorDescontar = item.cantidadVenta;
        final filasSnap = await db.collection('fila_inventario').where('calzado_id', isEqualTo: item.calzadoId).get();

        for (final fila in filasSnap.docs) {
          if (cantidadPorDescontar <= 0) break;
          Query subQuery = db.collection('subfila_inventario').where('fila_inventario_id', isEqualTo: fila.id).where('talla', isEqualTo: item.tallaSeleccionada);
          if (item.tipoTieneTaco && item.tacoSeleccionado != null) subQuery = subQuery.where('taco', isEqualTo: item.tacoSeleccionado);
          if (item.tipoTienePlataforma) subQuery = subQuery.where('plataforma', isEqualTo: item.plataformaSeleccionada);

          final subfilasSnap = await subQuery.get();
          for (final subDoc in subfilasSnap.docs) {
            if (cantidadPorDescontar <= 0) break;
            final cantidadActual = (subDoc['cantidad'] ?? 0) as int;
            final descuento = cantidadPorDescontar > cantidadActual ? cantidadActual : cantidadPorDescontar;
            cantidadPorDescontar -= descuento;
            final nuevaCantidad = cantidadActual - descuento;

            if (nuevaCantidad <= 0) {
              await subDoc.reference.delete();
            } else {
              await subDoc.reference.update({'cantidad': nuevaCantidad});
            }
          }
          final subRestantes = await db.collection('subfila_inventario').where('fila_inventario_id', isEqualTo: fila.id).get();
          if (subRestantes.docs.isEmpty) {
            await fila.reference.delete();
          } else {
            final nuevaCantFila = subRestantes.docs.fold<int>(0, (sum, d) => sum + ((d['cantidad'] ?? 0) as int));
            await fila.reference.update({'cantidad': nuevaCantFila});
          }
        }
      }

      _ocultarSplashScreen();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ventas registradas correctamente')));
      Navigator.pop(context, true);
    } catch (e) {
      _ocultarSplashScreen();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // -------------------------------------------------------
  // UI HELPERS & BUILDERS
  // -------------------------------------------------------

  Future<String?> _obtenerIconoTipo(String tipoCalzadoId) async {
    if (_iconCache.containsKey(tipoCalzadoId)) return _iconCache[tipoCalzadoId];
    final tipoSnap = await FirebaseFirestore.instance.collection('tipo_calzado').doc(tipoCalzadoId).get();
    String? icono = tipoSnap.data()?['icono']?.toString();
    _iconCache[tipoCalzadoId] = icono;
    return icono;
  }

  void _mostrarSplashScreen() => showDialog(context: context, barrierDismissible: false, builder: (_) => const SplashScreen02());
  void _ocultarSplashScreen() => Navigator.of(context, rootNavigator: true).canPop() ? Navigator.of(context, rootNavigator: true).pop() : null;

  Widget _buildDropdownCalzado(int index) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('calzado').where('usuario_creacion', isEqualTo: widget.firstName).where('activo', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Calzado', border: OutlineInputBorder()),
          value: _itemsVenta[index].calzadoId,
          items: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: FutureBuilder<String?>(
                future: _obtenerIconoTipo(data['tipo_calzado_id'] ?? ''),
                builder: (context, iconSnap) => Row(children: [
                  if (iconSnap.data != null) Image.asset(iconSnap.data!, width: 24, height: 24),
                  const SizedBox(width: 8),
                  Text(data['nombre'] ?? 'S/N'),
                ]),
              ),
            );
          }).toList(),
          onChanged: (v) async {
            if (v == null) return;
            final calzadoDoc = await FirebaseFirestore.instance.collection('calzado').doc(v).get();
            final data = calzadoDoc.data()!;
            setState(() {
              _itemsVenta[index].calzadoId = v;
              _itemsVenta[index].tipoTieneTaco = data['taco'] ?? false;
              _itemsVenta[index].tipoTienePlataforma = data['plataforma'] ?? false;
              _itemsVenta[index].errorTalla = false;
            });
            await _calcularStockPorCalzado(index, v);
          },
        );
      },
    );
  }

  Widget _buildDropdownTalla(int index) {
    var item = _itemsVenta[index];
    if (item.calzadoId == null || item.tallasDisponibles.isEmpty || item.errorTalla) {
      item.errorTalla = false; // Reset para permitir selección tras error
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: 'Talla', border: OutlineInputBorder()),
        value: item.tallaSeleccionada,
        items: item.tallasDisponibles.toSet().map((t) => DropdownMenuItem(value: t, child: Text(t.toString()))).toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() => item.tallaSeleccionada = v);
          _calcularStockPorTalla(index, v);
        },
      ),
    );
  }

  // ... (Resto de buildDropdownTaco, buildCheckboxPlataforma, buildCantidadVenta permanecen igual que la versión anterior)
  Widget _buildDropdownTaco(int index) {
    var item = _itemsVenta[index];
    if (!item.tipoTieneTaco || item.tallaSeleccionada == null || item.tacosDisponibles.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: 'Taco (cm)', border: OutlineInputBorder()),
        value: item.tacoSeleccionado,
        items: item.tacosDisponibles.map((t) => DropdownMenuItem(value: t, child: Text('$t cm'))).toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() => item.tacoSeleccionado = v);
          _calcularStockCompleto(index);
        },
      ),
    );
  }

  Widget _buildCheckboxPlataforma(int index) {
    var item = _itemsVenta[index];
    if (!item.tipoTienePlataforma || item.tallaSeleccionada == null) return const SizedBox();
    return Row(children: [
      const Text('Con plataforma'),
      Checkbox(value: item.plataformaSeleccionada, onChanged: (v) {
        setState(() => item.plataformaSeleccionada = v ?? false);
        _calcularStockCompleto(index);
      }),
    ]);
  }

  Widget _buildCantidadVenta(int index) {
    var item = _itemsVenta[index];
    if (item.tallaSeleccionada == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: item.cantidadController,
        decoration: InputDecoration(labelText: 'Cantidad', border: const OutlineInputBorder(), errorText: item.cantidadVenta > item.stockDisponible ? 'Excede stock' : null),
        keyboardType: TextInputType.number,
        onChanged: (v) => setState(() => item.cantidadVenta = int.tryParse(v) ?? 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool puedeVenderTodo = _itemsVenta.isNotEmpty && _itemsVenta.every((i) => i.calzadoId != null && i.tallaSeleccionada != null && i.cantidadVenta > 0 && i.cantidadVenta <= i.stockDisponible);

    return Scaffold(
      appBar: Designwidgets().appBarMain('Nueva Venta Multiple'),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _itemsVenta.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Producto #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (_itemsVenta.length > 1) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarItem(index)),
                    ]),
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: _itemsVenta[index].stockDisponible > 0 ? Colors.green.shade50 : Colors.red.shade50,
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Stock disponible:'),
                        _itemsVenta[index].cargandoStock ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : Text('${_itemsVenta[index].stockDisponible} unidades', style: TextStyle(fontWeight: FontWeight.bold, color: _itemsVenta[index].stockDisponible > 0 ? Colors.green : Colors.red)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownCalzado(index),
                    _buildDropdownTalla(index),
                    _buildDropdownTaco(index),
                    _buildCheckboxPlataforma(index),
                    _buildCantidadVenta(index),
                  ]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _agregarNuevoItem, icon: const Icon(Icons.add), label: const Text('Agregar otro producto'))),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: puedeVenderTodo ? Colors.green.shade600 : Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.shopping_cart_checkout),
                onPressed: puedeVenderTodo ? _realizarVenta : null,
                label: const Text('Registrar Venta Total'),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}
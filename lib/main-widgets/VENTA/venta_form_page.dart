import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';

class VentaFormPage extends StatefulWidget {
  final String? firstName;

  const VentaFormPage({
    super.key,
    required this.firstName,
  });

  @override
  State<VentaFormPage> createState() => _VentaFormPageState();
}

class _VentaFormPageState extends State<VentaFormPage> {
  // --- Selecciones del usuario ---
  String? _calzadoId;
  int? _tallaSeleccionada;
  int? _tacoSeleccionado;
  bool? _plataformaSeleccionada = false;

  // --- Flags del calzado seleccionado ---
  bool _tipoTieneTaco = false;
  bool _tipoTienePlataforma = false;

  // --- Stock y cantidad ---
  int _stockDisponible = 0;
  int _cantidadVenta = 0;
  bool _cargandoStock = false;

  // --- Opciones disponibles según filtros ---
  List<int> _tallasDisponibles = [];
  List<int> _tacosDisponibles = [];

  // --- Cache de iconos ---
  final Map<String, String?> _iconCache = {};

  // --- Controller para el campo cantidad ---
  final TextEditingController _cantidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calcularStockTotal();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------
  // CALCULOS DE STOCK
  // -------------------------------------------------------

  Future<void> _calcularStockTotal() async {
    setState(() => _cargandoStock = true);
    try {
      final calzadosSnap = await FirebaseFirestore.instance
          .collection('calzado')
          .where('usuario_creacion', isEqualTo: widget.firstName)
          .where('activo', isEqualTo: true)
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

      final tallasSorted = tallasSet.toList()..sort();

      setState(() {
        _stockDisponible = total;
        _tallasDisponibles = tallasSorted;
        _tallaSeleccionada = null;
        _tacoSeleccionado = null;
        _plataformaSeleccionada = false;
        _tacosDisponibles = [];
        _cargandoStock = false;
      });
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorTalla(int talla) async {
    if (_calzadoId == null) return;
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
            .where('talla', isEqualTo: talla)
            .get();

        for (final sub in subfilasSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
          final taco = sub['taco'] ?? 0;
          if (_tipoTieneTaco && taco > 0) tacosSet.add(taco as int);
        }
      }

      final tacosSorted = tacosSet.toList()..sort();

      setState(() {
        _stockDisponible = total;
        _tacosDisponibles = tacosSorted;
        _tacoSeleccionado = null;
        _plataformaSeleccionada = false;
        _cargandoStock = false;
      });
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorTaco(int taco) async {
    print('''Calculando stock por taco: $taco''');
    if (_calzadoId == null || _tallaSeleccionada == null) return;
    setState(() => _cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      int total = 0;
      for (final fila in filasSnap.docs) {
        final subfilasSnap = await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: _tallaSeleccionada)
            .where('taco', isEqualTo: taco)
            .where('plataforma', isEqualTo: _plataformaSeleccionada)
            .get();

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

  Future<void> _calcularStockPorPlataforma(bool plataforma) async {
    if (_calzadoId == null || _tallaSeleccionada == null) return;
    setState(() => _cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      int total = 0;
      for (final fila in filasSnap.docs) {
        final subfilasSnap = await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: _tallaSeleccionada)
            .where('plataforma', isEqualTo: plataforma)
            .get();

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

  Future<void> _calcularStockCompleto() async {
    if (_calzadoId == null || _tallaSeleccionada == null) return;
    if (!_tipoTieneTaco || _tacoSeleccionado == null) return;
    setState(() => _cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      int total = 0;
      for (final fila in filasSnap.docs) {
        final subfilasSnap = await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: _tallaSeleccionada)
            .where('taco', isEqualTo: _tacoSeleccionado)
            .where('plataforma', isEqualTo: _plataformaSeleccionada)
            .get();

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
  // VALIDACION
  // -------------------------------------------------------

  bool get _puedeVender {
    if (_calzadoId == null) return false;
    if (_tallaSeleccionada == null) return false;
    if (_cantidadVenta <= 0) return false;
    if (_stockDisponible <= 0) return false;
    if (_cantidadVenta > _stockDisponible) return false;
    return true;
  }

  String? get _mensajeBloqueo {
    if (_calzadoId == null) return null;
    if (_tallaSeleccionada == null) return null;
    if (_stockDisponible == 0) {
      return 'Sin stock disponible para esta seleccion';
    }
    if (_cantidadVenta > 0 && _cantidadVenta > _stockDisponible) {
      return 'No hay suficiente stock (disponible: $_stockDisponible)';
    }
    return null;
  }

  // -------------------------------------------------------
  // SPLASH
  // -------------------------------------------------------

  void _mostrarSplashScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const SplashScreen02(),
    );
  }

  void _ocultarSplashScreen() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // -------------------------------------------------------
  // ICONO
  // -------------------------------------------------------

  Future<String?> _obtenerIconoTipo(String tipoCalzadoId) async {
    if (_iconCache.containsKey(tipoCalzadoId)) return _iconCache[tipoCalzadoId];
    final tipoSnap = await FirebaseFirestore.instance
        .collection('tipo_calzado')
        .doc(tipoCalzadoId)
        .get();
    String? icono;
    final data = tipoSnap.data();
    if (data != null && data['icono'] != null) {
      icono = data['icono'].toString();
    }
    _iconCache[tipoCalzadoId] = icono;
    return icono;
  }

  // -------------------------------------------------------
  // GUARDAR VENTA
  // -------------------------------------------------------

  Future<void> _realizarVenta() async {
    if (!_puedeVender) return;

    _mostrarSplashScreen();

    try {
      final db = FirebaseFirestore.instance;

      // 1. Crear documento en coleccion "venta"
      final ventaRef = await db.collection('venta').add({
        'calzado_id': _calzadoId,
        'talla': _tallaSeleccionada,
        'taco': _tipoTieneTaco ? _tacoSeleccionado ?? 0 : 0,
        'plataforma': _tipoTienePlataforma ? _plataformaSeleccionada : false,
        'cantidad': _cantidadVenta,
        'fecha_venta': Timestamp.now(),
        'usuario_creacion': widget.firstName ?? 'anon',
      });

      // 2. Crear fila_venta con todos los datos necesarios para mostrarlos
      await db.collection('fila_venta').add({
        'venta_id': ventaRef.id,
        'calzado_id': _calzadoId,
        'talla': _tallaSeleccionada,
        'taco': _tipoTieneTaco ? _tacoSeleccionado ?? 0 : 0,
        'plataforma': _tipoTienePlataforma ? _plataformaSeleccionada : false,
        'cantidad': _cantidadVenta,
        'fecha_creacion': Timestamp.now(),
        'usuario_creacion': widget.firstName ?? 'anon',
      });

      // 3. Actualizar subfila_inventario (restar o eliminar)
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

        if (_tipoTieneTaco && _tacoSeleccionado != null) {
          subQuery = subQuery.where('taco', isEqualTo: _tacoSeleccionado);
        }
        if (_tipoTienePlataforma) {
          subQuery =
              subQuery.where('plataforma', isEqualTo: _plataformaSeleccionada);
        }

        final subfilasSnap = await subQuery.get();

        for (final subDoc in subfilasSnap.docs) {
          if (cantidadPorDescontar <= 0) break;

          final cantidadActual = (subDoc['cantidad'] ?? 0) as int;
          final descuento = cantidadPorDescontar > cantidadActual
              ? cantidadActual
              : cantidadPorDescontar;
          cantidadPorDescontar -= descuento;
          final nuevaCantidad = cantidadActual - descuento;

          if (nuevaCantidad <= 0) {
            await subDoc.reference.delete();
          } else {
            await subDoc.reference.update({'cantidad': nuevaCantidad});
          }
        }

        // 4. Recalcular cantidad de fila_inventario
        final subfilasRestantes = await db
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .get();

        if (subfilasRestantes.docs.isEmpty) {
          await fila.reference.delete();
        } else {
          final nuevaCantidadFila = subfilasRestantes.docs
              // ignore: avoid_types_as_parameter_names
              .fold<int>(0, (sum, d) => sum + ((d['cantidad'] ?? 0) as int));
          await fila.reference.update({'cantidad': nuevaCantidadFila});
        }
      }

      _ocultarSplashScreen();
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada correctamente')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _ocultarSplashScreen();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar venta: $e')),
      );
    }
  }

  // -------------------------------------------------------
  // UI
  // -------------------------------------------------------

  Widget _buildStockLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: _stockDisponible > 0 ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: _stockDisponible > 0
              ? Colors.green.shade300
              : Colors.red.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Stock disponible:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          _cargandoStock
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  '$_stockDisponible unidades',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _stockDisponible > 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDropdownCalzado(List<QueryDocumentSnapshot> calzados) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Seleccionar código',
        border: OutlineInputBorder(),
      ),
      value: _calzadoId,
      items: calzados.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final tipoCalzadoId = data['tipo_calzado_id'] ?? '';
        final nombre = data['nombre'] ?? 'Sin nombre';
        return DropdownMenuItem<String>(
          value: doc.id,
          child: FutureBuilder<String?>(
            future: _obtenerIconoTipo(tipoCalzadoId),
            builder: (context, iconSnapshot) {
              final icono = iconSnapshot.data;
              return Row(
                children: [
                  if (icono != null && icono.isNotEmpty)
                    Image.asset(icono, width: 32, height: 32),
                  const SizedBox(width: 8),
                  Text(nombre),
                ],
              );
            },
          ),
        );
      }).toList(),
      onChanged: (v) async {
        if (v == null) return;

        final calzadoDoc =
            await FirebaseFirestore.instance.collection('calzado').doc(v).get();

        if (calzadoDoc.exists) {
          final data = calzadoDoc.data()!;
          _tipoTieneTaco = data['taco'] ?? false;
          _tipoTienePlataforma = data['plataforma'] ?? false;
        }

        setState(() {
          _calzadoId = v;
          _tallaSeleccionada = null;
          _tacoSeleccionado = null;
          _plataformaSeleccionada = false;
          _cantidadVenta = 0;
          _cantidadController.clear();
        });

        await _calcularStockPorCalzado(v);
      },
    );
  }

  Widget _buildDropdownTalla() {
    if (_calzadoId == null || _tallasDisponibles.isEmpty) {
      return const SizedBox();
    }

    final tallas = List.generate(18, (i) => i + 25);

    return Column(
      children: [
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Seleccionar talla',
            border: OutlineInputBorder(),
          ),
          value:
              tallas.contains(_tallaSeleccionada) ? _tallaSeleccionada : null,
          items: _tallasDisponibles
              .map((t) => DropdownMenuItem<int>(
                    value: t,
                    child: Text(t.toString()),
                  ))
              .toList(),
          onChanged: (v) async {
            if (v == null) return;
            setState(() {
              _tallaSeleccionada = v;
              _tacoSeleccionado = null;
              _plataformaSeleccionada = false;
              _cantidadVenta = 0;
              _cantidadController.clear();
            });
            await _calcularStockPorTalla(v);
          },
        ),
      ],
    );
  }

  Widget _buildDropdownTaco() {
    if (!_tipoTieneTaco) return const SizedBox();
    if (_tallaSeleccionada == null || _tacosDisponibles.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Seleccionar taco (cm)',
            border: OutlineInputBorder(),
          ),
          value: _tacoSeleccionado,
          items: _tacosDisponibles
              .map((t) => DropdownMenuItem<int>(
                    value: t,
                    child: Text('$t cm'),
                  ))
              .toList(),
          onChanged: (v) async {
            if (v == null) return;
            setState(() {
              _tacoSeleccionado = v;
              _plataformaSeleccionada = false;
              _cantidadVenta = 0;
              _cantidadController.clear();
            });
            await _calcularStockPorTaco(v);
          },
        ),
      ],
    );
  }

  Widget _buildCheckboxPlataforma() {
    final mostrar = _tipoTienePlataforma &&
        _tallaSeleccionada != null &&
        (!_tipoTieneTaco || _tacoSeleccionado != null);

    if (!mostrar) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          const Text('Con plataforma', style: TextStyle(fontSize: 15)),
          Checkbox(
            value: _plataformaSeleccionada,
            onChanged: (v) async {
              final valor = v ?? false;
              setState(() {
                _plataformaSeleccionada = valor;
                _cantidadVenta = 0;
                _cantidadController.clear();
              });
              if (_tipoTieneTaco && _tacoSeleccionado != null) {
                await _calcularStockCompleto();
              } else {
                print('''Calculando stock completo con plataforma: $v''');
                await _calcularStockPorPlataforma(
                    _plataformaSeleccionada ?? false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCantidadVenta() {
    if (_calzadoId == null ||
        _tallaSeleccionada == null ||
        (_tipoTieneTaco && _tacoSeleccionado == null) ||
        (_tipoTienePlataforma && _plataformaSeleccionada == null)) {
      return const SizedBox();
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        TextFormField(
          controller: _cantidadController,
          decoration: const InputDecoration(
            labelText: 'Cantidad a vender',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            setState(() => _cantidadVenta = int.tryParse(v) ?? 0);
          },
        ),
        if (_mensajeBloqueo != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _mensajeBloqueo!,
                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ],
    );
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
                    .where('usuario_creacion', isEqualTo: widget.firstName)
                    .where('activo', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No tienes calzados registrados.');
                  }
                  return _buildDropdownCalzado(snapshot.data!.docs);
                },
              ),
              _buildDropdownTalla(),
              _buildDropdownTaco(),
              _buildCheckboxPlataforma(),
              _buildCantidadVenta(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _puedeVender
                        ? Colors.green.shade600
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Text(
                    _stockDisponible == 0 && _calzadoId != null
                        ? 'Sin stock disponible'
                        : 'Registrar venta',
                    style: const TextStyle(fontSize: 16),
                  ),
                  onPressed: _puedeVender ? _realizarVenta : null,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

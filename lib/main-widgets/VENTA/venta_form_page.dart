import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';

class VentaFormPage extends StatefulWidget {
  final String? firstName;
  final String inventarioId;

  const VentaFormPage({
    super.key,
    required this.firstName,
    required this.inventarioId,
  });

  @override
  State<VentaFormPage> createState() => _VentaFormPageState();
}

class _VentaFormPageState extends State<VentaFormPage> {
  String? _calzadoId;
  String? _filaInventarioId;
  bool _tipoTieneTaco = false;
  bool _tipoTienePlataforma = false;

  int _cantidadDisponible = 0;

  final List<Map<String, dynamic>> _subfilas = [];

  bool _cargando = false;

  /// 🔹 Splash
  void _mostrarSplash() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SplashScreen02(),
    );
  }

  void _ocultarSplash() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  /// 🔹 Cargar inventario del calzado seleccionado
  Future<void> _cargarStock(String calzadoId) async {
    setState(() => _cargando = true);

    final filaSnap = await FirebaseFirestore.instance
        .collection('fila_inventario')
        .where('inventario_id', isEqualTo: widget.inventarioId)
        .where('calzado_id', isEqualTo: calzadoId)
        .limit(1)
        .get();

    if (filaSnap.docs.isEmpty) {
      setState(() {
        _cantidadDisponible = 0;
        _subfilas.clear();
      });
      return;
    }

    final fila = filaSnap.docs.first;

    _filaInventarioId = fila.id;
    _cantidadDisponible = fila['cantidad'] ?? 0;

    // 🔹 Obtener datos del calzado
    final calzadoDoc = await FirebaseFirestore.instance
        .collection('calzado')
        .doc(calzadoId)
        .get();

    if (calzadoDoc.exists) {}

    // 🔹 Subfilas
    final subSnap = await FirebaseFirestore.instance
        .collection('subfila_inventario')
        .where('fila_inventario_id', isEqualTo: fila.id)
        .get();

    _subfilas.clear();

    for (var doc in subSnap.docs) {
      _subfilas.add({
        'subfila_id': doc.id,
        'stock': doc['cantidad'] ?? 0,
        'cantidad': 0,
        'talla': doc['talla'],
        'taco': doc['taco'],
        'plataforma': doc['plataforma'],
      });
    }

    setState(() => _cargando = false);
  }

  /// 🔹 Guardar venta
  Future<void> _guardarVenta() async {
    if (_calzadoId == null || _filaInventarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un calzado')),
      );
      return;
    }

    final totalVenta = _subfilas.fold<int>(
      0,
      (suma, item) => suma + (item['cantidad'] ?? 0) as int,
    );

    print(totalVenta);

    if (totalVenta <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa cantidades a vender')),
      );
      return;
    }

    if (totalVenta > _cantidadDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supera el stock disponible')),
      );
      return;
    }

    _mostrarSplash();

    try {
      final db = FirebaseFirestore.instance;

      /// 🔹 1. Crear fila_venta
      final ventaRef = await db.collection('fila_venta').add({
        'inventario_id': widget.inventarioId,
        'calzado_id': _calzadoId,
        'cantidad': totalVenta,
        'fecha_creacion': Timestamp.now(),
        'usuario_creacion': widget.firstName ?? 'anon',
      });

      /// 🔹 2. Insertar subfilas venta
      for (var sub in _subfilas) {
        final vender = (sub['cantidad'] ?? 0) as int;
        if (vender <= 0) continue;

        await db.collection('subfila_venta').add({
          'fila_venta_id': ventaRef.id,
          'subfila_inventario_id': sub['subfila_id'],
          'cantidad': vender,
          'talla': sub['talla'],
          'taco': sub['taco'],
          'plataforma': sub['plataforma'],
          'fecha_creacion': Timestamp.now(),
          'usuario_creacion': widget.firstName ?? 'anon',
        });
      }

      /// 🔹 3. ACTUALIZAR STOCK (SIN tx.get 💥)
      await db.runTransaction((tx) async {
        for (var sub in _subfilas) {
          final vender = (sub['cantidad'] ?? 0) as int;
          if (vender <= 0) continue;

          final stockActual = sub['stock'] as int;

          if (stockActual < vender) {
            throw Exception('Stock insuficiente');
          }

          final ref =
              db.collection('subfila_inventario').doc(sub['subfila_id']);

          tx.update(ref, {
            'cantidad': stockActual - vender,
          });
        }

        /// 🔹 actualizar fila inventario total
        final filaRef = db.collection('fila_inventario').doc(_filaInventarioId);

        tx.update(filaRef, {
          'cantidad': _cantidadDisponible - totalVenta,
        });
      });

      _ocultarSplash();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada correctamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      _ocultarSplash();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// 🔹 UI Subfila
  Widget _buildSubfila(int index) {
    final sub = _subfilas[index];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
  child: Text(
    // Primera fila: Talla y Stock
    'Talla: ${sub['talla']} | Stock: ${sub['stock']}${_tipoTieneTaco || _tipoTienePlataforma
        ? '\n'
          '${_tipoTieneTaco && (sub['taco'] != null && sub['taco'] > 0) ? 'Taco: ${sub['taco']}' : ''}'
          '${_tipoTieneTaco && _tipoTienePlataforma && (sub['plataforma'] != null) ? ' | ' : ''}'
          '${_tipoTienePlataforma && sub['plataforma'] != null ? 'Plataforma: ${sub['plataforma'] ? 'Sí' : 'No'}' : ''}'
        : ''}',
    style: const TextStyle(fontWeight: FontWeight.bold),
  ),
),
            SizedBox(
              width: 80,
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Vender'),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final val = int.tryParse(v) ?? 0;

                  if (val > sub['stock']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Excede stock')),
                    );
                    return;
                  }

                  setState(() => sub['cantidad'] = val);
                },
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const SplashScreen02();

    return Scaffold(
      appBar: Designwidgets().appBarMain("Registrar Venta"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔹 Dropdown calzado
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('calzado')
                  .where('usuario_creacion', isEqualTo: widget.firstName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final docs = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar calzado',
                    border: OutlineInputBorder(),
                  ),
                  value: _calzadoId,
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['nombre'] ?? 'Sin nombre'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() => _calzadoId = v);
                    if (v != null) {
                      // Buscar el calzado seleccionado en los docs
                      final seleccionado =
                          docs.firstWhere((doc) => doc.id == v);
                      final data = seleccionado.data() as Map<String, dynamic>;

                      setState(() {
                        _calzadoId = v;
                        // 🔹 Actualizar variables según la colección
                        _tipoTieneTaco = data['taco'] ?? false;
                        _tipoTienePlataforma = data['plataforma'] ?? false;
                      });
                      _cargarStock(v);
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            /// 🔹 Stock total
            Text(
              'Stock disponible: $_cantidadDisponible',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            /// 🔹 Subfilas
            Expanded(
              child: ListView.builder(
                itemCount: _subfilas.length,
                itemBuilder: (_, i) => _buildSubfila(i),
              ),
            ),

            /// 🔹 Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardarVenta,
                icon: const Icon(Icons.save),
                label: const Text('Registrar venta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

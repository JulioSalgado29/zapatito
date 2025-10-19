import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventarioFormPage extends StatefulWidget {
  final String? firstName;
  final String inventarioId;
  final String? filaId;

  const InventarioFormPage({
    super.key,
    required this.firstName,
    required this.inventarioId,
    this.filaId,
  });

  @override
  State<InventarioFormPage> createState() => _InventarioFormPageState();
}

class _InventarioFormPageState extends State<InventarioFormPage> {
  String? _calzadoId;
  int _cantidadFila = 0;
  final List<Map<String, dynamic>> _subfilas = [];
  final Map<String, String?> _iconCache = {};
  bool _cargandoDatos = false; // ✅ NUEVO indicador

  @override
  void initState() {
    super.initState();
    if (widget.filaId != null) {
      _cargarDatosExistentes(); // ✅ NUEVO
    } else {
      _subfilas.add({'cantidad': 0, 'talla': 1, 'taco': 1, 'plataforma': false});
    }
  }

  /// ✅ Cargar fila y subfilas si estamos en modo edición
  Future<void> _cargarDatosExistentes() async {
    setState(() => _cargandoDatos = true);
    final filaDoc = await FirebaseFirestore.instance
        .collection('fila_inventario')
        .doc(widget.filaId)
        .get();

    if (filaDoc.exists) {
      final data = filaDoc.data()!;
      _calzadoId = data['calzado_id'];
      _cantidadFila = data['cantidad'] ?? 0;

      final subSnap = await FirebaseFirestore.instance
          .collection('subfila_inventario')
          .where('fila_inventario_id', isEqualTo: widget.filaId)
          .get();

      _subfilas.clear();
      for (var doc in subSnap.docs) {
        _subfilas.add({
          'id': doc.id,
          'cantidad': doc['cantidad'] ?? 0,
          'talla': doc['talla'] ?? 1,
          'taco': doc['taco'] ?? 1,
          'plataforma': doc['plataforma'] ?? false,
        });
      }

      if (_subfilas.isEmpty) {
        _subfilas.add({'cantidad': 0, 'talla': 1, 'taco': 1, 'plataforma': false});
      }
    }
    setState(() => _cargandoDatos = false);
  }

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

  /// ✅ Guardar o actualizar fila y subfilas
  Future<void> _guardarFilaInventario() async {
  if (_calzadoId == null || _cantidadFila <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecciona un calzado y una cantidad válida')),
    );
    return;
  }

  for (var sub in _subfilas) {
    if ((sub['cantidad'] ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todas las subfilas deben tener cantidad mayor a 0')),
      );
      return;
    }
  }

  final totalSubfila = _subfilas.fold<int>(
    0,
    (suma, item) => suma + (item['cantidad'] ?? 0) as int,
  );

  if (totalSubfila != _cantidadFila) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La suma de subfilas debe ser igual a la cantidad total')),
    );
    return;
  }

  if (widget.filaId == null) {
    // ✅ Crear nueva fila
    final filaRef = await FirebaseFirestore.instance.collection('fila_inventario').add({
      'inventario_id': widget.inventarioId,
      'calzado_id': _calzadoId,
      'cantidad': _cantidadFila,
    });

    for (var sub in _subfilas) {
      await FirebaseFirestore.instance.collection('subfila_inventario').add({
        'fila_inventario_id': filaRef.id,
        'cantidad': sub['cantidad'],
        'talla': sub['talla'],
        'taco': sub['taco'],
        'plataforma': sub['plataforma'],
        'fecha_creacion': Timestamp.now(),
        'usuario_creacion': widget.firstName ?? 'anon',
      });
    }

    // 🔁 Devuelve "true" al cerrar para que la página anterior recargue
    Navigator.pop(context, true);
  } else {
    // ✅ Editar fila existente
    final filaRef = FirebaseFirestore.instance
        .collection('fila_inventario')
        .doc(widget.filaId);
    await filaRef.update({
      'calzado_id': _calzadoId,
      'cantidad': _cantidadFila,
    });

    for (var sub in _subfilas) {
      if (sub['id'] != null) {
        await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .doc(sub['id'])
            .update({
          'cantidad': sub['cantidad'],
          'talla': sub['talla'],
          'taco': sub['taco'],
          'plataforma': sub['plataforma'],
        });
      } else {
        await FirebaseFirestore.instance.collection('subfila_inventario').add({
          'fila_inventario_id': widget.filaId,
          'cantidad': sub['cantidad'],
          'talla': sub['talla'],
          'taco': sub['taco'],
          'plataforma': sub['plataforma'],
          'fecha_creacion': Timestamp.now(),
          'usuario_creacion': widget.firstName ?? 'anon',
        });
      }
    }

    // 🔁 También devolvemos "true" aquí
    Navigator.pop(context, true);
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Inventario guardado correctamente')),
  );
}

  /// ✅ Renderiza una subfila editable con campo cantidad
  Widget _buildSubfilaItem(int index) {
    final sub = _subfilas[index];
    final tallas = List.generate(15, (i) => i + 1);
    final tacos = List.generate(15, (i) => i + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: sub['cantidad'].toString(),
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final val = int.tryParse(v) ?? 0;
                  setState(() => _subfilas[index]['cantidad'] = val);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Talla'),
                value: sub['talla'],
                items: tallas
                    .map((t) =>
                        DropdownMenuItem<int>(value: t, child: Text(t.toString())))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _subfilas[index]['talla'] = v ?? 1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Taco'),
                value: sub['taco'],
                items: tacos
                    .map((t) =>
                        DropdownMenuItem<int>(value: t, child: Text(t.toString())))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _subfilas[index]['taco'] = v ?? 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Plataforma',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Checkbox(
              value: sub['plataforma'],
              onChanged: (v) =>
                  setState(() => _subfilas[index]['plataforma'] = v ?? false),
            ),
          ],
        ),
        const Divider(height: 24),
      ],
    );
  }

  Widget _buildDropdownConIconos(AsyncSnapshot<QuerySnapshot> snapshot) {
    final calzados = snapshot.data!.docs;
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Seleccionar calzado'),
      value: _calzadoId,
      items: calzados.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final tipoCalzadoId = data['tipo_calzado_id'];
        final nombre = data['nombre'] ?? 'Sin nombre';
        return DropdownMenuItem<String>(
          value: doc.id,
          child: FutureBuilder<String?>(
            future: _obtenerIconoTipo(tipoCalzadoId),
            builder: (context, iconSnapshot) {
              final icono = iconSnapshot.data;
              if (iconSnapshot.connectionState == ConnectionState.waiting &&
                  icono == null) {
                return Row(
                  children: [
                    const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text(nombre),
                  ],
                );
              }
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
      onChanged: (v) => setState(() => _calzadoId = v),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filaId == null
            ? 'Agregar Fila de Inventario'
            : 'Editar Fila de Inventario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('calzado')
                    .where('usuario_creacion', isEqualTo: widget.firstName)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No tienes calzados registrados.');
                  }
                  return _buildDropdownConIconos(snapshot);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _cantidadFila > 0 ? '$_cantidadFila' : '',
                decoration: const InputDecoration(labelText: 'Cantidad total'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _cantidadFila = int.tryParse(v) ?? 0,
              ),
              const Divider(height: 32),
              const Text(
                'Subfilas de inventario',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._subfilas.asMap().entries.map((entry) => _buildSubfilaItem(entry.key)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  for (var sub in _subfilas) {
                    if ((sub['cantidad'] ?? 0) <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('No puedes agregar más subfilas con cantidades en 0')),
                      );
                      return;
                    }
                  }

                  final totalActual = _subfilas.fold<int>(
                    0,
                    (suma, item) => suma + (item['cantidad'] ?? 0) as int,
                  );

                  if (totalActual >= _cantidadFila) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ya no puedes agregar más subfilas')),
                    );
                    return;
                  }

                  setState(() {
                    _subfilas.add(
                      {'cantidad': 0, 'talla': 1, 'taco': 1, 'plataforma': false},
                    );
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar subfila'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardarFilaInventario,
                child: Text(widget.filaId == null
                    ? 'Guardar inventario'
                    : 'Actualizar inventario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

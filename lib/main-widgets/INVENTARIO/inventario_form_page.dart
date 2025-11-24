import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/components/widgets.dart';

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
  bool _tipoTienePlataforma = false;
  bool _tipoTieneTaco = false;

  int _cantidadFila = 0;
  final List<Map<String, dynamic>> _subfilas = [];
  final Map<String, String?> _iconCache = {};
  bool _cargandoDatos = false;

  @override
  void initState() {
    super.initState();
    if (widget.filaId != null) {
      _cargarDatosExistentes();
    } else {
      _subfilas.add({'cantidad': 0, 'talla': 0, 'taco': 0, 'plataforma': false});
    }
  }

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

      // 🔹 Cargar directamente desde colección CALZADO
      final calzadoDoc = await FirebaseFirestore.instance
          .collection('calzado')
          .doc(_calzadoId)
          .get();

      if (calzadoDoc.exists) {
        final calzadoData = calzadoDoc.data()!;
        _tipoTieneTaco = calzadoData['taco'] ?? true;
        _tipoTienePlataforma = calzadoData['plataforma'] ?? true;
      }

      final subSnap = await FirebaseFirestore.instance
          .collection('subfila_inventario')
          .where('fila_inventario_id', isEqualTo: widget.filaId)
          .get();

      _subfilas.clear();
      for (var doc in subSnap.docs) {
        _subfilas.add({
          'id': doc.id,
          'cantidad': doc['cantidad'] ?? 0,
          'talla': doc['talla'] ?? 0,
          'taco': doc['taco'] ?? 0,
          'plataforma': doc['plataforma'] ?? false,
        });
      }

      if (_subfilas.isEmpty) {
        _subfilas.add({'cantidad': 0, 'talla': 0, 'taco': 0, 'plataforma': false});
      }
    }
    setState(() => _cargandoDatos = false);
  }

  // 🔹 Ya no se usa tipo_calzado, pero dejamos para compatibilidad con iconos
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

    // Validación de duplicados
    final combinaciones = <String>{};
    for (var sub in _subfilas) {
      final key = '${sub['talla']}_${sub['taco']}_${sub['plataforma']}';
      if (combinaciones.contains(key)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pueden repetir subfilas con misma talla, taco y plataforma')),
        );
        return;
      }
      combinaciones.add(key);
    }

    // Validar suma total
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

    try {
      if (widget.filaId == null) {
        final filaExistenteSnap = await FirebaseFirestore.instance
            .collection('fila_inventario')
            .where('inventario_id', isEqualTo: widget.inventarioId)
            .where('calzado_id', isEqualTo: _calzadoId)
            .limit(1)
            .get();

        DocumentReference filaRef;

        if (filaExistenteSnap.docs.isNotEmpty) {
          // Fusión
          final filaDoc = filaExistenteSnap.docs.first;
          filaRef = filaDoc.reference;
          final cantidadActual = filaDoc['cantidad'] ?? 0;
          await filaRef.update({'cantidad': cantidadActual + _cantidadFila});

          for (var sub in _subfilas) {
            final subExistente = await FirebaseFirestore.instance
                .collection('subfila_inventario')
                .where('fila_inventario_id', isEqualTo: filaRef.id)
                .where('talla', isEqualTo: sub['talla'])
                .where('taco', isEqualTo: sub['taco'])
                .where('plataforma', isEqualTo: sub['plataforma'])
                .limit(1)
                .get();

            if (subExistente.docs.isNotEmpty) {
              final doc = subExistente.docs.first;
              final cantidadNueva = (doc['cantidad'] ?? 0) + (sub['cantidad'] ?? 0);
              await doc.reference.update({'cantidad': cantidadNueva});
            } else {
              await FirebaseFirestore.instance.collection('subfila_inventario').add({
                'fila_inventario_id': filaRef.id,
                'cantidad': sub['cantidad'],
                'talla': sub['talla'],
                'taco': _tipoTieneTaco ? sub['taco'] : 0,
                'plataforma': _tipoTienePlataforma ? sub['plataforma'] : false,
                'fecha_creacion': Timestamp.now(),
                'usuario_creacion': widget.firstName ?? 'anon',
              });
            }
          }
        } else {
          // Nueva fila
          filaRef = await FirebaseFirestore.instance.collection('fila_inventario').add({
            'inventario_id': widget.inventarioId,
            'calzado_id': _calzadoId,
            'cantidad': _cantidadFila,
            'fecha_creacion': Timestamp.now(),
            'usuario_creacion': widget.firstName ?? 'anon',
          });

          for (var sub in _subfilas) {
            await FirebaseFirestore.instance.collection('subfila_inventario').add({
              'fila_inventario_id': filaRef.id,
              'cantidad': sub['cantidad'],
              'talla': sub['talla'],
              'taco': _tipoTieneTaco ? sub['taco'] : 0,
              'plataforma': _tipoTienePlataforma ? sub['plataforma'] : false,
              'fecha_creacion': Timestamp.now(),
              'usuario_creacion': widget.firstName ?? 'anon',
            });
          }
        }
      } else {
        // Editar fila existente
        final filaRef = FirebaseFirestore.instance.collection('fila_inventario').doc(widget.filaId);
        await filaRef.update({
          'calzado_id': _calzadoId,
          'cantidad': _cantidadFila,
        });

        // 🔹 1. Eliminar todas las subfilas anteriores
        final subExistentes = await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: widget.filaId)
            .get();

        for (var doc in subExistentes.docs) {
          await doc.reference.delete();
        }

        // 🔹 2. Insertar todas las subfilas actuales (nuevas)
        for (var sub in _subfilas) {
          await FirebaseFirestore.instance.collection('subfila_inventario').add({
            'fila_inventario_id': widget.filaId,
            'cantidad': sub['cantidad'],
            'talla': sub['talla'],
            'taco': _tipoTieneTaco ? sub['taco'] : 0,
            'plataforma': _tipoTienePlataforma ? sub['plataforma'] : false,
            'fecha_creacion': Timestamp.now(),
            'usuario_creacion': widget.firstName ?? 'anon',
          });
        }
      }


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventario guardado correctamente')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  /// ---------- UI ----------
  Widget _buildSubfilaItem(int index) {
  final sub = _subfilas[index];

  final tallas = List.generate(18, (i) => i + 25);
  final tacos = List.generate(15, (i) => i + 1);

  final tallaActual = (sub['talla'] != null && tallas.contains(sub['talla']))
      ? sub['talla']
      : null;
  final tacoActual = (sub['taco'] != null && tacos.contains(sub['taco']))
      ? sub['taco']
      : null;
  final cantidadActual = (sub['cantidad'] ?? 0) > 0 ? sub['cantidad'] : 0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          // Cantidad
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
              initialValue: cantidadActual > 0 ? cantidadActual.toString() : '',
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                setState(() => _subfilas[index]['cantidad'] = parsed);
              },
            ),
          ),

          // Talla
          Expanded(
            child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Talla'),
              value: tallaActual,
              items: tallas
                  .map((talla) => DropdownMenuItem<int>(
                        value: talla,
                        child: Text(talla.toString()),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => sub['talla'] = val),
            ),
          ),

          // Taco (si aplica)
          if (_tipoTieneTaco) ...[
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Taco'),
                value: tacoActual,
                items: tacos
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.toString())))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _subfilas[index]['taco'] = v ?? 0),
              ),
            ),
          ],

          // ❌ Botón para eliminar subfila (solo UI)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                _subfilas.removeAt(index);
              });
            },
          ),
        ],
      ),

      // Checkbox plataforma
      if (_tipoTienePlataforma)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Text('Plataforma'),
              Checkbox(
                value: sub['plataforma'] ?? false,
                onChanged: (v) =>
                    setState(() => _subfilas[index]['plataforma'] = v ?? false),
              ),
            ],
          ),
        ),

      const Divider(),
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
        return DropdownMenuItem(
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
        setState(() {
          _calzadoId = v;
        });
        if (v != null) {
          final calzadoDoc = await FirebaseFirestore.instance.collection('calzado').doc(v).get();
          if (calzadoDoc.exists) {
            final calzadoData = calzadoDoc.data()!;
            _tipoTieneTaco = calzadoData['taco'] ?? true;
            _tipoTienePlataforma = calzadoData['plataforma'] ?? true;
            setState(() {}); // refrescar vista
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: Designwidgets().appBarMain(
        widget.filaId != null ? "Editar Calzado" : "Agregar Calzado",
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
                    .where('activo', isEqualTo: true)
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
              const Text('Subfilas de inventario', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._subfilas.asMap().entries.map((e) => _buildSubfilaItem(e.key)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  if (_cantidadFila <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Primero ingresa una cantidad total')),
                    );
                    return;
                  }
                  if (_subfilas.length >= _cantidadFila) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('La cantidad de sufilas no puede exceder la cantidad total')),
                    );
                    return;
                  }
                  final totalActual = _subfilas.fold<int>(
                    0,
                    (suma, item) => suma + (item['cantidad'] ?? 0) as int,
                  );
                  if (totalActual >= _cantidadFila) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Las cantidades de las subfilas ya suman la cantidad total')),
                    );
                    return;
                  }
                  setState(() {
                    _subfilas.add({'cantidad': 0, 'talla': 0, 'taco': 0, 'plataforma': false});
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar subfila'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardarFilaInventario,
                child: Text(widget.filaId == null ? 'Guardar inventario' : 'Actualizar inventario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

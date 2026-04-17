import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';

class InventarioFormPage extends StatefulWidget {
  final String? firstName;
  final String? inventarioId;
  final String? filaId;
  final String? emailUser;

  const InventarioFormPage({
    super.key,
    this.firstName,
    this.inventarioId,
    this.filaId,
    this.emailUser,
  });

  @override
  State<InventarioFormPage> createState() => _InventarioFormPageState();
}

class _InventarioFormPageState extends State<InventarioFormPage> {
  String? _calzadoId;
  bool _tipoTienePlataforma = false;
  bool _tipoTieneColores = false;
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
      _subfilas.add({
        'cantidad': 0,
        'talla': 0,
        'taco': 0,
        'plataforma': null, // 🔹 Forzamos null para obligar selección
        'colores': ''
      });
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

      final calzadoDoc = await FirebaseFirestore.instance
          .collection('calzado')
          .doc(_calzadoId)
          .get();

      if (calzadoDoc.exists) {
        final calzadoData = calzadoDoc.data()!;
        _tipoTieneTaco = calzadoData['taco'] ?? true;
        _tipoTienePlataforma = calzadoData['plataforma'] ?? true;
        _tipoTieneColores = calzadoData['colores'] ?? true;
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
          'plataforma': doc['plataforma'], // 🔹 Carga el valor String o null
          'colores': doc['colores'] ?? '',
        });
      }

      if (_subfilas.isEmpty) {
        _subfilas.add({
          'cantidad': 0,
          'talla': 0,
          'taco': 0,
          'plataforma': null,
          'colores': ''
        });
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
    if (data != null && data['icono'] != null) icono = data['icono'].toString();
    _iconCache[tipoCalzadoId] = icono;
    return icono;
  }

  void _mostrarSplashScreen() => showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const SplashScreen02());
  void _ocultarSplashScreen() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _guardarFilaInventario() async {
    if (_calzadoId == null || _cantidadFila <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona un calzado y una cantidad válida')));
      return;
    }

    final combinaciones = <String>{};
    for (var sub in _subfilas) {
      final key =
          '${sub['talla']}_${sub['taco']}_${sub['plataforma']}_${sub['colores']}';

      if ((sub['cantidad'] ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Todas las subfilas deben tener cantidad mayor a 0')));
        return;
      }
      if ((sub['talla'] ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Todas las subfilas deben tener una talla seleccionada')));
        return;
      }
      // 🔹 Validación obligatoria de plataforma si el calzado la requiere
      if (_tipoTienePlataforma &&
          (sub['plataforma'] == null || sub['plataforma'].toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Selecciona el tipo de plataforma en todas las subfilas')));
        return;
      }
      if ((sub['colores'] ?? '') == '' && _tipoTieneColores) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Todas las subfilas deben tener un color especificado')));
        return;
      }
      if (combinaciones.contains(key)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('No se pueden repetir subfilas con mismos atributos')));
        return;
      }
      combinaciones.add(key);
    }

    final totalSubfila = _subfilas.fold<int>(
        0, (suma, item) => suma + (item['cantidad'] ?? 0) as int);
    if (totalSubfila != _cantidadFila) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('La suma de subfilas debe ser igual a la cantidad total')));
      return;
    }

    _mostrarSplashScreen();
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
          final filaDoc = filaExistenteSnap.docs.first;
          filaRef = filaDoc.reference;
          await filaRef
              .update({'cantidad': (filaDoc['cantidad'] ?? 0) + _cantidadFila});
          for (var sub in _subfilas) {
            final subExistente = await FirebaseFirestore.instance
                .collection('subfila_inventario')
                .where('fila_inventario_id', isEqualTo: filaRef.id)
                .where('talla', isEqualTo: sub['talla'])
                .where('taco', isEqualTo: sub['taco'])
                .where('plataforma', isEqualTo: sub['plataforma'])
                .where('colores', isEqualTo: sub['colores'])
                .limit(1)
                .get();
            if (subExistente.docs.isNotEmpty) {
              final doc = subExistente.docs.first;
              await doc.reference.update({
                'cantidad': (doc['cantidad'] ?? 0) + (sub['cantidad'] ?? 0)
              });
            } else {
              await FirebaseFirestore.instance
                  .collection('subfila_inventario')
                  .add({
                'fila_inventario_id': filaRef.id,
                'cantidad': sub['cantidad'],
                'talla': sub['talla'],
                'taco': _tipoTieneTaco ? sub['taco'] : 0,
                'plataforma': _tipoTienePlataforma ? sub['plataforma'] : '',
                'colores': _tipoTieneColores ? sub['colores'] : '',
                'fecha_creacion': Timestamp.now(),
                'usuario_creacion': widget.firstName ?? 'anon',
              });
            }
          }
        } else {
          filaRef = await FirebaseFirestore.instance
              .collection('fila_inventario')
              .add({
            'inventario_id': widget.inventarioId,
            'calzado_id': _calzadoId,
            'cantidad': _cantidadFila,
            'fecha_creacion': Timestamp.now(),
            'usuario_creacion': widget.firstName ?? 'anon',
            'email_user': widget.emailUser ?? 'anon'
          });
          for (var sub in _subfilas) {
            await FirebaseFirestore.instance
                .collection('subfila_inventario')
                .add({
              'fila_inventario_id': filaRef.id,
              'cantidad': sub['cantidad'],
              'talla': sub['talla'],
              'taco': _tipoTieneTaco ? sub['taco'] : 0,
              'plataforma': _tipoTienePlataforma ? sub['plataforma'] : '',
              'colores': _tipoTieneColores ? sub['colores'] : '',
              'fecha_creacion': Timestamp.now(),
              'usuario_creacion': widget.firstName ?? 'anon',
              'email_user': widget.emailUser ?? 'anon'
            });
          }
        }
      } else {
        await FirebaseFirestore.instance
            .collection('fila_inventario')
            .doc(widget.filaId)
            .update({'calzado_id': _calzadoId, 'cantidad': _cantidadFila});
        final subExistentes = await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: widget.filaId)
            .get();
        for (var doc in subExistentes.docs) {
          await doc.reference.delete();
        }
        for (var sub in _subfilas) {
          await FirebaseFirestore.instance
              .collection('subfila_inventario')
              .add({
            'fila_inventario_id': widget.filaId,
            'cantidad': sub['cantidad'],
            'talla': sub['talla'],
            'taco': _tipoTieneTaco ? sub['taco'] : 0,
            'plataforma': _tipoTienePlataforma ? sub['plataforma'] : '',
            'colores': _tipoTieneColores ? sub['colores'] : '',
            'fecha_creacion': Timestamp.now(),
            'usuario_creacion': widget.firstName ?? 'anon'
          });
        }
      }
      _ocultarSplashScreen();
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventario guardado correctamente')));
      Navigator.pop(context, true);
    } catch (e) {
      _ocultarSplashScreen();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  Widget _buildSubfilaItem(int index) {
    final sub = _subfilas[index];
    final tallas = List.generate(18, (i) => i + 25);
    final tacos = List.generate(15, (i) => i + 1);
    final opcionesPlataforma = ['Bajo', 'Mediano', 'Alto'];

    final tallaActual = (sub['talla'] != null && tallas.contains(sub['talla']))
        ? sub['talla']
        : null;
    final tacoActual = (sub['taco'] != null && tacos.contains(sub['taco']))
        ? sub['taco']
        : null;
    final cantidadActual = (sub['cantidad'] ?? 0) > 0 ? sub['cantidad'] : 0;

    // 🔹 Mantenemos null si no hay valor previo
    final plataformaActual = opcionesPlataforma.contains(sub['plataforma'])
        ? sub['plataforma']
        : null;

    return Column(
      key: ValueKey('subfila_$index'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        if (_tipoTieneColores)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.color_lens_outlined)),
              initialValue: sub['colores'] ?? '',
              onChanged: (v) => setState(() => _subfilas[index]['colores'] = v),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey(
                    'cantidad_${index}_${_subfilas[index]['id'] ?? ''}'),
                decoration: const InputDecoration(
                    labelText: 'Cantidad', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                initialValue:
                    cantidadActual > 0 ? cantidadActual.toString() : '',
                onChanged: (val) {
                  final parsed = int.tryParse(val) ?? 0;
                  setState(() => _subfilas[index]['cantidad'] = parsed);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                    labelText: 'Talla', border: OutlineInputBorder()),
                value: tallaActual,
                items: tallas
                    .map((talla) => DropdownMenuItem<int>(
                        value: talla, child: Text(talla.toString())))
                    .toList(),
                onChanged: (val) => setState(() => sub['talla'] = val),
              ),
            ),
            if (_tipoTieneTaco) ...[
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                      labelText: 'Taco', border: OutlineInputBorder()),
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
            IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => _subfilas.removeAt(index))),
          ],
        ),
        const SizedBox(height: 4),
        // Checkbox plataforma (ahora Dropdown)
        if (_tipoTienePlataforma)
          Padding(
            padding: const EdgeInsets.only(top: 8), // Aumenté a 8 para igualar al color
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Plataforma',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.layers_outlined),
              ),
              value: plataformaActual,
              items: opcionesPlataforma
                  .map((opcion) => DropdownMenuItem(
                        value: opcion,
                        child: Text(opcion),
                      ))
                  .toList(),
              onChanged: (v) => setState(
                  () => _subfilas[index]['plataforma'] = v),
            ),
          ),
        const Divider(),
      ],
    );
  }

  Widget _buildDropdownConIconos(
      AsyncSnapshot<QuerySnapshot> snapshot, bool esEdicion) {
    final calzados = snapshot.data!.docs;
    return IgnorePointer(
      ignoring: esEdicion,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
            labelText: 'Seleccionar código',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: esEdicion ? Colors.grey.shade200 : Colors.white),
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
                return Row(children: [
                  if (icono != null && icono.isNotEmpty)
                    Image.asset(icono, width: 32, height: 32),
                  const SizedBox(width: 8),
                  Text(nombre,
                      style: TextStyle(
                          color: esEdicion ? Colors.grey : Colors.black))
                ]);
              },
            ),
          );
        }).toList(),
        onChanged: (v) async {
          setState(() => _calzadoId = v);
          if (v != null) {
            final calzadoDoc = await FirebaseFirestore.instance
                .collection('calzado')
                .doc(v)
                .get();
            if (calzadoDoc.exists) {
              final calzadoData = calzadoDoc.data()!;
              setState(() {
                _tipoTieneTaco = calzadoData['taco'] ?? true;
                _tipoTienePlataforma = calzadoData['plataforma'] ?? true;
                _tipoTieneColores = calzadoData['colores'] ?? true;
              });
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) return const SplashScreen02();
    return Scaffold(
      appBar: Designwidgets().appBarMain(
          widget.filaId != null ? "Editar Inventario" : "Agregado Manual"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('calzado')
                    .where('id_inventario', isEqualTo: widget.inventarioId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No tienes calzados registrados.');
                  }
                  return _buildDropdownConIconos(
                      snapshot, widget.filaId != null);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                  initialValue: _cantidadFila > 0 ? '$_cantidadFila' : '',
                  decoration: const InputDecoration(
                      labelText: 'Cantidad total',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _cantidadFila = int.tryParse(v) ?? 0),
              const Divider(height: 32),
              const Text('Subfilas de inventario',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._subfilas.asMap().entries.map((e) => _buildSubfilaItem(e.key)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_cantidadFila <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Primero ingresa una cantidad total')));
                      return;
                    }
                    if (_subfilas.length >= _cantidadFila) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('No puede exceder la cantidad total')));
                      return;
                    }
                    final totalActual = _subfilas.fold<int>(0,
                        (suma, item) => suma + (item['cantidad'] ?? 0) as int);
                    if (totalActual >= _cantidadFila) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Ya suman la cantidad total')));
                      return;
                    }
                    setState(() => _subfilas.add({
                          'cantidad': 0,
                          'talla': 0,
                          'taco': 0,
                          'plataforma': null,
                          'colores': ''
                        }));
                  },
                  label: const Text('Agregar subfila'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: _guardarFilaInventario,
                    icon: Icon(
                        widget.filaId != null ? Icons.save_as : Icons.save),
                    label: Text(widget.filaId == null
                        ? 'Guardar inventario'
                        : 'Actualizar inventario')),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

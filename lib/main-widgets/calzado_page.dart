import 'package:flutter/material.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CalzadoPage extends StatefulWidget {
  const CalzadoPage({super.key});

  @override
  State<CalzadoPage> createState() => _CalzadoPageState();
}

class _CalzadoPageState extends State<CalzadoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _tallaController = TextEditingController();
  final _usuarioController = TextEditingController();

  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    // 🔹 Detectar conexión
    Connectivity().onConnectivityChanged.listen((status) {
      setState(() {
        isOnline = status != ConnectivityResult.none;
      });
    });
  }

  Future<void> _registrarCalzado() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'fecha_creacion': FieldValue.serverTimestamp(),
      'nombre': _nombreController.text,
      'precio_real': double.tryParse(_precioController.text) ?? 0.0,
      'talla': _tallaController.text,
      'usuario_creacion': _usuarioController.text,
    };

    try {
      await FirebaseFirestore.instance.collection('calzado').add(data);
      _nombreController.clear();
      _precioController.clear();
      _tallaController.clear();
      _usuarioController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isOnline
              ? 'Calzado registrado correctamente ✅'
              : 'Guardado localmente (sin conexión). Se enviará luego 🔄'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain("Registrar Calzados", isOnline: isOnline),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Formulario
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese un nombre' : null,
                  ),
                  TextFormField(
                    controller: _precioController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Precio real'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese un precio' : null,
                  ),
                  TextFormField(
                    controller: _tallaController,
                    decoration: const InputDecoration(labelText: 'Talla'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese una talla' : null,
                  ),
                  TextFormField(
                    controller: _usuarioController,
                    decoration:
                        const InputDecoration(labelText: 'Usuario creación'),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Ingrese el usuario creador'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _registrarCalzado,
                    icon: const Icon(Icons.save),
                    label: const Text('Registrar Calzado'),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            // 🔹 Lista de calzados
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('calzado')
                    .orderBy('fecha_creacion', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text('No hay calzados aún'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final c = docs[index].data() as Map<String, dynamic>;
                      final nombre = c['nombre'] ?? '';
                      final talla = c['talla'] ?? '';
                      final precio = c['precio_real'] ?? 0.0;
                      final usuario = c['usuario_creacion'] ?? '';

                      return Card(
                        child: ListTile(
                          title: Text(nombre),
                          subtitle: Text('Talla: $talla  |  \$${precio.toString()}'),
                          trailing: Text(usuario),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
class CalzadoPage extends StatefulWidget {
  const CalzadoPage({super.key});

  @override
  State<CalzadoPage> createState() => _CalzadoPageState();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain("Registrar Calzados"),
    );
  }
}
*/
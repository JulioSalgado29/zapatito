import 'package:flutter/material.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:zapatito/main-widgets/CALZADO/calzado_form.dart';

class CalzadoPage extends StatefulWidget {
  final String? firstName;

  const CalzadoPage({super.key, this.firstName});

  @override
  State<CalzadoPage> createState() => _CalzadoPageState();
}

class _CalzadoPageState extends State<CalzadoPage> {
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((status) {
      setState(() {
        isOnline = status != ConnectivityResult.none;
      });
    });
  }

  // 🔹 Abrir modal (crear o editar)
  void _mostrarFormulario({DocumentSnapshot? doc}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CalzadoForm(
          firstName: widget.firstName,
          isOnline: isOnline,
          doc: doc, // 👈 si viene un doc, es edición
        ),
      ),
    );
  }

  // 🔹 Confirmación extravagante para eliminar
  void _confirmarEliminacion(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 20,
        backgroundColor: Colors.black.withOpacity(0.85),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [
              Color.fromARGB(255, 33, 47, 243), // azul del appbar
              Color(0xFF4A5AF7), // tono más claro para el degradado
            ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                '¿Eliminar calzado?',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[900],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('calzado').doc(id).update({'activo': false});;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calzado eliminado correctamente 🗑️')),
                      );
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain("Registrar Calzados", isOnline: isOnline),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('calzado')
              .where('activo', isEqualTo: true)
              .orderBy('fecha_creacion', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text('No hay calzados aún'));
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final nombre = data['nombre'] ?? '';
                final precio = (data['precio_real'] ?? 0.0).toDouble();
                final usuario = data['usuario_creacion'] ?? '';

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('S/ ${precio.toStringAsFixed(2)}  |  $usuario'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _mostrarFormulario(doc: doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                          onPressed: () => _confirmarEliminacion(context, doc.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: const Color.fromARGB(255, 33, 47, 243),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ------------------------------------------------------------
// 🔹 WIDGET 2: Formulario (crear / editar)
// ------------------------------------------------------------

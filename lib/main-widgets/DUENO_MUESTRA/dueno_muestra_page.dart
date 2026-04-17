import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:zapatito/main-widgets/DUENO_MUESTRA/dueno_muestra_form.dart';
import 'package:zapatito/main-widgets/MAIN/home_page.dart';

class DuenoMuestraPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;
  const DuenoMuestraPage(
      {super.key, this.firstName, this.emailUser, this.inventarioId});

  @override
  State<DuenoMuestraPage> createState() => _DuenoMuestraPageState();
}

class _DuenoMuestraPageState extends State<DuenoMuestraPage> {
  
  @override
  void initState() {
    super.initState();
    _verificarInventario();
  }

  Future<void> _verificarInventario() async {
    try {
      // 1. Acceso directo al documento por su ID único
      final docSnapshot = await FirebaseFirestore.instance
          .collection('inventario')
          .doc(widget
              .inventarioId) // Buscamos el documento con ese nombre exacto
          .get();

      // 2. Verificamos si el documento existe físicamente en Firestore
      if (!docSnapshot.exists) {
        // Si no existe, redirigimos
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        });
      }
    } catch (e) {
      print("Error al buscar el ID del inventario: $e");
    }
  }


  void _confirmarEliminacion(String id, String nombre) {
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
              colors: [Color.fromARGB(255, 33, 47, 243), Color(0xFF4A5AF7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 60, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                '¿Eliminar Dueño?',
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '¿Seguro que deseas eliminar a "$nombre"? Esta acción no se puede deshacer.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón Cancelar
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Cancelar',
                        style: TextStyle(color: Colors.white)),
                  ),
                  // Botón Eliminar
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    // Dentro del onPressed del botón Eliminar del diálogo:
                    onPressed: () async {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const SplashScreen02(),
                      );

                      try {
                        // 🔹 CAMBIO: De .delete() a .update()
                        await FirebaseFirestore.instance
                            .collection('dueno_muestra')
                            .doc(id)
                            .update({
                          'estado': false, // Borrado lógico
                          'fecha_eliminacion': Timestamp.now(),
                          'usuario_eliminacion': widget.firstName ?? 'anon',
                        });

                        if (mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Dueño quitado de la lista correctamente 🗑️'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors
                                  .orangeAccent, // Cambié a naranja para indicar que no se borró de la DB
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al procesar: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Eliminar',
                        style: TextStyle(color: Colors.white)),
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
    if (widget.inventarioId == null) {
      return const SplashScreen02();
    }
    return Scaffold(
      appBar: Designwidgets().appBarMain('Dueños de Muestras'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 33, 47, 243),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DuenoMuestraForm(
              firstName: widget.firstName,
              emailUser: widget.emailUser,
              inventarioId: widget.inventarioId,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('dueno_muestra')
            .where('estado', isEqualTo: true) // 🔹 FILTRO: Solo activos
            .where('id_inventario', isEqualTo: widget.inventarioId)
            .orderBy('nombre', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No hay registros disponibles.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String id = doc.id;
              final String nombre = data['nombre'] ?? 'Sin nombre';

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.black12,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                title: Text(nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                // 🔹 Trailing con botones de Editar y Eliminar
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón Editar Azul
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: Color.fromARGB(255, 33, 47, 243)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DuenoMuestraForm(
                            firstName: widget.firstName,
                            emailUser: widget.emailUser,
                            inventarioId: widget.inventarioId,
                            duenoId: id,
                            nombreInicial: nombre,
                          ),
                        ),
                      ),
                    ),
                    // Botón Eliminar Rojo
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _confirmarEliminacion(id, nombre),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

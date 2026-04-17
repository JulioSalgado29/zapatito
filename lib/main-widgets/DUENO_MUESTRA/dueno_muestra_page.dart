import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:zapatito/main-widgets/DUENO_MUESTRA/dueno_muestra_form.dart';

class DuenoMuestraPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;
  const DuenoMuestraPage({super.key, this.firstName, this.emailUser, this.inventarioId});

  @override
  State<DuenoMuestraPage> createState() => _DuenoMuestraPageState();
}

class _DuenoMuestraPageState extends State<DuenoMuestraPage> {
  
  // 🔹 Función para mostrar el diálogo de confirmación de eliminación
  // 🔹 Función para mostrar el diálogo de confirmación con estilo "Zapatito"
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
              const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                '¿Eliminar Dueño?',
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                  ),
                  // Botón Eliminar
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () async {
                      // 🔹 Cerramos el diálogo primero
                      Navigator.pop(ctx);

                      // 🔹 Mostramos el SplashScreen de carga
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const SplashScreen02(),
                      );

                      try {
                        // 🔹 Eliminación real en Firestore
                        await FirebaseFirestore.instance
                            .collection('dueno_muestra')
                            .doc(id)
                            .delete();

                        // 🔹 Quitamos el Splash
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }

                        // 🔹 Mensaje de éxito
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dueño eliminado correctamente 🗑️'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } catch (e) {
                        // En caso de error, quitamos el splash y avisamos
                        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al eliminar: $e')),
                        );
                      }
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
            .orderBy('nombre', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error al cargar'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No hay registros disponibles.'));

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
                title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                // 🔹 Trailing con botones de Editar y Eliminar
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón Editar Azul
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color.fromARGB(255, 33, 47, 243)),
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
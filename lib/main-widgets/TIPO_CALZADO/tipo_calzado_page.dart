import 'package:flutter/material.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:zapatito/main-widgets/MAIN/home_page.dart';
import 'package:zapatito/main-widgets/TIPO_CALZADO/tipo_calzado_form.dart';

class TipoCalzadoPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  const TipoCalzadoPage(
      {super.key, this.firstName, this.emailUser, this.inventarioId});

  @override
  State<TipoCalzadoPage> createState() => _TipoCalzadoPageState();
}

class _TipoCalzadoPageState extends State<TipoCalzadoPage> {
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((status) {
      setState(() {
        isOnline = status != ConnectivityResult.none;
      });
    });
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

  void _mostrarFormulario({DocumentSnapshot? doc}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: TipoCalzadoForm(
          firstName: widget.firstName,
          emailUser: widget.emailUser,
          inventarioId: widget.inventarioId,
          isOnline: isOnline,
          doc: doc,
        ),
      ),
    );
  }

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
                Color.fromARGB(255, 33, 47, 243),
                Color(0xFF4A5AF7),
              ],
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
                '¿Eliminar tipo de calzado?',
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Cancelar',
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () async {
                      _mostrarSplashScreen();

                      await FirebaseFirestore.instance
                          .collection('tipo_calzado')
                          .doc(id)
                          .update({'activo': false});

                      _ocultarSplashScreen();

                      await Future.delayed(const Duration(milliseconds: 150));

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Tipo de calzado eliminado correctamente 🗑️'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }

                      Navigator.pop(ctx);
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

  Widget _buildFeatureChip(IconData icon, String label, bool value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: value ? Colors.blue : Colors.grey),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        Text(
          value ? "Sí" : "No",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: value ? Colors.green[700] : Colors.red[700],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inventarioId == null) {
      return const SplashScreen02();
    }
    return Scaffold(
      appBar: Designwidgets().appBarMain("Tipo de Calzado", isOnline: isOnline),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tipo_calzado')
              .where('activo', isEqualTo: true)
              .where('id_inventario', isEqualTo: widget.inventarioId)
              .orderBy('fecha_creacion', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text('No hay tipos de calzado aún'));
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final nombre = data['nombre'] ?? '';
                final icono = data['icono'] ?? '🥿';
                final usuario = data['usuario_creacion'] ?? '';
                final taco = data['taco'] ?? false;
                final plataforma = data['plataforma'] ?? false;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8), // Aumentamos margen entre cards
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8), // Espacio interno extra
                    child: ListTile(
                      leading: (icono.toString().endsWith('.png') ||
                              icono.toString().endsWith('.jpg'))
                          ? Image.asset(
                              icono,
                              width: 45,
                              height: 45,
                              fit: BoxFit.contain,
                            )
                          : Text(
                              icono,
                              style: const TextStyle(fontSize: 32),
                            ),
                      title: Text(
                        nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          // Cambiamos Row por Wrap para evitar el desbordamiento (Overflow)
                          Wrap(
                            spacing:
                                12, // Espacio horizontal entre Taco y Plataforma
                            runSpacing:
                                8, // Espacio vertical si uno se baja a la siguiente línea
                            children: [
                              _buildFeatureChip(Icons.height, 'Taco', taco),
                              _buildFeatureChip(
                                  Icons.layers, 'Plataforma', plataforma),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Autor con Expanded para que el texto no empuje nada hacia afuera
                          Row(
                            children: [
                              Icon(Icons.account_circle,
                                  size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Creado por: $usuario',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500]),
                                  overflow: TextOverflow
                                      .ellipsis, // Si es muy largo, pone "..."
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Wrap(
                        direction: Axis
                            .vertical, // Los botones se alinean verticalmente para no chocar
                        alignment: WrapAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent, size: 22),
                            onPressed: () => _mostrarFormulario(doc: doc),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever,
                                color: Colors.redAccent, size: 22),
                            onPressed: () =>
                                _confirmarEliminacion(context, doc.id),
                          ),
                        ],
                      ),
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

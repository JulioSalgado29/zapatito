import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:zapatito/main-widgets/INVENTARIO/inventario_form_page_serie.dart';
import 'package:zapatito/main-widgets/MAIN/home_page.dart';
import 'inventario_form_page.dart';

class InventarioPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  const InventarioPage(
      {super.key, this.firstName, this.emailUser, this.inventarioId});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  String? inventarioId;

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

  Stream<QuerySnapshot> _getFilasInventario() {
    return FirebaseFirestore.instance
        .collection('fila_inventario')
        .where('inventario_id', isEqualTo: inventarioId)
        .snapshots();
  }

  Future<List<QueryDocumentSnapshot>> _getSubfilas(String filaId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('subfila_inventario')
        .where('fila_inventario_id', isEqualTo: filaId)
        .orderBy('fila_inventario_id')
        .orderBy('talla')
        .orderBy('plataforma')
        .orderBy('taco')
        .get();
    return snapshot.docs;
  }

  /// 🔹 Obtiene datos del calzado directamente (sin tipo_calzado)
  Future<Map<String, dynamic>> _getDatosCalzado(String calzadoId) async {
    final calzadoSnap = await FirebaseFirestore.instance
        .collection('calzado')
        .doc(calzadoId)
        .get();

    if (!calzadoSnap.exists) {
      return {
        'nombre': 'Sin nombre',
        'icono': null,
        'taco': true,
        'plataforma': true,
      };
    }

    final calzadoData = calzadoSnap.data();

    return {
      'nombre': calzadoData?['nombre'] ?? 'Sin nombre',
      'icono': calzadoData?['icono'],
      'taco': calzadoData?['taco'] ?? true,
      'plataforma': calzadoData?['plataforma'] ?? true,
    };
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

  /// 🔹 Eliminar fila y sus subfilas
  Future<void> _eliminarFila(String filaId) async {
    final subfilas = await FirebaseFirestore.instance
        .collection('subfila_inventario')
        .where('fila_inventario_id', isEqualTo: filaId)
        .get();

    for (var sub in subfilas.docs) {
      await sub.reference.delete();
    }

    await FirebaseFirestore.instance
        .collection('fila_inventario')
        .doc(filaId)
        .delete();

    _ocultarSplashScreen();
    _ocultarSplashScreen();

    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Codigo de inventario eliminado correctamente 🗑️'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      return;
    }
  }

  /// 🔹 Abre formulario y recarga al volver
  Future<void> _abrirFormulario({String? filaId}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventarioFormPage(
          firstName: widget.firstName,
          emailUser: widget.emailUser,
          inventarioId: widget.inventarioId,
          filaId: filaId,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _abrirFormularioSerie() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventarioSerieFormPage(
          firstName: widget.firstName,
          emailUser: widget.emailUser,
          inventarioId: widget.inventarioId),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  /// 🔹 Construye icono (asset o URL)
  Widget _buildIcon(String? icono) {
    if (icono == null || icono.isEmpty) {
      return const Icon(Icons.shopping_bag_outlined,
          size: 40, color: Colors.blueAccent);
    }

    final lower = icono.toLowerCase();

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return Image.network(
        icono,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported, size: 40),
      );
    }

    return Image.asset(
      icono,
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.image_not_supported, size: 40),
    );
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
                '¿Eliminar codigo de inventario?',
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
                      await _eliminarFila(id);
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
      appBar: Designwidgets().appBarMain("Inventario"),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getFilasInventario(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay filas de inventario registradas.'),
            );
          }

          final filas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: filas.length,
            itemBuilder: (context, index) {
              final fila = filas[index];
              final calzadoId = fila['calzado_id'];
              final cantidad = fila['cantidad'];

              return FutureBuilder<Map<String, dynamic>>(
                future: _getDatosCalzado(calzadoId),
                builder: (context, calzadoSnap) {
                  if (!calzadoSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: LinearProgressIndicator(),
                    );
                  }

                  final calzadoData = calzadoSnap.data!;
                  final nombreCalzado = calzadoData['nombre'] ?? 'Sin nombre';
                  final icono = calzadoData['icono'] as String?;
                  final tieneTaco = calzadoData['taco'] ?? true;
                  final tienePlataforma = calzadoData['plataforma'] ?? true;

                  return FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: _getSubfilas(fila.id),
                    builder: (context, subfilaSnap) {
                      if (subfilaSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: LinearProgressIndicator(),
                        );
                      }

                      final subfilas = subfilaSnap.data ?? [];

                      // 🔹 Si ambos campos son falsos, no mostrar esta fila
                      //if (!tieneTaco && !tienePlataforma) {
                      //return const SizedBox.shrink();
                      //}

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        elevation: 3,
                        child: ExpansionTile(
                          leading: _buildIcon(icono),
                          title: Text(
                            nombreCalzado,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Cantidad total: $cantidad'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'editar') {
                                await _abrirFormulario(filaId: fila.id);
                              } else if (value == 'eliminar') {
                                _confirmarEliminacion(context, fila.id);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                  value: 'editar', child: Text('Editar')),
                              PopupMenuItem(
                                  value: 'eliminar', child: Text('Eliminar')),
                            ],
                          ),
                          children: subfilas.isEmpty
                              ? const [
                                  Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(
                                      'Sin subfilas registradas.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ]
                              : subfilas.map((sub) {
                                  final cantidad = sub['cantidad'];
                                  final talla = sub['talla'];
                                  final taco = sub['taco'];
                                  final plataforma = sub['plataforma'];

                                  Text? mostrarSubtitulo;
                                  if (tieneTaco && tienePlataforma) {
                                    mostrarSubtitulo = Text(
                                        'Taco: $taco  |  Plataforma: ${plataforma ? 'Sí' : 'No'}');
                                  } else if (tieneTaco) {
                                    mostrarSubtitulo = Text('Taco: $taco');
                                  } else if (tienePlataforma) {
                                    mostrarSubtitulo = Text(
                                        'Plataforma: ${plataforma ? 'Sí' : 'No'}');
                                  }

                                  Text? subtitle;
                                  if (tieneTaco || tienePlataforma) {
                                    subtitle = mostrarSubtitulo;
                                  } else {
                                    subtitle = null;
                                  }

                                  return ListTile(
                                    leading: const Icon(Icons.label_outline),
                                    title: Text(
                                      'Talla: $talla  |  Cantidad: $cantidad',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4E4E4E)),
                                    ),
                                    subtitle: subtitle,
                                  );
                                }).toList(),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
            width: 150, // 👌 Ambos iguales
            child: Container(
              decoration: BoxDecoration(
                gradient: Designwidgets().linearGradientBlue(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FloatingActionButton.extended(
                heroTag: "btn1",
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: _abrirFormulario,
                icon: const Icon(Icons.add, color: Colors.white),
                label:
                    const Text("Manual", style: TextStyle(color: Colors.white)),
              ),
            )),
        const SizedBox(height: 12),
        SizedBox(
          width: 150, // 👌 Mismo ancho
          child: Container(
            decoration: BoxDecoration(
              gradient: Designwidgets().linearGradientFire(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FloatingActionButton.extended(
              heroTag: "btn2",
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: () {
                _abrirFormularioSerie();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Por serie",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

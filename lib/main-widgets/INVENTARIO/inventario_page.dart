import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:zapatito/main-widgets/MAIN/home_page.dart';
import 'inventario_form_page.dart';

class InventarioPage extends StatefulWidget {
  final String? firstName;

  const InventarioPage({super.key, this.firstName});

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
    final query = await FirebaseFirestore.instance
        .collection('inventario')
        .where('propietario', isEqualTo: widget.firstName)
        .get();

    if (query.docs.isEmpty) {
      // Si no tiene inventario, redirige al home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      });
    } else {
      setState(() {
        inventarioId = query.docs.first.id;
      });
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
        .get();
    return snapshot.docs;
  }

  /// 🔹 Obtiene nombre e icono del tipo de calzado asociado
  Future<Map<String, dynamic>> _getDatosCalzado(String calzadoId) async {
    final calzadoSnap = await FirebaseFirestore.instance
        .collection('calzado')
        .doc(calzadoId)
        .get();

    if (!calzadoSnap.exists) {
      return {'nombre': 'Sin nombre', 'icono': null};
    }

    final calzadoData = calzadoSnap.data();

    final tipoId = calzadoData?['tipo_calzado_id'] as String?;

    String? icono;
    if (tipoId != null) {
      final tipoSnap = await FirebaseFirestore.instance
          .collection('tipo_calzado')
          .doc(tipoId)
          .get();

      final tipoData = tipoSnap.data();
      if (tipoData != null && tipoData['icono'] != null) {
        icono = tipoData['icono'].toString();
      }
    }

    return {
      'nombre': calzadoData?['nombre'] ?? 'Sin nombre',
      'icono': icono,
    };
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fila eliminada correctamente')),
      );
    }
  }

  /// 🔹 Abre formulario y recarga al volver
  Future<void> _abrirFormulario({String? filaId}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventarioFormPage(
          firstName: widget.firstName,
          inventarioId: inventarioId!,
          filaId: filaId,
        ),
      ),
    );

    if (result == true) {
      setState(() {}); // 🔁 Recargar datos al volver
    }
  }

  /// 🔹 Construye icono (asset o URL)
  Widget _buildIcon(String? icono) {
    if (icono == null || icono.isEmpty) {
      return const Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.blueAccent);
    }

    final lower = icono.toLowerCase();

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return Image.network(
        icono,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 40),
      );
    }

    return Image.asset(
      icono,
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (inventarioId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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

                  return FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: _getSubfilas(fila.id),
                    builder: (context, subfilaSnap) {
                      if (subfilaSnap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: LinearProgressIndicator(),
                        );
                      }

                      final subfilas = subfilaSnap.data ?? [];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                                await _eliminarFila(fila.id);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'editar', child: Text('Editar')),
                              PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
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

                                  return ListTile(
                                    leading: const Icon(Icons.label_outline),
                                    title: Text('Cantidad: $cantidad  |  Talla: $talla'),
                                    subtitle: Text(
                                      'Taco: $taco  |  Plataforma: ${plataforma ? 'Sí' : 'No'}',
                                    ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:zapatito/main-widgets/MAIN/home_page.dart';
import 'package:zapatito/main-widgets/VENTA/venta_form_page.dart';

class VentaPage extends StatefulWidget {
  
  final String? firstName;

  const VentaPage({super.key, this.firstName});

  @override
  State<VentaPage> createState() => _VentaPageState();
}

class _VentaPageState extends State<VentaPage> {
    String? inventarioId;

    @override
  void initState() {
    super.initState();
    _verificarInventario();
  }

  /// 🔹 Obtener filas de venta
  Stream<QuerySnapshot> _getFilasVenta() {
    return FirebaseFirestore.instance
        .collection('fila_venta')
        .orderBy('fecha_creacion', descending: true)
        .snapshots();
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

  void _navegarFormulario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VentaFormPage(
          firstName: widget.firstName,
          inventarioId: inventarioId!,
        ),
      ),
    );
  }

  /// 🔹 Obtener subfilas de una fila
  Future<List<QueryDocumentSnapshot>> _getSubfilas(String filaId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('subfila_venta')
        .where('fila_venta_id', isEqualTo: filaId)
        .orderBy('talla')
        .get();

        print('Subfilas encontradas: ${snapshot.docs.length}');
        
    return snapshot.docs;
  }

  /// 🔹 Obtener datos del calzado
  Future<Map<String, dynamic>> _getDatosCalzado(String calzadoId) async {
    final snap = await FirebaseFirestore.instance
        .collection('calzado')
        .doc(calzadoId)
        .get();

    if (!snap.exists) {
      return {
        'nombre': 'Sin nombre',
        'icono': null,
        'taco': true,
        'plataforma': true,
      };
    }

    final data = snap.data();

    return {
      'nombre': data?['nombre'] ?? 'Sin nombre',
      'icono': data?['icono'],
      'taco': data?['taco'] ?? true,
      'plataforma': data?['plataforma'] ?? true,
    };
  }

  /// 🔹 Icono
  Widget _buildIcon(String? icono) {
    if (icono == null || icono.isEmpty) {
      return const Icon(Icons.point_of_sale,
          size: 40, color: Colors.green);
    }

    if (icono.startsWith('http')) {
      return Image.network(icono, width: 40, height: 40);
    }

    return Image.asset(icono, width: 40, height: 40);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain("Ventas"),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getFilasVenta(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen02();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay ventas registradas.'),
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
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    );
                  }

                  final data = calzadoSnap.data!;
                  final nombre = data['nombre'];
                  final icono = data['icono'];
                  final tieneTaco = data['taco'];
                  final tienePlataforma = data['plataforma'];

                  return FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: _getSubfilas(fila.id),
                    builder: (context, subSnap) {
                      if (subSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: LinearProgressIndicator(),
                        );
                      }

                      final subfilas = subSnap.data ?? [];
                      print('Subfilas que se van a mostrar: $subfilas');
                      print('hola');
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        child: ExpansionTile(
                          leading: _buildIcon(icono),
                          title: Text(nombre,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle:
                              Text('Cantidad vendida: $cantidad'),
                          children: subfilas.map((sub) {
                            final talla = sub['talla'];
                            final cantidad = sub['cantidad'];
                            final taco = sub['taco'];
                            final plataforma = sub['plataforma'];
                            //final subtotal = sub['subtotal'];

                            Widget? subtitle;

                            if (tieneTaco && tienePlataforma) {
                              subtitle = Text(
                                  'Taco: $taco | Plataforma: ${plataforma ? 'Sí' : 'No'}');
                            } else if (tieneTaco) {
                              subtitle = Text('Taco: $taco');
                            } else if (tienePlataforma) {
                              subtitle = Text(
                                  'Plataforma: ${plataforma ? 'Sí' : 'No'}');
                            }

                            return ListTile(
                              leading: const Icon(Icons.sell),
                              title: Text(
                                'Talla: $talla | Cantidad: $cantidad',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: subtitle,
                              //trailing: Text('S/ $subtotal'),
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
        onPressed: () => _navegarFormulario(),
        backgroundColor: const Color.fromARGB(255, 33, 47, 243),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
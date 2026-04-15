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
      final docSnapshot = await FirebaseFirestore.instance
          .collection('inventario')
          .doc(widget.inventarioId)
          .get();

      if (!docSnapshot.exists) {
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
        .where('inventario_id', isEqualTo: widget.inventarioId)
        .snapshots();
  }

  Future<List<QueryDocumentSnapshot>> _getSubfilas(String filaId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('subfila_inventario')
        .where('fila_inventario_id', isEqualTo: filaId)
        .orderBy('fila_inventario_id')
        .orderBy('talla')
        .orderBy('taco')
        .orderBy('plataforma')
        .orderBy('colores')
        .get();
    return snapshot.docs;
  }

  /// 🔹 Obtiene datos del calzado directamente (Agregado campo 'estado')
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
        'colores': true,
        'activo': false, // Por defecto inactivo si no existe
      };
    }

    final calzadoData = calzadoSnap.data();

    return {
      'nombre': calzadoData?['nombre'] ?? 'Sin nombre',
      'icono': calzadoData?['icono'],
      'taco': calzadoData?['taco'] ?? true,
      'plataforma': calzadoData?['plataforma'] ?? true,
      'colores': calzadoData?['colores'] ?? true,
      'activo': calzadoData?['activo'] ?? true, // <--- Nuevo campo extraído
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
    }
  }

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

  Widget _buildInfoChip(String text, {bool isColor = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isColor ? Colors.indigo[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: isColor ? Colors.indigo[100]! : Colors.grey[300]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isColor ? Colors.indigo[900] : Colors.black87,
          fontWeight: isColor ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  /// 🔹 Widget para mostrar si el producto está Activo/Inactivo
  Widget _buildEstadoChip(bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: activo ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: activo ? Colors.green[200]! : Colors.red[200]!),
      ),
      child: Text(
        activo ? 'CODIGO\nACTIVO' : 'CODIGO\nINACTIVO',
        textAlign: TextAlign.center, // Alinea ambas palabras al centro
        style: TextStyle(
          fontSize: 10,
          height: 1.1, // Ajusta el espacio entre las dos líneas si es necesario
          fontWeight: FontWeight.bold,
          color: activo ? Colors.green[700] : Colors.red[700],
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
                  final tieneColores = calzadoData['colores'] ?? true;
                  final estaActivo =
                      calzadoData['activo'] ?? true; // <--- Valor obtenido

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

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        elevation: 3,
                        child: ExpansionTile(
                          leading: _buildIcon(icono),
                          title: Row(
                            // <-- Row para mostrar nombre y estado
                            children: [
                              Expanded(
                                child: Text(
                                  nombreCalzado,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildEstadoChip(
                                  estaActivo), // <-- Indicador de Estado
                            ],
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
                                  final colores = sub['colores'];

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                          Icons.inventory_2_outlined,
                                          color: Color(0xFF4E4E4E)),
                                    ),
                                    title: Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Talla: $talla',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Cant: $cantidad',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    subtitle: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if (tieneTaco)
                                          _buildInfoChip('Taco: $taco'),
                                        if (tienePlataforma)
                                          _buildInfoChip(
                                              'Plataforma: ${plataforma ? 'Sí' : 'No'}'),
                                        if (tieneColores &&
                                            colores != null &&
                                            colores.toString().isNotEmpty)
                                          _buildInfoChip('Color: $colores',
                                              isColor: true),
                                      ],
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFab(
            Designwidgets().linearGradientBlue(context),
            "btn1",
            _abrirFormulario,
            "Manual",
            Icons.add_circle_outline,
          ),
          const SizedBox(height: 12),
          _buildFab(
            Designwidgets().linearGradientFire(context),
            "btn2",
            _abrirFormularioSerie,
            "Por serie",
            Icons.inventory_2,
          ),
        ],
      ),
    );
  }

  Widget _buildFab(Gradient gradient, String tag, VoidCallback onPressed,
      String label, IconData icon) {
    return SizedBox(
      width: 170,
      child: Container(
        decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ]),
        child: FloatingActionButton.extended(
          heroTag: tag,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

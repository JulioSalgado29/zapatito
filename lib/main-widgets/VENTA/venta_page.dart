import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:zapatito/main-widgets/MAIN/home_page.dart';
import 'package:zapatito/main-widgets/VENTA/venta_form_page.dart';
import 'package:zapatito/main-widgets/VENTA/venta_form_page_multiple.dart';

class VentaPage extends StatefulWidget {
  final String? firstName;

  const VentaPage({super.key, this.firstName});

  @override
  State<VentaPage> createState() => _VentaPageState();
}

class _VentaPageState extends State<VentaPage> {
  String? inventarioId;

  // Cache para evitar llamadas repetidas a Firestore
  final Map<String, Map<String, dynamic>> _calzadoCache = {};

  @override
  void initState() {
    super.initState();
    _verificarInventario();
  }

  // -------------------------------------------------------
  // STREAM DE VENTAS
  // -------------------------------------------------------

  Stream<QuerySnapshot> _getFilasVenta() {
    return FirebaseFirestore.instance
        .collection('fila_venta')
        .where('usuario_creacion', isEqualTo: widget.firstName)
        .orderBy('fecha_creacion', descending: true)
        .snapshots();
  }

  // -------------------------------------------------------
  // VERIFICAR INVENTARIO
  // -------------------------------------------------------

  Future<void> _verificarInventario() async {
    final query = await FirebaseFirestore.instance
        .collection('inventario')
        .where('propietario', isEqualTo: widget.firstName)
        .get();

    if (query.docs.isEmpty) {
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

  // -------------------------------------------------------
  // NAVEGACION AL FORMULARIO
  // -------------------------------------------------------

  void _navegarFormulario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VentaFormPage(
          firstName: widget.firstName,
        ),
      ),
    );
  }

  void _navegarFormularioMultiple() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VentaFormPageMultiple(
          firstName: widget.firstName,
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // DATOS DEL CALZADO (con cache)
  // -------------------------------------------------------

  Future<Map<String, dynamic>> _getDatosCalzado(String calzadoId) async {
    if (_calzadoCache.containsKey(calzadoId)) {
      return _calzadoCache[calzadoId]!;
    }

    final snap = await FirebaseFirestore.instance
        .collection('calzado')
        .doc(calzadoId)
        .get();

    Map<String, dynamic> result;

    if (!snap.exists) {
      result = {
        'nombre': 'Sin nombre',
        'icono': null,
        'taco': false,
        'plataforma': false,
      };
    } else {
      final data = snap.data()!;
      result = {
        'nombre': data['nombre'] ?? 'Sin nombre',
        'icono': data['icono'],
        'taco': data['taco'] ?? false,
        'plataforma': data['plataforma'] ?? false,
      };
    }

    _calzadoCache[calzadoId] = result;
    return result;
  }

  // -------------------------------------------------------
  // ICONO
  // -------------------------------------------------------

  Widget _buildIcon(String? icono) {
    if (icono == null || icono.isEmpty) {
      return const Icon(Icons.point_of_sale, size: 40, color: Colors.green);
    }
    if (icono.startsWith('http')) {
      return Image.network(
        icono,
        width: 40,
        height: 40,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.point_of_sale, size: 40, color: Colors.green),
      );
    }
    return Image.asset(
      icono,
      width: 40,
      height: 40,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.point_of_sale, size: 40, color: Colors.green),
    );
  }

  // -------------------------------------------------------
  // FORMATEAR FECHA
  // -------------------------------------------------------

  String _formatFecha(dynamic timestamp) {
    if (timestamp == null) return 'Sin fecha';
    try {
      final dt = (timestamp as Timestamp).toDate();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Sin fecha';
    }
  }

  // -------------------------------------------------------
  // CARD DE CADA VENTA
  // -------------------------------------------------------

  Widget _buildVentaCard(QueryDocumentSnapshot fila) {
    final filaData = fila.data() as Map<String, dynamic>;
    final calzadoId = filaData['calzado_id'] ?? '';
    final cantidad = filaData['cantidad'] ?? 0;
    final talla = filaData['talla'] ?? 0;
    final taco = filaData['taco'] ?? 0;
    final plataforma = filaData['plataforma'] ?? false;
    final fecha = filaData['fecha_creacion'];
    // 🔥 Capturamos el precio de la fila_venta
    final precioTotal = (filaData['precio_venta_total'] ?? 0.0).toDouble();

    return FutureBuilder<Map<String, dynamic>>(
        future: _getDatosCalzado(calzadoId),
        builder: (context, calzadoSnap) {
          if (!calzadoSnap.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: LinearProgressIndicator(),
            );
          }

          final calzadoData = calzadoSnap.data!;
          final nombre = calzadoData['nombre'] as String;
          final icono = calzadoData['icono'] as String?;
          final tieneTaco = calzadoData['taco'] as bool;
          final tienePlataforma = calzadoData['plataforma'] as bool;

          final List<Widget> detalles = [];

          detalles.add(
            _buildDetalleRow(Icons.straighten, 'Talla', talla.toString()),
          );
          detalles.add(
            _buildDetalleRow(
                Icons.inventory_2, 'Cantidad', cantidad.toString()),
          );
          
          // 🔥 Detalle del precio en la lista desplegada
          detalles.add(
            _buildDetalleRow(Icons.monetization_on, 'Precio Total', 'S/ ${precioTotal.toStringAsFixed(2)}'),
          );

          if (tieneTaco && taco > 0) {
            detalles.add(
              _buildDetalleRow(Icons.height, 'Taco', '$taco cm'),
            );
          }

          if (tienePlataforma) {
            detalles.add(
              _buildDetalleRow(
                Icons.layers,
                'Plataforma',
                plataforma ? 'Si' : 'No',
              ),
            );
          }

          return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ExpansionTile(
                leading: _buildIcon(icono),
                title: Text(
                  nombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 Subtítulo con el precio resaltado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cant: $cantidad | Talla: $talla',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'S/ ${precioTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.green
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatFecha(fecha),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...detalles,
                  const SizedBox(height: 4),
                ],
              ));
        });
  }

  Widget _buildDetalleRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (inventarioId == null) {
      return const SplashScreen02();
    }
    
    return Scaffold(
      appBar: Designwidgets().appBarMain('Ventas'),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getFilasVenta(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar ventas: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No hay ventas registradas.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final filas = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: filas.length,
            itemBuilder: (context, index) {
              return _buildVentaCard(filas[index]);
            },
          );
        },
      ),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
            width: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: Designwidgets().linearGradientBlue(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FloatingActionButton.extended(
                heroTag: "btn1",
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: _navegarFormulario,
                icon: const Icon(Icons.add, color: Colors.white),
                label:
                    const Text("Por Código", style: TextStyle(color: Colors.white)),
              ),
            )),
        const SizedBox(height: 12),
        SizedBox(
            width: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: Designwidgets().linearGradientFire(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FloatingActionButton.extended(
                heroTag: "btn2", // 🔥 Cambiado a btn2 para evitar conflicto de Hero
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: _navegarFormularioMultiple,
                icon: const Icon(Icons.add, color: Colors.white),
                label:
                    const Text("Múltiple", style: TextStyle(color: Colors.white)),
              ),
            )),
        const SizedBox(height: 12),
      ]),
    );
  }
}
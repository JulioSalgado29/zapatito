import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:zapatito/main-widgets/MAIN/home_page.dart';
import 'package:zapatito/main-widgets/VENTA/venta_form_page.dart';
import 'package:zapatito/main-widgets/VENTA/venta_form_page_multiple.dart';

class VentaPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  const VentaPage(
      {super.key, this.firstName, this.emailUser, this.inventarioId});

  @override
  State<VentaPage> createState() => _VentaPageState();
}

class _VentaPageState extends State<VentaPage> {
  final Map<String, Map<String, dynamic>> _calzadoCache = {};
  DateTime? _fechaFiltro;

  @override
  void initState() {
    super.initState();
    _verificarInventario();
  }

  Stream<QuerySnapshot> _getFilasVenta() {
    Query query = FirebaseFirestore.instance
        .collection('fila_venta')
        .where('id_inventario', isEqualTo: widget.inventarioId);

    if (_fechaFiltro != null) {
      DateTime inicioDia =
          DateTime(_fechaFiltro!.year, _fechaFiltro!.month, _fechaFiltro!.day);
      DateTime finDia = inicioDia.add(const Duration(days: 1));
      query = query
          .where('fecha_creacion',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .where('fecha_creacion', isLessThan: Timestamp.fromDate(finDia));
    }
    return query.orderBy('fecha_creacion', descending: true).snapshots();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _fechaFiltro) {
      setState(() => _fechaFiltro = picked);
    }
  }

  Future<void> _verificarInventario() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('inventario')
          .doc(widget.inventarioId)
          .get();
      if (!docSnapshot.exists) {
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      print("Error de inventario: $e");
    }
  }

  // CORRECCIÓN DE "14e" -> "14 de"
  String _formatFechaLarga(dynamic timestamp) {
    if (timestamp == null) return 'Sin fecha';
    try {
      final DateTime dt = (timestamp as Timestamp).toDate();
      String dia = DateFormat('EEEE', 'es_ES').format(dt);
      String resto = DateFormat("d 'de' MMMM - yyyy", "es_ES")
          .format(dt); // Escapado con 'de'
      String hora = DateFormat('hh:mm a').format(dt);
      return "${dia[0].toUpperCase()}${dia.substring(1)} - $resto ($hora)";
    } catch (e) {
      return 'Fecha no válida';
    }
  }

  Future<Map<String, dynamic>> _getDatosCalzado(String calzadoId) async {
    if (_calzadoCache.containsKey(calzadoId)) return _calzadoCache[calzadoId]!;
    final snap = await FirebaseFirestore.instance
        .collection('calzado')
        .doc(calzadoId)
        .get();
    Map<String, dynamic> result =
        snap.exists ? snap.data()! : {'nombre': 'Sin nombre', 'icono': null};
    _calzadoCache[calzadoId] = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inventarioId == null) return const SplashScreen02();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff5b16c2),
        foregroundColor: Colors.white,
        // Forzamos la flecha de regreso para que el drawer no la quite
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ventas Realizadas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
          ),
        ),
        actions: [
          if (_fechaFiltro != null)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              onPressed: () => setState(() => _fechaFiltro = null),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _seleccionarFecha(context),
          ),
        ],
      ),
      drawer:
          Designwidgets().drawerHome(context, widget.firstName ?? "Invitado"),
      body: SafeArea(
        child: Column(
          children: [
            if (_fechaFiltro != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.blue.shade50,
                child: Text(
                  'Filtrado: ${DateFormat('dd/MM/yyyy').format(_fechaFiltro!)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFilasVenta(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error de conexión.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No hay ventas registradas.'));
                  }

                  final filas = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.only(
                        top: 10, bottom: 150), // Tu padding original
                    cacheExtent: 10, // Parche invisible para Impeller
                    itemCount: filas.length,
                    itemBuilder: (context, index) =>
                        _buildVentaCard(filas[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFab(Designwidgets().linearGradientBlue(context), "btn1",
              _navegarFormulario, "Por Código"),
          const SizedBox(height: 12),
          _buildFab(Designwidgets().linearGradientFire(context), "btn2",
              _navegarFormularioMultiple, "Múltiple"),
        ],
      ),
    );
  }

  Widget _buildVentaCard(QueryDocumentSnapshot fila) {
    final filaData = fila.data() as Map<String, dynamic>;
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDatosCalzado(filaData['calzado_id'] ?? ''),
      builder: (context, calzadoSnap) {
        if (!calzadoSnap.hasData) return const LinearProgressIndicator();

        final calzadoData = calzadoSnap.data!;
        final precioTotal = (filaData['precio_venta_total'] ?? 0.0).toDouble();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: _buildIcon(calzadoData['icono']),
            title: Text(calzadoData['nombre'],
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Cant: ${filaData['cantidad']} • Talla: ${filaData['talla']}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                    Text('S/ ${precioTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 12, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              _formatFechaLarga(filaData['fecha_creacion']),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              const Divider(),
              _buildDetalleRow(Icons.person, 'Vendedor',
                  filaData['usuario_creacion'] ?? 'Desconocido'),
              _buildDetalleRow(Icons.straighten, 'Talla Seleccionada',
                  filaData['talla'].toString()),
              _buildDetalleRow(Icons.shopping_bag, 'Cantidad Vendida',
                  filaData['cantidad'].toString()),
              _buildDetalleRow(Icons.monetization_on, 'Total de la Fila',
                  'S/ ${precioTotal.toStringAsFixed(2)}'),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetalleRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildIcon(String? icono) {
    if (icono == null || icono.isEmpty) {
      return const Icon(Icons.image_not_supported,
          size: 35, color: Colors.grey);
    }
    return Image.asset(icono,
        width: 40,
        height: 40,
        errorBuilder: (_, __, ___) => const Icon(Icons.receipt));
  }

  void _navegarFormulario() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => VentaFormPage(
              firstName: widget.firstName,
              emailUser: widget.emailUser,
              inventarioId: widget.inventarioId)));
  void _navegarFormularioMultiple() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => VentaFormPageMultiple(
              firstName: widget.firstName,
              emailUser: widget.emailUser,
              inventarioId: widget.inventarioId)));

  Widget _buildFab(
      Gradient gradient, String tag, VoidCallback onPressed, String label) {
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
          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:zapatito/main-widgets/CALZADO/calzado_page.dart';
import 'package:zapatito/main-widgets/INVENTARIO/inventario_page.dart';
import 'package:zapatito/main-widgets/TIPO_CALZADO/tipo_calzado_page.dart';
import 'package:zapatito/main-widgets/VENTA/venta_page.dart';
import 'package:zapatito/services/local_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName;
  String? firstName;
  String? emailUser;
  String? propietarioId;
  String? inventarioId;

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  Future<void> loadUserName() async {
    final data = await LocalStorageService.getUserData();
    final userEmail = data['email'];

    setState(() {
      userName = data['name'] ?? 'Invitado';
      firstName = userName;
      emailUser = userEmail;
    });

    if (userEmail != null) {
      try {
        // --- PASO 1: Buscar el Propietario ---
        final userQuery = await FirebaseFirestore.instance
            .collection('usuario')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final idProp = userQuery.docs.first.data()['propietario'];

          setState(() {
            propietarioId = idProp;
          });

          // --- PASO 2: Buscar el Inventario usando el propietarioId ---
          if (idProp != null) {
            final invQuery = await FirebaseFirestore.instance
                .collection(
                    'inventario') // 👈 Asegúrate que este sea el nombre de tu colección
                .where('propietario', isEqualTo: idProp)
                .limit(1)
                .get();

            if (invQuery.docs.isNotEmpty) {
              setState(() {
                // Obtenemos el ID del documento (el código alfanumérico de Firebase)
                inventarioId = invQuery.docs.first.id;
              });
            }
          }
        }
      } catch (e) {
        print('Error en la búsqueda masiva: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain("Principal"),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Hola $firstName 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            /*MaterialButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VentasPage(), // 👈 aquí lo pasas directamente
                  ),
                );
              },
              color: const Color.fromARGB(255, 33, 47, 243),
              textColor: Colors.white,
              child: const Text('Ventas'),
            ),*/
            SizedBox(
              width: 200, // 🔹 mismo ancho para ambos
              child: MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TipoCalzadoPage(
                          firstName: firstName,
                          emailUser: emailUser,
                          inventarioId: inventarioId),
                    ),
                  );
                },
                color: const Color.fromARGB(255, 33, 47, 243),
                textColor: Colors.white,
                child: const Text('Tipos de Calzados'),
              ),
            ),
            SizedBox(
              width: 200,
              child: MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalzadoPage(
                          firstName: firstName,
                          emailUser: emailUser,
                          inventarioId: inventarioId),
                    ),
                  );
                },
                color: const Color.fromARGB(255, 33, 47, 243),
                textColor: Colors.white,
                child: const Text('Códigos'),
              ),
            ),
            SizedBox(
              width: 200, // 🔹 mismo ancho para ambos
              child: MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InventarioPage(
                          firstName: firstName,
                          emailUser: emailUser,
                          inventarioId: inventarioId),
                    ),
                  );
                },
                color: const Color.fromARGB(255, 33, 47, 243),
                textColor: Colors.white,
                child: const Text('Inventario'),
              ),
            ),
            SizedBox(
              width: 200, // 🔹 mismo ancho para ambos
              child: MaterialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VentaPage(
                          firstName: firstName,
                          emailUser: emailUser,
                          inventarioId: inventarioId),
                    ),
                  );
                },
                color: const Color.fromARGB(255, 33, 47, 243),
                textColor: Colors.white,
                child: const Text('Ventas'),
              ),
            ),
          ],
        ),
      ),
      drawer: Designwidgets().drawerHome(context, firstName ?? "Invitado"),
    );
  }
}

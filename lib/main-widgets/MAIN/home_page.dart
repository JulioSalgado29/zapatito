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
  String? rolName; // 👈 Nueva variable para el nombre del rol

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
      // --- PASO 1: Buscar datos del Usuario ---
      final userQuery = await FirebaseFirestore.instance
          .collection('usuario')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        final idProp = userData['propietario'];
        final idRol = userData['id_usuario_rol']; // 👈 Obtenemos el ID del rol

        setState(() {
          propietarioId = idProp;
        });

        // --- PASO 1.5: Buscar el Nombre del Rol ---
        if (idRol != null) {
          final rolDoc = await FirebaseFirestore.instance
              .collection('usuario_rol') // 👈 Tu colección de roles
              .doc(idRol) // Buscamos directamente por ID
              .get();
          if (rolDoc.exists) {
            setState(() {
              // Asumiendo que el campo se llama 'nombre' en la colección rol_usuario
              rolName = rolDoc.data()?['nombre_rol'] ?? 'Sin Rol';
            });
          }
        }

        // --- PASO 2: Buscar el Inventario usando el propietarioId ---
        if (idProp != null) {
          final invQuery = await FirebaseFirestore.instance
              .collection('inventario')
              .where('propietario', isEqualTo: idProp)
              .limit(1)
              .get();

          if (invQuery.docs.isNotEmpty) {
            setState(() {
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
@override
Widget build(BuildContext context) {
  // Definimos permisos rápidos
  final bool isAdmin = rolName == "Administrador";
  final bool isVendedor = rolName == "Vendedor";
  final bool isAlmacenero = rolName == "Almacenero";

  return Scaffold(
    appBar: Designwidgets().appBarMain("Principal"),
    // VALIDACIÓN: Si rolName es nulo, significa que aún está consultando Firebase
    body: (rolName == null) 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Cargando perfil y permisos..."),
              ],
            ),
          )
        : Center( // Si ya tenemos el rol, mostramos el menú normal
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Hola $firstName 👋',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Rol: $rolName',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),

                if (isAdmin || isAlmacenero)
                  _buildMenuButton(
                    context,
                    label: 'Tipos de Calzados',
                    page: TipoCalzadoPage(
                        firstName: firstName,
                        emailUser: emailUser,
                        inventarioId: inventarioId),
                  ),

                if (isAdmin || isAlmacenero)
                  _buildMenuButton(
                    context,
                    label: 'Códigos',
                    page: CalzadoPage(
                        firstName: firstName,
                        emailUser: emailUser,
                        inventarioId: inventarioId,
                        isAlmacenero: isAlmacenero),
                  ),

                if (isAdmin || isAlmacenero)
                  _buildMenuButton(
                    context,
                    label: 'Inventario',
                    page: InventarioPage(
                        firstName: firstName,
                        emailUser: emailUser,
                        inventarioId: inventarioId),
                  ),

                if (isAdmin || isVendedor)
                  _buildMenuButton(
                    context,
                    label: 'Ventas',
                    page: VentaPage(
                        firstName: firstName,
                        emailUser: emailUser,
                        inventarioId: inventarioId),
                  ),
              ],
            ),
          ),
    drawer: Designwidgets().drawerHome(context, firstName ?? "Invitado"),
  );
}

// Función auxiliar para no repetir código de diseño de botones
Widget _buildMenuButton(BuildContext context, {required String label, required Widget page}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: SizedBox(
      width: 200,
      child: MaterialButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        color: const Color.fromARGB(255, 33, 47, 243),
        textColor: Colors.white,
        child: Text(label),
      ),
    ),
  );
}
}

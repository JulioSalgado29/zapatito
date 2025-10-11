import 'package:flutter/material.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:zapatito/main-widgets/CALZADO/calzado_page.dart';
import 'package:zapatito/services/local_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName;
  String? firstName;

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  Future<void> loadUserName() async {
    final data = await LocalStorageService.getUserData();
    setState(() {
      userName = data['name'] ?? 'Invitado';
      firstName = userName?.split(' ')[0];
    });
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
              'Hola $userName 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            MaterialButton(
              onPressed: () {
                Navigator.pushNamed(context, '/ventas_page');
              },
              color: const Color.fromARGB(255, 33, 47, 243),
              textColor: Colors.white,
              child: const Text('Ventas'),
            ),
            MaterialButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalzadoPage(firstName: firstName), // 👈 aquí lo pasas directamente
                  ),
                );
              },
              color: const Color.fromARGB(255, 33, 47, 243),
              textColor: Colors.white,
              child: const Text('Calzados'),
            ),
          ],
        ),
      ),
      drawer: Designwidgets().drawerHome(context, userName ?? "Invitado"),
    );
  }
}

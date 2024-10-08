import 'package:flutter/material.dart';
import 'main-widgets/first_page.dart';
//import 'package:shoe_inventory_app/Services/local_storage.dart';


void main() {
  //LocalStorage.configurePrefs();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prueba de cambio 1',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3a086c)),
      ),
      //home: const MyHomePage(title: 'Inventario - Nibbet'),
      //home: const FirsRoute(),
      initialRoute: '/',
      routes: {'/': (context) => const FirsRoute()},
    );
  }
}

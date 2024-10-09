import 'package:flutter/material.dart';
import 'package:zapatito/main-widgets/second_page.dart';
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
      initialRoute: '/',
      routes: {
                '/': (context) => const FirstRoute(),
                '/second_page': (context) => const SecondRoute()
              },
      
    );
  }
}

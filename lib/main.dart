import 'package:flutter/material.dart';
import 'package:zapatito/main-widgets/home_page.dart';
import 'package:zapatito/main-widgets/welcome_page.dart';
import 'package:zapatito/splash-screens/splash_screen.dart';
import 'main-widgets/first_page.dart';
import 'main-widgets/second_page.dart';

void main() async {
  //LocalStorage.configurePrefs();
  await Future.delayed(const Duration(seconds: 3));
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
      home: const WelcomePage(),
      routes: {
        '/welcome_page': (context) => const WelcomePage(),
        '/splash_screen': (context) => const SplashScreen(),
        '/home': (context) => const HomePage(),
        '/first_page': (context) => const FirstPage(),
        '/second_page': (context) => const SecondPage(),
      }
    );
  }
}
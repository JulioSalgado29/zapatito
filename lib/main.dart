import 'package:flutter/material.dart';
import 'package:zapatito/main-widgets/home_page.dart';
import 'package:zapatito/main-widgets/login_page.dart';
import 'package:zapatito/main-widgets/welcome_page.dart';
import 'package:zapatito/components/SplashScreen/splash_screen.dart';
import 'main-widgets/first_page.dart';
import 'main-widgets/second_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  //LocalStorage.configurePrefs();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //await Future.delayed(const Duration(seconds: 3));
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
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WelcomePage(),
      routes: {
        '/splash_screen': (context) => const SplashScreen(),
        '/welcome_page': (context) => const WelcomePage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/first_page': (context) => const FirstPage(),
        '/second_page': (context) => const SecondPage(),
      }
    );
  }
}
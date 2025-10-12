import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zapatito/main-widgets/MAIN/home_page.dart';
import 'package:zapatito/main-widgets/CALZADO/calzado_page.dart';
import 'package:zapatito/main-widgets/MAIN/ventas_page.dart';
import 'package:zapatito/main-widgets/MAIN/login_page.dart';
import 'package:zapatito/main-widgets/MAIN/welcome_page.dart';
import 'package:zapatito/components/SplashScreen/splash_screen_aut.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // 🔹 Asegura almacenamiento offline
  );
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
        '/ventas_page': (context) => const VentasPage(),
        '/calzado_page': (context) => const CalzadoPage(),
      }
    );
  }
}
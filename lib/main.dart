import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 1. IMPORTA ESTO
import 'package:zapatito/main-widgets/INVENTARIO/inventario_page.dart';
import 'package:zapatito/main-widgets/MAIN/home_page.dart';
import 'package:zapatito/main-widgets/CALZADO/calzado_page.dart';
import 'package:zapatito/main-widgets/MAIN/login_page.dart';
import 'package:zapatito/main-widgets/MAIN/welcome_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zapatito/main-widgets/TIPO_CALZADO/tipo_calzado_page.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  // Inicializa el formato de fecha para español
  await initializeDateFormatting('es_ES', null);
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zapatito',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3a086c)),
        scaffoldBackgroundColor: Colors.white,
      ),

      // --- 2. CONFIGURACIÓN DE IDIOMAS (ESTO ARREGLA EL ERROR DEL CALENDARIO) ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés
      ],
      locale: const Locale('es', 'ES'), // Idioma predeterminado
      // -----------------------------------------------------------------------

      home: const WelcomePage(),
      routes: {
        '/welcome_page': (context) => const WelcomePage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/calzado_page': (context) => const CalzadoPage(),
        '/tipo_calzado': (context) => const TipoCalzadoPage(),
        '/inventario_page': (context) => const InventarioPage(),
      }
    );
  }
}
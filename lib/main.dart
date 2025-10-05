import 'package:flutter/material.dart';
import 'package:zapatito/main-widgets/welcome_page.dart';
import 'package:zapatito/splash-screens/splash_screen.dart';
import 'main-widgets/first_page.dart';
import 'main-widgets/second_page.dart';

void main() async {
  //LocalStorage.configurePrefs();
  await Future.delayed(const Duration(seconds: 3));
  runApp(const MyApp());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
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
        '/home': (context) => const MyHomePage(),
        '/splash_screen': (context) => const SplashScreen(),
        '/first_page': (context) => const FirstPage(),
        '/second_page': (context) => const SecondPage(),
      }
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zapatito'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MaterialButton(
              onPressed: () {
                Navigator.pushNamed(context, '/splash_screen', arguments: '/first_page',);
              },
              color: const Color.fromARGB(255, 33, 47, 243),
              textColor: Colors.white,
              child: const Text(
                'Pagina 1',
                ),
              ),
            MaterialButton(
              onPressed: () {
                Navigator.pushNamed(context, '/splash_screen', arguments: '/second_page',);
              },
              color: const Color.fromARGB(255, 33, 47, 243),
              textColor: Colors.white,
              child: const Text(
                'Pagina 2',
              ),
            ),
          ]
        )
      ),
    );
  }
}
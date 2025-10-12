import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:zapatito/auth/service/google_auth.dart';
import 'package:zapatito/components/Buttons/login_button.dart';
import 'package:zapatito/components/Buttons/singup_button.dart';
import 'package:zapatito/components/widgets.dart';
import 'package:zapatito/main-widgets/MAIN/home_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late final Future<FirebaseApp> _initialization;
  bool _navigated = false; // 👈 Evita múltiples redirecciones

  @override
  void initState() {
    super.initState();
    _initialization = Firebase.initializeApp();
  }

  void _checkIfSignedIn() async {
    if (_navigated) return; // Evita que se ejecute más de una vez
    _navigated = true;

    final isSignedIn = await GoogleAuthService().isCurrentSignIn();
    if (!mounted) return;

    if (isSignedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('FIREBASE INIT. ERROR');
            return const Center(
              child: Text("Error al inicializar Firebase"),
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            print('FIREBASE INIT. DONE ✅');
            // 👇 Solo se ejecuta una vez, después de renderizar el frame
            WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfSignedIn());
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Designwidgets().tittleCustom("Bienvenido a Zapatito"),
                const SizedBox(height: 20),
                const LoginButton(
                  text: "Iniciar Sesión",
                  color: Colors.white,
                  textColor: Color(0xff3a086c),
                  routeName: '/login',
                ),
                const SingupButton(
                  text: "Registrarte",
                  color: Color(0xff3a086c),
                  textColor: Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
